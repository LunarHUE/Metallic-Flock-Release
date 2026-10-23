{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2012-pr.1040.1730";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2012-pr.1040.1730/metallic-flock-linux-amd64";
    hash = "sha256-uW4TFnaSJDlQ/yLQkX2tMtXgGGWJjp5G7GpTnq0Ysys=";
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
