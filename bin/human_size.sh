#!/usr/bin/env bash

# Safer shell script with these options
# -e          : exit if a command exits with non-zero status
# -u          : exit if an expanded variable does not exist
set -eu

if [[ $# != 1 ]]; then
  2>&1 echo "Usage: human_size.sh [-]NUMBER_OF_BYTES"
  exit 1
fi

# NOTE: format precision is not always available, fallback to default format is it fails.
numfmt --to=iec-i --format="%.1f" -- $1 2>/dev/null || numfmt --to=iec-i -- $1
