# A set of fzf-based zsh widgets, for key bindings
# TODO: add a LICENSE for these!

# NOTE: These lines may be rewritten by config manager.
_BIN_fzf=fzf
_BIN_fd=fd
_BIN_bat=bat
_BIN_git=git

if [[ $- != *i* ]]; then
  # -> This is not an interactive shell, bail out!
  return
fi

# Transforms a list of results to a list of relative paths to the given dir
# (it must be given _at least_ relative to CWD, or as an absolute path).
function zwidget::utils::results_to_paths_relative_to
{
  local relative_to_path="$1"
  while read item; do
    # NOTE: --no-symlinks is used to ensure symlinks are not expanded and kept as is.
    realpath --relative-to="$relative_to_path" --no-symlinks "$item"
  done
}

# Transforms a list of results to a list of absolute paths.
function zwidget::utils::results_to_absolute_paths
{
  while read item; do
    realpath "$item"
  done
}

# Transforms a list of results to zsh arguments, to be inserted at cursor
# position in the cmdline.
function zwidget::utils::results_to_args
{
  while read item; do
    echo -n "${(D)item} "
  done
}

FZF_BASE_CMD=($_BIN_fzf)

function zwidget::utils::__fzf_generic_impl_for_paths
{
  local completion_prefix="${LBUFFER/* /}" # we remove everything until the last space
  local lbuffer_without_completion_prefix="${LBUFFER%${completion_prefix}}"

  # NOTE: it's important to NOT put it inside quotes, the expansion wouldn't work :eyes:.
  local expanded_completion_prefix=${~completion_prefix}

  # --- cases ---
  # completion_prefix ~ "foo/bar/"
  # completion_prefix ~ "foo/bar/ba"
  # completion_prefix = "~/" or "~special/"
  # completion_prefix = "~/bar" or "~special/bar"
  # (INFO: 'foo' can be anything, including . or ..)

  local query_prefill
  local maybe_root_path

  if [[ -n "$expanded_completion_prefix" ]]; then
    if [[ "$expanded_completion_prefix" =~ '.*\/$' ]]; then
      # -> The completion prefix ends with a /
      local query_prefill=""
      # NOTE: var%? removes last char from var
      # ref: https://unix.stackexchange.com/a/310243/159811
      # (allows display_root_path to add the '/' and it's not a duplicate)
      local maybe_root_path="${expanded_completion_prefix%?}"
    elif [[ "$expanded_completion_prefix" =~ '\/' ]]; then
      # -> The completion prefix has at least a /
      local maybe_root_path="$(dirname "$expanded_completion_prefix")"
      local query_prefill="$(basename "$expanded_completion_prefix")"
    else
      # -> The completion prefix is not a path (or is a partial one)
      local query_prefill="$completion_prefix"
      local maybe_root_path="."
    fi
  fi

  if [[ -d "$maybe_root_path" ]]; then
    # -> Search will be from that root path
    local search_root_path="$maybe_root_path"
    local display_root_path="${(D)maybe_root_path}/"
  else
    # -> Search will be from FZF_ROOT_PATH or simply CWD.
    local search_root_path="${FZF_ROOT_PATH:-$PWD}"
    local display_root_path=""
  fi

  # NOTE: the results transformers should be run from "$search_root_path", to
  # be able to understand the result paths they take as input.
  if [[ "$completion_prefix" =~ '^~' ]]; then
    # -> The completion prefix starts with ~
    # The results should not be transformed to CWD, otherwise we'll get a lot
    # of ../../... etc..
    # Instead, the results should be all absolute paths, and the final
    # transformation to cmdline args will transform these absolute paths back
    # to ~/... paths (or ~special/... if relevant).
    local results_transformer=(zwidget::utils::results_to_absolute_paths)
  else
    # By default, the results are transformed back to be relative to CWD.
    local results_transformer=( \
      zwidget::utils::results_to_paths_relative_to "$(realpath "$PWD")"
    )
  fi

  # WARNING: This var CANNOT be named 'prompt' because it conflicts with zsh'
  # own 'prompt' var.
  local final_prompt="${FZF_PROMPT:-}${display_root_path}"

  local fzf_cmd=($FZF_BASE_CMD --multi)
  fzf_cmd+=(--query "$query_prefill")
  fzf_cmd+=(--prompt "${final_prompt}")
  if [[ -n "${FZF_PREVIEW_CMD:-}" ]]; then
    fzf_cmd+=(--preview "$FZF_PREVIEW_CMD")
  fi
  if [[ -n "${FZF_PREVIEW_WINDOW:-}" ]]; then
    fzf_cmd+=(--preview-window "$FZF_PREVIEW_WINDOW")
  fi
  if [[ -n "${FZF_USE_FOCUS_AS_PREVIEW_LABEL}" ]]; then
    fzf_cmd+=(
      --bind='focus:transform-preview-label:echo [ {} ]'
      --color=preview-label:247:bold
    )
  fi

  local selected_completions=$( \
    (cd "$search_root_path"; "${FZF_FINDER_CMD[@]}" | "${fzf_cmd[@]}" | "${results_transformer[@]}") |
    zwidget::utils::results_to_args
  )

  if [[ -n "$selected_completions" ]]; then
    LBUFFER="${lbuffer_without_completion_prefix}${selected_completions}"
  fi
  zle reset-prompt
}

