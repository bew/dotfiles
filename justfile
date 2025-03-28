_default:
  @{{ just_executable() }} --list

rebuild *ARGS:
  #!/usr/bin/env bash
  set -e
  function show_and_run {
    echo "=>> $*"
    "$@"
  }
  nix_bin=nom
  if ! command -v nom >/dev/null 2>&1; then
    echo '!!! `nom` (nix-output-monitor) is not in $PATH, using native `nix`'
    nix_bin=nix
  fi
  if [[ -n "${NIX_NOT_NOM:-}" ]]; then
    echo '$NIX_NOT_NOM is set, using native `nix`'
    nix_bin=nix
  fi
  show_and_run $nix_bin build '.#homeConfig.activationPackage' {{ ARGS }}
  echo
  echo "Home config successfully build!"
  echo

# Build the current home config WITHOUT switching to it
rebuild-and-diff *ARGS: (rebuild ARGS)
  #!/usr/bin/env bash
  set -euo pipefail
  cd {{ justfile_directory() }}

  CURRENT_HOME_MANAGER_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager"
  BUILT_HOME_MANAGER_PATH="./result"
  DIFF_FILE="./.nix-lastBuild-homeDiff.txt"

  # FIXME FIXME FIXME:
  # This doesn't work right, I need to diff the whole final home-manager derivation, not just it's 'path' derivation!
  # => I'm currently missing any changes of the files (home/xdg/..) and added dependencies that are
  #    not in 'path' (like something that is referenced in a file / in a string)
  # I'd like to also see what new binaries I have in bin/ (and where they come from?)

  # Helper script to nicely show:
  # * `nix store diff-closures`'s output
  # * the closure sizes (and +/- diff)
  ./bin/nix-diff-closures.sh $CURRENT_HOME_MANAGER_PATH $BUILT_HOME_MANAGER_PATH -o $DIFF_FILE

# Build the current home config AND switch to it
reswitch *ARGS: (rebuild ARGS)
  cd {{ justfile_directory() }}
  ./result/activate
