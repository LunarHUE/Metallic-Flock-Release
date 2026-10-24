{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2054-pr.1139.1772";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2054-pr.1139.1772/metallic-flock-linux-amd64";
    hash = "sha256-llD3OBKCAwQ5Q67Ri6O4QZ6/DPa6T9QUpJrpN8f4mWw=";
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
