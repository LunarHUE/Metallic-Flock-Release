{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2539-branch.slice-nixos-2611-a2.44251223928";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/branch-slice-nixos-2611-a2-44251223928/metallic-flock-linux-amd64";
    hash = "sha256-TDc/qnRmD+68B0daooyroh5vRVGQoHMQ3yGGpvZzxyg=";
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
