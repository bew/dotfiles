{ config, pkgsChannels, lib, mybuilders, flakeInputs, pkgs, myHomeModules, ... }:

let
  inherit (pkgsChannels) stable bleedingedge myPkgs;

  neovim-pseudo-flake = stable.callPackage ./../../nvim-wip/cli-package.nix {
    inherit (bleedingedge) neovim;
    inherit mybuilders;
  };

  # NOTE: tentative at a global list of cli tools, referenced in other tools as needed..
  #
  # TODO: need to make a proper module, potentially at higher level than the home config?..
  #   (see comment above mkHomeModule in </zsh/tool-package.nix> for thoughts on bins deps propagation..)
  cliPkgs = {
    fzf = myPkgs.fzf-bew;
  };

in {
  imports = [
    myHomeModules.zsh-bew
    # Setup minimal bash config to proxy to zsh when SHLVL==1 and interactive
    ../../bash_minimal/proxy_to_zsh.home-module.nix

    neovim-pseudo-flake.homeModules.nvim-base-bins
    neovim-pseudo-flake.homeModules.nvim-bew
  ];

  home.packages = [
    stable.tmux

    bleedingedge.eza # alternative ls, more colors!
    cliPkgs.fzf
    stable.bat
    stable.fd
    (pkgs.buildEnv {
      name = "git-bew-env";
      paths = [
        stable.git
        # config tools
        bleedingedge.delta # for nice git diffs
        stable.onefetch # repo global info
        # extra commands
        stable.git-lfs # store specific (large) files out-of-repo
        stable.git-trim # auto delete merged branches
        stable.git-absorb # automatic `git commit --fixup` on relevant commits
        # other tools
        stable.gh # github cli for view & operations
      ];
      meta.mainProgram = "git";
    })
    stable.jq
    stable.yq
    stable.ripgrep
    stable.tree
    stable.just
    (stable.ranger.override { imagePreviewSupport = false; })
    stable.pueue # interactive cli process 'scheduler' & manager

    stable.less

    stable.ncdu
    stable.htop

    # try some nu!
    bleedingedge.nushell

    # network tools
    (mybuilders.linkBins "dogdns-as-dig" { dig = "${stable.dogdns}/bin/dog"; }) # nicer `dig`
    stable.netcat-openbsd # for `nc`

    stable.jless # less for JSON
    stable.xsv # Fast toolkit to slice through CSV files (kinda sql-like)

    stable.ansifilter # Convert text with ANSI seqs to other formats (e.g: remove them)
    stable.xh # httpie but fasterrr
    stable.entr
    stable.tokei

    stable.units # gnu's unit converter, has MANY units (https://www.gnu.org/software/units/)
    # Best alias: units -1 --compact FROM-UNIT TO-UNIT

    bleedingedge.ouch # ~universal {,de}compression utility
    # NOTE: decompressing to a specific folder with `--dir` creates a subfolder if the archive
    #   contains multiple files.. (can be annoying if I know what I'm doing)
    #   Existing issue: https://github.com/ouch-org/ouch/issues/322

    stable.dupeguru # Nice cross-platform duplicate finder

    stable.strace

    stable.moreutils # for ts, and other nice tools https://joeyh.name/code/moreutils/
    stable.gron # to have grep-able json <3
    stable.diffoscopeMinimal # In-depth comparison of files, archives, and directories.

    stable.chafa # crazy cool img/gif terminal viewer
    # Best alias: chafa -c 256 --fg-only (--size 70x70) --symbols braille YOUR_GIF
    stable.translate-shell
    stable.asciiquarium # nice ASCII aquarium 'screen saver'
    bleedingedge.yt-dlp # youtube-dl FTW!!
    stable.ffmpeg # (transcode all-the-things!)
    # FIXME(?): Would be nice to be able to use the same ffmpeg pkg as used for mpv

    # Languages
    # NOTE: Compilers, interpreter shouldn't really be made available in a global way..
    #       Goes a bit against Nix-motto to have well defined dependencies, per-projects.
    # => Could still be nice-to-have for one-of tests/experiments...
    #    * Could make these available through a custom shell I need to launch?
    #      (or a kind of shell module to enable)
    #      With an explicit name like `shell-with-languages-for-ad-hoc-experimenting`
    #      (FIXME: need a shorter name...)
    stable.python3
    (let
      ipythonEnv = pyPkg: pyPkg.withPackages (pypkgs: [
        pypkgs.ipython
        # Rich extension is used for nicer UI elements
        # See: https://rich.readthedocs.io/en/stable/introduction.html#ipython-extension
        pypkgs.rich
      ]);
    in mybuilders.linkSingleBin "${ipythonEnv stable.python3}/bin/ipython")

    (let androidPkgs = stable.androidenv.androidPkgs_9_0;
    in mybuilders.linkBins "android-tools-bins" [
      "${androidPkgs.platform-tools}/bin/adb"
      "${androidPkgs.platform-tools}/bin/fastboot"
    ])

    # Nix tools
    (mybuilders.linkBins "some-nix-tools" {
      # TUI to browse the dependencies of a derivation (https://github.com/utdemir/nix-tree)
      nix-explore = "${lib.getExe stable.nix-tree}";
      # CLI to explain why 2 derivations differ (https://github.com/Gabriel439/nix-diff)
      nix-diff-drv = "${lib.getExe stable.nix-diff}";
    })
    stable.nixfmt # a Nix formatter (more at https://github.com/nix-community/nixpkgs-fmt#formatters)
    # stable.nix-update # Swiss-knife for updating nix packages
    # TODO: add nix-index!
  ];
}
