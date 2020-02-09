# ----------------------------------------------
# Completion - setup

# Import color helpers
autoload -U colors && colors

fpath=(~/.zsh/completions/ $fpath)
fpath+=(~/.zsh/completions/nix-completions)

# Initialize the completion system
autoload -U compinit && compinit
zmodload zsh/complist

# Activate interactive menu completion
zstyle ':completion:*' menu select

# Directories first when completing files
zstyle ':completion:*' list-dirs-first on

# Force a reload of completion system if nothing matched; this fixes installing
# a program and then trying to tab-complete its name.
function _compl_force_rehash
{
  # rehash only when trying to complete a command name
  if (( CURRENT == 1 )); then
    rehash
  fi

  return 1 # Because we didn't really complete anything
}
# Completers to use: rehash, general completion, then various magic stuff and
# spell-checking.  Only allow two errors when correcting.
# (NOTE: left out _correct & _approximate)
zstyle ':completion:*' completer _compl_force_rehash _complete _ignored _match _prefix

# Case insensitive tab-completion <3
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Formatting and messages
# http://www.masterzen.fr/2009/04/19/in-love-with-zsh-part-one/
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format "$fg[yellow]%B--- %d%b"
zstyle ':completion:*:messages' format "$fg[cyan]%B-> %d%b"
zstyle ':completion:*:warnings' format "$fg[red]No matches for:$reset_color %d"
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'

# Separate matches into groups by tag
zstyle ':completion:*' group-name ''

# sections for man completion
zstyle ':completion:*:manuals'    separate-sections true
zstyle ':completion:*:manuals.*'  insert-sections   true
zstyle ':completion:*:man:*'      menu yes select

# cd/rm/vim will never select the parent directory (e.g.: cd ../<TAB>)
zstyle ':completion:*:(cd|nvim):*' ignore-parents parent pwd

# Color completion for some things.
zstyle ':completion:*' list-colors yes
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:original' list-colors "=*=$color[red];$color[bold]"
zstyle ':completion:*:commands' list-colors "=*=$color[green];$color[bold]"
zstyle ':completion:*:builtins' list-colors "=*=$color[cyan];$color[bold]"
zstyle ':completion:*:functions' list-colors "=*=$color[cyan]"
zstyle ':completion:*:parameters' list-colors "=*=$color[red]"
zstyle ':completion:*:aliases' list-colors "=*=$color[cyan];$color[bold]"
zstyle ':completion:*:reserved-words' list-colors "=*=$color[magenta]"
zstyle ':completion:*:options' list-colors "=^(-- *)=$color[green]"

# Pretty 'kill' completion
zstyle ':completion:*:*:kill:*' list-colors '=(#b) #([0-9]#)*( *[a-z])*=34=31=33'

# Ignore some files when completing a text editor command (TODO: add more)
zstyle ":completion:*:*:${EDITOR}:*:*files" ignored-patterns '*.pdf|*.o'

# Provide a fallback completer which always completes files. Useful when Zsh's
# completion is too "smart". Thanks to Frank Terbeck <ft@bewatermyfriend.org>
# (http://www.zsh.org/mla/users/2009/msg01038.html).
zle -C complete-files complete-word _generic
zstyle ':completion:complete-files:*' completer _files
bindkey '^F' complete-files
