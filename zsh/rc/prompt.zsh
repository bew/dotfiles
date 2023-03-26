#-------------------------------------------------------------
# Prompt setup

# TODO: find a way (kinda profiles?) to split prompt segments between:
# * shell-specific (segmt::shlvl or segmt::short_vim_mode)
# * common-cli-specific (like segmt::git_branch_fast or segmt::in-nix-shell)
# * code-tech-specific (like segmt::python_venv)


# Import color helpers
autoload -U colors && colors

# Segment git branch
function segmt::git_branch_slow
{
  [ -n "$SEGMT_DISABLE_GIT_BRANCH" ] && return

  local branchName=$(__git_ps1 "%s")
  if [ -z "${branchName}" ]; then
    return
  fi
  local branchNameStyle="%F{red}${branchName}%f"

  echo -n "%K{black} On ${branchNameStyle} %k"
}

# Segment git branch (fast! complete! responsive!)
function segmt::git_branch_fast
{
  [ -n "$SEGMT_DISABLE_GIT_BRANCH" ] && return

  emulate -L zsh
  typeset -g GITSTATUS_PROMPT=""

  # Call gitstatus_query synchronously. Note that gitstatus_query can also be called
  # asynchronously; see documentation in gitstatus.plugin.zsh.
  gitstatus_query MY                  || return 1  # error
  [[ $VCS_STATUS_RESULT == ok-sync ]] || return 0  # not a git repo

  # colors used below
  local      col_background="black"
  local     col_is_all_good="034"  # green
  local col_is_not_all_good="178"  # yellow
  local   col_has_untracked="cyan" # cyan
  local    col_has_unstaged="196"  # red
  local      col_has_staged="034"  # green
  local     col_has_stashes="038"  # blue (medium)
  local       col_is_behind="196"  # red
  local        col_is_ahead="202"  # orange

  local sym_arrow_up
  local sym_arrow_down
  local sym_dots
  local sym_staged="+"
  local sym_unstaged="~"
  local sym_untracked="?"
  if [[ -z "$ASCII_ONLY" ]]; then
    # %G : Within a %{...%} sequence, include a 'glitch': assume that a single
    #      character width will be output.
    #      Can be needed when a unicode char is considered as 2 chars by mistake.
    sym_arrow_up="%{↑%G%}"
    sym_arrow_down="%{↓%G%}"
    sym_dots="%{…%G%}"
  else
    sym_arrow_up="^"
    sym_arrow_down="v"
    sym_dots=".."
  fi

  # note: when not on a branch, show commit id (but shorter than usual 40-chars)
  local current_ref="${VCS_STATUS_LOCAL_BRANCH:-@${VCS_STATUS_COMMIT[0,20]}${sym_dots}}"
  local current_ref_short="${VCS_STATUS_LOCAL_BRANCH[0,10]:-@${VCS_STATUS_COMMIT[0,10]}}"
  [[ ${#current_ref_short} -lt ${#current_ref} ]] && current_ref_short+="$sym_dots"
  [[ -n $VCS_STATUS_TAG ]] && {
    current_ref+="#${VCS_STATUS_TAG}"
    current_ref_short+="#${sym_dots}"
  }
  local col_current_ref
  if (( VCS_STATUS_HAS_STAGED || VCS_STATUS_HAS_UNSTAGED )); then
    col_current_ref+="$col_is_not_all_good"
  elif (( VCS_STATUS_HAS_UNTRACKED )); then
    col_current_ref+="$col_has_untracked"
  else
    col_current_ref+="$col_is_all_good"
  fi
  local current_ref_info="%F{$col_current_ref}${current_ref}%f"
  local current_ref_info_short="%F{$col_current_ref}${current_ref_short}%f"

  local worktree_info
  (( VCS_STATUS_HAS_STAGED    )) && worktree_info+="%F{$col_has_staged}%B${sym_staged}%b%f"
  (( VCS_STATUS_HAS_UNSTAGED  )) && worktree_info+="%F{$col_has_unstaged}%B${sym_unstaged}%b%f"
  (( VCS_STATUS_HAS_UNTRACKED )) && worktree_info+="%F{$col_has_untracked}%B${sym_untracked}%b%f"

  local commits_info commits_info_short
  [[ $VCS_STATUS_COMMITS_AHEAD  -gt 0 ]] && {
    commits_info+="%F{$col_is_ahead}${sym_arrow_up}${VCS_STATUS_COMMITS_AHEAD}%f"
    commits_info_short+="%F{$col_is_ahead}${sym_arrow_up}%f"
  }
  [[ $VCS_STATUS_COMMITS_BEHIND -gt 0 ]] && {
    [[ -n "$commits_info" ]] && commits_info+=" "
    commits_info+="%F{$col_is_behind}${sym_arrow_down}${VCS_STATUS_COMMITS_BEHIND}%f"
    commits_info_short+="%F{$col_is_behind}${sym_arrow_down}%f"
  }
  [[ $VCS_STATUS_STASHES -gt 0 ]] && {
    [[ -n "$commits_info" ]] && commits_info+=" "
    commits_info+="%F{$col_has_stashes}*${VCS_STATUS_STASHES}%f"
    commits_info_short+="%F{$col_has_stashes}*%f"
  }

  local repo_info_long="On $current_ref_info"
  [[ -n "$worktree_info" ]] && repo_info_long+=" $worktree_info"
  [[ -n "$commits_info" ]] && repo_info_long+=" $commits_info"
  local repo_info_short="$current_ref_info_short"
  [[ -n "${worktree_info}${commits_info_short}" ]] && \
    repo_info_short+=" ${worktree_info}${commits_info_short}"

  local repo_info
  (( COLUMNS > 70 )) && repo_info=$repo_info_long || repo_info=$repo_info_short

  echo -n "%K{$col_background} $repo_info %k"
}

# Segment last exit code
function segmt::exit_code_on_error
{
  echo -n "%(?||%K{232}%F{red} %? %f%k )"
}

# Segment is shell in sudo session
function segmt::in_sudo
{
  local result=$(sudo -n echo -n bla 2>/dev/null)

  if [[ "$result" == "bla" ]]; then
    local content="In sudo"
    echo -n "%K{88}%F{white}%B $content %b%f%k"
  fi
}

# Segment prompt vim mode (normal/insert)
function segmt::short_vim_mode
{
  zle::utils::get-vim-mode
  case "$REPLY" in
    insert)  echo -n "%B%K{28}%F{white} I %f%k%b";; # bg: dark green
    normal)  echo -n "%B%K{26}%F{white} N %f%k%b";; # bg: dark blue
    replace) echo -n "%B%K{88}%F{white} R %f%k%b";; # bg: dark red
    # NOTE: does not work, we're NOT notified on normal<=>visual mode change
    # visualchar) echo -n "%B%K{133}%F{white} V %f%k%b";; # bg: light violet
    # visualline) echo -n "%B%K{133}%F{white} VL %f%k%b";; # bg: light violet
    *) echo -n "$KEYMAP";;
  esac
}

