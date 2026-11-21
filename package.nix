{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2712-pr.2051.2776";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2712-pr.2051.2776/metallic-flock-linux-amd64";
    hash = "sha256-wzRztrO9w+XKrIiN3ey/1kTfuF5gdHCbqmjgX1GHUY0=";
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
