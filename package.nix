{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2402-pr.1318.1834";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2402-pr.1318.1834/metallic-flock-linux-amd64";
    hash = "sha256-QnNB4w7DQuR6o2lWlGvrnFyRCLfGTUM+ZPLzVeK8/W8=";
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
