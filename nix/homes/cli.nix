{ config, pkgsChannels, lib, mybuilders, flakeInputs, pkgs, myToolConfigs, ... }:

let
  inherit (pkgsChannels) stable bleedingedge myPkgs;

  # NOTE: tentative at a global list of cli tools, referenced in other tools as needed..
  #
  # TODO: need to make a proper module, potentially at higher level than the home config?..
  #   (see comment above homeModules.withDefaults in </zsh/tool-configs.nix> for thoughts on bins deps propagation..)
  cliPkgs = {
    fzf = myPkgs.fzf-bew;
  };

in {
  imports = [
    # Setup minimal bash config to proxy to zsh when SHLVL==1 and interactive
    ../../bash_minimal/proxy_to_zsh.home-module.nix

    myToolConfigs.zsh-bew.outputs.homeModules.withDefaults

    ./cli/neovim.nix
    ./cli/direnv.nix
  ];

  home.packages = [
    stable.tmux

    # alternative ls, more colors!
    (bleedingedge.eza.overrideAttrs (final: prev: {
      patches = prev.patches ++ [
        (pkgs.fetchpatch {
          # Commit: fix(color-scale): use file size unit custom color when not using color scale
          # PR: https://github.com/eza-community/eza/pull/975
          url = "https://github.com/eza-community/eza/commit/e52c367a421c7109e23a4d69b8c5ba7882c1b20b.patch";
          hash = "sha256-kWR65F0LxqQp6LBP/TXLIzt1zFpgKT1jA3b4VvHfnUw=";
        })
        (pkgs.fetchpatch {
          # Commit: fix(tree-view): Ensure nested tree parts align under item name
          # PR: https://github.com/eza-community/eza/pull/1193
          url = "https://github.com/eza-community/eza/commit/7ad1b8765977227a78e1d9a4554ffb96d756f8e5.patch";
          excludes = ["tests/*"]; # Exlude tests files, seems they are not found when patching (weird..)
          hash = "sha256-w5uUyD8T8Oziyi6Z+9VMsYhzHr4EfKvh+XyDIzW0kdw=";
        })
      ];
    }))

    cliPkgs.fzf
    stable.bat
    stable.fd
    stable.trashy
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

        # EXPERIMENT with git annex
        # https://git-annex.branchable.com/
        stable.git-annex
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
    stable.cpulimit # Limit CPU usage, especially useful for CPU-intensive tasks

    stable.tealdeer # tldr, examples for many programs (offline once DB cached)

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

    stable.libtree # a better & more secure `ldd` (see: 20240331T1410)
    stable.strace

    stable.pastel # generate, analyze, convert & manipulate RGB colors
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
