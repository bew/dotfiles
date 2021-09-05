# vim:set sw=2:

# Add the entry to PATH if it's not already present.
function path_maybe_add_entry
{
  local entry="$1"
  local where="${2:-priority}"

  if [[ -n "$ZSH_VERSION" ]]; then
    # For zsh
    # Copied from https://unix.stackexchange.com/a/411307/159811
    if ! [[ ${path[(ie)$entry]} -le ${#path} ]]; then
      # => The entry is not yet in $path, add it now
      case "$where" in
        priority) path=("$entry" $path);;
        fallback) path=($path "$entry");;
      esac
    fi
  else
    # For bash
    # Inspired from https://serverfault.com/a/192517 but simplified
    if ! echo ":$PATH:" | grep -q ":$entry:"; then
      # => The entry is not yet in $PATH, add it now
      case "$where" in
        priority) PATH="$entry:$PATH";;
        fallback) PATH="$PATH:$entry";;
      esac
    fi
  fi
}

# Dotfiles bins
path_maybe_add_entry "$HOME/.dot/bin"

# adb & fastboot PATH, installed using install.sh script at
# https://github.com/corbindavenport/nexus-tools
path_maybe_add_entry "$HOME/.nexustools"

# User-local bins
path_maybe_add_entry "$HOME/.local/bin"

# OSX bins
path_maybe_add_entry "/usr/local/bin" fallback


# -R : Output raw ANSI "color" escape sequences directly
# -+X (Disables the `-X` option) : Send alt-screen term init sequence if necessary
export LESS="-R -+X"

export PAGER="most"
export MANPAGER='nvim -R +Man!' # man in vim!
export BAT_PAGER="less" # `most` does not work with `bat`

export EDITOR="nvim"
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"

# Setup Nix env (ONCE!) when /nix is available <3 <3
if [[ -d /nix ]] && [[ -z "${NIX_PROFILE_SOURCED:-}" ]]; then
  source ~/.nix-profile/etc/profile.d/nix.sh
  export NIX_PROFILE_SOURCED=yes
fi
