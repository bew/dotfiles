export alias cddot = cd ~/.dot

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

# Without args: close the current sudo session if any.
# With args: run args _then_ close current sudo session.
#
# NOTE: `def --wrapped` is used to make sure all args are passed as strings
#   (avoiding the default auto-handling of `-h` & `--help`)
#
# FIXME: How to define the completion for `nosudo` as the same as for `sudo` ?
export def --wrapped nosudo [...args] {
  if ($args | length) == 0 {
    sudo -k # Close the current sudo session if any
  } else {
    sudo $args
    let exit_code = $env.LAST_EXIT_CODE
    sudo -k # Close the current sudo session
    # FIXME: how to forward the $exit_code to the outside world?
  }
}
