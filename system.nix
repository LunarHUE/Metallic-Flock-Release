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
      description = "Mode in which to run Compute Flock (agent/controller).";
    };

    liveMode = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Set true on the bare-metal install ISO. Drops the k3s.service
        ordering dependency (no k3s on the live USB) and exports
        METALLIC_FLOCK_LIVE_MODE=1 so the agent takes the install-to-disk
        code path instead of the in-RAM reconcile path.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    networking.firewall = {
      allowedTCPPorts = [ 6443 10250 9000 22 ];
      allowedUDPPorts = [ 8472 5353 ];
    };

    systemd.services.metallic-flock = {
      description = "Compute Flock Agent";
      after = [ "network-online.target" ]
        ++ lib.optional (!cfg.liveMode) "k3s.service";
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [ procps iptables k3s opentofu git openssh nix nixos-option nixos-rebuild ];

      environment = {
        NIX_PATH = "nixpkgs=${pkgs.path}";
      } // lib.optionalAttrs cfg.liveMode {
        METALLIC_FLOCK_LIVE_MODE = "1";
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
