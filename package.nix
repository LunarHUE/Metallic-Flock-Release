# The metallic-flock release package, with no nixpkgs: Nix's built-in fetcher
# downloads the release NAR and unpacks it. The NAR holds bin/metallic-flock and
# the bin/metallic symlink (release.yml packs it), so the output keeps the bin/
# layout system.nix and `nix run` expect. builtin:fetchurl unpacks only in
# recursive hash mode, so the hash is the NAR hash of that tree, not the sha256
# of the raw binary asset.
let
  version = "0.0.2926";
  url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2926/metallic-flock-linux-amd64.nar";
in
derivation {
  name = "metallic-flock-${version}";
  pname = "metallic-flock";
  inherit version url;
  urls = [ url ];
  system = "builtin";
  builder = "builtin:fetchurl";
  unpack = true;
  executable = false;
  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = "sha256-duRm05krHixJveJn8v4+5BKGL3AY1g1b3A3op98xfFo=";
  preferLocalBuild = true;
  impureEnvVars = [ "http_proxy" "https_proxy" "ftp_proxy" "all_proxy" "no_proxy" ];
}
