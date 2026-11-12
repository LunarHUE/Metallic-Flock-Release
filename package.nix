{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2087-pr.1582.2033";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2087-pr.1582.2033/metallic-flock-linux-amd64";
    hash = "sha256-bcTZ9NLr5SA1vxMbYDmVqYn/Jg3i5v4Cx9xu5sQd3Rc=";
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
