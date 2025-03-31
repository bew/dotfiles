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
    nixpkgsStable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgsBleedingEdge.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flakeTemplates.url = "github:nixos/templates";

    homeManager.url = "github:nix-community/home-manager/release-24.11";
    homeManager.inputs.nixpkgs.follows = "nixpkgsStable";

    systems.url = "github:nix-systems/default";
  };

  # TO-EXPERIMENT(?): flake-parts (https://github.com/hercules-ci/flake-parts) to
  #   define my toplevel flake in multiples files & auto-merge packages, homeConfig, homeModules, {tool,…}ConfigModules...
  outputs = { self, systems, ... }@flakeInputs: let
    lib = flakeInputs.nixpkgsStable.lib;
    eachSystem = lib.genAttrs (import systems);

    pkgsForSys = system: {
      myPkgs = self.packages.${system};
      stablePkgs = flakeInputs.nixpkgsStable.legacyPackages.${system};
      bleedingedgePkgs = flakeInputs.nixpkgsBleedingEdge.legacyPackages.${system};
    };
    forSys = system: let
      inherit (pkgsForSys system) myPkgs stablePkgs bleedingedgePkgs;
    in rec {
      inherit myPkgs stablePkgs bleedingedgePkgs;

      lib = stablePkgs.lib;
      mybuilders = stablePkgs.callPackage ./nix/homes/mylib/mybuilders.nix {};
      # IDEA: rename to `pkglib`?
      #   (to show it's a lib but about packages (so not system-agnostic))

      # NOTE: flake-parts would help with imports & auto-merging here.
      zsh-configs = stablePkgs.callPackage ./zsh/tool-configs.nix {};
      # TODO: find a better place to configure & instantiate tool configs (in a flake-parts module?)
      mk-zsh-bew-config = {fewBinsFromPATH ? false}: zsh-configs.lib.evalZshConfig {
        pkgs = stablePkgs;
        configuration = {
          imports = [
            zsh-configs.zshConfigModule.zsh-bew
          ];
          config = lib.mkIf fewBinsFromPATH {
            deps.bins.fzf.pkg = lib.mkForce "from-PATH";
            deps.bins.eza.pkg = lib.mkForce "from-PATH";
          };
        };
      };

      nvim-configs = stablePkgs.callPackage ./nvim-wip/tool-configs.nix {};
      mk-nvim-config = {nvimConfig, asDefault ? false}: (
        nvim-configs.lib.evalNvimConfig {
          pkgs = stablePkgs;
          configuration = {
            imports = [
              nvimConfig
            ];
            # Is config supposed to be the default 🤔
            config.useDefaultBinName = asDefault;
            # Override the symlinker function, to point to editable paths
            config.lib.mkLink = stablePkgs.callPackage ./nix/homes/mylib/editable-symlinker.nix {
              nixStorePath = self;
              realPath = "/home/bew/.dot"; # FIXME: leak hardcoded $USER
            };
            # FIXME(?): find a way to avoid having to do that for every config manually?
          };
        }
      );
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
      extraSpecialArgs.myToolConfigs = {
        zsh-bew = mk-zsh-bew-config { fewBinsFromPATH = true; };
        nvim-minimal = mk-nvim-config { nvimConfig = nvim-configs.nvimConfigModule.nvim-minimal; };
        nvim-bew = mk-nvim-config {
          nvimConfig = nvim-configs.nvimConfigModule.nvim-bew;
          asDefault = true;
        };
      };
    };

    # note: it's annoying w.r.t system (this is now a multi-system flake)
    # zshConfig.zsh-bew = mk-zsh-bew-config {};

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
      zsh-bew-config = mk-zsh-bew-config {};
    in {
      zsh-bew = zsh-bew-config.outputs.toolPkg.standalone;
      zsh-bew-zdotdir = zsh-bew-config.outputs.zdotdir;
      zsh-bew-bin = mybuilders.linkSingleBin (lib.getExe zsh-bew-config.outputs.toolPkg.standalone);

      fzf-bew = stablePkgs.callPackage ./nix/pkgs/fzf-with-bew-cfg.nix {
        fzf = stablePkgs.fzf;
        replaceBinsInPkg = mybuilders.replaceBinsInPkg;
      };
      fzf-bew-bin = mybuilders.linkSingleBin (lib.getExe myPkgs.fzf-bew);

      nvim-minimal = let
        cfg = nvim-configs.lib.evalNvimConfig {
          pkgs = stablePkgs;
          configuration = nvim-configs.nvimConfigModule.nvim-minimal;
        };
      in cfg.outputs.toolPkg.standalone;
      nvim-bew = let
        cfg = nvim-configs.lib.evalNvimConfig {
          pkgs = stablePkgs;
          configuration = nvim-configs.nvimConfigModule.nvim-bew;
        };
      in cfg.outputs.toolPkg.standalone;

      #tmux-bew = ...
    });

    apps = eachSystem (system: with (forSys system); {
      # An env with all 'core' cli tools :)
      default = {
        type = "app";
        program = let
          env = stablePkgs.buildEnv {
            name = "cli-base-env";
            paths = [
              # note: cannot use `myPkgs.zsh-bew`, otherwise my fzf-bew custom pkg isn't used
              #   (packages in myPkgs are not cross-referenced yet..)
              (mk-zsh-bew-config { fewBinsFromPATH = true; }).outputs.toolPkg.standalone
              myPkgs.nvim-minimal
              myPkgs.nvim-bew
              myPkgs.fzf-bew
              (mybuilders.linkBins "nvim-default" {
                nvim = lib.getExe myPkgs.nvim-bew;
              })
            ];
            meta.mainProgram = myPkgs.zsh-bew.meta.mainProgram;
          };
          entrypoint = stablePkgs.writeShellScript "cli-base-entrypoint" ''
            export PATH=${env}/bin:$PATH
            exec ${lib.getExe env} "$@"
          '';
        in entrypoint.outPath;
      };
    });
  };
}
