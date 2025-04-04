# --- venv helper functions

# TODO: When I make this a proper repo, need to add completion scripts
#   IDEA for completion of venv_* (except venv_with_do),
#        search DIRs where $DIR/bin/python exists.

function _venv__echo2_n_color_guard
{
  local color="${1:-0m}"; shift
  local content="$*"
  if [[ -t 2 ]] || [[ -n "${VENV_FORCE_COLOR:-}" ]]; then # NOTE: we check we're on a tty for colors
    >&2 echo -ne "\e[${color}"
    >&2 echo -n "$content"
    >&2 echo -ne "\e[0m"
  else
    >&2 echo -n "$content"
  fi
}

VENV_QUIET=""
_VENV__ECHO_LAST_LINE_COLOR=""
_VENV__ECHO_LAST_LINE_PREFIX=""
_VENV__ECHO_LAST_LINE_PREFIX_COLOR=""

function _venv__echo2
{
  if [[ $# == 0 ]] || [[ $1 =~ "^-h|--help$" ]]; then
    _venv__echo2 usage "Usage: _venv__echo2 KIND [stuff-to-echo...]"
    _venv__echo2 usage
    _venv__echo2 usage "Some KIND have special formatting,"
    _venv__echo2 usage "check the source for details."
    _venv__echo2 usage
    _venv__echo2 usage "Can be disabled by setting \$VENV_QUIET"
    _venv__echo2 usage
    return 1
  fi

  [[ -n "$VENV_QUIET" ]] && return

  local kind="$1"; shift
  local content="$*"
  local col_red="31m" col_cyan="36m" col_yellow="33m" col_bold_green="1;32m"
  local line_color line_prefix line_prefix_color
  case "$kind" in
    info) line_prefix="| "; line_prefix_color="$col_cyan";;
    note) line_prefix="| "; line_color="$col_cyan";;
    warn*) line_prefix="/!\\ "; line_color="$col_yellow";;
    err*) line_prefix="!!! "; line_color="$col_red";;
    section) line_prefix=">>> "; line_color="$col_bold_green";;
    usage) line_prefix="| "; line_prefix_color="$col_yellow";;
    last_line) line_color="$_VENV__ECHO_LAST_LINE_COLOR";;
    last)
      line_color="$_VENV__ECHO_LAST_LINE_COLOR"
      line_prefix="$_VENV__ECHO_LAST_LINE_PREFIX"
      line_prefix_color="$_VENV__ECHO_LAST_LINE_PREFIX_COLOR"
      ;;
    *) true;; # use the default formatting
  esac
  _VENV__ECHO_LAST_LINE_COLOR="$line_color"
  _VENV__ECHO_LAST_LINE_PREFIX="$line_prefix"
  _VENV__ECHO_LAST_LINE_PREFIX_COLOR="$line_prefix_color"
  [[ -n "$line_prefix" ]] && _venv__echo2_n_color_guard "${line_prefix_color:-$line_color}" "$line_prefix"
  _venv__echo2_n_color_guard "$line_color" "$content"
  >&2 echo
}

VENV_DEFAULT_DIR="${VENV_DEFAULT_DIR:-.venv}"

function _venv__ensure_exists
{
  local venv_dir="${1:-$VENV_DEFAULT_DIR}"

  if ! [[ -d "$venv_dir" ]]; then
    _venv__echo2 err "ERROR: '$venv_dir' directory does NOT exist"
    return 1
  fi

  if ! [[ -f "$venv_dir/bin/python" ]]; then
    _venv__echo2 err "ERROR: Interpreter '$venv_dir/bin/python' does NOT exist"
    return 1
  fi
}

function _venv__ensure_inside
{
  if [[ -z "${VIRTUAL_ENV:-}" ]]; then
    _venv__echo2 err "ERROR: not in a virtual env"
    return 1
  fi
}

function _venv__ensure_outside
{
  if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    _venv__echo2 info "--- Disabling active virtual env.."
    _venv__deactivate_with_fallback
  fi
}

