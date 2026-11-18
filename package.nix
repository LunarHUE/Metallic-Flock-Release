{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2534-branch.slice-nixos-2611-a1b.44244264712";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/branch-slice-nixos-2611-a1b-44244264712/metallic-flock-linux-amd64";
    hash = "sha256-IHt0+eWON0l6mpxI8ur6KHxmTIVZmM5EWiX62dQSeCg=";
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm755 $src $out/bin/metallic-flock
  '';

  meta = with lib; {
    description = "Compute Flock Agent";
    platforms = [ "x86_64-linux" ];
  };
}
