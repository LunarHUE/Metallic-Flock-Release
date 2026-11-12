{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2085-pr.1582.2029";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2085-pr.1582.2029/metallic-flock-linux-amd64";
    hash = "sha256-1Fs/7Qb73+gJWsig6pqGlQ8wWUe7hMYbxmJXUk94MeA=";
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
