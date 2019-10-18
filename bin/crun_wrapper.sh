#!/bin/sh

function echo_err
{
    echo $* >&2
}

REPO_NAME='crun'
REPO_PATH="$HOME/.bin/repos/$REPO_NAME"

CRUN_BIN_PATH="$REPO_PATH/crun"

if [[ -x "$CRUN_BIN_PATH" ]]; then
    if [[ -n "$CRUN_VERBOSE" ]]; then
        echo "Binary '$CRUN_BIN_PATH' found, executing.."
    fi

    exec "$CRUN_BIN_PATH" "$@"
fi

echo_err "crun binary not found at '$CRUN_BIN_PATH'"
echo_err "make sure you cloned the crun repo to '$REPO_PATH'"
echo_err "and built the crun binary"
exit 1
