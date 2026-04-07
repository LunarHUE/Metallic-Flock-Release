{ lib, stdenv, fetchurl, autoPatchelfHook }:

let
  version = "0.1.0";
  hashes = {
    x86_64-linux = "sha256-AAAA...";
    aarch64-linux = "sha256-BBBB...";
  };
  arch = {
    x86_64-linux = "amd64";
    aarch64-linux = "arm64";
  };
in stdenv.mkDerivation {
  pname = "metallic-flock";
  inherit version;

  src = fetchurl {
    url = "https://github.com/LunarHUE/Metallic-Flock-Release/releases/download/v${version}/metallic-flock-linux-${arch.${stdenv.hostPlatform.system}}";
    hash = hashes.${stdenv.hostPlatform.system};
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/metallic-flock
    chmod +x $out/bin/metallic-flock
  '';

  meta = with lib; {
    description = "Metallic Flock — bare-metal cluster agent";
    homepage = "https://github.com/LunarHUE/Metallic-Flock-Release";
    license = licenses.unfree;
    platforms = builtins.attrNames hashes;
  };
}