function _venv__deactivate_with_fallback
{
  if ! deactivate; then
    _venv__echo2 warn "'deactivate' failed, maybe we're in a subshell?"
    _venv__echo2 info "--- Disabling virtual env manually (remove it from \$PATH and unset \$VIRTUAL_ENV)"
    local venv_bin_path="$VIRTUAL_ENV/bin"
    # remove the venv bin path from $PATH
    # ref: https://unix.stackexchange.com/a/311761/159811
    PATH=${PATH//${venv_bin_path}:}
    unset VIRTUAL_ENV
    # Refresh cached list of binaries
    hash -r
  fi
}

VENV_DEFAULT_PYTHON_BIN="${VENV_DEFAULT_PYTHON_BIN:-python3}"

function _venv__find_python_bin_path
{
  local show_used_bin=false
  local want_path=false
  [[ "${1:-}" == "--verbose" ]] && shift && show_used_bin=true

  local python_bin_raw="${VENV_PYTHON_BIN:-$VENV_DEFAULT_PYTHON_BIN}"
  local python_bin_path="$(command -v "$python_bin_raw")"
  if ! [[ -f "$python_bin_path" ]]; then
    _venv__echo2 err "error: The python bin '$python_bin_raw' is not in \$PATH"
    return 1
  fi
  if $show_used_bin; then
    _venv__echo2 info "Using python bin: '$python_bin_raw' at '$python_bin_path' (set \$VENV_PYTHON_BIN to override)"
  fi
  echo "$python_bin_path"
}

function venv_init
{
  local venv_dir="${1:-$VENV_DEFAULT_DIR}"

  if [[ -d "$venv_dir" ]]; then
    _venv__echo2 err "ERROR: '$venv_dir' directory already exists"
    return 1
  fi

  local python_bin_path="$(_venv__find_python_bin_path --verbose)"
  [[ -z "$python_bin_path" ]] && return 1
  "$python_bin_path" -m venv -- "$venv_dir"
}

function venv_on
{
  local venv_dir="${1:-$VENV_DEFAULT_DIR}"

  _venv__ensure_outside

  if ! _venv__ensure_exists "$venv_dir"; then
    _venv__echo2 last "  Use venv_init to create a venv there."
    return 1
  fi

  local used_python_version="$("$venv_dir/bin/python" --version)"
  _venv__echo2 info "+++ Enabling virtual env.. ($used_python_version)"
  source "$venv_dir/bin/activate"
}

function venv_off
{
  _venv__ensure_inside || return 1

  _venv__echo2 info "--- Disabling virtual env.."
  _venv__deactivate_with_fallback
}

function venv_do
{
  # NOTE: here venv_dir is assumed to be "$VENV_DEFAULT_DIR"
  if [[ $# == 0 ]] || [[ $1 =~ "^-h|--help$" ]]; then
    _venv__echo2 usage "Usage: venv_do [VENV_DIR] -- CMD..."
    _venv__echo2 usage
    _venv__echo2 usage "Enable venv at VENV_DIR (or \$VENV_DEFAULT_DIR),"
    _venv__echo2 usage "run CMD... and finally disable the venv"
    _venv__echo2 usage "(and restore previous venv if needed)."
    _venv__echo2 usage
    _venv__echo2 usage "    $ venv_do -- python -V"
    _venv__echo2 usage "    Will show the python version in default venv name"
    _venv__echo2 usage
    _venv__echo2 usage "    $ venv_do ./my-venv -- python -V"
    _venv__echo2 usage "    Will show the python version in venv named './my-venv'"
    _venv__echo2 usage
    return 1
  fi

  local venv_dir
  if [[ "$1" == "--" ]]; then
    shift
    venv_dir="$VENV_DEFAULT_DIR"
  else
    venv_dir="${1:-$VENV_DEFAULT_DIR}"
    if [[ "${2:-}" != "--" ]]; then
      _venv__echo2 err "error: '--' must follow the venv name if given"
      return 1
    fi
    shift; shift
  fi

  if [[ $# == 0 ]]; then
    _venv__echo2 err "error: missing the command!"
    return 1
  fi

  SAVED_VIRTUAL_ENV="${VIRTUAL_ENV:-}"

  local maybe_saved_msg
  if [[ -n "$SAVED_VIRTUAL_ENV" ]]; then
    maybe_saved_msg=" (current venv saved)"
  fi
  _venv__echo2 section "Switching to venv '$venv_dir' to run cmd${maybe_saved_msg}"
  venv_on "$venv_dir" || return 1

  _venv__echo2 section "Running command '$*'"
  local ret=0
  "$@" || ret=$?

  [[ $ret == 0 ]] || _venv__echo2 err "command failed, exited with $ret"

  if [[ -n "$SAVED_VIRTUAL_ENV" ]]; then
    _venv__echo2 section "Re-enabling saved venv"
    if [[ -d "$SAVED_VIRTUAL_ENV" ]]; then
      venv_on "$SAVED_VIRTUAL_ENV"
    else
      _venv__echo2 warn "warning: cannot re-enable saved venv, no directory at '$SAVED_VIRTUAL_ENV'"
    fi
  else
    _venv__echo2 section "Bye bye"
    venv_off
  fi
  return $ret
}

# Helper to activate a venv, deactivating an existing one and
# creating it if necessary.
function venv_here
{
  local venv_dir="${1:-$VENV_DEFAULT_DIR}"

  _venv__ensure_outside

  if ! [[ -d "$venv_dir" ]]; then
    _venv__echo2 info "Venv directory '$venv_dir' missing, creating venv now.."
    venv_init "$venv_dir" || return 1
  fi

  venv_on "$venv_dir"
}
alias venv=venv_here # short alias

# Helper to reset a venv, deactivating an existing one and recreate
# the whole virtual env.
function venv_reset
{
  local venv_dir="${1:-$VENV_DEFAULT_DIR}"

  _venv__ensure_outside

  if [[ -d "$venv_dir" ]]; then
    _venv__echo2 info "Resetting existing virtual env in directory '$venv_dir'.."
    local python_bin_path="$(_venv__find_python_bin_path --verbose)"
    [[ -z "$python_bin_path" ]] && return 1
    "$python_bin_path" -m venv --clear -- "$venv_dir" || return 1
    venv_on "$venv_dir"
  else
    venv_here "$venv_dir"
  fi
}

VENV_VOLATILE_BASE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/volatile-venvs"
# Helper to create a volatile venv with the given packages and run a command.
#
# E.g: venv_with_do ansible -- ansible-playbook ...
function venv_with_do
{
  if [[ $# == 0 ]] || [[ $1 =~ "^-h|--help$" ]]; then
    _venv__echo2 usage "Usage: venv_with_do [--new|--upgrade|--quiet|-q] PKGS... [-- [CMD...]]"
    _venv__echo2 usage
    _venv__echo2 usage "Creates a volatile python virtual env, installs the given PKGS in it."
    _venv__echo2 usage "Subsequent calls with the same python version and PKGS will reuse the env."
    _venv__echo2 usage
    _venv__echo2 usage "The virtual env directory is located in '$VENV_VOLATILE_BASE_DIR'"
    _venv__echo2 usage "The virtual env name is derived from:"
    _venv__echo2 usage "  - the used python version"
    _venv__echo2 usage "  - the wanted PKGS..."
    _venv__echo2 usage "This means that using different PKGS or a different python version"
    _venv__echo2 usage "will create a *different* virtual env."
    _venv__echo2 usage
    _venv__echo2 usage "note: To make an empty volatile venv, use: 'venv_with_do --'"
    _venv__echo2 usage
    _venv__echo2 usage "Config is done through env vars: (self explainatory)"
    _venv__echo2 usage "  - VENV_VOLATILE_BASE_DIR"
    _venv__echo2 usage "  - VENV_VOLATILE_DEFAULT_CMD"
    _venv__echo2 usage "  - VENV_PYTHON_BIN"
    _venv__echo2 usage
    return 1
  fi

  # NOTE: this will be run in a subshell
  # Running this in a subshell allows to have almost anything as the cmd (even exit), and avoid
  # polluting the current shell's env vars with env vars that are temporary for the volatile venv.
  function _venv_with_do::impl
  {
    # split args for packages and cmd to run
    local pkgs=()
    local cmd=()
    local force_new=false
    local force_upgrade=false
    local quiet_install=false
    local dashdash_found=false
    while [[ -n "${1:-}" ]]; do
      case "$1" in
        --new|--reset)
          force_new=true;;
        --upgrade)
          force_upgrade=true;;
        --quiet|-q)
          quiet_install=true;;
        --)
          dashdash_found=true;;
        *)
          if $dashdash_found; then
            cmd+=("$1")
          else
            pkgs+=("$1")
          fi
          ;;
      esac
      shift
    done
    if [[ "${#cmd[@]}" == 0 ]]; then
      cmd=("${VENV_VOLATILE_DEFAULT_CMD:-zsh}")
      _venv__echo2 section "Initialization checks"
      _venv__echo2 info "Command not given, defaulting to '${cmd[*]}' (override the default with \$VENV_VOLATILE_DEFAULT_CMD)"
    fi

    # Make a venv somewhere volatile (based on wanted packages)
    # We use a simple md5 hash of the wanted packages as a venv identifier.
    # E.g: /home/me/.cache/volatile-venvs/d3b07384d113edec49eaa6238ad5ff00
    local venv_dir_hash=$(echo "${pkgs[@]}" | md5sum | awk '{ print $1 }')
    local python_bin_path="$(_venv__find_python_bin_path)"
    # `python --version` looks like `Python 3.7.10 (optional stuff here)`
    # => Transform it to: `Py3.7.10
    local python_version=$("$python_bin_path" --version \
      | awk '{ sub(/Python/, "Py", $1); print $1$2 }')
    local venv_path="${VENV_VOLATILE_BASE_DIR}/${python_version}-${venv_dir_hash}"

    local created_or_reused_msg="created"
    [[ -d "$venv_path" ]] && created_or_reused_msg="reused"
    _venv__echo2 section "venv will be $created_or_reused_msg in '$venv_path'"
    if $force_new; then
      _venv__echo2 section "--new/--reset passed, force create new venv.."
      venv_reset "$venv_path" || return $?
    else
      venv_here "$venv_path" || return $?
    fi

    if [[ "${#pkgs[@]}" != 0 ]]; then
      local opts_msg=""
      $force_upgrade && opts_msg+=" (with upgrade)"
      $quiet_install && opts_msg+=" (quiet)"
      _venv__echo2 section "Installing packages${opts_msg}: ${pkgs[@]}"
      local opts=()
      $force_upgrade && opts+=("--upgrade")
      $quiet_install && opts+=("--quiet" "--quiet") # show errors only (hides usual + warnings logs)
      pip install "${opts[@]}" "${pkgs[@]}" || return $?
      echo "pip install ${opts[*]} ${pkgs[*]}" > "$venv_path/volatile-venv-pip-invocation"
    else
      _venv__echo2 section "No package to install"
      echo > "$venv_path/volatile-venv-pip-invocation"
    fi
    ln -fs "$python_bin_path" "$venv_path/volatile-venv-python-used" >/dev/null

    _venv__echo2 section "Running command '${cmd[*]}'"
    VENV_IS_VOLATILE=true "${cmd[@]}"
  }

  # Run in a subshell, to ensure we don't change env vars
  # in the current shell.
  ( _venv_with_do::impl "$@" )
}
alias venv_with_do::upgrade="venv_with_do --upgrade"

# cd into current venv (to search something, ..)
function cdvenv
{
  if [[ -z "$VIRTUAL_ENV" ]]; then
    >&2 echo "Not in a virtual env :shrug: (\$VIRTUAL_ENV not set)"
  fi

  cd $(dirname "$VIRTUAL_ENV")

  local venv_name=$(basename "$VIRTUAL_ENV")
  >&2 echo "Welcome to your current virtual env, named '$venv_name'"
}

# A pip replacement, disabled unless in a virtual env or --allow-for-global-env is passed
# to avoid changing the global user python env by mistake.
function pip::disabled-for-global-env
{
  if [[ "$1" == "--allow-for-global-env" ]]; then
    shift
    _venv__echo2 note "note: if a virtual env is currently active, you'll change that env not your user's."
    command pip "$@"
    return $?
  fi

  # If there is a venv, ensure the dir actually exists and pip is in there
  # (otherwise the global pip would be used..)
  if [[ -n "${VIRTUAL_ENV:-}" ]] && [[ -e "$VIRTUAL_ENV/bin/pip" ]]; then
    "$VIRTUAL_ENV/bin/pip" "$@"
    return $?
  fi
  _venv__echo2 err "Nope! 'pip' is disabled globally, use 'pip-for-global-env' to manage packages in the user env"
  return 1
}
if command -v pip 2>&1 >/dev/null; then
  # pip is available globally, disable it:
  alias pip=pip::disabled-for-global-env
  alias pip-for-global-env="pip::disabled-for-global-env --allow-for-global-env"
fi

# pytest helpers

alias pytest::no-cov="pytest --no-cov"
alias pytest::no-warn="echo '!!!! Warnings are disabled !!!!'; pytest --disable-warnings"
alias pytest::no-cov-no-warn="pytest::no-warn --no-cov"
alias pytest::report-10-slowest="pytest::no-cov-no-warn --durations=10"
alias pytest::fail-fast-verbose="pytest::no-cov-no-warn --exitfirst -vv --showlocals"
alias pytest::last-failed-verbose="pytest::no-cov-no-warn --last-failed -vv --showlocals"
alias pytest::failed-first="pytest::no-cov-no-warn --failed-first"

# vim:set sw=2:
