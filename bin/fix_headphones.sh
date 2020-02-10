#!/bin/bash

CARD_NO=1

CONTROL="Speaker+LO"

# Unmute and set volume to 100%
amixer -c "$CARD_NO" set "$CONTROL" unmute 100%

