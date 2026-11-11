{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2078-pr.1573.2002";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2078-pr.1573.2002/metallic-flock-linux-amd64";
    hash = "sha256-3DzR4EzDhdZfhlPZTd1RhJNkQ1VhuhcYd0hL9jAmWwg=";
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
