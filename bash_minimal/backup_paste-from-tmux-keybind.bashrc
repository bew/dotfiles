# Setup paste from tmux binding
# Inspired from https://stackoverflow.com/a/25201467/5655255
paste-from-tmux-clipboard()
{
  local buffer="$(cli-clipboard-provider paste-from tmux)"
  local new_text_length="${#buffer}"

  local before_text="${READLINE_LINE:0:$READLINE_POINT}"
  local after_text="${READLINE_LINE:$READLINE_POINT}"

  # insert clipboard content at cursor position
  READLINE_LINE="${before_text}${buffer}${after_text}"
  READLINE_POINT=$(( READLINE_POINT + new_text_length ))
}
# Alt-v
bind -x '"\ev" : paste-from-tmux-clipboard'

# vim:set ft=sh:
