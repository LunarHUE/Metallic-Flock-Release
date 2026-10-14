{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.1912-pr.926.1585";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.1912-pr.926.1585/metallic-flock-linux-amd64";
    hash = "sha256-10vosDq42pRe6m+8Y2/kS9hIWEszTOcSswC2BHhmum8=";
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
