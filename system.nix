# We wrap the standard module signature to inject the flake's `self`
{ self }: 

{ config, lib, pkgs, ... }:

let
  cfg = config.services.metallic-flock;
in {
  options.services.metallic-flock = with lib; {
    enable = mkEnableOption "Compute Flock Service";

    package = mkOption {
      type = types.package;
      # Grab the package we built in package.nix dynamically based on the target system
      default = self.packages.${pkgs.system}.metallic-flock;
      description = "The Compute Flock package to use.";
    };

    mode = mkOption {
      type = types.str;
      default = "agent";
      description = ''
        Subcommand passed to metallic-flock. Valid values:
          "agent"         — installed node (heartbeat + reconcile)
          "agent iso"     — live ISO (adoption + install + reboot)
          "controller"    — controller node
      '';
    };

    releaseRef = mkOption {
      type = types.str;
      default = "";
      description = ''
        Git ref in lunarhue/metallic-flock-release to use during install.
        When non-empty, the agent overrides the metallic-flock flake input
        before nixos-install. Empty = use cluster repo's flake.lock as-is.
      '';
    };

    profile = mkOption {
      type = types.enum [ "solo" "production" ];
      default = "production";
      description = ''
        Operating profile, passed to metallic-flock via METALLIC_FLOCK_PROFILE.
          "solo"        — single-node convenience profile (listens on :80)
          "production"  — multi-node profile (listens on :8080)
        On installed nodes this is set by the generated cluster config
        (services.metallic-flock.profile in node-default.nix), so the process
        resolves profile=...source=env. source=default would mean this thread
        broke.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    networking.firewall = {
      # Ports 80 (plaintext) and 443 (HTTPS, 3c-6) are the controller dashboard
      # (1c/3c). Both gated on cfg.mode == "controller" — NOT profile/solo
      # (adopted solo agents must not open them). In HA every server-role node
      # resolves mode=controller and would open 80/443; acceptable for Phase 1
      # (solo has one server), revisited in phase 6. k3s runs with
      # --disable=traefik --disable=servicelb (see modules/k3s.nix +
      # nix/k3s_airgap_test.go), so nothing else claims :80/:443 via the silent
      # servicelb hostPort/PREROUTING DNAT — the controller binds them directly.
      allowedTCPPorts = [ 6443 10250 9000 22 ]
        ++ lib.optionals (cfg.mode == "controller") [ 80 443 ];
      allowedUDPPorts = [ 8472 5353 ];
    };

    systemd.services.metallic-flock = {
      description = "Compute Flock Agent";
      after = [ "network-online.target" ]
        ++ lib.optional (cfg.mode == "controller") "postgresql.service"
        # Live installers ("agent iso" / "controller iso") run no k3s, so they
        # must not order after a k3s.service that will never start.
        ++ lib.optional (!(lib.hasSuffix " iso" cfg.mode)) "k3s.service";
      requires = lib.optional (cfg.mode == "controller") "postgresql.service";
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      # Never give up restarting the controller. With Restart=always but the default
      # start-limit (5 starts / 10s), systemd would mark the unit failed and stop after
      # a few fast crashes — leaving the node with no controller and no self-repair.
      # startLimitIntervalSec=0 disables that limit so it keeps retrying indefinitely.
      startLimitIntervalSec = 0;

      # Install-critical tools (git, nix, nixos-install-tools, disko, util-linux,
      # …) are factored into ./nix/install-tools.nix and SHARED with the
      # controller ISO's autologin installer shell (controller-image.nix) so the
      # two install paths can never drift. nixos-install needs the base utilities
      # during its "setting up /etc" and "installing the boot loader" phases.
      # Runtime-only tools below are appended here — the installer never execs
      # them, so they stay out of install-tools.nix (and off the controller ISO).
      path = (import ./nix/install-tools.nix pkgs) ++ (with pkgs; [
        procps iptables k3s openssh nixos-option nixos-rebuild dmidecode
      ]);

      environment = {
        NIX_PATH = "nixpkgs=${pkgs.path}";
        # Threaded UNCONDITIONALLY (never under optionalAttrs): every installed
        # node must always carry its profile so the process resolves
        # source=env. Gating this would reintroduce source=default and break
        # the metallic.local path. See config.resolveProfile.
        METALLIC_FLOCK_PROFILE = cfg.profile;
      } // lib.optionalAttrs (cfg.releaseRef != "") {
        METALLIC_RELEASE_REF = cfg.releaseRef;
      };

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/metallic-flock ${cfg.mode}";
        DynamicUser = false;
        User = "root";
        Group = "root";
        Restart = "always";
        RestartSec = "5s";
        StateDirectory = "metallic-flock";
        CacheDirectory = "metallic-flock";
      };
    };

    # GC roots for the baked offline flake-input sources. The controller self-install
    # copies the cluster input SOURCES into this node's store and records them in
    # /etc/metallic/offline-inputs (node/install persistOfflineSources). Those sources
    # are flake INPUTS, not part of any system closure, so `nix-collect-garbage` would
    # delete them and break offline reconcile. This oneshot (re)creates one GC root per
    # manifest entry on every boot — idempotent, and a no-op when the manifest is absent
    # (adopted agents, or a controller from a non-offline ISO), so it is safe on every
    # node. A failed root is surfaced as a failed unit (diagnosable), not swallowed.
    systemd.services.metallic-offline-gcroots = {
      description = "Create/repair GC roots for baked offline flake input sources";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" "nix-daemon.socket" ];
      before = [ "nix-gc.service" ];
      path = with pkgs; [ nix coreutils ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        manifest=/etc/metallic/offline-inputs
        if [ ! -f "$manifest" ]; then
          echo "metallic-offline-gcroots: no manifest at $manifest; nothing to root"
          exit 0
        fi
        rootdir=/nix/var/nix/gcroots/metallic-offline-inputs
        mkdir -p "$rootdir"
        rc=0
        while IFS='=' read -r name path; do
          case "$name" in ""|"#"*) continue ;; esac
          if [ -e "$path" ]; then
            if nix-store --add-root "$rootdir/$name" --realise "$path" >/dev/null; then
              echo "rooted $name -> $path"
            else
              echo "ERROR: failed to root $name -> $path" >&2; rc=1
            fi
          else
            echo "ERROR: offline source $name missing from store: $path" >&2; rc=1
          fi
        done < "$manifest"
        exit $rc
      '';
    };
  };
}
