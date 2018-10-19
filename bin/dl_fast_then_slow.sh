#!/bin/bash

if [[ $# == 0 ]]; then
    echo "Usage: $0 <program with args>"
    echo "(read the code for more infos)"
    echo
    echo "FIXME: read code, read FIXME note :P"
    echo
    exit 1
fi


# Some links can DL very fast (~3Mo/s) for a few seconds,
# then go very slow for the rest of the time (~300ko/s)
#
# This script will launch the command, wait a few seconds,
# then kill it and start again, bypassing the slow regulation :P

# An approximation of the time (in seconds) while the DL speed is fast
FAST_TO_SLOW_DELAY=4

# An approximation of the time (in seconds) the program takes to start
PROGRAM_STARTUP_OVERHEAD=1

delay=$(( FAST_TO_SLOW_DELAY + PROGRAM_STARTUP_OVERHEAD ))

echo '-----------------------------------------------'

# FIXME: currently the loop will never end
# I don't know how to set `$ret` to the return status of the killed process..

ret=1;
until [[ $ret == 0 ]]; do
    $@ &
    pid=$!

    echo "Started pid: $pid"
    # wait for the program to start, and DL fast
    sleep $delay

    kill -KILL $pid
    sleep 1 # wait for it to stop

    echo # separator between invocations
done

echo "Finished!"
