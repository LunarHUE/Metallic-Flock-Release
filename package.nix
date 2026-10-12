{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.1882-branch.slice-d2-generation-truth.38277806479";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/branch-slice-d2-generation-truth-38277806479/metallic-flock-linux-amd64";
    hash = "sha256-v+vNs6v1T4sLEQq2XNHvz0ci2p0uoAhmXjembfSLe58=";
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
