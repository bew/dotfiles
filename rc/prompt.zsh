#-------------------------------------------------------------
# Prompt setup

# Import color helpers
autoload -U colors && colors

# Get the cursor position on the terminal.
#
# It saves the result in CURSOR_POS_ROW & CURSOR_POS_COL
#-------------------------------------------------------------
# NOTE: if the read buffer is not empty, behavior is undifined
#-------------------------------------------------------------
function term::get_cursor_pos
{
    echo -en "\e[6n"; read -u0 -sd'[' _; read -u0 -sdR pos

    # pos has format 'row;col'
    CURSOR_POS_ROW=${pos%;*} # remove ';col'
    CURSOR_POS_COL=${pos#*;} # remove 'row;'
}

# Segment git branch
function segmt::git_branch_slow
{
  [ -n "$NO_SEGMT_GIT_BRANCH" ] && return

  local branchName=$(__git_ps1 "%s")
  if [ -z "${branchName}" ]; then
    return
  fi
  local branchNameStyle="%{$fg[red]%}${branchName}"

  local gitInfo=" On ${branchNameStyle} "
  local gitInfoStyle="%{$bg[black]%}${gitInfo}%{$reset_color%}"

  echo -n ${gitInfoStyle}
}

# Segment git branch (fast!)
function segmt::git_branch_fast
{
  [ -n "$NO_SEGMT_GIT_BRANCH" ] && return

  emulate -L zsh
  typeset -g GITSTATUS_PROMPT=""

  # Call gitstatus_query synchronously. Note that gitstatus_query can also be called
  # asynchronously; see documentation in gitstatus.plugin.zsh.
  gitstatus_query MY                  || return 1  # error
  [[ $VCS_STATUS_RESULT == ok-sync ]] || return 0  # not a git repo

  local       clean='%F{076}'  # green foreground
  local c_untracked='%F{014}'  # teal foreground
  local  c_modified='%F{011}'  # yellow foreground

  local p
  if (( VCS_STATUS_HAS_STAGED || VCS_STATUS_HAS_UNSTAGED )); then
    p+=$c_modified
  elif (( VCS_STATUS_HAS_UNTRACKED )); then
    p+=$c_untracked
  else
    p+=$clean
  fi
  local current_ref="${VCS_STATUS_LOCAL_BRANCH:-@${VCS_STATUS_COMMIT}}"
  [[ -n $VCS_STATUS_TAG ]] && current_ref+="#${VCS_STATUS_TAG}"

  p+=${current_ref//\%/%%}  # escape %

  local repo_status
  [[ $VCS_STATUS_HAS_STAGED      == 1 ]] && repo_status+="${c_modified}+"
  [[ $VCS_STATUS_HAS_UNSTAGED    == 1 ]] && repo_status+="${c_modified}!"
  [[ $VCS_STATUS_HAS_UNTRACKED   == 1 ]] && repo_status+="${c_untracked}?"
  [[ -n "$repo_status" ]] && p+=" ${repo_status}${clean}"

  # %G : Within a %{...%} sequence, include a 'glitch': assume that a single character width will be output.
  local arrow_up_unicode="%{⇡%G%}"
  local arrow_down_unicode="%{⇣%G%}"

  [[ $VCS_STATUS_COMMITS_AHEAD  -gt 0 ]] && p+=" ${arrow_up_unicode}${VCS_STATUS_COMMITS_AHEAD}"
  [[ $VCS_STATUS_COMMITS_BEHIND -gt 0 ]] && p+=" ${arrow_down_unicode}${VCS_STATUS_COMMITS_BEHIND}"
  [[ $VCS_STATUS_STASHES        -gt 0 ]] && p+=" *${VCS_STATUS_STASHES}"

  echo -n "%K{black} On ${p} %k"
}

# Segment last exit code
function segmt::exit_code_long_on_error
{
  local content="Last Exit: %?"
  local on_error="%B%K{black}%F{red} $content %f%k%b"
  echo -n "%(?||$on_error)"
}

# Segment last exit code
function segmt::exit_symbol_on_error
{
  local on_error="%K{124} ✘ %k"
  echo -n "%(?||$on_error)"
}

# Segment last exit code
function segmt::exit_code_on_error
{
  local on_error="%K{124}%F{white}%B %? %b%f%k"
  echo -n "%(?||$on_error)"
}

# Segment is shell in sudo session
function segmt::in_sudo
{
  local result=$(sudo -n echo -n bla 2>/dev/null)

  if [[ "$result" == "bla" ]]; then
    local content="In sudo"
    local with_style="%K{red}%F{white}%B $content %b%f%k"
    echo -n "$with_style"
  fi
}

# Segment prompt vim mode (normal/insert)
function segmt::vim_mode
{
  local insert_mode_style="%B%K{green}%F{white} INSERT %f%k%b"
  local normal_mode_style="%B%K{blue}%F{white} NORMAL %f%k%b"

  if [[ -z "$KEYMAP" ]] || [[ "$KEYMAP" =~ "(main|viins)" ]]; then
    echo -n ${insert_mode_style}
  elif [[ "$KEYMAP" == "vicmd" ]]; then
    echo -n ${normal_mode_style}
  else
    echo -n "$KEYMAP"
  fi
}

# Segment prompt vim mode (normal/insert)
function segmt::short_vim_mode
{
  local insert_mode_style="%B%K{green}%F{white} I %f%k%b"
  local normal_mode_style="%B%K{blue}%F{white} N %f%k%b"

  if [[ -z "$KEYMAP" ]] || [[ "$KEYMAP" =~ "(main|viins)" ]]; then
    echo -n ${insert_mode_style}
  elif [[ "$KEYMAP" == "vicmd" ]]; then
    echo -n ${normal_mode_style}
  else
    echo -n "$KEYMAP"
  fi
}

function zle::utils::reset-prompt
{
  zle && zle reset-prompt
}
hooks-add-hook zle_keymap_select_hook zle::utils::reset-prompt

zmodload zsh/system

# Scroll when prompt gets too close to bottom edge
function prompt-auto-scroll
{
  # Don't attempt to scroll in a tty
  [ "$TERM" = "linux" ] && return

  # check if there is a command in the stdin buffer
  # (as the term::get_cursor_pos will discard it)
  # FIXME: find how to turn on raw input
  local buff
  sysread -t 0 -i 0 buff
  #echo "Buff: '$buff'"
  if [ -n "$buff" ]; then
    # push it on the ZLE input stack
    print -z "${buff}"
  fi

  # Get the cursor position for the (new) current prompt
  term::get_cursor_pos

  if (( CURSOR_POS_ROW > (LINES - 4) )) then
    echo -n $'\e[4S' # Scroll the terminal
    echo -n $'\e[4A' # Move the cursor back up
  fi
}
hooks-add-hook precmd_hook prompt-auto-scroll


function segmt::shlvl
{
  [[ $SHLVL == 1 ]] && return

  echo -n "{%BLVL%L%b}"
}

# Segment variable debug
function segmt::debug
{
  echo -n "%K{blue} DEBUG: $* %k"
}

# Build a string from an array of parts.
# A part can be a function or a simple text.
#
# Args: (reset_code, *parts)
# - reset_code: The reset code to add after a function call (e.g: color reset).
# - *parts: The parts as described below.
#
# Each part uses 2 elements in the parts array for the type and the value.
# The types of parts are:
# - func : a function call
# - text : raw text
# In addition there are special parts that configures parts rendering:
# - part_separator : separator between parts
# - func_reset : reset sequence inserted after a func call
# - (TODO ?: part_reset)
#
# Example:
#
#   parts=(
#     # change part config
#     part_separator: "|"
#     func_reset: "reset"
#
#     func: some_func1
#     func: some_func2
#     text: "xxx"
#
#     # change part config
#     func_reset: "XX"
#
#     func: some_func3
#   )
#   make_prompt_str_from_parts "${parts[@]}"
#
# Gives literaly:
#
#   $(some_func1)reset|$(some_func2)reset|xxx|$(some_func3)XX
#
# The result will need to be re-evaluated by the prompt system to call
# the functions (some_func{1,2,3}).
#
# TODO: (oneday) allow func args, like:
#   func: 2 some_func arg1 arg2
function make_prompt_str_from_parts
{
  local parts=("$@")

  local str
  local func_reset
  local part_separator
  local user_part_idx=0 # user parts, skipping config parts

  local len_parts=${#parts}
  if (( len_parts % 2 != 0 )); then
    echo >&2 "Error while making prompt str from parts, invalid length of parts (${#parts} - must be divisible by 2)"
    echo "foo"
    return 1
  fi

  while [[ ${#parts} -ne 0 ]]; do
    # read the part as "type: value"
    local type="${parts[1]}"
    local value="${parts[2]}"
    shift 2 parts # NOTE: zsh only! bash does not accept array name

    # No part separator before the first user part
    local maybe_separator="$part_separator"
    [[ "$user_part_idx" == 0 ]] && maybe_separator=""

    case "$type" in
      # Config parts handling
      func_reset:) func_reset="$value" ;;
      part_separator:) part_separator="$value" ;;

      # User parts handling
      func:)
        user_part_idx=$(( user_part_idx + 1 ))
        str+="$maybe_separator"
        str+='$('"$value"')'
        str+="$func_reset"
        ;;
      text:)
        user_part_idx=$(( user_part_idx + 1 ))
        str+="$maybe_separator"
        str+="$value"
        ;;
    esac
  done

  echo -n $str
}

## Prompts & Status line
##############################################
#
#  %B (%b)
#         Start (stop) boldface mode.
#
#  %E     Clear to end of line.
#
#  %U (%u)
#         Start (stop) underline mode.
#
#  %S (%s)
#         Start (stop) standout mode.
#
#  %F (%f)
#         Start  (stop) using a different foreground colour, if supported by the
#         terminal.  The colour may be specified two ways: either as a numeric
#         argument, as normal, or by a sequence in braces following the %F, for
#         example %F{red}.  In the latter case the values allowed are as described
#         for the  fg  zle_highlight  attribute;  see  Character Highlighting in
#         zshzle(1).  This means that numeric colours are allowed in the second
#         format also.
#
#  %K (%k)
#         Start (stop) using a different bacKground colour.  The syntax is identical
#         to that for %F and %f.

autoload -U promptinit && promptinit

# -- Status line

STATUSLINE_PARTS=(
  func: segmt::vim_mode
  func: segmt::in_sudo
  func: segmt::exit_code_long_on_error
)

# NOTE: the generated prompt str is static, the segment functions are not called.
function sl::build_prompt_str
{
  local _cur_save=$'\e[s'
  local _cur_restore=$'\e[u'
  local _goto_bottom=$'\e[$LINES;0H'
  local _clear_line=$'\e[2K'

  local sl_default_bg="${bg[magenta]}" # in my setup, magenta is orange
  local sl_default_fg=""

  local sl_col_reset="${reset_color}${sl_default_bg}${sl_default_fg}"

  local sl_init="${sl_col_reset}${_clear_line}"

  local sl_content="$(make_prompt_str_from_parts func_reset: "$sl_col_reset" "${STATUSLINE_PARTS[@]}")"

  local sl_container="${_cur_save}${_goto_bottom}${sl_init}${sl_content}${_cur_restore}"
  echo -n "%{${sl_container}%}"
}

# -- Left prompt

PROMPT_CURRENT_PARTS=(
  func: segmt::shlvl
  func: segmt::exit_symbol_on_error
  text: "%B%F{magenta} %2~ %f%b" # current dir
  text: "%(!.#.▷)"
)
PROMPT_PAST_PARTS=(
  func: segmt::shlvl
  func: segmt::exit_symbol_on_error
  text: "%K{black}%B%F{cyan} %2~ %f%b%k" # current dir
  text: " "
  text: "%B%F{black}%%%f%b" # cmd separator
)

PROMPT_CURRENT="$(sl::build_prompt_str)""$(make_prompt_str_from_parts "${PROMPT_CURRENT_PARTS[@]}")"
PROMPT_PAST="$(make_prompt_str_from_parts "${PROMPT_PAST_PARTS[@]}")"

# Add space before user input
PROMPT_CURRENT+=" "
PROMPT_PAST+=" "

# -- Right prompt

RPROMPT_CURRENT_PARTS=(
  func_reset: "%k%f%b%u%{$reset_color%}"

  func: segmt::in_sudo
  func: segmt::git_branch_fast
  func: segmt::vim_mode
)

RPROMPT_PAST_PARTS=(
  func_reset: "%k%f%b%u%{$reset_color%}"

  func: segmt::in_sudo
  func: segmt::git_branch_fast
)

RPROMPT_CURRENT="$(make_prompt_str_from_parts "${RPROMPT_CURRENT_PARTS[@]}")"
RPROMPT_PAST="$(make_prompt_str_from_parts "${RPROMPT_PAST_PARTS[@]}")"
# RPROMPT_CURRENT='$(segmt::in_sudo)''$(segmt::git_branch_fast)''$(segmt::vim_mode)'
# RPROMPT_PAST='$(segmt::in_sudo)''$(segmt::git_branch_fast)'

# -- Setup prompts hooks

function set-current-prompts
{
  PROMPT="%{$reset_color%}"$PROMPT_CURRENT
  RPROMPT="%{$reset_color%}"$RPROMPT_CURRENT
}
hooks-add-hook precmd_hook set-current-prompts

function set-past-prompts
{
  PROMPT="%{$reset_color%}"$PROMPT_PAST
  RPROMPT="%{$reset_color%}"$RPROMPT_PAST

  zle reset-prompt
}
hooks-add-hook zle_line_finish_hook set-past-prompts

function simple_prompts
{
  PROMPT_CURRENT="[%?] %2~ ▷ "
  PROMPT_PAST=$PROMPT_CURRENT
  RPROMPT_CURRENT= # no right prompt
  RPROMPT_PAST=    # no right prompt
}

