# Key bindings
# ------------
if [[ $- != *i* ]]; then
	return
fi

FIND_IGNORE_OPTIONS="\\( -path '*/\\.*' -o -fstype 'dev' -o -fstype 'proc' \\) -prune"

# CTRL-T - Paste the selected file path(s) into the command line
__fsel()
{
	if [ -n "$1" ]; then
		local base_dir="$1"
	else
		local base_dir='.'
	fi
	local cmd="${FZF_CTRL_T_COMMAND:-"command find -L '$base_dir' ${FIND_IGNORE_OPTIONS} \
		-o -type f -print \
		-o -type d -print \
		-o -type l -print 2> /dev/null | sed 1d"}"
	eval "$cmd" | $(__fzfcmd) -m | while read item; do
	echo -n "${(q)item} "
done
echo
}

__fzfcmd()
{
	[ ${FZF_TMUX:-1} -eq 1 ] && echo "fzf-tmux -d${FZF_TMUX_HEIGHT:-40%}" || echo "fzf"
}

fzf-file-widget()
{
	local completion_prefix="${LBUFFER/* /}"
	local lbuffer_without_completion_prefix="${LBUFFER%$completion_prefix}"
	local selected_completions="$(__fsel $completion_prefix)"
	if [ -n "$selected_completions" ]; then
		LBUFFER="${lbuffer_without_completion_prefix}${selected_completions}"
		zle redisplay
	fi
}
zle     -N   fzf-file-widget

# ALT-C - cd into the selected directory
fzf-cd-widget()
{
	local cmd="${FZF_ALT_C_COMMAND:-"command find -L . ${FIND_IGNORE_OPTIONS} \
		-o -type d -print 2> /dev/null | sed 1d | cut -b3-"}"
	cd "${$(eval "$cmd" | $(__fzfcmd) +m):-.}"
	zle reset-prompt
}
zle     -N    fzf-cd-widget

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
	zle redisplay
}
zle     -N   fzf-history-widget
