#!/bin/bash

# Some links can DL very fast (~3Mo/s) for a few seconds,
# then go very slow for the rest of the time (~300ko/s)
#
# This script will launch the command, wait a few seconds,
# then kill it and start again, bypassing the slow regulation :P

if [[ $# == 0 ]]; then
    echo "Usage: $0 <program with args>"
    echo "(read the code for more infos)"
    echo
    echo "FIXME: read code, read FIXME note :P"
    echo
    exit 1
fi

PROC_PID=0

function int_handler
{
    echo "Interrupted!"
    if [[ "$PROC_PID" != 0 ]]; then
        echo "Killing the underlying process to remove zombies.."
        kill -KILL "$PROC_PID"
    fi
    exit 1
}
trap int_handler INT

# An approximation of the time (in seconds) while the DL speed is fast
FAST_TO_SLOW_DELAY=5

# An approximation of the time (in seconds) the program takes to start
PROGRAM_STARTUP_OVERHEAD=2

delay=$(( FAST_TO_SLOW_DELAY + PROGRAM_STARTUP_OVERHEAD ))

echo '-----------------------------------------------'

still_processing=1;
while [[ $still_processing == 1 ]]; do
    $@ &
    PROC_PID=$!

    echo "Started pid: $PROC_PID"
    # wait for the program to start, and DL fast
    sleep $delay

    if ! kill -KILL "$PROC_PID"; then
        # `kill` failed
        echo "Failed to kill process $PROC_PID, assuming it is finished!"
        still_processing=0
    else
        PROC_PID=0
        # `kill` worked
        sleep 1 # wait for it to stop
    fi

    echo # space separator between invocations
done

echo "Finished!"
