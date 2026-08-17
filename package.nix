{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.750";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.750/metallic-flock-linux-amd64";
    hash = "sha256-73Sjxh+wxgT6uK7ujdpP/zk8ax5wDhzKa9iSVxuFe3Y=";
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
