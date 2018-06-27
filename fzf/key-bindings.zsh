# Key bindings
# ------------
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

function __fzfcmd
{
	echo "fzf ${FZF_BEW_LAYOUT} ${FZF_BEW_KEYBINDINGS}"
}

function zwidget::fzf::find_file
{
	local completion_prefix=${LBUFFER/* /}
	local lbuffer_without_completion_prefix="${LBUFFER%${completion_prefix}}"

    local base_dir=${completion_prefix:-./}
    base_dir=${~base_dir} # expand ~ (at least)

    local finder_cmd=(fd --type f --type l)
    local fzf_cmd=($(__fzfcmd) --multi --prompt "$base_dir")
    local cpl=$(cd ${base_dir}; "${finder_cmd[@]}" | "${fzf_cmd[@]}" | __results_to_path_args "$base_dir")
    local selected_completions=$cpl

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

    local base_dir=${completion_prefix:-./}
    base_dir=${~base_dir} # expand ~ (at least)

    local finder_cmd=(fd --type d)
    local fzf_cmd=($(__fzfcmd) --multi --prompt "$base_dir")
	local cpl=$(cd $base_dir; "${finder_cmd[@]}" | "${fzf_cmd[@]}" | __results_to_path_args "$base_dir")
    local selected_completions=$cpl

	if [ -n "$selected_completions" ]; then
		LBUFFER="${lbuffer_without_completion_prefix}${selected_completions}"
	fi
	zle reset-prompt
}
zle -N zwidget::fzf::find_directory


FZF_HISTORY_OPTIONS=(--no-multi -n2..,.. --tiebreak=index)

function zwidget::fzf::history
{
    # -l  | list the commands
    # -r  | show in reverse order (=> most recent first)
    # 1   | start at command n° 1 (the oldest still in history)
    local history_cmd=(fc -lr 1)

    local fzf_cmd=($(__fzfcmd) $FZF_HISTORY_OPTIONS --query "${LBUFFER//$/\\$}")
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

# --nth 2..         | ignore first field (the popularity of the dir) when matching
FZF_Z_OPTIONS=(--tac --tiebreak=index --nth 2..)

function zwidget::fzf::z
{
    local last_pwd=$PWD

    local fzf_cmd=($(__fzfcmd) $FZF_Z_OPTIONS --prompt 'Fuzzy jump to: ')
    local selected=( $( z | "${fzf_cmd[@]}" ) )
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
