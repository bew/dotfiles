_default:
  @{{just_executable()}} --list

_build-only *ARGS:
  #!/usr/bin/env bash
  set -euo pipefail
  cd "{{justfile_directory()}}"
  nix build .#homeConfig.activationPackage {{ ARGS }}
  echo
  echo "Home config successfully build!"
  echo

# Build the current home config WITHOUT switching to it
build-and-diff *ARGS: (_build-only ARGS)
  #!/usr/bin/env bash
  set -euo pipefail
  cd "{{justfile_directory()}}"

  DIFF_FILE="{{justfile_directory()}}/.nix-lastBuild-homeDiff.txt"
  # NOTE: `nix-env -q --out-path home-manager-path`
  # looks like `home-manager-path /nix/store/...`
  CURRENT_HOME_MANAGER_PATH="$(nix-env -q --out-path home-manager-path | awk '{ print $2 }')"
  BUILT_HOME_MANAGER_PATH="./result/home-path"

  echo "Changed packages between current ('$CURRENT_HOME_MANAGER_PATH') and build:"
  nix store diff-closures $CURRENT_HOME_MANAGER_PATH $BUILT_HOME_MANAGER_PATH > $DIFF_FILE
  cat $DIFF_FILE
  echo "--- NOTE: saved diff to '$DIFF_FILE'"
  echo
  # echo "Run 'just build' to apply the changes :)"
  echo

# Build the current home config AND switch to it
switch *ARGS: (_build-only ARGS)
  #!/usr/bin/env bash
  cd "{{justfile_directory()}}"
  ./result/activate
