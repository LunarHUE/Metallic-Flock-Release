{
  description = "Metallic Flock — bare-metal cluster management";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }: let
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs { inherit system; };
    in {
      metallic-flock = pkgs.callPackage ./package.nix {};
      default = self.packages.${system}.metallic-flock;
    });

    nixosModules = {
      metallic-flock = import ./system.nix { inherit self; };
      default = self.nixosModules.metallic-flock;
    };
  };
}