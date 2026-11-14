{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2252-pr.1664.2269";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2252-pr.1664.2269/metallic-flock-linux-amd64";
    hash = "sha256-b0tN0ZAHlktTbwpmOqGh5M+I7P8bE5DZ+CN9aEOw0sE=";
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
