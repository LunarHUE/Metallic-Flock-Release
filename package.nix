{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2222-pr.1586.2056";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2222-pr.1586.2056/metallic-flock-linux-amd64";
    hash = "sha256-yMtfUc8jsi5BQeEMwS4RKGc1L5ZaI6q8+jaPHIjJkKg=";
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
