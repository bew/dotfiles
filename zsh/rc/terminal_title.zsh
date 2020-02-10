# Sets the status line (title bar for most terminal emulator)
#
# The argument will be expanded like a prompt string
function term::set_status_line
{
  local text="$1"

  # tsl (to_status_line): Move cursor to status line
  # fsl (from_status_line): Move cursor from status line
  if [[ -n "$terminfo[tsl]" ]] && [[ -n "$terminfo[fsl]" ]]; then
    echoti tsl # to status line
    print -Pn "$text"
    echoti fsl # from status line
  fi
}

function set_title_on_idle
{
  term::set_status_line 'term - %~'
}
hooks-add-hook precmd_hook set_title_on_idle

function set_title_on_exec
{
  local typed_cmd="$1"
  #local expanded_cmd="$2"

  term::set_status_line "term - $typed_cmd"
}
hooks-add-hook preexec_hook set_title_on_exec
