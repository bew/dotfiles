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
path_maybe_add_entry "$HOME/.dot/gui/bin"

# User-local bins
path_maybe_add_entry "$HOME/.local/bin"

# Automatically make available project-local helper binaries.
# MUST BE LAST (to take precedence)
#
# The idea is to use an esoteric dirname for $PATH, and make a symlink with
# that name to the bin/ of a given project, when I need this
# auto-bins behavior.
path_maybe_add_entry "__auto_bins__"
if [[ -n "$ZSH_VERSION" ]] && [[ $- == *i* ]]; then # when in interactive zsh
  # For some reason, using a non-absolute path in $path does not make auto-completion work when that
  # path exists in cwd.
  # To work around that, we tell the completion system to add an absolute path in it's command
  # search path every time a command is looked for.
  # (-e flag tells zstyle to eval the given string every the completion system requests the value of command-path)
  # ref: https://superuser.com/a/1564543/536847
  zstyle -e ':completion:*' command-path 'reply=( "$PWD/__auto_bins__" "${(@)path}" )'
fi

# OSX bins
path_maybe_add_entry "/usr/local/bin" fallback


# -R : Output raw ANSI "color" & "hyperlink" escape sequences directly
# --ignore-case : smart case search
# --incsearch : incremental search
# --LONG-PROMPT : show scroll information at the bottom
# --tabs : Sets length of tabs
# --window=-n : Changes the scrolling window size, -n means VISIBLE_LINES -N
export LESS="-R --ignore-case --incsearch --LONG-PROMPT --tabs=4 --window=-4"
export LESSKEYIN=~/.dot/lesskey-bew

export PAGER="less"
export MANPAGER='nvim +Man!' # man in vim!

export EDITOR="nvim"
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"

# Setup Nix env (ONCE!) when /nix is available <3 <3
if [[ -d /nix ]] && [[ -z "${NIX_PROFILE_SOURCED:-}" ]]; then
  source ~/.nix-profile/etc/profile.d/nix.sh
  export NIX_PROFILE_SOURCED=yes
fi
