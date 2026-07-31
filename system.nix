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
        # Update channel, threaded UNCONDITIONALLY alongside PROFILE (same
        # source=env invariant — the controller's updatecheck poller reads
        # METALLIC_UPDATE_CHANNEL). The option lives in the flock.* drop-in
        # library (modules/update.nix), which installed nodes always import; the
        # `or "stable"` fallback keeps the two live ISOs building — they enable
        # this service but do NOT import the flock modules, so flock.update.channel
        # is absent there (host-verified: config.<undeclared>.x or default → default).
        # On installed nodes the option is always declared, so the real channel
        # always threads (source=env holds).
        METALLIC_UPDATE_CHANNEL = config.flock.update.channel or "stable";
      } // lib.optionalAttrs (cfg.releaseRef != "") {
        METALLIC_RELEASE_REF = cfg.releaseRef;
      };

      serviceConfig = {
        # DELIBERATELY the systemPackages symlink, NOT "${cfg.package}/bin/...".
        #
        # Two things depend on it. (1) The unit body must not change on a
        # metallic-flock-only bump, or reloadTriggers below can never produce a
        # reload — an ExecStart carrying the store path changes on every version
        # and forces a restart, silently killing the whole fd-handoff path.
        # (2) tableflip re-execs os.Args[0] and offers no way to override it, so
        # with a store path the successor would re-exec the OLD binary and the
        # upgrade would be a no-op. LookPath passes a slash-containing path
        # through verbatim, so the symlink is resolved at exec time — and
        # activation (where /run/current-system flips) strictly precedes the
        # reload step, so by the time SIGHUP lands this already points at the new
        # binary. Valid only because environment.systemPackages = [ cfg.package ]
        # above guarantees the symlink exists and tracks cfg.package.
        ExecStart = "/run/current-system/sw/bin/metallic-flock ${cfg.mode}";
        DynamicUser = false;
        User = "root";
        Group = "root";
        Restart = "always";
        RestartSec = "5s";
        # Backstop for the stop path, NOT the fix. The process bounds its own
        # shutdown legs in-process (bounded gRPC drain + joined HTTP drain); this
        # only keeps a future unbounded wait from costing systemd's 90s default
        # and a SIGKILL — which is what every controller stop cost until
        # 2026-07-25, on every update, since a self-apply restarts this unit.
        #
        # > **Stale (corrected 2026-07-31)** — the "bounds its own shutdown legs
        # > in-process" claim above was TRUE OF THE DESIGN but FALSE OF THE
        # > RUNTIME until this date. The binary installed no signal handler at
        # > all (cmd/root.go called rootCmd.Execute(), never ExecuteContext), so
        # > SIGTERM hit Go's default disposition and killed the process
        # > instantly: the errgroup teardown, the bounded gRPC drain and the 30s
        # > detached terminal-generation write never ran, and this 45s budget
        # > bounded a drain that could not happen. The SIGTERM/SIGINT handler
        # > added in the same change as the reload wiring below makes the claim
        # > true for the first time. Kept rather than rewritten per docs/spec.md
        # > §8.4.
        #
        # 45s is derived, not guessed: the errgroup's legs stop CONCURRENTLY, so
        # the budget is a max, not a sum — the longest legitimate leg is the 30s
        # terminal-generation write (adoption/reconcile.go completeDetached),
        # which must survive a Postgres that is itself restarting in the same
        # switch. 30s + slack, well under the 90s default. Applies to both modes
        # deliberately: the agent's reconcile stop is bounded the same way.
        TimeoutStopSec = "45s";
        StateDirectory = "metallic-flock";
        CacheDirectory = "metallic-flock";

      }
      # Type=notify is what lets the fd handoff survive. Under the default
      # Type=simple systemd tracks the ExecStart pid as MAINPID; after a handoff
      # that process exits, systemd sees the main process die and — with
      # Restart=always and the default KillMode=control-group — kills the whole
      # cgroup including the brand-new successor, then restarts the unit. Worse
      # than no handoff at all. The successor instead sends MAINPID+READY=1 over
      # $NOTIFY_SOCKET, which re-points systemd at it before the old process
      # exits. NotifyAccess=all is required because that datagram comes from a
      # process that is not yet MAINPID (safe here: the unit runs as root).
      #
      # ISO-GATED. The live ISO runs this same unit with mode "agent iso" and
      # deliberately grows no upgrade machinery. It does send READY=1 anyway
      # (cmd/agent/iso.go), so this gate is belt-and-braces rather than the sole
      # protection — but without it, one edit that dropped that call would leave
      # the ISO hanging until TimeoutStartSec and then restart-looping forever
      # on startLimitIntervalSec=0. Only "agent iso" can reach this: the
      # controller ISO force-disables the service entirely and runs its
      # installer from a login shell, so "controller iso" is never a cfg.mode.
      // lib.optionalAttrs (!(lib.hasSuffix " iso" cfg.mode)) {
        Type = "notify";
        NotifyAccess = "all";

        # SIGHUP to the main pid triggers the in-process listener handoff.
        #
        # coreutils, NOT "${cfg.package}/bin/...", and this is load-bearing: any
        # cfg.package interpolation in the unit body re-embeds a store path that
        # moves on every version bump, which changes the unit, which forces a
        # restart instead of a reload — silently disabling the entire path this
        # block exists to enable. coreutils does not move when metallic-flock
        # does.
        #
        # Inside the ISO gate with Type/NotifyAccess: the ISO binary installs no
        # HUP handler, so an ExecReload there would let a manual
        # `systemctl reload` kill the process on HUP's default disposition
        # (Restart=always recovers, but a reload verb that kills is worse than
        # no reload verb). Without ExecReload, reload on the ISO is simply
        # refused.
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      };

      # A package-only bump must RELOAD (fd handoff, no downtime) rather than
      # stop/start. switch-to-configuration reloads when the only unit-file
      # delta is X-Reload-Triggers or ExecReload, and restarts on any other
      # delta — restart winning when a unit lands on both lists. Combined with
      # the store-path-free ExecStart above, that gives exactly the split we
      # need:
      #
      #   package bump only  → X-Reload-Triggers differs → reload → fd handoff
      #   env / mode change  → [Service] body differs    → restart (fresh env)
      #   both               → body differs              → restart
      #
      # The restart case is the important one to preserve. reloadIfChanged was
      # REJECTED precisely because it converts any unit change into a reload,
      # including a changed environment= block — and a re-exec'd process
      # inherits the OLD environ, so METALLIC_FLOCK_PROFILE and
      # METALLIC_UPDATE_CHANNEL would silently go stale and break the
      # source=env invariant. Env changes must restart.
      reloadTriggers = lib.optional (!(lib.hasSuffix " iso" cfg.mode)) cfg.package;

      # Turns the restart case from stop → activate → start into a single
      # systemctl restart, removing the activation-window gap. This is the
      # baseline for every path that still restarts.
      stopIfChanged = false;
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
