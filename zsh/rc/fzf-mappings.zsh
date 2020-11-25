# Key bindings

if [[ $- != *i* ]]; then
  return
fi

function __results_to_path_args
{
  local prefix="$1"

  while read item; do
    local full_item="${prefix}${item}"
    echo -n "${(D)full_item} "
  done
}

# Those layout & keybindings vars come from ~/.zshenv
FZF_BASE_CMD=(fzf ${FZF_BEW_LAYOUT_ARRAY} ${FZF_BEW_KEYBINDINGS_ARRAY})

FZF_PREVIEW_CMD_FOR_FILE="bat --color=always --style=numbers"
FZF_PREVIEW_CMD_FOR_DIR="ls --color=always --group-directories-first -F --dereference"

function __fzf_widget_file_impl
{
  local completion_prefix=${LBUFFER/* /}
  local lbuffer_without_completion_prefix="${LBUFFER%${completion_prefix}}"

  local base_dir=${completion_prefix:-./}
  base_dir=${~base_dir} # expand ~ (at least)

  local fzf_cmd=($FZF_BASE_CMD --multi --prompt "$base_dir" --preview "$FZF_PREVIEW_CMD_FOR_FILE"" {}")
  local selected_completions=$(cd ${base_dir}; "${FZF_FINDER_CMD[@]}" | "${fzf_cmd[@]}" |
    __results_to_path_args "$base_dir"
  )

  if [ -n "$selected_completions" ]; then
    LBUFFER="${lbuffer_without_completion_prefix}${selected_completions}"
  fi
  zle reset-prompt
}

function zwidget::fzf::smart_find_file
{
  FZF_FINDER_CMD=(fd --type f --type l --follow) # follow symlinks

  __fzf_widget_file_impl

  unset FZF_FINDER_CMD
}
zle -N zwidget::fzf::smart_find_file

function zwidget::fzf::find_file
{
  FZF_FINDER_CMD=(find -L) # follow symlinks
  FZF_FINDER_CMD+=('(' -path '*/.*' -o -fstype 'dev' -o -fstype 'proc' ')' -prune) # ignore options
  FZF_FINDER_CMD+=(-o -type f -o -type l) # actual file filter

  __fzf_widget_file_impl

  unset FZF_FINDER_CMD
}
zle -N zwidget::fzf::find_file

function zwidget::fzf::find_directory
{
  local completion_prefix="${LBUFFER/* /}"
  local lbuffer_without_completion_prefix="${LBUFFER%$completion_prefix}"

  local base_dir=${completion_prefix:-./}
  base_dir=${~base_dir} # expand ~ (at least)

  local finder_cmd=(fd --type d --type l --follow) # follow symlinks
  local fzf_cmd=($FZF_BASE_CMD --multi --prompt "$base_dir" --preview "$FZF_PREVIEW_CMD_FOR_DIR"" {}")
  local cpl=$(cd $base_dir; "${finder_cmd[@]}" | "${fzf_cmd[@]}" | __results_to_path_args "$base_dir")
  local selected_completions=$cpl

  if [ -n "$selected_completions" ]; then
    LBUFFER="${lbuffer_without_completion_prefix}${selected_completions}"
  fi
  zle reset-prompt
}
zle -N zwidget::fzf::find_directory

# --tiebreak=index  | when score are tied, prefer line that appeared first in input stream
# --nth 2..         | ignore first field (the popularity of the dir) when matching
FZF_HISTORY_OPTIONS=(--no-multi --tiebreak=index --nth 2..)

function zwidget::fzf::history
{
  # -l  | list the commands
  # -r  | show in reverse order (=> most recent first)
  # 1   | start at command n° 1 (the oldest still in history)
  local history_cmd=(fc -l -r 1)

  local fzf_cmd=($FZF_BASE_CMD $FZF_HISTORY_OPTIONS --query "${LBUFFER//$/\\$}")
  local selected=( $( "${history_cmd[@]}" | "${fzf_cmd[@]}" ) )
  if [ -n "$selected" ]; then
    local history_index=$selected[1]
    if [ -n "$history_index" ]; then
      zle vi-fetch-history -n $history_index
    fi
  fi
  zle reset-prompt
}
zle -N zwidget::fzf::history

# --tiebreak=index  | when score are tied, prefer line that appeared first in input stream
# --nth 2..         | ignore first field (the popularity of the dir) when matching
FZF_Z_OPTIONS=(--tac --tiebreak=index --nth 2..)

function zwidget::fzf::z
{
  local last_pwd=$PWD

  local fzf_cmd=($FZF_BASE_CMD $FZF_Z_OPTIONS --prompt "Fuzzy jump to: " --preview "$FZF_PREVIEW_CMD_FOR_DIR"" {2..}")
  local selected=( $( z | "${fzf_cmd[@]}" ) )
  if [ -n "$selected" ]; then
    local directory="${selected[2, -1]}" # pop first element (the frecency score)
    if [ -n "$directory" ]; then
      cd "$directory"
      HOOK_LIKE_TOPLEVEL=1 hooks-run-hook chpwd_hook
    fi
  fi
  zle reset-prompt

  if [ $last_pwd != $PWD ]; then
    zle -M "cd'ed to '${(D)PWD}'"
  fi
}
zle -N zwidget::fzf::z
