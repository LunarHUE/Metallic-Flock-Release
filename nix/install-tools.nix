# Tools the self-installer (install.Run + the snapshot/seed/clone helpers it
# calls) shells out to: git for the cluster repo, nix + nixos-install-tools for
# nixos-install/-enter/-generate-config, disko for partitioning, and the base
# utilities nixos-install invokes while populating /mnt. Imported by BOTH the
# installed-node systemd service PATH (system.nix) and the controller ISO's
# autologin installer shell (metallic-image/controller-image.nix) so the
# install-critical PATH cannot drift between the two install paths.
#
# Runtime-only tools the installer never execs (procps iptables k3s openssh
# nixos-option nixos-rebuild) are NOT here — they are appended in system.nix so
# they stay off the controller live ISO.
pkgs: with pkgs; [
  git
  nix nixos-install-tools
  disko jq
  util-linux coreutils gnugrep gnused gawk findutils diffutils ethtool
  e2fsprogs dosfstools parted systemd
]