# Set to anything to show a short venv segment
PROMPT_SEGMT_VENV_SHORT="${PROMPT_SEGMT_VENV_SHORT:-}"

# Segment with the current active venv directory if any
function segmt::python_venv
{
  [[ -n "$VIRTUAL_ENV" ]] || return

  local venv_dir=$(basename "$VIRTUAL_ENV")
  local venv_display="venv"

  if [[ -n "${VENV_IS_VOLATILE:-}" ]]; then
    # Current venv is volatile (created with venv_with_do)
    venv_display+=" volatile"
  else
    # Add venv name if not 'venv'
    if [[ "$venv_dir" != "venv" ]]; then
      if [[ -n "$PROMPT_SEGMT_VENV_SHORT" ]]; then
        # For $venv_dir == `Py3.9.7-231c4f5db9de5be7df4255ec41a3139b`
        # -> prints `'Py3.9.7-231c~'`
        venv_display+=" '${venv_dir[0,12]}~'"
      else
        venv_display+=" '$venv_dir'"
      fi
    fi

    local venv_parent_dir_path=$(dirname "$VIRTUAL_ENV")
    if [[ "$(realpath $PWD)" == "$(realpath $venv_parent_dir_path)" ]]; then
      # venv is in PWD, no need to repeat the dir name
      venv_display+=" here"
    else
      # venv is not in $PWD, show the venv parent dir name to avoid ambiguity.
      if [[ -n "$PROMPT_SEGMT_VENV_SHORT" ]]; then
        venv_display+=" not here"
      else
        local venv_parent_dir_relative_path="$(realpath --relative-to="$PWD" "$venv_parent_dir_path")"
        local venv_parent_dir_aliased_path="${(D)venv_parent_dir_path}" # try to shorten using dir aliases
        if [[ "${#venv_parent_dir_relative_path}" -le "${#venv_parent_dir_aliased_path}" ]]; then
          # Use relative path if it's shorter than the dir aliased path
          venv_display+=" in ${venv_parent_dir_relative_path}"
        elif [[ "${#venv_parent_dir_aliased_path}" -lt "${#venv_parent_dir_path}" ]]; then
          # Use path with existing dir alias if it's shorter than the full dir path
          venv_display+=" in ${venv_parent_dir_aliased_path}"
        elif [[ "${#venv_parent_dir_path}" -lt $(( COLUMNS / 5 )) ]]; then
          # Use path when its length is less than 20% of available width
          # (that percentage looks like a good compromise, leaving space for other prompt segments)
          venv_display+=" in $venv_parent_dir_path"
        else
          # Use only the dir nam eof parent of venv
          # (less precise, we don't really know _where_ it is, only its name)
          local venv_parent_dir=$(basename "$venv_parent_dir_path")
          venv_display+=" in […]/$venv_parent_dir"
        fi
      fi
    fi
  fi
  # Example venv_display:
  #   - venv volatile
  #   - venv here
  #   - venv 'myvenv' here
  #   - venv in SomeParentDir
  #   - venv 'myvenv' in SomeParentDir

  echo -n "($venv_display) "
  # FIXME: find a way to not have to specify before/after spacing in the segements!!!
}

