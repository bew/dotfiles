_default:
  @{{just_executable()}} --list

_build-only *ARGS:
  #!/usr/bin/env bash
  set -e
  nix build .#homeConfig.activationPackage {{ ARGS }}
  echo
  echo "Home config successfully build!"
  echo

# Build the current home config WITHOUT switching to it
build-and-diff *ARGS: (_build-only ARGS)
  #!/usr/bin/env bash
  set -euo pipefail

  # NOTE: `nix-env -q --out-path home-manager-path`'s output
  #       looks like `home-manager-path /nix/store/...`
  CURRENT_HOME_MANAGER_PATH=$(nix-env -q --out-path home-manager-path | awk '{ print $2 }')
  BUILT_HOME_MANAGER_PATH="./result/home-path"
  DIFF_FILE="./.nix-lastBuild-homeDiff.txt"

  # Helper script to nicely show:
  # * `nix store diff-closures`'s output
  # * the closure sizes (and +/- diff)
  ./bin/nix-diff-closures.sh $CURRENT_HOME_MANAGER_PATH $BUILT_HOME_MANAGER_PATH -o $DIFF_FILE

# Build the current home config AND switch to it
switch *ARGS: (_build-only ARGS)
  @./result/activate

upgrade-multiuser-nix:
  @# Ref: https://nixos.org/manual/nix/stable/installation/upgrading.html
  sudo nix-channel --update
  sudo nix-env -iA nixpkgs.nix nixpkgs.cacert
  sudo systemctl daemon-reload
  sudo systemctl restart nix-daemon
  sudo -k

# Bootstrap dotfiles, remove default channel, build and switch home config
# NOTE: task starts with 'z-' because ~never used, and I want 'just b<TAB>' to compl to build
z-bootstrap-build-and-switch:
  # Setup channels (rename default in case we really need it)
  nix-channel --remove nixpkgs || true
  nix-channel --remove legacy_channel_please_use_flakes_now || true
  nix-channel --add https://nixos.org/channels/nixpkgs-unstable legacy_channel_please_use_flakes_now
  nix-channel --update

  {{ just_executable() }} switch
