{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2257-pr.1582.2070";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2257-pr.1582.2070/metallic-flock-linux-amd64";
    hash = "sha256-Rlt7hcaB5FSmn09A9EMG27jNEA1Fi2dbG0ZZnGUD3rM=";
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
