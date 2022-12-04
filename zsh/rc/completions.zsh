# ----------------------------------------------
# Completion - setup
#
# NOTE: While configuring zsh completions with ~advanced features like the auto-interactive mode,
#       it seems like I've hit a few bugs, and have now a few features requests :)
#
#       See this Zsh FAQ for info on how to report bugs, request features:
#       https://zsh.sourceforge.io/FAQ/zshfaq06.html
#
#       I recently (2021-11) subscribed to the zsh-announce@zsh.org mailing list :)
#
# NOTE: The docs for the completion system is in man zshcompsys.

fpath=(~/.zsh/completions/ $fpath)
# Add system completions if available
# (allows to have 'pacman' completions in nix's zsh for example)
[[ -d /usr/share/zsh/functions ]] && fpath+=(/usr/share/zsh/functions/*)
[[ -d /usr/share/zsh/site-functions ]] && fpath+=(/usr/share/zsh/site-functions)
# Add completions from Nix is available
[[ -d ~/.nix-profile/share/zsh/site-functions ]] && fpath+=(~/.nix-profile/share/zsh/site-functions)
[[ -d /run/current-system/sw/share/zsh/site-functions ]] && fpath+=(/run/current-system/sw/share/zsh/site-functions)

setopt NO_auto_remove_slash # Don't remove slash for accepted directory compl
setopt complete_in_word # Enable compl in the middle of a word
setopt always_to_end # After a successfull middle word compl, move cursor at end of word
setopt list_packed # Smaller compl list by 'packing' matches in columns

# Initialize the completion system
autoload -U compinit && compinit
zmodload zsh/complist

# FIXME: completion inside text (with remaining input after cursor) is BROKEN,
#        it eats chars from the right..
#   mpv-audio-loop tra| --shuffle
#   ('|' is cursor, start menu completion (with interactive mode) then accept entry 'trance/')
# gives:
#   mpv-audio-loop trance/|huffle
#   (=> the entry is inserted, but chars after cursor are overwritten..)
#
# TOCHECK: does it work with a completely stripped down zsh config? (looks like not, read on..)
# -> I checked in an old shell (does not have my new completion cfg), and entering interactive mode
#    then exit out of interactive mode to the normal menu mode is ALSO broken.. (eats right chars)
#    (don't even need to accept the match)
# => This seems to be a bug in zsh with the interactive menu mode :/
# TODO (bug report): see above (about broken interactive mode when accepting match, when completion initiated in the middle of the BUFFER)

# zstyle's context format for the completion system is:
#
#   ':completion:function:completer:command:argument:tag'
#
# It is documented in man zshcompsys, section 'COMPLETION SYSTEM CONFIGURATION' in
# the 'Overview' subsection.

# Add few missing options completions (_gnu_generic parses and extracts options from 'cmd --help')
# (maybe move these somewhere else?)
function zcompl::extract_options_completion_from_cmd_help
{
  local program="$1"
  compdef _gnu_generic "$1"
  # Rename the option tag to say it comes from --help (for display in menu completion)
  local new_desc="option    [extracted from '$program --help']"
  # NOTE: We need '${(q)new_desc}' to ensure spaces are escaped like '\ ', because 'tag-order'
  #       accepts a (list of) space-separated list of tags.
  zstyle ':completion:*:*:'"$program"':options:*' tag-order "options:options:${(q)new_desc}"
  # (dev-note: context string found by debugging the used tags with '^Xh' binding)
  # (note: didn't find a way to do this in a generic way (to not have to repeat it for each cmd)
  #  for all option completions gathered from '_gnu_generic' :shrug:)
}
zcompl::extract_options_completion_from_cmd_help "fzf"

# Activate menu completion (in interactive mode!!)
zstyle ':completion:*' menu select #interactive
# NOTE: the menu is immediately shown because Tab is mapped to 'menu-complete' in ./mappings.zsh

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

# Completer functions to use: (tried in order until we have 1+ match(es))
# (NOTE: full docs in man zshcompsys)
# - _compl_force_rehash - refresh commands list if we're completing a command (see definition above)
# - _complete - try standard compl [meta-note: 'compl' stands for 'completion']
# - _match - retry compl by allowing some input-text coersions (see style 'matcher-list')
# - _prefix - retry compl with suffix ignored (everything after cursor)
#       (note: this is only useful if COMPLETE_IN_WORD option is set.)
# - _ignored - retry compl, without normally ignored matches (see style 'ignored-patterns')
# - _approximate - retry compl, allowing a certain number of errors (see style 'max-errors')
#       (similar to 'levenshtein distance' algo)
zstyle ':completion:*' completer _compl_force_rehash _complete _match _prefix _ignored _approximate

# Additional matcher specifications to try one after the other until we have 1+ match.
# (They will all by tried for all completers)
# 1. 'm:{[:lower:]}={[:upper:]}' -> Case insensitive (low -> up) completions
# 2. '+r:|[-_:./]=**' -> [1.] + Allow '-_:./' chars to act similar to glob patterns,
#    meaning that writing 'ni-h' then TAB would match 'nix-home' & 'nix-foo-home-bar'.
#    (note that writing 'ni-o' would not have worked in that example).
#    => It's _really_ powerful with `git ch TAB`, a 'kind' of structured fuzzy matcher!! <3
zstyle ':completion:*' matcher-list \
  'm:{[:lower:]}={[:upper:]}' \
  '+r:|[-_:./]=**'
# NOTE: Read 'matcher-list' doc in man 'zshcompsys' for details (not trivial).
# NOTE: Syntax of matcher specifications is documented in man 'zshcompwid', in the
#       section named 'COMPLETION MATCHING CONTROL'.
#
# FIXME: I have a problem, when in a subdir and ../README.md is modified,
#   doing 'git checkout ../rea' then TAB gives 'no match for...'  GRRR
#
# FIXME: I have a problem (that existed before my completion config changes),
#   for modified files (on `git checkout ...`) the matcher is tried AFTER normal compl,
#   instead of at the same time...
#   => If I have modified files 'config' and 'CONTRIBUTE', doing 'con' then  trigger completion
#      should show both! Instead it auto-completes 'config' only.. :/ :/ :/ :/ :/ :/

# Make completion stops at the first ambiguous component
zstyle ':completion:*' ambiguous true
zstyle ':completion:*' insert-unambiguous true

# In a dir with 'nix' and 'nix-home' directories, makes 'nix' match both, and 'nix/' match only 'nix'.
# Does _not_ block partial path completions like '/u/b/foo'.
zstyle ':completion:*' accept-exact-dirs true

# When corrections are needed/triggered, always give ability to select the original text
zstyle ':completion:*' original true

# Makes a particular prefix necessary (non-configurable) to show a set of matches:
# * for command options, need '-', '+' or '--' prefixes (the default)
# * for signal names, need '-' prefix (the default)
# * for job names, need '%' prefix (the default)
# * for function & param names, need '_' or '.' prefix if it starts with one of those (not the default)
zstyle ':completion:*' prefix-needed true

# When the _approximate completer is active, allow errors based on the size of the text
# NOTE: it is case-sensitive, even if you have a matcher-list cfg to make it insensitive
zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX + $#SUFFIX) / 3 )) )'


# -- Specific programs settings

# sections for man completion
zstyle ':completion:*:manuals'    separate-sections true
zstyle ':completion:*:manuals.*'  insert-sections   true

# cd/nvim will never select the parent directory (e.g.: cd ../<TAB>)
zstyle ':completion:*:(cd|nvim):*' ignore-parents parent pwd
# Enable options completion for `cd -`
# (I know I can just accept line without completing to go back to last cwd)
zstyle ':completion:*:(cd|chdir|pushd):*' complete-options true

# Ignore some files when completing a text editor command
zstyle ":completion:*:*:nvim:*:*files" ignored-patterns '*.pdf|*.o|*.lock'

# TODO: see what I can do with the `file-patterns` style (looks really cool!)

# NOTE (doc): The styles `tag-order` & `group-order` configures what kind of completions appear, and in which order.
# They differ by:
# * `tag-order` allows to specify which kinds of completions should appear at all,
#   or be removed, or which tags are tried before others, but do NOT control
#   the order of appearance of tags in a given completion menu.
#   (its value syntax is quite advanced, allows many things)
# * `group-order` only controls the order of appearance of tags.
#   Its value syntax is verry basic, only a space-separated list of tags to show
#   first (all unspecified tags, will appear after these).

# Complete named-directories first on `~TAB` (instead of users first)
zstyle ':completion:*:*:-tilde-:*' group-order \
  named-directories directory-stack users


# -- Formatting and messages (for the menu selection UI)
# Inspiration from: http://www.masterzen.fr/2009/04/19/in-love-with-zsh-part-one/

zstyle ':completion:*' verbose true
# format for the group names
zstyle ':completion:*:descriptions' format "%F{yellow}%B>>> %d %b%f"

# format for messages requested to be displayed by some compl funcs
zstyle ':completion:*:messages' format "%F{cyan}%B-> %d %b%f"
# format when no matches
zstyle ':completion:*:warnings' format "%F{red}!! No matches for:%f %d"
# format when corrections are in action
zstyle ':completion:*:corrections' format '%K{236}%B ~= %d (with %e errors) =~ %b%k'

# Bottom prompt when menu-select can be scrolled
# TODO (bug report): For some reason the bg color is reset after %b or %f, instead of %k,
#     so I have to re-enable the bg color with %K{..} in the middle of the string..
zstyle ':completion:*' select-prompt '%K{236} :: %F{33}match %B%m%b%f%K{236} (scroll at %p) :: %k'
# TODO (zsh feature request): have the ability to get the current completion group
#     in that prompt, as it's easy to forget when we're in a looonnng selection menu
#     (like for man pages).

# Separate matches into groups of their tag name
zstyle ':completion:*' group true
zstyle ':completion:*' group-name ''

# Describe options in full
zstyle ':completion:*:options' description true
zstyle ':completion:*:options' auto-description "specify: %d"

# Directories first when completing files
zstyle ':completion:*' list-dirs-first true

# Add `..` in completions when the current prefix is empty, is a single `.', or starts with `../'
# (from man zshcompsys, in the doc for 'special-dirs' style)
zstyle -e ':completion:*' special-dirs '[[ $PREFIX = (../)#(|.|..) ]] && reply=(..)'


# -- colorful completions! \o/

# Import color helpers for the special syntax of 'list-colors' style
autoload -U colors && colors
# my magenta is actually orange!
color[orange]="${color[magenta]}"
color[bg-orange]="${color[bg-magenta]}"
# TODO: have a 'color2' helper for the 256 color palette, like `${color2[166]}` `${color2[bg-166]}`
#   In 256 color palette: '48;5;XYZ' sets color XYZ as bg color, '38;5;XYZ' for fg.

zstyle ':completion:*' list-colors true

# Color the options but not their description
# (from: https://github.com/nakal/shell-setup/blob/89913cc2befb22e/shell/zsh/.zsh/completion.zsh#L23)
# note: first spec is for options with description, second spec is for options without description
zstyle ':completion:*:options'        list-colors \
  "=(#b)(-*) -- *=0=${color[green]}" \
  "=^(-- )*=${color[green]}"

zstyle ':completion:*:commands'       list-colors "=*=${color[green]}"
zstyle ':completion:*:functions'      list-colors "=*=${color[cyan]}"
zstyle ':completion:*:parameters'     list-colors "=*=${color[red]}"
zstyle ':completion:*:aliases'        list-colors "=*=${color[cyan]};${color[bold]}"
zstyle ':completion:*:builtins'       list-colors "=*=${color[orange]}"
zstyle ':completion:*:reserved-words' list-colors "=*=${color[black]};${color[bold]}"
zstyle ':completion:*:original'       list-colors "=*=${color[red]};${color[bold]}"

# For the default LS_COLORS, it is defined a bit later instead, where we also add elements
# to customize the colors of the completion menu.
# zstyle ':completion:*:default'        list-colors ${(s.:.)LS_COLORS}

# This example 'tries' to highlight the currently matching text for commands
# (taken from https://github.com/stevenspasbo/dotfiles/blob/6401cff4cd3/dotfiles/zsh-custom/config/completion.zsh#L81)
# BUT it's not perfect: (TODO (feature req?))
# - doesn't work when Backspace-ing in interactive menu mode..
# - or in isearch menu mode..
# - or with matcher-list matches (which are not necessarily at the beginning of the entry)
# NOTE: we need 'zstyle -e' with a 'reply=(..)' to have access to '$words' special completion var.
# zstyle -e ':completion:*:commands' list-colors 'reply=( "=(#b)($words[CURRENT]|)*='"${color[green]}=${color[green]};${color[underline]}"'" )'


# for kill program (example, to show capability)
zstyle ':completion:*:*:kill:*' list-colors '=(#b) #([0-9]#)*( *[a-z])*='"${color[red]}=${color[blue]}=${color[yellow]}"

zstyle ':completion:*:*:git*:*:commits*' list-colors "=(#b)(*) -- *=0=${color[cyan]}"

# for just's receipe (color args & description)
# format is `the-receipe -- Args: FOO # Receipe description`
zstyle ':completion:*:*:just:*:argument-1'  list-colors "=(#b)* (-- *) (\#*)=0=${color[blue]}=${color[green]}"


# Custom color for the menu completion (let's try!)
#
# --- From man zshmodules, in the `Colored completion listings` section (of zsh/complist module):
# > When printing a match, the code prints the value of `lc`, the value for the file-type or the
# > last matching specification with a `*', the value of `rc`, the string to display for the
# > match itself, and then the value of `ec` if that is defined or the values of `lc`, `no`,
# > and `rc` if `ec` is not defined.
# --- And a bit lower, in the `Menu selection` section:
# > In the list one match is highlighted using the value for `ma`. (The default value for this
# > is `7' which forces the selected match to be highlighted using standout mode)
#
# Interesting capabilities for menu entries (with their default value + description)
#    no 0     for normal text (i.e. when displaying something other than a matched file)
#    lc \e[   for the left code
#    rc m     for the right code
#    tc 0     for the character indicating the file type  printed after filenames if the LIST_TYPES option is set
#    sp 0     for the spaces printed after matches to align the next column
#    ec none  for the end code
#    ma 7     for the highlighted match   (<- we change this!)
#
zstyle ':completion:*' list-colors \
  ${(s.:.)LS_COLORS} \
  "ma=${color[bg-orange]};${color[white]};${color[bold]}"
  # TODO? use a slightly less bright white fg?
  # Alternative with a less bright bg orange, 130 (in 256 color palette):
  # "ma=48;5;130;${color[white]};${color[bold]}"


# -- Specialized completers

# Provide a fallback completer which always completes files. Useful when Zsh's
# completion is too "smart". Thanks to Frank Terbeck <ft@bewatermyfriend.org>
# (http://www.zsh.org/mla/users/2009/msg01038.html).
zle -C complete-files menu-complete _generic
zstyle ':completion:complete-files:*' completer _files _match
bindkey '^x^f' complete-files # Force complete file names
# bindkey '^f' complete-files # Force complete file names

# Complete words from history
zle -C complete-words-from-history menu-complete _generic
zstyle ':completion:complete-words-from-history:*' completer _history _match _approximate
zstyle ':completion:complete-words-from-history:*' remove-all-dups true
zstyle ':completion:complete-words-from-history:*' accept-exact false
bindkey '^x^h' complete-words-from-history # Force complete words from history

# Insert all completion matches (does not show the menu)
# (from 'zshcompsys' man page, around doc for '_all_matches')
zle -C insert-all-completion-matches complete-word _generic
bindkey '^x^a' insert-all-completion-matches
zstyle ':completion:insert-all-completion-matches:*' \
  completer _all_matches _complete _match
zstyle ':completion:insert-all-completion-matches:*' insert true

# Force expand current parameter ($foo, ~foo, foo*, ...)
zle -C expand-param-or-alias complete-word _generic
zstyle ':completion:expand-param-or-alias:*' completer _expand _expand_alias
zstyle ':completion:expand-param-or-alias:*' tag-order '!original' # remove original text in matches
bindkey '^xx'  expand-param-or-alias
bindkey '^x^x' expand-param-or-alias

# NOTE: more ^x builtin keys around completions:
# bindkey "^Xh" _complete_help      <<- Show internal info on completion system (tags)
# bindkey "^XC" _correct_filename
# bindkey "^Xa" _expand_alias       # superseeded by my expand-param-or-alias above
# bindkey "^Xc" _correct_word
# bindkey "^Xd" _list_expansions
# bindkey "^Xm" _most_recent_file
# bindkey "^X?" _complete_debug     (creates a debug trace of completers in a file)
