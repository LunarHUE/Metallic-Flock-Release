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

  # x86_64-linux ONLY by design: the install target is x86_64-linux. No inputs at
  # all: the release package is a fixed-output builtin:fetchurl of the release
  # NAR (package.nix), so its store path depends only on its name and NAR hash
  # and is identical at ISO prebuild, at install and on every cluster channel.
  # The flake.lock beside this file is the root-only lock release.yml writes.
  inputs = { };

  # `...`: a cluster lock written against an older release still passes that
  # release's `nixpkgs` input until the next relock drops it.
  outputs = { self, ... }:
    let
      system = "x86_64-linux";
    in
    {
      packages.${system} = {
        metallic-flock = import ./package.nix;
        default = self.packages.${system}.metallic-flock;
      };
      nixosModules = {
        metallic-flock = import ./system.nix { inherit self; };
        default = self.nixosModules.metallic-flock;
      };
    };
}
