# Docs on flakes:
# - https://nixos.wiki/wiki/Flakes
# - https://www.tweag.io/blog/2020-05-25-flakes/
# - https://www.tweag.io/blog/2020-07-31-nixos-flakes/
#
# Example configs:
# - https://github.com/mjlbach/nix-dotfiles/blob/master/nixpkgs/flake.nix
# - https://discourse.nixos.org/t/example-use-nix-flakes-with-home-manager-on-non-nixos-systems/10185

# NOTE about specialArgs/extraSpecialArgs vs _module.args
# Setting something through `_module.args` has major limitation:
#
# A value in `_module.args.……` CANNOT be used in modules `imports`
# .. because an option like `_module` needs to resolve all imports _first_ 🤪.
# (e.g. to use `callPackage` to dynamically fill/configure a function that returns a module,
# like `(pkgsets.fooPkgs.callPackage ./bar.nix {}).someBarSpecificModule`)
#
# => Setting `pkgsets` via `specialArgs` of the underlying `evalModules` function works
#    because it statically sets module arguments from OUTSIDE of the module system,
#    without going through all of the fixpoint stuff and resolving all imports.
#
# (Thank you `Lily Foster` on Matrix for quickly helping me find the recursion issue! ❤️)

{
  description = "Nix flake packaging bew's dotfiles";

  # NOTE: inputs url can be written using the flake reference syntax,
  # documented at https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html#flake-references

  # We use specific branches to get most/all packages from the official cache.
  inputs = {
    nixpkgsStable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgsBleedingEdge.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    officialTemplates.url = "github:nixos/templates";
    myTemplates.url = "github:bew/my-nix-templates";

    homeManager.url = "github:nix-community/home-manager/release-26.05";
    homeManager.inputs.nixpkgs.follows = "nixpkgsStable";

    dynpaths.url = "path:./nix/dynpaths-flake";
    dynpaths.inputs.nixpkgs.follows = "nixpkgsStable";
    dynpaths.inputs.systems.follows = "systems";

    systems.url = "github:nix-systems/default";
    devshell.url = "github:numtide/devshell";
  };

  # TO-EXPERIMENT(?): flake-parts (https://github.com/hercules-ci/flake-parts) to
  #   define my toplevel flake in multiples files & auto-merge packages, homeConfig, homeModules, {tool,…}ConfigModules...
  outputs = { self, systems, devshell, ... }@flakeInputs: let
    lib = flakeInputs.nixpkgsStable.lib;
    eachSystem = lib.genAttrs (import systems);

    pkgsetsForSys = system: {
      mypkgs = self.packages.${system};
      stable = flakeInputs.nixpkgsStable.legacyPackages.${system};
      bleedingedge = flakeInputs.nixpkgsBleedingEdge.legacyPackages.${system};
    };
    forSys = system: let pkgsets = pkgsetsForSys system; in rec {
      inherit (pkgsets) mypkgs stable bleedingedge;
      inherit pkgsets;

      lib = stable.lib;
      mypkglib = stable.callPackage ./nix/mypkglib.nix {};

      toolkits = (import ./nix/kits { inherit lib flakeInputs; }).toolkits;

      toolConfigs.zsh-bew = toolkits.zshkit.eval {
        pkgs = stable;
        config = ./zsh/bew-config.zshkit-module.nix;
      };
      toolConfigs.zsh-bew-bins-from-PATH = toolConfigs.zsh-bew.lib.extendWith {
        deps.bins = {
          fzf.pkg = lib.mkForce "from-PATH";
          eza.pkg = lib.mkForce "from-PATH";
        };
      };

      toolConfigs.nvim-minimal = toolkits.nvimkit.eval {
        pkgs = stable;
        config = ./nvim/minimal-config.nvimkit-module.nix;
      };
      toolConfigs.nvim-bew = toolkits.nvimkit.eval {
        pkgs = stable;
        config = ./nvim/bew-config.nvimkit-module.nix;
        configOverride = {
          # Override to use latest Ruff (always better!)
          deps.bins.ruff.pkg = lib.mkForce bleedingedge.ruff;
          # Override to use latest Pyrefly (always better!)
          deps.bins.pyrefly.pkg = lib.mkForce bleedingedge.pyrefly;
          # Override to use latest lua LS (always better!)
          deps.bins.lua-language-server.pkg = lib.mkForce bleedingedge.lua-language-server;
          # Always use latest to ensure editing my projects using Rust from unstable work well
          # (e.g. when proc-macro-server is more recent in a project, generating errors)
          deps.bins.rust-analyzer.pkg = lib.mkForce bleedingedge.rust-analyzer;
        };
      };

      toolConfigs.tmux-bew = toolkits.tmuxkit.eval {
        pkgs = stable;
        config = ./tmux/bew-config.tmuxkit-module.nix;
      };

      # Returns dynamic kit configs with symlinks pointing to `dotfilesRealPath`.
      # Called per-home so each host gets its own real dotfiles path ✨.
      mkKitConfigsDynamic = dotfilesRealPath: let
        dynpathsOverride = {
          dynpaths.roots.dots = {
            nixStorePath = self;
            realPath = dotfilesRealPath;
          };
        };
        makeDynamic = config: config.lib.extendWith {
          imports = [dynpathsOverride];
          # Make the config dynamic if it's supported
          dynamicConfig.tryEnable = true;
        };
      in {
        zsh-bew = toolConfigs.zsh-bew-bins-from-PATH;
        nvim-minimal = makeDynamic toolConfigs.nvim-minimal;
        nvim-bew = makeDynamic toolConfigs.nvim-bew;
        tmux-bew = makeDynamic toolConfigs.tmux-bew;
      };
    };

    mkDynamicBewHomeConfig = { system, username, homeDir, defaultPkgsetName, configImports }: let
      sys = forSys system;
      pkgs = sys.pkgsets.${defaultPkgsetName};
    in import "${flakeInputs.homeManager}/modules" {
      inherit pkgs;
      configuration = {
        imports = configImports ++ [
          {
            home.username = username;
            home.homeDirectory = homeDir;
          }
          (import ./nix/setup-nix-registry.nix { inherit flakeInputs; })
          flakeInputs.dynpaths.modules.generic.dynpaths
          flakeInputs.dynpaths.modules.homeManager.dynpathsChecker
          {
            # Configure my dotfiles root, so that direct links created with
            # `config.dynpaths.mkLink` point to my repo (editable!).
            dynpaths.mode = "dynamic";
            dynpaths.roots.dots = {
              nixStorePath = flakeInputs.self;
              realPath = "${homeDir}/.dot";
            };
          }
        ];
      };

      # Expose pkgs sets from flake inputs
      extraSpecialArgs.pkgsets = sys.pkgsets;
      # Expose various tool configs to home modules, with symlink redirects for this host's dotfiles path
      extraSpecialArgs.kitConfigs = sys.mkKitConfigsDynamic "${homeDir}/.dot";
      # .. Must be in `extraSpecialArgs` since it's going to be used in modules' imports.
    };

  in {
    homeConfig.frametop-bew = mkDynamicBewHomeConfig rec {
      system = "x86_64-linux";
      username = "bew";
      homeDir = "/home/${username}";
      defaultPkgsetName = "stable";
      configImports = [
        ./nix/homes/frametop-bew
        { home.stateVersion = "21.05"; }
      ];
    };

    homeConfig.work-mac = mkDynamicBewHomeConfig rec {
      system = "aarch64-darwin";
      username = "benoitlesellierdechezelles";
      homeDir = "/Users/${username}";
      defaultPkgsetName = "stable";
      configImports = [
        ./nix/homes/work-mac
        { home.stateVersion = "26.05"; }
      ];
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
      zsh-bew-bin = mypkglib.linkSingleBin mypkgs.zsh-bew;
      # note: this variant is useful for testing zsh zwidgets with my custom fzf config (:
      zsh-bew-with-fzf-bew = useStandalonePkg (toolConfigs.zsh-bew.lib.extendWith {
        deps.bins.fzf.pkg = lib.mkForce mypkgs.fzf-bew;
      });

      fzf-bew = stable.callPackage ./fzf/package-bew.nix {};
      fzf-bew-bin = mypkglib.linkSingleBin mypkgs.fzf-bew;

      nvim-minimal = useStandalonePkg toolConfigs.nvim-minimal;
      nvim-bew = useStandalonePkg toolConfigs.nvim-bew;

      tmux-bew = useStandalonePkg toolConfigs.tmux-bew;
    });

    # (useful for debugging in `nix repl`)
    toolConfigs = eachSystem (system: with (forSys system); toolConfigs);
    toolkits = eachSystem (system: with (forSys system); toolkits);

    apps = eachSystem (system: with (forSys system); {
      # An env with all 'core' cli tools :)
      default = {
        type = "app";
        program = let
          tmux-config = toolConfigs.tmux-bew;
          env = stable.buildEnv {
            name = "cli-base-env";
            paths = let
              useStandalonePkg = config: config.outputs.toolPkg.standalone;
            in [
              # note: cannot use `toolConfigs.zsh-bew`, otherwise my fzf-bew custom pkg isn't used
              #   (packages in mypkgs are not cross-referenced yet..)
              (useStandalonePkg toolConfigs.zsh-bew-bins-from-PATH)
              mypkgs.nvim-minimal
              mypkgs.nvim-bew
              mypkgs.fzf-bew
              (useStandalonePkg tmux-config)
              (mypkglib.linkBins "nvim-default" {
                nvim = lib.getExe mypkgs.nvim-bew;
              })
              (stable.callPackage ./git/package-bew-env.nix {})
              stable.less # ensure modern pager
            ];
            meta.mainProgram = "zsh";
          };
          entrypoint = stable.writeShellScript "cli-base-entrypoint" /* sh */ ''
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

    devShells = eachSystem (system: with (forSys system); {
      default = devshell.legacyPackages.${system}.mkShell {
        packages = [
          stable.just # for repo actions

          # deps for drv diff on build
          stable.dix # drv diff viewer
          stable.ansifilter
          stable.moreutils
        ];
      };
    });
  };
}
