#!/usr/bin/env bash

ESC=$'\e'
RESET=$'\e[0m'

echo "## Text styles:"
echo -e "$ESC[1mbold$RESET"
echo -e "$ESC[3mitalic$RESET"
echo -e "$ESC[1;3mbold italic$RESET"
echo -e "$ESC[4msimple underline$RESET"
echo -e "$ESC[9mstrikethrough$RESET 👀"

function rainbow_text
{
  local text="$1"
  local rainbow_colors=(
    "255;102;118"
    "255;179;102"
    "255;255;153"
    "153;255;153"
    "153;204;255"
    "178;153;255"
    "255;153;255"
  )
  local length=${#rainbow_colors[@]}

  for ((i = 0; i < ${#text}; i++)); do
    local char="${text:i:1}"
    local color="${rainbow_colors[i % length]}"
    echo -ne "$ESC[38;2;${color}m${char}"
  done
  echo "$RESET"
}
echo
rainbow_text "RGB colored"

echo
echo "## Underlines:"
echo -e "$ESC[58:2::255:0:0m$ESC[4:1msingle$ESC[4:2mdouble$ESC[4:3mcurly$ESC[4:4mdotted$ESC[4:5mdashed$RESET"

echo
