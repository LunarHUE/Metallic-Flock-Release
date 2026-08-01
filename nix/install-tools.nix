# The shared install toolset. It feeds THREE runtime surfaces, and on two of
# them it is the AGENT's runtime PATH, not an installer PATH:
#   - installed node + agent ISO: the list lands on the metallic-flock systemd
#     service `path` (services.metallic-flock, system.nix), which is the agent's
#     runtime PATH (and, on the agent ISO, where the install itself runs).
#   - controller ISO: the ISO disables the metallic-flock service and runs the
#     installer from an autologin shell, so it adds this list to
#     environment.systemPackages itself (metallic-image/controller-image.nix).
# The list is the same across all three so the install-critical PATH cannot
# drift between them.
#
# Core installer deps: git for the cluster repo, nix + nixos-install-tools for
# nixos-install/-enter/-generate-config, disko for partitioning, and the base
# utilities nixos-install invokes while populating /mnt.
#
# cryptsetup + smartmontools serve the Lode storage claim/unlock path; today
# they are execed by the AGENT at claim/unlock time, not by the installer. They
# live here rather than in the system.nix runtime-only appendix for two reasons:
# the controller ISO installer shell must also resolve them (the shared-toolset
# invariant — every surface carries the same PATH), and the install-time claim
# entry path is deferred to 6k, at which point cryptsetup genuinely becomes
# installer-execed. The two tools add a small, measured, accepted closure cost
# to the controller live ISO — the price of the shared-toolset invariant — with
# the measurement recorded in the phase-6 status evidence.
#
# NOTE: the Go list installToolBinaries in node/install/doctor.go is a
# deliberately NARROWER mirror of this file — the installer-execed subset only.
# It is intentionally NOT extended with cryptsetup/smartmontools by this slice:
# the installer doctor `LookPath`s each entry pre-wipe and would fail a legitimate
# install over tools the installer never calls today. Extending it is 6k's job,
# when the install-time claim entry path lands.
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
  cryptsetup smartmontools
]
