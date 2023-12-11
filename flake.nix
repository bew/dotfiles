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
    nixpkgsStable.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgsBleedingEdge.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flakeTemplates.url = "github:nixos/templates";

    homeManager.url = "github:nix-community/home-manager/release-23.05";
    homeManager.inputs.nixpkgs.follows = "nixpkgsBleedingEdge";
  };

  # TO-EXPERIMENT(?): flake-parts (https://github.com/hercules-ci/flake-parts) to
  #   define my toplevel flake in multiples files
  # TO-EXPERIMENT(?): flakelight (https://github.com/accelbread/flakelight) to
  #   auto-define the flake elements from files and folder structure..
  outputs = { self, ... }@flakeInputs: let
    # I only care about ONE system for now...
    system = "x86_64-linux";
    myPkgs = self.packages.${system};
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
    };

    # TODO(idea): expose packages (& apps?) of my tools pre-configured,
    # like tmux-bew (easiest), fzf-bew (easy?), nvim-bew (hard), zsh-bew (hard), ...
    # and finally cli-bew (with all previous packages)

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
      lib = stablePkgs.lib;
      stablePkgs = flakeInputs.nixpkgsStable.legacyPackages.${system};
      bleedingedgePkgs = flakeInputs.nixpkgsBleedingEdge.legacyPackages.${system};
      mybuilders = stablePkgs.callPackage ./nix/homes/mylib/mybuilders.nix {};
    in {
      mpv-bew = bleedingedgePkgs.callPackage ./nix/pkgs/mpv {};
      mpv-helpers = bleedingedgePkgs.callPackage ./nix/pkgs/mpv-helpers {};

      zsh-bew-zdotdir = stablePkgs.callPackage ./zsh/pkg-zsh-bew-zdotdir.nix {
        fzf = myPkgs.fzf-bew;
      };
      zsh-bew = let
        # zsh pkg wrapper, using my zsh-bew-zdotdir as configuration, and using a cli env for dependent binaries
        pkg = { buildEnv, makeWrapper, zsh, zdotdir }:
          mybuilders.replaceBinsInPkg {
            name = "zsh-bew";
            copyFromPkg = zsh;
            nativeBuildInputs = [ makeWrapper ];
            meta.mainProgram = "zsh";
            postBuild = /* sh */ ''
              makeWrapper ${lib.getExe zsh} $out/bin/zsh \
                --set ZDOTDIR ${zdotdir} \
                --set SHELL_CLI_ENV : ${zdotdir.shellCliEnv}
            '';
          };
      in stablePkgs.callPackage pkg { zdotdir = myPkgs.zsh-bew-zdotdir; };
      zsh-bew-bin = mybuilders.linkSingleBin (lib.getExe myPkgs.zsh-bew);

      fzf-bew = stablePkgs.callPackage ./nix/pkgs/fzf-with-bew-cfg.nix {
        fzf = bleedingedgePkgs.fzf;
        replaceBinsInPkg = mybuilders.replaceBinsInPkg;
      };
      fzf-bew-bin = mybuilders.linkSingleBin (lib.getExe myPkgs.fzf-bew);

      #tmux-bew = ...
    };
    apps.${system} = {
      # FIXME: should be an env with all 'core' cli tools
      default = { type = "app"; program = myPkgs.zsh-bew; };
    };
  };
}
