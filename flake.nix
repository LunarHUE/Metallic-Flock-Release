{
  description = "Compute Flock - Public Release";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # 1. Version Control
        # You update these when you do a new release
        version = "0.0.2";
        
        # 2. Architecture Mapping
        # Map Nix system names to your Binary release naming convention
        arch = if system == "x86_64-linux" then "amd64"
               else if system == "aarch64-linux" then "arm64"
               else throw "Unsupported system: ${system}";
               
        # 3. Checksums (You must update these for every release!)
        # Running `nix-prefetch-url` on your binaries gives you these
        sha256 = if system == "x86_64-linux" then "sha256-PkQl..." 
                 else "sha256-AbCd..."; 

      in rec {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "metallic-flock";
          inherit version;

          # Download the binary instead of building source
          src = pkgs.fetchurl {
            url = "https://github.com/lunarhue/metallic-flock/releases/download/v${version}/metallic-flock-linux-${arch}";
            sha256 = sha256;
          };

          # No build phase needed for pre-compiled binaries
          dontUnpack = true; 
          
          # Install Phase: Create the bin directory and copy the file
          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/metallic-flock
            chmod +x $out/bin/metallic-flock
          '';

          meta = with pkgs.lib; {
            description = "Compute Flock Agent";
            homepage = "https://github.com/lunarhue/metallic-flock";
            license = licenses.mit;
            platforms = [ "x86_64-linux" "aarch64-linux" ];
          };
        };
      })
    
    # 4. THE NIXOS MODULE
    # The module lives here so public users can import it.
    // {
      nixosModules.default = { pkgs, lib, config, ... }:
        let 
          cfg = config.services.metallic-flock; 
          # We refer to the package defined above in this flake
          defaultPackage = self.packages.${pkgs.system}.default;
        in {
          options.services.metallic-flock = with lib; {
            enable = mkEnableOption "Compute Flock Service";

            package = mkOption {
              type = types.package;
              default = defaultPackage; 
              description = "The metallic-flock package to use.";
            };

            mode = mkOption {
              type = types.str;
              default = "agent";
              description = "Mode (agent/controller).";
            };
          };

          config = lib.mkIf cfg.enable {
            # ... (Copy your Firewall and Systemd config from your original snippet here) ...
            # The only change is inside serviceConfig.ExecStart:
            
            systemd.services.metallic-flock = {
               # ... other config ...
               serviceConfig = {
                 # Use the package defined in options
                 ExecStart = "${cfg.package}/bin/metallic-flock --mode ${cfg.mode}";
                 # ...
               };
            };
          };
        };
    };
}
