_default:
  @{{just_executable()}} --list

_build-only *ARGS:
  #!/usr/bin/env bash
  set -e
  cd "{{ justfile_directory() }}"
  nix build .#homeConfig.activationPackage {{ ARGS }}
  echo
  echo "Home config successfully build!"
  echo

# Build the current home config WITHOUT switching to it
build-and-diff *ARGS: (_build-only ARGS)
  #!/usr/bin/env bash
  set -euo pipefail

  cd "{{ justfile_directory() }}"

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
  #!/usr/bin/env bash
  set -e
  cd "{{ justfile_directory() }}"
  ./result/activate
