{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2460-pr.1577.2080";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2460-pr.1577.2080/metallic-flock-linux-amd64";
    hash = "sha256-dQ7o0cU6Or5Y6kKyjBoLSg0SQO0VNCKIWtXqAbO6YPI=";
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
