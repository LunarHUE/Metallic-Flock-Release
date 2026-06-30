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

  # x86_64-linux ONLY by design — the install target is x86_64-linux. nixpkgs is the
  # sole input (one fewer public dependency on the install boundary), and the release
  # package is built with THIS flake's own locked nixpkgs (Layer-3 identity — see the
  # cluster template comment on why metallic-flock must not follow the consumer's nixpkgs).
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      packages.${system} = {
        metallic-flock = pkgs.callPackage ./package.nix { };
        default = self.packages.${system}.metallic-flock;
      };
      nixosModules = {
        metallic-flock = import ./system.nix { inherit self; };
        default = self.nixosModules.metallic-flock;
      };
    };
}
