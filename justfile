set lazy # eval variable value lazily, on first need
set unstable # necessary for 'which' function

# Use full path to exe if just isn't in $PATH, or 'just' otherwise
just_exe := if which("just") == "" { just_executable() } else { "just" }

CURRENT_HOME := ```
  CURRENT_HOME_NAME_PATH=./current-home-name

  if ! [[ -f "$CURRENT_HOME_NAME_PATH" ]]; then
    >&2 echo "!! Cannot use this action: File '$CURRENT_HOME_NAME_PATH' does not exist / is not readable"
    exit 1
  fi
  home_name=$(head -n1 "$CURRENT_HOME_NAME_PATH")
  >&2 echo ":: Current home name: $home_name (found in '$CURRENT_HOME_NAME_PATH')"
  >&2 echo # blank line

  echo "$home_name"
```

_default:
  @{{just_exe}} --list

# Eval any home (even for different system)
doeval-home NAME *ARGS:
  nix eval .#homeConfig."{{ NAME }}".activationPackage {{ ARGS }}

# Eval current home (useful to check without build)
reeval-home *ARGS:
  nix eval .#homeConfig."{{ CURRENT_HOME }}".activationPackage {{ ARGS }}

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

  show_and_run $nix_bin build .#homeConfig."{{ CURRENT_HOME }}".activationPackage {{ ARGS }}
  echo
  echo "Home config successfully build!"
  echo

# Build the current home config WITHOUT switching to it
rebuild-and-diff *ARGS: (rebuild ARGS)
  #!/usr/bin/env bash
  set -euo pipefail

  diff_tool=dix

  if ! command -v $diff_tool 2>/dev/null; then
    >&2 echo "ERROR: Cannot diff home, '$diff_tool' not in \$PATH"
    exit 1
  fi
  echo # blank line

  CURRENT_HOME_MANAGER_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager"
  BUILT_HOME_MANAGER_PATH="./result"

  DIFF_FILE="./.nix-lastBuild-homeDiff.txt"
  $diff_tool --color=always $CURRENT_HOME_MANAGER_PATH $BUILT_HOME_MANAGER_PATH | tee $DIFF_FILE
  # cleanup ANSI sequences from diff file
  # (depends on ansifilter & moreutils (for 'sponge'))
  ( ansifilter "$DIFF_FILE" || cat "$DIFF_FILE" ) | sponge "$DIFF_FILE"

# Build the current home config AND switch to it
reswitch *ARGS: (rebuild ARGS)
  cd {{ justfile_directory() }}
  ./result/activate
