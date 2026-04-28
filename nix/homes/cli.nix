{ pkgsChannels, ... }:

let
  inherit (pkgsChannels) stable bleedingedge myPkgs;
in {
  imports = [
    # Setup minimal bash config to proxy to zsh when SHLVL==1 and interactive
    ../../bash_minimal/proxy_to_zsh.home-module.nix

    ./cli-core.nix
    ./cli/nix-recent.nix
    ./cli/nix-tools.nix
    ./cli-tech-python-simple.nix
  ];

  home.packages = [

    stable.nushell
    stable.bats # Cool bash testing system

    # AI
    bleedingedge.opencode # ✨ 🤔

    # Extra - system (?)
    stable.cpulimit # Limit CPU usage, especially useful for CPU-intensive tasks
    stable.libtree # a better & more secure `ldd` (see: 20240331T1410)
    stable.strace

    # Extra - one-of
    stable.ouch # ~universal {,de}compression utility
    stable.jless # less for JSON
    stable.pastel # generate, analyze, convert & manipulate RGB colors
    stable.moreutils # for ts, and other nice tools https://joeyh.name/code/moreutils/
    stable.translate-shell # cli for text translation & definition (via GTranslate)

    # Extra - terminal fun
    stable.asciiquarium # nice ASCII aquarium 'screen saver'
    bleedingedge.lavat # nice lavalamp
    (stable.writeShellScriptBin "lavat-fancy" ''
      ${bleedingedge.lavat}/bin/lavat -g -b 15 -r 1 -k f2902e -c 3a2919
    '')
    stable.chafa # crazy cool img/gif terminal viewer
    # Best alias: chafa -c 256 --fg-only (--size 70x70) --symbols braille YOUR_GIF

    # Extra - media stuff
    stable.ffmpeg # (transcode all-the-things!)
    # @2026-04 `yt-dlp` now requires `deno`, which takes ~forever to build its `rusty-v8` dep...
    # Let's only manage its install via `nix profile install` for now 🤔
    # bleedingedge.yt-dlp # youtube-dl FTW!!

    # Languages
    # NOTE: Compilers, interpreter shouldn't really be made available in a global way..
    #       Goes a bit against Nix-motto to have well defined dependencies, per-projects.
    # => Could still be nice-to-have for one-of tests/experiments...
    #    * Could make these available through a custom shell I need to launch?
    #      (or a kind of shell module to enable)
    #      With an explicit name like `shell-with-languages-for-ad-hoc-experimenting`
    #      (FIXME: need a shorter name...)
    # FIXME: where to put this comment???
  ];
}
