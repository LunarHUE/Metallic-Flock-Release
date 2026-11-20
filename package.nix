{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2905-pr.1739.2578";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2905-pr.1739.2578/metallic-flock-linux-amd64";
    hash = "sha256-HbOMJmkNoPeZxvSGVMhA1Ndsg5G+0Q7rb1RyNWrKoT8=";
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