function segmt::in-nix-shell
{
  local shell_tag
  if [[ -n "$IN_NIX_SHELL" ]]; then
    # We are in a `nix-shell` or `nix develop` env.
    shell_tag="nixsh"
  elif [[ -n "$DEVSHELL_ROOT" ]]; then
    # We are specifically in a Nix devshell (github:numtide/devshell).
    shell_tag="devsh"
  else
    return
  fi

  echo -n "(%F{red}$shell_tag%f) "
}

function segmt::shlvl
{
  [[ $SHLVL == 1 ]] && return

  # e.g: "L3"
  echo -n "%BL%L%b "
}

function segmt::jobs
{
  # e.g: "J3 "
  echo -n "%(1j|%B%F{178}J%j%f%b |)"
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
      # TODO: remove, I don't use these.... (the whole function can be trashed?)
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

## Prompts
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

VIRTUAL_ENV_DISABLE_PROMPT=thankyou # Avoid python's venv loader script to change my prompt

# -- Left prompt

PROMPT_CURRENT_PARTS=(
  func: segmt::shlvl
  func: segmt::jobs
  func: segmt::python_venv
  func: segmt::exit_code_on_error

  text: "%B%F{166}%2~%f%b " # current dir

  func: segmt::short_vim_mode
  text: " "
  text: "%(!.#.>)" # normal (>) or sudo (#) cmd separator
)
PROMPT_PAST_PARTS=(
  func: segmt::shlvl
  func: segmt::jobs
  func: segmt::python_venv
  func: segmt::exit_code_on_error

  text: "%K{235}%B%F{30} %2~ %f%b%k" # current dir

  text: " "
  text: "%(!.#.%B%F{243}%%%f%b)" # normal (%) or sudo (#) cmd separator
)

PROMPT_CURRENT="$(make_prompt_str_from_parts "${PROMPT_CURRENT_PARTS[@]}")"
PROMPT_PAST="$(make_prompt_str_from_parts "${PROMPT_PAST_PARTS[@]}")"

# Add space before user input
PROMPT_CURRENT+=" "
PROMPT_PAST+=" "

# -- Right prompt

RPROMPT_CURRENT_PARTS=(
  func: segmt::in_sudo
  func: segmt::git_branch_fast
)

RPROMPT_PAST_PARTS=(
  func: segmt::in_sudo
  func: segmt::git_branch_fast
)

RPROMPT_CURRENT="$(make_prompt_str_from_parts "${RPROMPT_CURRENT_PARTS[@]}")"
RPROMPT_PAST="$(make_prompt_str_from_parts "${RPROMPT_PAST_PARTS[@]}")"
# RPROMPT_CURRENT='$(segmt::in_sudo)''$(segmt::git_branch_fast)'
# RPROMPT_PAST='$(segmt::in_sudo)''$(segmt::git_branch_fast)'

# -- Setup prompts hooks

function set-current-prompts
{
  PROMPT=$PROMPT_CURRENT
  RPROMPT=$RPROMPT_CURRENT
}
hooks-add-hook precmd_hook set-current-prompts

function set-past-prompts
{
  PROMPT=$PROMPT_PAST
  RPROMPT=$RPROMPT_PAST

  zle reset-prompt
}
hooks-add-hook zle_line_finish_hook set-past-prompts

function simple_prompts
{
  PROMPT_CURRENT="[%?] %F{cyan}%2~%f > "
  PROMPT_PAST=$PROMPT_CURRENT
  RPROMPT_CURRENT= # no right prompt
  RPROMPT_PAST=    # no right prompt
}

# Setup reactions to keymap changes

function prompt::utils::regen-prompt
{
  zle reset-prompt

  # NOTE: keep it commented because it is nice when debugging (:
  # zle::utils::get-vim-mode && zle -M "vim mode: $REPLY"
}
hooks-add-hook zle_keymap_select_hook prompt::utils::regen-prompt

# Set to disable cursor shape changes.
# It is NOT set based on the current terminal and support for cursor change feature,
# maybe this can come one day..
CURSOR_SHAPE_CHANGE_DISABLED="${CURSOR_SHAPE_CHANGE_DISABLED:-}"

# Set cursor style (DECSCUSR), VT520.
# 0 => blinking block.
# 1 => blinking block (default).
# 2 => steady block.
# 3 => blinking underline.
# 4 => steady underline.
# 5 => blinking bar, xterm.
# 6 => steady bar, xterm.
function prompt::utils::set-cursor-block
{
  [[ -n "$CURSOR_SHAPE_CHANGE_DISABLED" ]] && return
  echo -ne "\e[2 q" # steady block
}
function prompt::utils::set-cursor-underline
{
  [[ -n "$CURSOR_SHAPE_CHANGE_DISABLED" ]] && return
  echo -ne "\e[4 q" # steady underline
}
function prompt::utils::set-cursor-beam
{
  [[ -n "$CURSOR_SHAPE_CHANGE_DISABLED" ]] && return
  echo -ne "\e[6 q" # steady bar
}
function prompt::utils::apply-cursor-shape
{
  zle::utils::get-vim-mode
  case "$REPLY" in
    insert) prompt::utils::set-cursor-beam;;
    replace) prompt::utils::set-cursor-underline;;
    *) prompt::utils::set-cursor-block;;
  esac
}
hooks-add-hook zle_keymap_select_hook prompt::utils::apply-cursor-shape
hooks-add-hook zle_line_init_hook prompt::utils::set-cursor-beam
hooks-add-hook zle_line_finish_hook prompt::utils::set-cursor-block
# FIXME: we're not notified when going normal<=>visual mode :/
