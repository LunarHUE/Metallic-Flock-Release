{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2732-pr.2055.2812";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2732-pr.2055.2812/metallic-flock-linux-amd64";
    hash = "sha256-98ru4eDN1Ce/LtEWYw3QO1Eu3J87cglcdYbh2JPoQIE=";
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
