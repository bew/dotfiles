alias cddot = cd ~/.dot

alias cp = cp --verbose --interactive --progress
alias mv = mv --verbose --interactive
alias rm = rm --verbose --interactive-once
alias eza = eza --group-directories-first
alias tmux = tmux -u
alias rg = rg -n

# Use 'rename' binary by default, the nushell command only when needed
# NOTE: the order is important here!
alias nu-rename = rename
alias rename = ^rename -v

alias e = nvim
alias v = nvim -R

alias tx = tmux

alias g = git
alias gnp = git --no-pager
alias gdiff = git dd --no-index
alias gdiff-split = git dds --no-index

alias ll = eza -l
alias la = ll -a
alias l = la

alias ltre = eza -la --tree --git-ignore
alias lltre = eza -l --tree --git-ignore

alias tree = tree -C --dirsfirst -F -A
alias tre = tree

alias mkd = mkdir
def --env mkcd [path: path] {
  mkdir $path
  cd $path
}

alias todo = rg -i "todo|fixme" --colors=match:fg:yellow --colors=match:style:bold

# -f : full listing (show process name & args)
# --forest : Show a processes hierarchy
alias pss = ^ps -f --forest
