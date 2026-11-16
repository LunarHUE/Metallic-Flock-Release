{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2335-pr.1729.2317";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2335-pr.1729.2317/metallic-flock-linux-amd64";
    hash = "sha256-4DRoVyxEWF1QvA+oKNVvp3JR1IsDLsPRKNYvwdAuS4o=";
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
