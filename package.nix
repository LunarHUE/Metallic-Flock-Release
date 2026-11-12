{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2277-pr.1565.2060";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2277-pr.1565.2060/metallic-flock-linux-amd64";
    hash = "sha256-Q2xytNaQ+HayjsMPLo/ej2j4+0bVWRqgQVKaFbLPWYM=";
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
