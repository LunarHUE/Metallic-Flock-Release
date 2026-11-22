# The metallic-flock release package, with no nixpkgs: Nix's built-in fetcher
# downloads the release NAR and unpacks it. The NAR holds bin/metallic-flock and
# the bin/metallic symlink (release.yml packs it), so the output keeps the bin/
# layout system.nix and `nix run` expect. builtin:fetchurl unpacks only in
# recursive hash mode, so the hash is the NAR hash of that tree, not the sha256
# of the raw binary asset.
let
  version = "0.0.2747-pr.2151.2984";
  url = "https://github.com/lunarhue/metallic-flock-release/releases/download/v0.0.2747-pr.2151.2984/metallic-flock-linux-amd64.nar";
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
  outputHash = "sha256-ysR5WBJOwMRbCDeN5lo5h/KTYstjOPgiQLH3Bc9LQ8c=";
  preferLocalBuild = true;
  impureEnvVars = [ "http_proxy" "https_proxy" "ftp_proxy" "all_proxy" "no_proxy" ];
}
