{
  writeShellScript,
  lib,
  replaceBinsInPkg,

  ncurses,
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

    # suggestions nav (short movement)
    alt-j = "down"; alt-k     = "up";
    # suggestions nav (long movement)
    ctrl-alt-j = "next-selected"; ctrl-alt-k = "prev-selected";
    alt-g = "first"; alt-G = "last";
    alt-J = "half-page-down"; alt-K = "half-page-up";
    alt-z = "jump"; # easymotion-like 1/2-keystroke movement!

    # selection
    enter  = "accept-non-empty"; # FIXME: does not seem to work (@ v0.35.1: works same as 'accept')
    ctrl-j = "accept-non-empty"; # FIXME: does not seem to work (@ v0.35.1: works same as 'accept')
    alt-a     = "toggle+down";
    alt-space = "toggle+down";
    ctrl-a = "toggle-all";
    ctrl-c = "clear-selection"; # `ctrl-q` & `esc` can still quit!

    # preview nav
    alt-p = "toggle-preview";
    pgup       = "preview-page-up"; pgdn       = "preview-page-down";
    ctrl-alt-p = "preview-page-up"; ctrl-alt-n = "preview-page-down";

    # history
    ctrl-n = "next-history"; ctrl-p = "prev-history";

    # Ensure I can't double-click on a result to confirm-select it
    double-click = "ignore";
  };

  # Better highlights (current line, substring matches, multiline markers)
  colors = {
    "bg+" = "237"; # bg of current line
    "hl+" = "202"; # matching substring in current line (fg)
    "hl"  = "166"; # matching substring on all lines (fg)
    "gutter" = "-1"; # bg color for left gutter : use default terminal bg
    "marker" = "220:bold"; # current line marker in the gutter
    "preview-bg" = "233"; # bg of preview window
  };
  colorsArg = lib.concatStringsSep ","
    (lib.mapAttrsToList (hl: color: "${hl}:${color}") colors);

  layoutArgs = [
    "--reverse" # prompt at the top
    "--info=inline" # put info on right of prompt
    "--color='${colorsArg}'"
    "--scrollbar=▌▐"
    "--preview-window=border-bold"
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
  meta.mainProgram = "fzf";
  bins = {
    fzf = writeShellScript "fzf" ''
      TERMINAL_HEIGHT=$(${ncurses}/bin/tput lines)
      if (( TERMINAL_HEIGHT <= 30 )); then
        SMART_HEIGHT=90%
      else
        SMART_HEIGHT=20
      fi
      exec ${fzf}/bin/fzf ${toString keybindingsArgs} --height=$SMART_HEIGHT ${toString layoutArgs} "$@"
    '';
  };
}
