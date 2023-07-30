#!/usr/bin/env bash

# mpv daemon player
#
# Example usage:
# ```sh
# # Start the daemon in a separate terminal
# $ @mpv daemon-start zik
#
# # And then
# $ @mpv add zik file1 file2 file3
#
# # Enjoy!
# ```
#
# The idea of channels is to be able to remote control multiple mpv instance,
# e.g: one for music, one for some films, one for youtube videos, ...

# dependencies
_BIN_mpv=mpv
_BIN_socat=socat
_BIN_jq=jq
_BIN_jo=jo

# Start an mpv instance in daemon mode identified by channel $1
function _daemon_start
{
  local channel=${1:-default}; [[ -n "$1" ]] && shift
  local ipc_socket="/tmp/mpv-socket-${channel}"

  echo ">>> Starting mpv daemon for channel '$channel' on IPC socket '$ipc_socket'..."
  $_BIN_mpv --idle --input-ipc-server="$ipc_socket" "$@"
}

# Send an arbitrary command to mpv on channel $1
#
# For command documentation checkout `man mpv` section "JSON IPC"
function _send_cmd
{
  if [[ $# == 0 ]] || [[ $# == 1 ]]; then
    echo "Usage: $PROG $SUBCMD <channel> <command> [<arg> ...]"
    return 1
  fi

  local channel=$1; shift
  local ipc_socket="/tmp/mpv-socket-${channel}"

  $_BIN_jo "command=$($_BIN_jo -a "$@")" \
    | $_BIN_socat - "$ipc_socket"
}

# Helper function to make sure the mpv instance on channel $1 exists
#
# Exits with non-0 if it doesn't exist.
function _ensure_socket_exist
{
  local channel=$1
  local ipc_socket="/tmp/mpv-socket-${channel}"

  # -S   : socket
  if ! [[ -S "$ipc_socket" ]]; then
    >&2 echo ">>> ERROR: mpv channel '$channel' invalid"
    >&2 echo "     -> '$ipc_socket' is not an mpv IPC socket."
    return 1
  fi
}

# Add any number of medias to mpv on channel $1,
# then start playback if the playlist was empty before.
function _add_media
{
  if [[ $# == 0 ]]; then
    echo "Usage: $PROG $SUBCMD <channel> <path> [<path> ...]"
    return 1
  fi

  local channel=$1; shift
  _ensure_socket_exist "$channel" || return 1

  echo ">>> Adding $# medias to mpv on channel '$channel'"

  local media_full_path
  for media_path in "$@"; do
    media_full_path=$(realpath "$media_path")
    echo ">>> Appending media '$media_path'"
    if ! _send_cmd "$channel" "loadfile" "$media_full_path" "append-play"; then
      return $?
    fi
  done

  echo ">>> $# medias added!"
}

# Show the playlist of mpv on channel $1
function _show_playlist
{
  if [[ $# == 0 ]]; then
    echo "Usage: $PROG $SUBCMD <channel>"
    return 1
  fi

  local channel=$1
  _ensure_socket_exist "$channel" || return 1

  _send_cmd "$channel" "get_property" "playlist" | $_BIN_jq .
}

function main
{
  case "$SUBCMD" in
    daemon-start) _daemon_start "$@";;
    add) _add_media "$@";;
    playlist) _show_playlist "$@";;
    cmd) _send_cmd "$@";;
    "")
      echo "Usage: $PROG <subcmd> ..."
      echo
      echo "SUBCMD:"
      echo "  daemon-start <channel>"
      echo "  add <channel> <media> [<media> ...]"
      echo "  playlist <channel>"
      echo "  cmd <cmd> [<cmd> ...]"
      echo
      ;;
    *)
      >&2 echo "$PROG: Unknown subcommand '$SUBCMD'"
      exit 1
      ;;
  esac
}

# ---------------------------------

# shell guard
set -euo pipefail

PROG=$(basename "$0")
SUBCMD="${1:-}"
[[ -n "$SUBCMD" ]] && shift

main "$@"
