{ config, pkgsChannels, lib, mybuilders, flakeInputs, system, ... }:

let
  inherit (pkgsChannels) stable bleedingedge myPkgs;

  neovim-pseudo-flake = stable.callPackage ./../../nvim-wip/cli-package.nix {
    inherit (bleedingedge) neovim;
    inherit mybuilders;
  };

  # NOTE: tentative at a global list of cli tools, referenced in other tools as needed..
  cliPkgs = {
    fzf = myPkgs.fzf-bew;
  };

  zshHomeModule = let
    zdotdir = (myPkgs.zsh-bew-zdotdir.override {
      inherit (cliPkgs) fzf; # make sure to use my fzf config with specific fzf version
    });
  in {
    imports = [
      # Setup minimal bash config to proxy to zsh when SHLVL==1 and interactive
      ../../bash_minimal/proxy_to_zsh.home-module.nix
    ];
    # This module installs my config in ~, using usual config files discovery of zsh in home
    # (`~/.zshrc` & `~/.zshenv`).
    # => Every config change still require a home rebuild & activation, but it's less hardcoded
    # than if the package itself had an internal reference to a specific zdotdir,
    # which would make reloading shell config (to use new one) from existing shells impossible.
    home.packages = [ stable.zsh ];
    home.file.".zshrc".text = ''
      ZDOTDIR=${zdotdir}
      source ${zdotdir}/.zshrc
    '';
    home.file.".zshenv".text = ''
      source ${zdotdir}/.zshenv
    '';
    # FIXME: Add `.zlogin` ?
  };

in {
  imports = [
    zshHomeModule
    neovim-pseudo-flake.homeConfig.nvim-base-bins
    neovim-pseudo-flake.homeConfig.nvim-bew
  ];

  home.packages = [
    stable.tmux
    cliPkgs.fzf

    bleedingedge.eza # alternative ls, more colors!
    stable.bat
    stable.fd
    stable.git
    stable.git-lfs
    stable.gh  # github cli for view & operations
    bleedingedge.delta # for nice git diffs
    stable.jq
    stable.yq
    stable.ripgrep
    stable.tree
    stable.just
    (stable.ranger.override { imagePreviewSupport = false; })

    stable.less

    stable.ncdu
    stable.htop

    # network tools
    (mybuilders.linkBins "dogdns-as-dig" { dig = "${stable.dogdns}/bin/dog"; }) # nicer `dig`
    stable.netcat-openbsd # for `nc`

    stable.jless # less for JSON
    stable.xsv # Fast toolkit to slice through CSV files (kinda sql-like)

    stable.ansifilter # Convert text with ANSI seqs to other formats (e.g: remove them)
    stable.cloc
    stable.httpie
    stable.strace
    stable.entr
    stable.tokei

    stable.units # gnu's unit converter, has MANY units (https://www.gnu.org/software/units/)
    # Best alias: units -1 --compact FROM-UNIT TO-UNIT

    stable.moreutils # for ts, and other nice tools https://joeyh.name/code/moreutils/
    stable.gron # to have grep-able json <3
    stable.diffoscopeMinimal # In-depth comparison of files, archives, and directories.

    stable.chafa # crazy cool img/gif terminal viewer
    # Best alias: chafa -c 256 --fg-only (--size 70x70) --symbols braille YOUR_GIF
    stable.translate-shell
    stable.asciiquarium # nice ASCII aquarium 'screen saver'
    bleedingedge.yt-dlp # youtube-dl FTW!!

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
