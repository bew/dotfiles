# Docs on flakes:
# - https://nixos.wiki/wiki/Flakes
# - https://www.tweag.io/blog/2020-05-25-flakes/
# - https://www.tweag.io/blog/2020-07-31-nixos-flakes/
#
# Example configs:
# - https://github.com/mjlbach/nix-dotfiles/blob/master/nixpkgs/flake.nix
# - https://discourse.nixos.org/t/example-use-nix-flakes-with-home-manager-on-non-nixos-systems/10185

{
  description = "Nix flake packaging bew's dotfiles";

  # NOTE: inputs url can be written using the flake reference syntax,
  # documented at https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html#flake-references

  # We use specific branches to get most/all packages from the official cache.
  inputs = {
    nixpkgsStable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgsBleedingEdge.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flakeTemplates.url = "github:nixos/templates";

    homeManager.url = "github:nix-community/home-manager/release-25.05";
    homeManager.inputs.nixpkgs.follows = "nixpkgsStable";

    systems.url = "github:nix-systems/default";
  };

  # TO-EXPERIMENT(?): flake-parts (https://github.com/hercules-ci/flake-parts) to
  #   define my toplevel flake in multiples files & auto-merge packages, homeConfig, homeModules, {tool,…}ConfigModules...
  outputs = { self, systems, ... }@flakeInputs: let
    lib = flakeInputs.nixpkgsStable.lib;
    eachSystem = lib.genAttrs (import systems);

    # FIXME: This should be configured in each 'home' config,
    #   and injected in tool configs with an override 🤔
    editableConfigOverride = {
      editable.config = {
        nixStorePath = self;
        realPath = "/home/bew/.dot"; # FIXME: hardcoded $USER 😬
      };
    };

    pkgsForSys = system: {
      myPkgs = self.packages.${system};
      stablePkgs = flakeInputs.nixpkgsStable.legacyPackages.${system};
      bleedingedgePkgs = flakeInputs.nixpkgsBleedingEdge.legacyPackages.${system};
    };
    forSys = system: let
      inherit (pkgsForSys system) myPkgs stablePkgs bleedingedgePkgs;
    in rec {
      inherit myPkgs stablePkgs bleedingedgePkgs;

      directSymlinker = stablePkgs.callPackage ./nix/mylib/editable-symlinker.nix {};

      lib = stablePkgs.lib;
      mybuilders = stablePkgs.callPackage ./nix/mylib/mybuilders.nix {};
      # IDEA: rename to `pkglib`?
      #   (to show it's a lib but about packages (so not system-agnostic))

      kitsys = import ./nix/kit-system { inherit lib; };

      zsh-kit = kitsys.newKit (import ./nix/kits/zsh-toolkit/kit.nix);
      toolConfigs.zsh-bew = zsh-kit.eval {
        pkgs = stablePkgs;
        config = ./zsh/zsh-bew.zsh-config.nix;
      };
      toolConfigs.zsh-bew-bins-from-PATH = toolConfigs.zsh-bew.lib.extendWith {
        deps.bins = {
          fzf.pkg = lib.mkForce "from-PATH";
          eza.pkg = lib.mkForce "from-PATH";
        };
      };

      nvim-kit = kitsys.newKit (import ./nix/kits/nvim-toolkit/kit.nix);
      toolConfigs.nvim-minimal = nvim-kit.eval {
        pkgs = stablePkgs;
        config = ./nvim/nvim-minimal.nvim-config.nix;
        configOverride = editableConfigOverride;
      };
      toolConfigs.nvim-bew = nvim-kit.eval {
        pkgs = stablePkgs;
        config = ./nvim/nvim-bew.nvim-config.nix;
        configOverride = {
          imports = [editableConfigOverride];
          # Override python lsp to use more recent python
          # (Attempting to fix FREQUENT crashes with dmypy 1.11.x)
          deps.bins.python-lsp-server.extra.pyPkg = lib.mkForce bleedingedgePkgs.python313;
          # Require v0.15.0+ to avoid this issue:
          # ref: https://github.com/LuaLS/lua-language-server/issues/3175
          # ref: https://github.com/LuaLS/lua-language-server/pull/3182 (PR)
          deps.bins.lua-language-server.pkg = lib.mkForce bleedingedgePkgs.lua-language-server;
        };
      };

      tmux-kit = kitsys.newKit (import ./nix/kits/tmux-toolkit/kit.nix);
      toolConfigs.tmux-bew = tmux-kit.eval {
        pkgs = stablePkgs;
        config = ./tmux/bew.tmux-config.nix;
        configOverride = editableConfigOverride;
      };
    };

  in {
    # note: force system
    homeConfig = with (forSys "x86_64-linux"); import "${flakeInputs.homeManager}/modules" {
      pkgs = stablePkgs;
      configuration = import ./nix/homes/main.nix {
        inherit flakeInputs;
        system = "x86_64-linux";
        username = "bew";
      };

      # Pkgs channels from flakeInputs
      # => Allows to have a stable sharing point for multiple pkgs sets
      #
      # NOTE: `pkgsChannels` CANNOT be set through `_module.args` without a major limitation:
      #   Using `_module.args...` somewhere in `imports` is NOT possible because evaluating
      #   an option like `_module` needs to resolve all imports _first_.
      #   (e.g. to use `callPackage` to dynamically fill/configure a function that returns a module,
      #   like `(pkgsChannels.fooPkgs.callPackage ./bar.nix {}).someBarSpecificModule`)
      #
      #   => Setting `pkgsChannels` via `specialArgs` of the underlying `evalModules` function works
      #      because it statically sets module arguments from OUTSIDE of the module system,
      #      without going through all of the fixpoint stuff and resolving all imports.
      #
      #   (Thank you `Lily Foster` on Matrix for quickly helping me find the recursion issue! ❤️)
      extraSpecialArgs.pkgsChannels = {
        stable = stablePkgs;
        bleedingedge = bleedingedgePkgs;
        myPkgs = myPkgs;
      };

      # Expose to home modules various tool configs.
      # (but not exposed out of the dotfiles flake')
      #
      # Must be in `extraSpecialArgs` since it's going to be used in modules' imports.
      extraSpecialArgs.kitConfigs = let
        makeEditable = config: config.lib.extendWith {
          # Make the config editable if it's supported
          editable.try_enable = true;
        };
      in {
        zsh-bew = toolConfigs.zsh-bew-bins-from-PATH;
        nvim-minimal = makeEditable toolConfigs.nvim-minimal;
        nvim-bew = makeEditable toolConfigs.nvim-bew;
        tmux-bew = makeEditable toolConfigs.tmux-bew;
      };
    };

    # --- Stuff I want to be able to do with binaries & packages:
    # In my packages:
    # - a `zsh-bew` full pkg with the full `zsh` pkg + `zsh` binary wrapped to use my config (using fzf-bew)
    # - a `fzf-bew` full pkg with the full `fzf` pkg + `fzf` binary wrapped to use my config
    # - a `zsh-bew-bin` pkg with only `${zsh-bew}/bin/zsh`
    # - a `fzf-bew-bin` pkg with only `${fzf-bew}/bin/fzf`
    # - ...
    # => Installing `zsh-bew` or `fzf-bew` should also make `man zsh` & `man fzf` available!
    #    (`man` will auto discover man pages based on binary in `$PATH`, see `man 5 manpath`!)
    #
    # In my CLI env:
    # - a `zsh` bin, with my config (may be editable?)
    # - a `zsh-special-config` bin, for a zsh with a specialized config (bin only)
    # - a `fzf` bin, for fzf with my config
    packages = eachSystem (system: with (forSys system); let
      useStandalonePkg = config: config.outputs.toolPkg.standalone;
    in {
      zsh-bew = useStandalonePkg toolConfigs.zsh-bew;
      zsh-bew-zdotdir = toolConfigs.zsh-bew.outputs.zdotdir;
      zsh-bew-bin = mybuilders.linkSingleBin (
        lib.getExe (useStandalonePkg toolConfigs.zsh-bew)
      );

      fzf-bew = stablePkgs.callPackage ./nix/pkgs/fzf-with-bew-cfg.nix {
        fzf = stablePkgs.fzf;
        replaceBinsInPkg = mybuilders.replaceBinsInPkg;
      };
      fzf-bew-bin = mybuilders.linkSingleBin (lib.getExe myPkgs.fzf-bew);

      nvim-minimal = useStandalonePkg toolConfigs.nvim-minimal;
      nvim-bew = useStandalonePkg toolConfigs.nvim-bew;

      tmux-bew = useStandalonePkg toolConfigs.tmux-bew;
    });

    apps = eachSystem (system: with (forSys system); {
      # An env with all 'core' cli tools :)
      default = {
        type = "app";
        program = let
          tmux-config = toolConfigs.tmux-bew;
          env = stablePkgs.buildEnv {
            name = "cli-base-env";
            paths = let
              useStandalonePkg = config: config.outputs.toolPkg.standalone;
            in [
              # note: cannot use `toolConfigs.zsh-bew`, otherwise my fzf-bew custom pkg isn't used
              #   (packages in myPkgs are not cross-referenced yet..)
              (useStandalonePkg toolConfigs.zsh-bew-bins-from-PATH)
              myPkgs.nvim-minimal
              myPkgs.nvim-bew
              myPkgs.fzf-bew
              (useStandalonePkg tmux-config)
              (mybuilders.linkBins "nvim-default" {
                nvim = lib.getExe myPkgs.nvim-bew;
              })
              stablePkgs.less # ensure modern pager
            ];
            meta.mainProgram = "zsh";
          };
          entrypoint = stablePkgs.writeShellScript "cli-base-entrypoint" /* sh */ ''
            if [[ -z "''${PATH_BEFORE_MY_NIX_CLI_ENV:-}" ]]; then
              export PATH_BEFORE_MY_NIX_CLI_ENV=$PATH
              # note: Do _not_ re-set it to ensure its content is not 'infected' by Nix paths
            fi
            export PATH=${env}/bin:$PATH_BEFORE_MY_NIX_CLI_ENV

            # MAYBE: Move to tmux kit (?)
            if [[ -n "''${TMUX:-}" ]]; then
              # We are in TMUX!
              echo
              echo "--------------------------------------------------------------------------------"
              echo '!! Tmux needs the new cli env !!'
              echo "To ensure new tmux panes spawn apps from the NEW cli env, update tmux's \$PATH:"
              echo
              echo "👉 tmux set-environment -g PATH '$PATH'"
              echo
              echo "--------------------------------------------------------------------------------"
              echo
              previous_tmux_config_env=$(tmux show-environment -g TMUX_CONFIG_ENTRYPOINT 2>/dev/null)
              new_tmux_config_env=TMUX_CONFIG_ENTRYPOINT=${tmux-config.outputs.cfgEntrypoint}
              if [[ "$previous_tmux_config_env" != "$new_tmux_config_env" ]]; then
                echo "!! Tmux config changed !!"
                echo
                echo "Update target config:"
                echo "👉 tmux set-environment -g TMUX_CONFIG_ENTRYPOINT '${tmux-config.outputs.cfgEntrypoint}'"
                echo
                echo "Then reload the config"
                echo
                echo "--------------------------------------------------------------------------------"
                echo
              fi
            fi

            exec ${lib.getExe env} "$@"
          '';
        in entrypoint.outPath;
      };
    });
  };
}
