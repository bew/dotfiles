{ pkgsChannels, ... }:

let
  inherit (pkgsChannels) stable bleedingedge myPkgs;
in {
  imports = [
    # Setup minimal bash config to proxy to zsh when SHLVL==1 and interactive
    ../../bash_minimal/proxy_to_zsh.home-module.nix

    ./cli-core.nix
    ./cli/android-tools.nix
    ./cli/nix-tools.nix
    ./cli-tech-python-simple.nix
  ];

  home.packages = [

    # try some nu!
    bleedingedge.nushell

    bleedingedge.ouch # ~universal {,de}compression utility
    # NOTE: decompressing to a specific folder with `--dir` creates a subfolder if the archive
    #   contains multiple files.. (can be annoying if I know what I'm doing)
    #   Existing issue: https://github.com/ouch-org/ouch/issues/322

    stable.jless # less for JSON
    stable.xsv # Fast toolkit to slice through CSV files (kinda sql-like)

    # Extra - system (?)
    stable.cpulimit # Limit CPU usage, especially useful for CPU-intensive tasks
    stable.libtree # a better & more secure `ldd` (see: 20240331T1410)
    stable.strace

    # Extra - one-of
    stable.pastel # generate, analyze, convert & manipulate RGB colors
    stable.moreutils # for ts, and other nice tools https://joeyh.name/code/moreutils/
    stable.gron # to have grep-able json <3
    stable.diffoscopeMinimal # In-depth comparison of files, archives, and directories.

    stable.translate-shell

    # Extra - terminal fun
    stable.asciiquarium # nice ASCII aquarium 'screen saver'
    stable.chafa # crazy cool img/gif terminal viewer
    # Best alias: chafa -c 256 --fg-only (--size 70x70) --symbols braille YOUR_GIF

    # Extra - media stuff
    bleedingedge.yt-dlp # youtube-dl FTW!!
    stable.ffmpeg # (transcode all-the-things!)

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
