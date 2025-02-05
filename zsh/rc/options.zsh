# do not beep !!!!
setopt NO_beep

# Allow comment (with '#') in zsh interactive mode
setopt interactive_comments

# Allow substitution in the prompt
setopt prompt_subst

# Accept args with ? or * in them and leave them unchanged, without erroring
# (because filename generation returns no match).
# This also applies to file expansion of an initial ‘~’ or ‘=’.
# E.g: `echo foo?bar` prints `foo?bar` or `echo ~foobar` prints `~foobar`.
setopt NO_nomatch

# Make ** an abbreviation of **/* and *** an abbreviation of ***/*
# (note: the *** variant follows symlinks)
setopt glob_star_short

# History options
#-------------------------------------------------------------

# Set the history file, shared between all zsh instances
if [[ -n "$ZSH_STATE_DIR_SHARED" ]]; then
  HISTFILE=$ZSH_STATE_DIR_SHARED/shell_history
else
  # History is important!
  # If there is no shared data dir set, make sure I'm aware of the problem and the consequences
  >&2 echo "/!\\ WARNING /!\\: Something is wrong, \$ZSH_STATE_DIR_SHARED is not set 👀"
  >&2 echo "-> History will not persist unless you set \$HISTFILE manually"
fi

# Lines of history to keep in memory
HISTSIZE=10000

# Lines to keep in the history file
SAVEHIST=1000000

# ignore history duplications
setopt hist_ignore_dups

# Even if there are commands inbetween commands that are the same, still only save the last one
setopt hist_ignore_all_dups

# Ignore commands with a space before
setopt hist_ignore_space

# When searching history don't display results already cycled through twice
setopt hist_find_no_dups

# Remove extra blanks from each command line being added to history
setopt hist_reduce_blanks

# Remove duplicated history entries on history save (usually at end of shell session)
setopt hist_save_no_dups

# Disable shared history between shells
#
# For some reason this is enabled by default with nix-darwin
# SEE: https://github.com/LnL7/nix-darwin/issues/983
setopt NO_sharehistory

# OTHERS
#-------------------------------------------------------------

# Send a CONT signal to processes when they are explicitely `disown`ed from the shell
setopt auto_continue

# Report the status of background jobs immediately, rather than waiting until just before printing a prompt
setopt notify

# List jobs in the long format
setopt long_list_jobs

# Don't kill background jobs on shell exit
setopt check_jobs
setopt check_running_jobs
setopt hup # Send SIGHUP to signal if we force exit

# Allow functions to have local options
setopt local_options

# Allow functions to have local traps
setopt local_traps
