{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2771-pr.1739.2487";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2771-pr.1739.2487/metallic-flock-linux-amd64";
    hash = "sha256-JXh4Wm3lYo6T5CCcOOJH2d80/X2+flGrKPQjAZ+/g0k=";
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
