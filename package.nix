{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2786-pr.1739.2493";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2786-pr.1739.2493/metallic-flock-linux-amd64";
    hash = "sha256-pVnWAdMU8LJP2oGwdPVeZB01/3Lgy2Wi2lMRqIv0fVM=";
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
