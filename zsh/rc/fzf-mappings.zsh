# Key bindings

if [[ $- != *i* ]]; then
  return
fi

# TODO: Add some doc about the arg, and how it works.
function zwidget::utils::results_to_relative_paths_from_root
{
  local from_root_path="$1"

  (cd "$from_root_path"; while read item; do realpath --relative-to="$OLDPWD" "$item"; done)
}

function zwidget::utils::results_to_args
{
  while read item; do
    echo -n "${(D)item} "
  done
}

# Those layout & keybindings vars come from ~/.zshenv
FZF_BASE_CMD=(fzf ${FZF_BEW_LAYOUT_ARRAY} ${FZF_BEW_KEYBINDINGS_ARRAY})

function zwidget::utils::__fzf_generic_impl_for_paths
{
  local completion_prefix="${LBUFFER/* /}"
  local lbuffer_without_completion_prefix="${LBUFFER%${completion_prefix}}"

  # NOTE: `~` flag will expand `~` to $HOME (at least)
  if [[ -d "${~completion_prefix}" ]]; then
    local query=""
    local real_root_path="${~completion_prefix}/"
    local display_root_path="${completion_prefix}" # ~/ is not expanded
  else
    local query="$completion_prefix"
    local real_root_path="${FZF_ROOT_PATH:-.}/"
    local display_root_path=""
  fi

  # WARNING: this var CANNOT be named 'prompt' as it conflicts with zsh' own PROMPT/prompt vars.
  local final_prompt="${FZF_PROMPT:-}${display_root_path}"
  local preview_cmd="${FZF_PREVIEW_CMD:-}"

  local fzf_cmd=($FZF_BASE_CMD --multi)
  fzf_cmd+=(--query "$query")
  fzf_cmd+=(--prompt "${final_prompt}")
  fzf_cmd+=(--preview "$preview_cmd")
  if [[ -n "${FZF_PREVIEW_WINDOW:-}" ]]; then
    fzf_cmd+=(--preview-window "$FZF_PREVIEW_WINDOW")
  fi

  local selected_completions=$( \
    (cd "$real_root_path"; "${FZF_FINDER_CMD[@]}" | "${fzf_cmd[@]}") |
    zwidget::utils::results_to_relative_paths_from_root "$real_root_path" |
    zwidget::utils::results_to_args
  )

  if [[ -n "$selected_completions" ]]; then
    LBUFFER="${lbuffer_without_completion_prefix}${selected_completions}"
  fi
  zle reset-prompt
}

FZF_PREVIEW_CMD_FOR_FILE="bat --color=always --style=numbers,header -- {}"

function zwidget::fzf::smart_find_file
{
  FZF_FINDER_CMD=(fd --type f --type l --follow) # follow symlinks
  FZF_PROMPT="Smart files: "
  FZF_PREVIEW_CMD="$FZF_PREVIEW_CMD_FOR_FILE"

  zwidget::utils::__fzf_generic_impl_for_paths

  unset FZF_FINDER_CMD FZF_PROMPT FZF_PREVIEW_CMD
}
zle -N zwidget::fzf::smart_find_file

function zwidget::fzf::find_file
{
  FZF_FINDER_CMD=(find -L) # follow symlinks
  FZF_FINDER_CMD+=('(' -path '*/.*' -o -fstype 'dev' -o -fstype 'proc' ')' -prune) # ignore options
  FZF_FINDER_CMD+=(-o -type f -o -type l) # actual file filter

  FZF_PROMPT="All files: "
  FZF_PREVIEW_CMD="$FZF_PREVIEW_CMD_FOR_FILE"

  zwidget::utils::__fzf_generic_impl_for_paths

  unset FZF_FINDER_CMD FZF_PROMPT FZF_PREVIEW_CMD
}
zle -N zwidget::fzf::find_file

function zwidget::fzf::find_directory
{
  FZF_PROMPT="Smart dirs: "
  FZF_FINDER_CMD=(fd --type d --type l --follow) # follow symlinks

  # -F : show / for dirs, and other markers
  # -C : show dirs in columns
  FZF_PREVIEW_CMD="echo --- {} ---; ls --color=always --group-directories-first -F -C --dereference -- {}"
  FZF_PREVIEW_WINDOW="down:10"

  zwidget::utils::__fzf_generic_impl_for_paths

  unset FZF_PROMPT FZF_FINDER_CMD FZF_PREVIEW_CMD FZF_PREVIEW_WINDOW
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
  if [[ -n "$selected" ]]; then
    local history_index=$selected[1]
    if [[ -n "$history_index" ]]; then
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
  if [[ -n "$selected" ]]; then
    local directory="${selected[2, -1]}" # pop first element (the frecency score)
    if [[ -n "$directory" ]]; then
      cd "$directory"
      HOOK_LIKE_TOPLEVEL=1 hooks-run-hook chpwd_hook
    fi
  fi
  zle reset-prompt

  if [[ $last_pwd != $PWD ]]; then
    zle -M "welcome to '${(D)PWD}' :)"
  fi
}
zle -N zwidget::fzf::z

function zwidget::fzf::git_changed_files
{
  zle::utils::check_git || return

  if [[ -n "$FZF_GIT_CHANGED_FROM_CWD" ]]; then
    # files from cwd
    local prompt_note="in cwd"
    local finder_cmd="git diff --name-only --relative"
    local preview_cmd="git diff --color=always -- {}"
    FZF_ROOT_PATH="."
  else
    # files from root of the repo
    local prompt_note="in repo"
    local finder_cmd="git diff --name-only"
    local preview_cmd="git diff --color=always -- :/{}"

    # The finder_cmd gives paths absolute to the root of the repo
    # (without a leading '/' though). When inserting the results in the
    # cmdline, each path will be made relative to cwd. We need to give it
    # the git root to be able to compute correct relative paths:
    FZF_ROOT_PATH="$(git rev-parse --show-toplevel)"
  fi

  FZF_PROMPT="Changed files ($prompt_note): "
  # The `uniq` is necessary in some cases to remove doubles
  # (like when rebasing, unmerged paths 'modified by both' appear twice)
  FZF_FINDER_CMD=(sh -c "$finder_cmd | uniq")
  FZF_PREVIEW_CMD="$preview_cmd | delta"

  zwidget::utils::__fzf_generic_impl_for_paths

  unset FZF_PROMPT FZF_FINDER_CMD FZF_PREVIEW_CMD FZF_ROOT_PATH
}
zle -N zwidget::fzf::git_changed_files

function zwidget::fzf::git_changed_files_in_cwd
{
  FZF_GIT_CHANGED_FROM_CWD=1 zwidget::fzf::git_changed_files
}
zle -N zwidget::fzf::git_changed_files_in_cwd
