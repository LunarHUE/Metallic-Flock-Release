{
  nixConfig = {
    extra-substituters = [
      "https://metallic.cachix.org"
    ];
    extra-trusted-public-keys = [
      "metallic.cachix.org-1:ETkGy1z4wMK9/UBOJ2nxliDATYvKhV5DAoRYeFA8beY="
    ];
  };

  description = "Metallic Flock - Public Release";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    nixpkgs.lib.recursiveUpdate
      # Only x86_64-linux is released; restrict to avoid confusing failures on other systems
      (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          packages = {
            metallic-flock = pkgs.callPackage ./package.nix {};
            default = self.packages.${system}.metallic-flock;
          };
        }))
      {
        nixosModules = {
          metallic-flock = import ./system.nix { inherit self; };
          default = self.nixosModules.metallic-flock;
        };
      };
}
