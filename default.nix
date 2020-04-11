#
# Wanted: describe my dotfiles in a way that can be installed/managed by Nix if wanted
#
# I want to choose what I 'install' from my dotfiles (with options).
# I want to be able to edit some files and immediately test the changes, in a dev-env.
#
# With Nix, I want to "deploy" my dotfiles in multiple directories, to test different
# things in parallel (e.g: from different branches), using `HOME=some_path binary` or
# maybe even using a pure nix-shell (let's be crazy).
#
# I want to be able to split work-only, fun-only, headless-only (no gui) configs to
# compose them easily.
#
# I don't want to write a nix file for every packages (e.g: only one for all gui configs)
# (may change later)
#
# I want an 'activation script' (similar to NixOS) to deploy a 'generation' of my dotfiles
# to a specific directory (e.g: my home directory) without force-breaking existing symlinks
# (give an error before changing files).
#
#
# I want composable dotfiles, I may have part of my dotfiles public, another in a private
# repository (with work creds, scripts, ...), some parts here and there..
#
# I want to be able to easily deploy a minimal zsh & nvim config on a new VPS server (+ a few tools) or for a new user
# ---> with & WITHOUT being root on the target server.
#      The 'without' being root part, meaning there is no /nix and I can't create it.
#
#      One way would be to provide a proot-based bootstrap tool to simulate the /nix, to
#      be able to install /nix-based files and configs.
#
#      Another way ...... (TBD)
#
#
# Steps:
# A simple nvim config derivation with the 'put everything (e.g: whole nvim dir) in the store' strategy. Then maybe a minimal nvim config (no plugins) + a medium config (with basic plugins).
# May need to try PlugSnapshot and install plugins as part of the derivation build...
#
# Same for zsh (not sure how it would work with plugins too)
#
# A Nix set that describe where each file should go
#
# -----------------------
# ---- Multiple ways Nix can be used for dotfiles (using nvim as an example):
#
# 1. Only use nix as a description on where to put symlinks, can be spread in many
#    directories. Meaning that we could have sth like:
#
#    ```
#    dotfiles/
#    - gitconfig
#    - tmux.conf
#    - farmlinks.nix
#    - nvim/
#      - init.vim
#      - farmlinks.nix
#    ```
#
#    In this case, the farmlinks files would be gathered in a similar way as nixos modules.
#    And the final file would look like this:
#
#    ```
#    {
#      home.".gitconfig" = "${./gitconfig}";
#      home.".tmux.conf" = "${./tmux.conf}";
#      xdg_config."nvim/init.vim" = "${./nvim/init.vim}";
#    }
#    ```
#    The various config files would be added to the nix store, and the out derivation would be
#    an env looking like the home folder with all the links to the configs in the nix store.
#
#    Then there would be an activation script that would link (and make it a nix root) the
#    derivation in (e.g: ~/.dot) and the various links from the config would be made in the
#    real home dir.
#
#    In this case, everything is pretty static (is it?), we don't have configurable packages
#    (well actually we could, the linked files could be generated / put there on various
#    conditions..)
#
#
# 2. Only provide already configured binaries. So each package would have its own derivation,
#    were the binary would be a wrapper to the original bin + some config file 'hardcoded' in
#    the wrapper.
#
#    Ex wrapper:
#    ```
#    # nvim-minimal
#    /nix/store/...nvim -u /nix/store/...minimal-init.vim "$@"
#    # nvim
#    /nix/store/...nvim -u /nix/store/...init.vim "$@"
#    ```
#
#    In this case, it's hard to use a binary with another config or without config..
#    On the other hand, there are no configs to symlink anywhere! just put the binaries in PATH
#    and you can use various configs using various binaries.
#
#    There could be a `nvim-unwrapped` bin, pointing to the original binary, so I can still use
#    it if needed.
#
#
# 3. Per app config with Nix, where you can choose which kind of configs to use (picking
#    existing files accordingly).
#    FIXME: what would be the derivation? sth like 2. ?
#
#    Also, to allow some existing files to be loaded or not, the main config files could be
#    generated from various configs, and they would import the existing configs when needed.
#
#
# 4. Deep per-app configs in Nix, where for example plugins for nvim and their configuration
#    are described in a Nix file, which will generate the final init.vim with everything in it.
#
#
# 5. A MIX OF EVERYTHING #yolo! We can start small with 1., then start some 3. with some 2., and
#    if necessary, do some 4., but then the configs would be tied to Nix, because Nix is
#    generating the files! But that's not necessarily a bad things, it's just that on systems
#    without Nix, I'll need to use a tarball (e.g: from the CI) of a given Nix config...
#    (Not sure how to generate such a thing that will not put things in /nix in case I'm not
#    root on that server...)
#
#    Interesting stuff done in home-manager:
#    https://github.com/rycee/home-manager/blob/9f223e98b7a7e72037ecbba7c1076e35fea2a8f3/modules/programs/bash.nix#L143

{}
