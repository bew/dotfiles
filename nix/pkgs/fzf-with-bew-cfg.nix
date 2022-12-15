{
  writeShellScript,
  lib,
  replaceBinsInPkg,

  fzf,
}:

let
  keybindings = {
    # meta
    change = "top"; # when changing filter text, select top most result

    # editor
    alt-h = "backward-char"; alt-l = "forward-char";
    alt-b = "backward-word"; alt-w = "forward-word";
    "alt-^" = "beginning-of-line"; "alt-$" = "end-of-line";

    # suggestions nav
    alt-j = "down"; alt-k     = "up";
    tab   = "down"; shift-tab = "down";

    # selection
    ctrl-j = "accept";
    alt-a     = "toggle+down";
    alt-space = "toggle+down";
    ctrl-a = "toggle-all";

    # preview nav
    alt-p = "toggle-preview";
    pgup   = "preview-page-up"; pgdn   = "preview-page-down";
    ctrl-p = "preview-page-up"; ctrl-n = "preview-page-down";
  };

  # Better highlights (current line, substring matches, multiline markers)
  colors = {
    "bg+" = "237"; # bg of current line
    "hl+" = "202"; # matching substring in current line (fg)
    "hl"  = "166"; # matching substring on all lines (fg)
    "gutter" = "-1"; # bg color for left gutter : use default terminal bg
    "marker" = "220:bold"; # current line marker in the gutter
  };
  colorsArg = lib.concatStringsSep ","
    (lib.mapAttrsToList (hl: color: "${hl}:${color}") colors);

  layoutArgs = [
    "--height=40%"
    "--reverse" # prompt at the top
    "--inline-info" # include info on right of prompt
    "--color='${colorsArg}'"
  ];

  keybindingsArgs = lib.flatten (
    lib.mapAttrsToList
      (key: bind: ["--bind" "${key}:${bind}"])
      keybindings
  );
in

replaceBinsInPkg {
  name = "fzf-bew";
  copyFromPkg = fzf;
  bins = {
    fzf = writeShellScript "fzf" ''
      exec ${fzf}/bin/fzf ${toString keybindingsArgs} ${toString layoutArgs} "$@"
    '';
  };
}
