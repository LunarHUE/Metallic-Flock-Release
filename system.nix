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
      # Port 80 is the controller dashboard (1c). Gated on cfg.mode ==
      # "controller" — NOT profile/solo (adopted solo agents must not open it).
      # In HA every server-role node resolves mode=controller and would open 80;
      # acceptable for Phase 1 (solo has one server), revisited in phase 6.
      allowedTCPPorts = [ 6443 10250 9000 22 ]
        ++ lib.optional (cfg.mode == "controller") 80;
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

      # Install-critical tools (git, nix, nixos-install-tools, disko, util-linux,
      # …) are factored into ./nix/install-tools.nix and SHARED with the
      # controller ISO's autologin installer shell (controller-image.nix) so the
      # two install paths can never drift. nixos-install needs the base utilities
      # during its "setting up /etc" and "installing the boot loader" phases.
      # Runtime-only tools below are appended here — the installer never execs
      # them, so they stay out of install-tools.nix (and off the controller ISO).
      path = (import ./nix/install-tools.nix pkgs) ++ (with pkgs; [
        procps iptables k3s openssh nixos-option nixos-rebuild
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
  };
}
