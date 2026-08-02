{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.627";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.627/metallic-flock-linux-amd64";
    hash = "sha256-pvK9xg5ChNZ7hP7bNBXIepR0oa79c1Zx/7vZMmMe+aA=";
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
