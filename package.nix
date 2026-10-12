{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.1847-pr.837.1506";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.1847-pr.837.1506/metallic-flock-linux-amd64";
    hash = "sha256-BwoQ1FCgvmo96B6Ha7gMZMJquUCzBxdtfEyHzTQn5+o=";
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
