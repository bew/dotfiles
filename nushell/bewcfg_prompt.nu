const home = $nu.home-path
const named_paths = [
  { name: "~dot"    dir: ($home + /projects/dotfiles) }
  { name: "~tmp"    dir: /tmp }
  { name: "~"       dir: $home }
]

def shorten_path [path: string] {
  for $repl in $named_paths {
    if ($path | str starts-with $repl.dir) {
      return ($path | str replace $repl.dir $repl.name)
    }
  }
  $path
}

def color_surround [color: any text: closure] {
  [(ansi $color) (do $text) (ansi reset)] | str join
}

def maybe_space [where: string text: closure] -> string {
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

def "segment path" [] {
  let style = {
    path: ((ansi reset) + (ansi attr_bold) + (ansi darkorange))
    sep: ((ansi reset) + (ansi red3b))
    special: ((ansi reset) + (ansi orangered1))
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

def "segment exit_code" [] {
  if $env.LAST_EXIT_CODE == 0 {
    return ""
  }
  color_surround red_bold { $env.LAST_EXIT_CODE }
}

def exits_successfully [cmd: closure] -> bool {
  # NOTE: `complete` eats up all input & errors
  (do $cmd | complete | get exit_code) == 0
}

def "segment git-status-slow" [] {
  # FIXME: The fast version would use nushell_plugin_gstat
  #   https://github.com/nushell/nushell/tree/main/crates/nu_plugin_gstat
  #   (should be in nixpkgs already)

  # FIXME: Find a way to disable the segment if it's really slow
  #   (-> How to expose 'settings' to the runtime?)
  if (not (exits_successfully { ^git rev-parse --is-inside-work-tree })) {
    return
  }

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
    ^git status --porcelain=v2 --branch --show-stash | lines | each {|line|
      # process here!
      null
    }
    $status
  }
  "git: TODO"
}

# -------------------------------------------------------------

def create_left_prompt [] {
  let segments = [
    (
      # to differenciate my nu prompt vs zsh prompt
      color_surround {fg: white attr: b} {"NU "}
    )
    (maybe_space after { segment exit_code })
    (segment path)
  ]
  $segments | str join
}

def create_right_prompt [] {
  let segments = [
    (segment git-status-slow)
  ]
  $segments | str join
}

export-env {
  $env.PROMPT_COMMAND = { create_left_prompt }
  $env.PROMPT_COMMAND_RIGHT = { create_right_prompt }

  # The prompt indicators are environmental variables that represent
  # the state of the prompt
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
}
