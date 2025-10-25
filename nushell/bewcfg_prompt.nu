const home = $nu.home-path
const named_paths = [
  { name: "~dot"    dir: ($home + /projects/dotfiles) }
  { name: "~tmp"    dir: /tmp }
  { name: "~"       dir: $home }
]

def shorten_path [path: string]: nothing -> string {
  for $repl in $named_paths {
    if ($path | str starts-with $repl.dir) {
      return ($path | str replace $repl.dir $repl.name)
    }
  }
  $path
}

def color_surround [color: any text: closure]: nothing -> string {
  [(ansi $color) (do $text) (ansi reset)] | str join
}

# IDEA: alt call signature:
#   maybe_space __space__ { something }   # maybe space before
#   maybe_space { something } __space__   # maybe space after
def maybe_space [where: string text: closure]: nothing -> string {
  if $where not-in [after before] {
    error make {
      msg: "$where must be one of: after, before"
      label: {
        text: "here"
        span: (metadata $where).span
      }
    }
  }
  let text = do $text
  if ($text | str stats | get chars) != 0 {
    if $where == "after" {
      $text + " "
    } else if $where == "before" {
      " " + $text
    }
  }
}

def "segment path" [--old-prompt]: nothing -> string {
  let style = if $old_prompt {
    {
      special: ((ansi reset) + (ansi attr_bold) + (ansi springgreen4))
      path: ((ansi reset) + (ansi turquoise4))
      sep: ((ansi reset) + (ansi darkseagreen4b))
    }
  } else {
    {
      special: ((ansi reset) + (ansi attr_bold) + (ansi orangered1))
      path: ((ansi reset) + (ansi attr_bold) + (ansi darkorange))
      sep: ((ansi reset) + (ansi red1))
    }
  }
  let path = shorten_path $env.PWD
  let path_parts = $path | path split
  let path_start = $path_parts | first
  let path_rest = $path_parts | skip
  let sep_styled = $"($style.sep)(char path_sep)($style.path)"
  let path_start_styled = do {
    if ($path_start | str starts-with "~") {
      let maybe_sep = if ($path_rest | length) == 0 { "" } else { $sep_styled }
      $"($style.special)($path_start)($maybe_sep)"
    } else if $path_start == "/" {
      $"($style.sep)/" # start of absolute path
    } else {
      $"(style.path)($path_start)"
    }
  }
  $path_start_styled + ($path_rest | str join $sep_styled)
}

def "segment exit_code" []: nothing -> string {
  if $env.LAST_EXIT_CODE == 0 {
    return ""
  }
  color_surround red_bold { $env.LAST_EXIT_CODE }
}

def exits_successfully [cmd: closure]: nothing -> bool {
  # NOTE: `complete` eats up all input & errors
  (do $cmd | complete | get exit_code) == 0
}

def "segment git-status-slow" []: nothing -> string {
  # FIXME: A faster alternative would be to use nushell_plugin_gstat
  #   https://github.com/nushell/nushell/tree/main/crates/nu_plugin_gstat
  #   (it's in nixpkgs already)

  # FIXME: Find a way to disable the segment if it's really slow
  #   (-> How to expose 'settings' to the runtime?)
  if (not (exits_successfully { ^git rev-parse --is-inside-work-tree })) {
    return
  }

  # NOTE: can take inspiration from:
  # https://github.com/nushell/nu_scripts/blob/91b6a2b2280123ed5789f5c0870b9de22c722fb3/modules/git/git-v2.nu#L449-L542

  let status = do {
    mut status = {
      branch.oid: null
      branch.head: null
      branch.upstream: null
      branch.local_ahead: null
      branch.local_behind: null
      staged.any: null
      unstaged.any: null
      untracked.any: null
    }
    ^git status --porcelain=v2 --branch --show-stash | lines | each { |line|
      # process here!
      null
    }
    $status
  }
  "git: TODO"
}

def "segment shell_level" []: nothing -> string {
  let lvl = $env.SHLVL
  if $lvl == 0 {
    return ""
  }
  color_surround {fg: white attr: b} {$"L($lvl)"}
}

def "segment jobs" []: nothing -> string {
  let frozen_jobs = job list | where type == frozen
  if ($frozen_jobs | is-empty) {
    return ""
  }
  color_surround {fg: gold3b attr: b} {$"J($frozen_jobs | length)"}
}

# -------------------------------------------------------------

def create_current_left_prompt []: nothing -> string {
  let segments = [
    (
      # to differenciate my nu prompt vs zsh prompt
      color_surround {fg: white attr: b} {"NU "}
    )
    (maybe_space after { segment shell_level })
    (maybe_space after { segment jobs })
    (maybe_space after { segment exit_code })
    (segment path)
  ]
  $segments | str join
}

def create_current_right_prompt []: nothing -> string {
  let segments = [
    (segment git-status-slow)
  ]
  $segments | str join
}

def create_old_left_prompt []: nothing -> string {
  let segments = [
    (
      # to differenciate my nu prompt vs zsh prompt
      color_surround {fg: grey58 attr: b} {"NU "}
    )
    (maybe_space after { segment exit_code })
    (segment path --old-prompt)
  ]
  $segments | str join
}

def create_old_right_prompt []: nothing -> string {
  create_current_right_prompt
}

export-env {
  $env.PROMPT_COMMAND = { create_current_left_prompt }
  $env.PROMPT_COMMAND_RIGHT = { create_current_right_prompt }

  $env.IN_TRANSIENT_PROMPT = false
  $env.TRANSIENT_PROMPT_COMMAND = {
    $env.IN_TRANSIENT_PROMPT = true
    let ret = create_old_left_prompt
    $env.IN_TRANSIENT_PROMPT = false
    $ret
  }
  $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {
    $env.IN_TRANSIENT_PROMPT = true
    let ret = create_old_right_prompt
    $env.IN_TRANSIENT_PROMPT = false
    $ret
  }

  # The prompt indicators are environmental variables that represent
  # the state of the prompt
  # -- Current prompt
  $env.PROMPT_INDICATOR = { " > " }
  $env.PROMPT_INDICATOR_VI_INSERT = {
    $" (color_surround {fg: green3a attr: b} {"I"})> "
  }
  $env.PROMPT_INDICATOR_VI_NORMAL = {
    $" (color_surround {fg: blue attr: b} {"N"})> "
  }
  $env.PROMPT_MULTILINE_INDICATOR = {||
    $"(color_surround {fg: grey39} {":::"}) "
  }

  # -- Past prompts
  $env.TRANSIENT_PROMPT_INDICATOR = {
    $" (color_surround {fg: grey46 attr: b} {"%"}) "
  }
  $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = $env.TRANSIENT_PROMPT_INDICATOR
  $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = $env.TRANSIENT_PROMPT_INDICATOR
  $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = $env.PROMPT_MULTILINE_INDICATOR
}
