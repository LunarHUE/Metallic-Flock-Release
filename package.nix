{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2632";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2632/metallic-flock-linux-amd64";
    hash = "sha256-SA/8YF3Iq7+ZkoIg4esZeGldhnJldgiqtCELcR7vsAo=";
  };

  dontUnpack = true;

  installPhase = ''
    install -Dm755 $src $out/bin/metallic-flock
    ln -s $out/bin/metallic-flock $out/bin/metallic
  '';

  meta = with lib; {
    description = "Compute Flock Agent";
    platforms = [ "x86_64-linux" ];
  };
}
