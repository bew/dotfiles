# Key bindings
# ------------
if [[ $- != *i* ]]; then
	return
fi

FIND_IGNORE_OPTIONS="\\( -path '*/\\.*' -o -fstype 'dev' -o -fstype 'proc' \\) -prune"

FIND_FILTER_ALL_FILES="-o -type f -print -o -type d -print"
FIND_FILTER_DIRS="-o -type d -print"

__fsel()
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
	eval "$cmd" | $(__fzfcmd) | while read item; do
		echo -n "${(q)item} "
	done
	echo
}

FZF_KEYBINDINGS=()

# input nav
FZF_KEYBINDINGS+=(--bind 'alt-h:backward-char' --bind 'alt-l:forward-char')
FZF_KEYBINDINGS+=(--bind 'alt-b:backward-word' --bind 'alt-w:forward-word')

# suggestions nav
FZF_KEYBINDINGS+=(--bind 'alt-j:down' --bind 'alt-k:up')
FZF_KEYBINDINGS+=(--bind 'tab:down' --bind 'shift-tab:up' --bind 'alt-g:jump')

FZF_KEYBINDINGS+=(--bind 'alt-a:toggle+down') # select
FZF_KEYBINDINGS+=(--bind 'change:top') # select best result on input change

FZF_OPTIONS=(--height=40% --multi --reverse --inline-info --border)

__fzfcmd()
{
	echo "fzf ${FZF_OPTIONS} ${FZF_KEYBINDINGS}"
}

fzf-file-widget()
{
	local completion_prefix="${LBUFFER/* /}"
	local lbuffer_without_completion_prefix="${LBUFFER%$completion_prefix}"

	local selected_completions="$(__fsel "$FIND_FILTER_ALL_FILES" "$completion_prefix")"

	if [ -n "$selected_completions" ]; then
		LBUFFER="${lbuffer_without_completion_prefix}${selected_completions}"
	fi
	zle reset-prompt
}
zle -N fzf-file-widget

fzf-directory-widget()
{
	local completion_prefix="${LBUFFER/* /}"
	local lbuffer_without_completion_prefix="${LBUFFER%$completion_prefix}"

	local selected_completions="$(__fsel "$FIND_FILTER_DIRS" "$completion_prefix")"

	if [ -n "$selected_completions" ]; then
		LBUFFER="${lbuffer_without_completion_prefix}${selected_completions}"
	fi
	zle reset-prompt
}
zle -N fzf-directory-widget

# CTRL-R - Paste the selected command from history into the command line
fzf-history-widget()
{
	local selected num
	selected=( $(fc -l 1 | $(__fzfcmd) +s +m -n2..,.. --tiebreak=index --toggle-sort=ctrl-r ${=FZF_CTRL_R_OPTS} -q "${LBUFFER//$/\\$}") )
	if [ -n "$selected" ]; then
		num=$selected[1]
		if [ -n "$num" ]; then
			zle vi-fetch-history -n $num
		fi
	fi
	zle reset-prompt
}
zle -N fzf-history-widget
