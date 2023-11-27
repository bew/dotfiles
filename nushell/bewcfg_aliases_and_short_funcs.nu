export alias cp = cp --verbose --interactive --progress
export alias mv = mv --verbose --interactive
export alias rm = rm --verbose --interactive-once
export alias eza = eza --group-directories-first
export alias tmux = tmux -u
export alias rg = rg -n

# Use 'rename' binary by default, the nushell command only when needed
# NOTE: the order is important here!
export alias nu-rename = rename
export alias rename = ^rename -v

export alias e = nvim
export alias v = nvim -R

export alias tx = tmux

export alias g = git
export alias gnp = git --no-pager
export alias gdiff = git dd --no-index
export alias gdiff-split = git dds --no-index

export alias ll = eza -l
export alias la = ll -a
export alias l = la

export alias ltre = eza -la --tree --git-ignore
export alias lltre = eza -l --tree --git-ignore

export alias tree = tree -C --dirsfirst -F -A
export alias tre = tree

export alias mkd = mkdir
export def --env mkcd [path: path] {
  mkdir $path
  cd $path
}

export alias todo = rg -i "todo|fixme" --colors=match:fg:yellow --colors=match:style:bold

# -f : full listing (show process name & args)
# --forest : Show a processes hierarchy
export alias pss = ^ps -f --forest

# FIXME: how to impl external command wrappers that can take N unknown params?
# (ex: to impl 'nosudo' helper)
