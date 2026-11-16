{ stdenv, fetchurl, lib }:
stdenv.mkDerivation {
  pname = "metallic-flock";
  version = "0.0.2434-branch.issue-prewave-sweep-fixes.43846845546";

  src = fetchurl {
    url = "https://github.com/lunarhue/metallic-flock-release/releases/download/branch-issue-prewave-sweep-fixes-43846845546/metallic-flock-linux-amd64";
    hash = "sha256-4olH2fWiWWq7rsWhYdCIYOll8rlRyKrdeJJEAvXZrgs=";
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
