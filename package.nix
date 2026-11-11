{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2105-pr.1519.1887";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2105-pr.1519.1887/metallic-flock-linux-amd64";
    hash = "sha256-4SGAsZd5Pu8iqW8ZvYgoR9pVQ5eGyaqQWhmEkt10e4g=";
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
