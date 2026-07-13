#!/usr/bin/env bash

set -euo pipefail # Safe, strict script execution

INDENT="    "

function make-link() {
  local link_to="$1"
  local link_destination="$2"

  # When linking `src/bar` to `foo/`
  # $link_destination should be `foo/bar`
  #
  # NOTE: in bash, ${foo:(-N)} takes last N chars
  # Ref: https://stackoverflow.com/a/19858692
  if [[ "${link_destination:(-1)}" == "/" ]]; then
    link_destination="${link_destination}$(basename "$link_to")"
  fi

  echo "'$link_destination' -> '$link_to'"

  # Check if link already correct
  local old_link_to
  old_link_to="$(readlink "$link_destination" || true)"
  if [[ "$link_to" == "$old_link_to" ]]; then
    echo "${INDENT}already correct, nothing to do"
    return
  fi

  if [[ "$DRYRUN_ONLY" == "true" ]]; then
    local before before_short
    if [[ -n "$old_link_to" ]]; then
      before_short="retarget"
      before="was '$old_link_to'"
    else
      before_short="new"
      before="to create"
    fi
    echo "${INDENT}[DRYRUN] $before_short: $before"
  else
    ln -sf --no-dereference "$link_to" "$link_destination"
  fi
}

function label() {
  echo
  echo "---- $1"
}

function skip() {
  echo "SKIPPED: $*"
}

# opt-in apply
DRYRUN_ONLY=true
if [[ "${1:-}" == "--apply" ]]; then
  DRYRUN_ONLY=false
fi
DOTS_PATH=$(dirname "$(realpath "$0")")

label "Bootstraping .dot symlinks"
make-link "$DOTS_PATH"  ~/.dot

label "bin links"
make-link ~/.dot/bin     ~/.bin
make-link ~/.dot/gui-apps/bin ~/.bin-gui

label "shell links"
# skip make-link ~/.dot/zsh/zshrc   ~/.zshrc # now managed by Nix
# skip make-link ~/.dot/zsh/zshenv  ~/.zshenv # now managed by Nix
# skip make-link ~/.dot/zsh/zlogin  ~/.zlogin # now managed by Nix
make-link ~/.dot/cli-others/nushell  ~/.config/nushell

# skip label "nvim link"
# skip make-link ~/.dot/nvim  ~/.config/nvim # now managed by Nix

label "git links"
# skip make-link ~/.dot/git  ~/.config/git # now manual
make-link ~/.dot/cli-others/gh   ~/.config/gh

label "Nix stuff"
make-link ~/.dot/nix/nix-self-config  ~/.config/nix

label "other cli tools"
make-link ~/.dot/cli-others/htop ~/.config/htop
# skip make-link ~/.dot/tmux     ~/.config/tmux # now managed by Nix
make-link ~/.dot/cli-others/gdb      ~/.config/gdb

mkdir -vp ~/.ipython/profile_default/startup
make-link ~/.dot/ipy-startup/00-custom-config.py ~/.ipython/profile_default/startup/

label "X apps configs"
# terms
make-link ~/.dot/gui-apps/wezterm   ~/.config/wezterm

# Desktop env
# skip make-link ~/.dot/gui-apps/flameshot     ~/.config/flameshot

# tools
make-link ~/.dot/gui-apps/tridactyl ~/.config/tridactyl

# vscode (if I ever want to have it..)
if [[ -d ~/.config/"Code - OSS" ]]; then
  make-link ~/.dot/gui-apps/vscode-user-config ~/.config/"Code - OSS"/User
fi

if $DRYRUN_ONLY; then
  echo
  echo "### To apply the above config, re-run with '--apply"
  echo
fi
