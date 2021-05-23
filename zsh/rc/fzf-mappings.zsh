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

FZF_DEFAULT_PREVIEW_CMD_FOR_FILE="bat --color=always --style=numbers,header {}"

# -F : show / for dirs, and other markers
# -C : show dirs in columns
FZF_DEFAULT_PREVIEW_CMD_FOR_DIR="echo --- {} ---; ls --color=always --group-directories-first -F -C --dereference {}"

function __fzf_widget_file_impl
{
  local completion_prefix=${LBUFFER/* /}
  local lbuffer_without_completion_prefix="${LBUFFER%${completion_prefix}}"

  local base_dir=${completion_prefix:-./}
  base_dir=${~base_dir} # expand ~ (at least)

  local prompt_prefix=${FZF_PROMPT_PREFIX:-}
  local preview_cmd=${FZF_PREVIEW_CMD:-${FZF_DEFAULT_PREVIEW_CMD_FOR_FILE}}

  local fzf_cmd=($FZF_BASE_CMD --multi --prompt "${prompt_prefix}${base_dir}" --preview "$preview_cmd")
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
  local preview_cmd=${FZF_PREVIEW_CMD:-${FZF_DEFAULT_PREVIEW_CMD_FOR_DIR}}

  local fzf_cmd=($FZF_BASE_CMD --multi --prompt "$base_dir" --preview "$preview_cmd" --preview-window down:10)
  local selected_completions=$(cd $base_dir; "${finder_cmd[@]}" | "${fzf_cmd[@]}" |
    __results_to_path_args "$base_dir"
  )

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

  # Replace all {} with {2..} to ensure we don't pass the first field (popularity of the dir)
  local _braces="{}"
  local _braces_skip_first="{2..}"
  local preview_cmd="${FZF_DEFAULT_PREVIEW_CMD_FOR_DIR//$_braces/$_braces_skip_first}"

  local fzf_cmd=($FZF_BASE_CMD $FZF_Z_OPTIONS --prompt "Fuzzy jump to: " --preview "${preview_cmd}" --preview-window down:10)
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
