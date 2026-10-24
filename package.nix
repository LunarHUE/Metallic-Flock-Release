{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2067-pr.1298.1786";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2067-pr.1298.1786/metallic-flock-linux-amd64";
    hash = "sha256-vbQXYt9VfXkdSDGowO4B+kkwd6wHrbiuWQ+4BSsvD/A=";
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