FZF_PREVIEW_CMD_FOR_FILE="$_BIN_bat --color=always --style=numbers,header -- {}"

function zwidget::fzf::smart_find_file
{
  FZF_FINDER_CMD=($_BIN_fd --type f --type l --follow) # follow symlinks
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

# -F : show / for dirs, and other markers
# -C : show dirs in columns
FZF_PREVIEW_CMD_FOR_DIR="ls --color=always --group-directories-first -F -C --dereference -- {}"

function zwidget::fzf::find_directory
{
  FZF_PROMPT="Smart dirs: "
  FZF_FINDER_CMD=($_BIN_fd --type d --type l --follow) # follow symlinks
  FZF_PREVIEW_CMD="$FZF_PREVIEW_CMD_FOR_DIR"
  FZF_PREVIEW_WINDOW="down:10"
  FZF_USE_FOCUS_AS_PREVIEW_LABEL=true

  zwidget::utils::__fzf_generic_impl_for_paths

  unset FZF_PROMPT FZF_FINDER_CMD FZF_PREVIEW_CMD FZF_PREVIEW_WINDOW FZF_USE_FOCUS_AS_PREVIEW_LABEL
}
zle -N zwidget::fzf::find_directory

# --scheme=history  | Scoring scheme for command history (no additional bonus points)
#                   | (prefer lines that are first in the input)
# --nth 2..         | Ignore first field when matching (history entry number)
# --no-sort         | Do not sort the results (keep history order)
#                   | => use ctrl-r for better matches if needed
FZF_HISTORY_OPTIONS=(--scheme=history --nth 2.. --no-sort --no-multi --bind=ctrl-r:toggle-sort)

function zwidget::fzf::history
{
  # -l  | list the commands
  # -r  | show in reverse order (=> most recent first)
  # 1   | start at command n° 1 (the oldest still in history)
  local history_cmd=(fc -l -r 1)

  local fzf_cmd=($FZF_BASE_CMD $FZF_HISTORY_OPTIONS)
  fzf_cmd+=(--query "${LBUFFER//$/\\$}")

  local selected=( $( "${history_cmd[@]}" | "${fzf_cmd[@]}" ) )
  if [[ -n "$selected" ]]; then
    local history_index="${selected[1]}"
    if [[ -n "$history_index" ]]; then
      zle vi-fetch-history -n "$history_index"
    fi
  fi
  zle reset-prompt
}
zle -N zwidget::fzf::history

function zwidget::fzf::z
{
  local last_pwd=$PWD

  # Replace all {} with {2..} to ensure we don't pass the first field (popularity of the dir)
  local _braces="{}"
  local _braces_skip_first="{2..}"
  local preview_cmd="${FZF_PREVIEW_CMD_FOR_DIR//$_braces/$_braces_skip_first}"

  # --tiebreak=index  | when score are tied, prefer line that appeared first in input stream
  # --nth 2..         | ignore first field (the popularity of the dir) when matching
  local fzf_cmd=($FZF_BASE_CMD --tac --scheme=history --nth 2..)
  fzf_cmd+=(--prompt "Fuzzy jump to: ")
  fzf_cmd+=(--preview "$preview_cmd" --preview-window down:10)
  fzf_cmd+=(
    --bind='focus:transform-preview-label:echo [ {} ]'
    --color=preview-label:247:bold
  )

  local selected=( $( z | "${fzf_cmd[@]}" ) )
  if [[ -n "$selected" ]]; then
    local directory="${selected[2, -1]}" # pop first element (the frecency score)
    if [[ -n "$directory" ]]; then
      cd "$directory"
      HOOK_LIKE_TOPLEVEL=1 hooks-run-hook chpwd_hook
    fi
  fi
  zle reset-prompt

  if [[ "$last_pwd" != "$PWD" ]]; then
    zle -M "welcome to '${(D)PWD}' :)"
  fi
}
zle -N zwidget::fzf::z

# Checks if we are in a git repository, displays a ZLE message otherwize.
# Copied from zle::utils::check_git here to have a mostly self-contained file
function zwidget::utils::check_git
{
  if ! $_BIN_git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    zle -M "Error: Not a git repository"
    return 1
  fi
}

function zwidget::fzf::git_changed_files
{
  zwidget::utils::check_git || return

  if [[ -n "$FZF_GIT_CHANGED_FROM_CWD" ]]; then
    # files from cwd
    local prompt_note="in cwd"
    local finder_cmd="$_BIN_git diff --name-only --relative"
    local preview_cmd="$_BIN_git diff --color=always -- {}"
    FZF_ROOT_PATH="."
  else
    # files from root of the repo
    local prompt_note="in repo"
    local finder_cmd="$_BIN_git diff --name-only"
    local preview_cmd="$_BIN_git diff --color=always -- :/{}"

    # The finder_cmd gives paths absolute to the root of the repo
    # (without a leading '/' though). When inserting the results in the
    # cmdline, each path will be made relative to cwd. We need to give it
    # the git root to be able to compute correct relative paths:
    FZF_ROOT_PATH="$($_BIN_git rev-parse --show-toplevel)"
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
