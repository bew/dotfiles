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
    nixpkgsStable.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgsBleedingEdge.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flakeTemplates.url = "github:nixos/templates";

    homeManager.url = "github:nix-community/home-manager/release-23.11";
    homeManager.inputs.nixpkgs.follows = "nixpkgsBleedingEdge";
  };

  # TO-EXPERIMENT(?): flake-parts (https://github.com/hercules-ci/flake-parts) to
  #   define my toplevel flake in multiples files & auto-merge packages, homeConfig, homeModules, {tool,…}ConfigModules...
  outputs = { self, ... }@flakeInputs: let
    # I only care about ONE system for now...
    system = "x86_64-linux";
    myPkgs = self.packages.${system};

    lib = stablePkgs.lib;
    stablePkgs = flakeInputs.nixpkgsStable.legacyPackages.${system};
    bleedingedgePkgs = flakeInputs.nixpkgsBleedingEdge.legacyPackages.${system};

    mybuilders = stablePkgs.callPackage ./nix/homes/mylib/mybuilders.nix {};
    # IDEA: rename to `pkglib`?
    #   (to show it's a lib but about packages (so not system-agnostic))

    # NOTE: flake-parts would help with imports & auto-merging here.
    zsh-tool-package = stablePkgs.callPackage ./zsh/tool-package.nix {
      inherit mybuilders;
    };
    # TODO: find a better place to instantiate the config & configure it..
    zsh-bew-config = zsh-tool-package.lib.mkZshConfig {
      pkgs = stablePkgs;
      configuration = {
        imports = [
          zsh-tool-package.zshConfigModule.zsh-bew
        ];
        # NOTE: FORCE the config to use a different fzf bin dependency
        #   (see comment above mkHomeModule in </zsh/tool-package.nix> for thoughts on bins deps propagation..)
        deps.bins.fzf.pkg = lib.mkForce myPkgs.fzf-bew;
      };
    };

  in {
    homeConfig = let
      username = "bew";
    in import "${flakeInputs.homeManager}/modules" {
      pkgs = flakeInputs.nixpkgsStable.legacyPackages.${system};
      configuration = import ./nix/homes/main.nix { inherit flakeInputs system username; };

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
      extraSpecialArgs.pkgsChannels = let
        legacyPkgsForSystem = nixpkgs: nixpkgs.legacyPackages.${system};
        pkgsForSystem = nixpkgs: nixpkgs.packages.${system};
      in {
        stable = legacyPkgsForSystem flakeInputs.nixpkgsStable;
        bleedingedge = legacyPkgsForSystem flakeInputs.nixpkgsBleedingEdge;
        myPkgs = pkgsForSystem flakeInputs.self;
      };

      # Expose to home modules a set of 'private' home modules from other places
      # (but not exposed out of the dotfiles flake')
      #
      # Must be in `extraSpecialArgs` since it's going to be used in modules' imports.
      extraSpecialArgs.myHomeModules = {
        zsh-bew = (zsh-tool-package.lib.mkZshHomeModule zsh-bew-config);
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
    packages.${system} = let
      zsh-bew-pkgs = zsh-tool-package.lib.mkZshPackages zsh-bew-config;
    in {
      inherit (zsh-bew-pkgs) zsh-bew zsh-bew-bin zsh-bew-zdotdir;

      mpv-bew = bleedingedgePkgs.callPackage ./nix/pkgs/mpv {};
      mpv-helpers = bleedingedgePkgs.callPackage ./nix/pkgs/mpv-helpers {};

      fzf-bew = stablePkgs.callPackage ./nix/pkgs/fzf-with-bew-cfg.nix {
        fzf = bleedingedgePkgs.fzf;
        replaceBinsInPkg = mybuilders.replaceBinsInPkg;
      };
      fzf-bew-bin = mybuilders.linkSingleBin (lib.getExe myPkgs.fzf-bew);

      #tmux-bew = ...
    };
    apps.${system} = {
      # FIXME: should be an env with all 'core' cli tools
      default = { type = "app"; program = lib.getExe myPkgs.zsh-bew; };
    };
  };
}
