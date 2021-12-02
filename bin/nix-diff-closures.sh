#!/usr/bin/env bash

# Dependencies:
# pkg nix (for nix commands)
# pkg moreutils (for sponge)
# pkg ansifilter

# Safer shell script with these options
# -e          : exit if a command exits with non-zero status
# -u          : exit if an expanded variable does not exist
# -o pipefail : if a command in a pipeline fail, fail the pipeline
#               (e.g this now fails: false | true)
set -euo pipefail

function get_closure_size
{
  local drv_path="$1"
  nix path-info --closure-size $drv_path | awk '{ print $2 }'
}

function human_size
{
  local num="$1"
  # NOTE: format precision is not always available, fallback to default format is it fails.
  numfmt --to=iec-i --format="%.1f" -- $num 2>/dev/null || numfmt --to=iec-i -- $num
}

function echo_section
{
  echo -ne "\e[1;34m" # blue, bold
  echo -ne ">>> $*"
  echo -ne "\e[0m"
  echo
}

function echo_info
{
  echo -ne "\e[1;36m" # cyan, bold
  echo -ne "--- $*"
  echo -ne "\e[0m"
  echo
}

function echo_header
{
  echo -ne "\e[1;33;40m" # fg: yellow, bold | bg: dark grey
  echo -ne ">>>  $* <<<"
  echo -ne "\e[0m"
  echo
}

if [[ $# -lt 2 ]]; then
  2>&1 echo "Usage: nix-diff-closure.sh BEFORE AFTER [-o DIFF_OUTPUT_FILE]"
  exit 1
fi

CLOSURE_BEFORE="$1"
CLOSURE_AFTER="$2"

if [[ "${3:-}" == "-o" ]]; then
  if [[ -z "${4:-}" ]]; then
    2>&1 echo "ERROR: missing diff output file name"
    exit 1
  fi
  DIFF_FILE="$4"
else
  # TODO: Use /tmp/nix-diff-closure--BEFORE_HASH--AFTER_HASH.txt
  #       when I find a way to get the nix hash of BEFORE & AFTER.
  DIFF_FILE="/tmp/nix-diff-closure--last.txt"
fi

echo_header "Nix closure diff"
echo "'$CLOSURE_BEFORE' -> '$CLOSURE_AFTER'"
echo

nix store diff-closures $CLOSURE_BEFORE $CLOSURE_AFTER > $DIFF_FILE

if [[ -s $DIFF_FILE ]]; then
  # file is not empty
  echo_section "Significant (>8KB) packages changes or new/removed packages"
  cat $DIFF_FILE
  echo_info "NOTE: diff available in '$(realpath --relative-base=. $DIFF_FILE)'"
else
  # file is empty
  echo_info "No significant (>8KB) package changes"
fi
echo

# Strip ANSI sequences from $DIFF_FILE
# NOTE: 'sponge' read all its input before opening its arg and writing to it, allows self-overwrite
( ansifilter "$DIFF_FILE" || cat "$DIFF_FILE" ) | sponge "$DIFF_FILE"

size_before=$(get_closure_size $CLOSURE_BEFORE)
size_after=$(get_closure_size $CLOSURE_AFTER)
size_diff=$(( size_after - size_before ))

if (( size_diff != 0 )); then
  echo_section "Closure size diff"
  echo "Before: $(human_size $size_before) (${size_before}B)"
  echo "After:  $(human_size $size_after) (${size_after}B)"
  if (( size_diff < 0 )); then
    echo_info "Diff: \e[1;32m$(human_size $size_diff)B\e[0m" # green
  else
    echo_info "Diff: \e[1;31m+$(human_size $size_diff)B\e[0m" # red
  fi
  echo
else
  echo_info "Closure size is exactly the same"
  echo
fi
