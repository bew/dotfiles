# Key bindings
# ------------
if [[ $- != *i* ]]; then
	return
fi

FIND_IGNORE_OPTIONS="\\( -path '*/\\.*' -o -fstype 'dev' -o -fstype 'proc' \\) -prune"

#FIND_FILTER_ALL_FILES="-o -type f -print -o -type d -print"
FIND_FILTER_ALL_FILES="-o -type f -print"
FIND_FILTER_DIRS="-o -type d -print"

function __fsel
{
	local filters="$1"

	if [ -n "$2" ]; then
		local base_dir="$2"
        base_dir=${~base_dir} # expand ~ (at least)
	else
		local base_dir='.'
	fi
	local cmd="command find -L '$base_dir' ${FIND_IGNORE_OPTIONS} \
		$filters
		2> /dev/null | sed 1d"
	eval "$cmd" | $(__fzfcmd) --multi | while read item; do
		echo -n "${(q)item} "
	done
	echo
}

function __fzfcmd
{
	echo "fzf ${FZF_BEW_LAYOUT} ${FZF_BEW_KEYBINDINGS}"
}

function zwidget::fzf::find_file
{
	local completion_prefix="${LBUFFER/* /}"
	local lbuffer_without_completion_prefix="${LBUFFER%$completion_prefix}"

	local selected_completions="$(__fsel "$FIND_FILTER_ALL_FILES" "$completion_prefix")"

	if [ -n "$selected_completions" ]; then
		LBUFFER="${lbuffer_without_completion_prefix}${selected_completions}"
	fi
	zle reset-prompt
}
zle -N zwidget::fzf::find_file

function zwidget::fzf::find_directory
{
	local completion_prefix="${LBUFFER/* /}"
	local lbuffer_without_completion_prefix="${LBUFFER%$completion_prefix}"

	local selected_completions="$(__fsel "$FIND_FILTER_DIRS" "$completion_prefix")"

	if [ -n "$selected_completions" ]; then
		LBUFFER="${lbuffer_without_completion_prefix}${selected_completions}"
	fi
	zle reset-prompt
}
zle -N zwidget::fzf::find_directory

# -l  | list the commands
# -r  | show in reverse order (=> most recent first)
# 1   | start at command n° 1 (the oldest still in history)
HISTORY_CMD=(fc -lr 1)

FZF_HISTORY_OPTIONS=(--no-multi -n2..,.. --tiebreak=index)

function zwidget::fzf::history
{
	local selected=( $( $HISTORY_CMD | $(__fzfcmd) $FZF_HISTORY_OPTIONS -q "${LBUFFER//$/\\$}") )
	if [ -n "$selected" ]; then
		local history_index=$selected[1]
		if [ -n "$history_index" ]; then
			zle vi-fetch-history -n $history_index
		fi
	fi
	zle reset-prompt
}
zle -N zwidget::fzf::history

# --nth 2..         | ignore first field (the popularity of the dir) when matching
FZF_Z_OPTIONS=(--tac --tiebreak=index --nth 2..)

function zwidget::fzf::z
{
    local last_pwd=$PWD

    local selected=( $( z | $(__fzfcmd) $FZF_Z_OPTIONS ) )
    if [ -n "$selected" ]; then
        local directory=$selected[2]
        if [ -n "$directory" ]; then
            cd $directory
            HOOK_LIKE_TOPLEVEL=1 hooks-run-hook chpwd_hook
        fi
    fi
    zle reset-prompt

    if [ $last_pwd != $PWD ]; then
        zle -M "cd'ed to '$PWD'"
    fi
}
zle -N zwidget::fzf::z
