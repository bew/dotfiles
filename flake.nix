# Docs on flakes:
# - https://nixos.wiki/wiki/Flakes
# - https://www.tweag.io/blog/2020-05-25-flakes/
# - https://www.tweag.io/blog/2020-07-31-nixos-flakes/
#
# Example configs:
# - https://github.com/mjlbach/nix-dotfiles/blob/master/nixpkgs/flake.nix
# - https://discourse.nixos.org/t/example-use-nix-flakes-with-home-manager-on-non-nixos-systems/10185

# TODO: a (sensible) minimal flake that can build a home config package for
# normal (copy-files-to-store) & dev use (link-to-dot-files).

{
  description = "Nix flake packaging bew's dotfiles";

  # NOTE: inputs url can be written using the flake reference syntax,
  # documented at https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html#flake-references

  # We use specific branches to get most/all packages from the official cache.

  # This is the backbone package set, DO NOT REMOVE/CHANGE unless you know what you're doing
  inputs.nixpkgsBackbone.url = "github:nixos/nixpkgs/nixos-21.11";

  inputs.nixpkgsStable.url = "github:nixos/nixpkgs/nixos-21.11";
  inputs.nixpkgsUnstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  inputs.homeManager = {
    url = "github:nix-community/home-manager/release-21.11";
    inputs.nixpkgs.follows = "nixpkgsStable";
  };

  outputs = { self, nixpkgsStable, homeManager, ... }@inputs: {
    homeConfig = let
      # I only care about ONE system for now...
      system = "x86_64-linux";
    in import "${homeManager}/modules" {
      pkgs = nixpkgsStable.legacyPackages.${system};
      configuration = { config, lib, ... }: {
        imports = [
          ./nix-home/modules/flake-inputs.nix
          ./nix-home/modules/nix-registry.nix
          ./nix-home/modules/pkgs-channels.nix
          ./nix-home # my actual home package!
        ];

        # Save inputs for use in other modules, and link to home for personal reading
        flakeInputs.inputs = inputs;
        flakeInputs.linkToHome.directory = ".nix-home-current";

        # Restrict user nix/registry.json to the following indirect flakes:
        nixRegistry.indirectFlakes = {
          # -> flake ref: "path:${nixpkgs.outPath}"
          pkgs = { type = "path"; path = inputs.nixpkgsStable.outPath; };
          # -> flake ref: "github:nixos/nixpkgs/nixpkgs-unstable"
          unstable = {
            type = "github";
            owner = "nixos";
            repo = "nixpkgs";
            ref = "nixpkgs-unstable";
          };
        };

        pkgsChannels = let
          pkgsFromNixpkgs = nixpkgs: nixpkgs.legacyPackages.${system};
        in {
          backbone = pkgsFromNixpkgs inputs.nixpkgsBackbone;
          stable = pkgsFromNixpkgs inputs.nixpkgsStable;
          bleedingedge = pkgsFromNixpkgs inputs.nixpkgsUnstable;
        };

        home.username = "lesell_b";
        # FIXME: this will be annoying to change to a dynamic DIR based on env for dev builds..
        #   => Maybe mark them as the default?
        #      (so we can override from a wrapper script or sth?)
        #   => NOTE: using a switch with an env var like
        #     `NIX_HOME_DEV_OVERRIDE` doesn't seem to trigger a rebuild..
        home.homeDirectory = "/home/${config.home.username}";

        # ---
        # Proof of concept of a dynamic/editable symlink-to-a-dot-file, managed by Nix, using
        # the `config.lib.file.mkOutOfStoreSymlink` helper function exposed by homeManager.
        home.file.".test-out-of-store-gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dot/gitconfig";
        # NOTE: (for when I finally commit and have my home dot-files managed by Nix)
        # * https://github.com/nix-community/home-manager/issues/2085
        # * https://www.reddit.com/r/NixOS/comments/qlhifw/comment/hj32l2b/ (my own comment on the subject)
        home.file.".test-out-of-store-gitconfig--automatic".source = let
          # Allows to give a ./relative/path/value and have it automatically converted
          # to a path in my dotfiles directory. (Instead of being a path in the
          # nix-stored flake source: /nix/store/...-source)
          linkToDots = pathRaw: let
            pathStr = toString pathRaw;
            flakeSourceDir = toString self; # same as `toString ./.` # Could be computed elsewhere
            actualDotsDir = "${config.home.homeDirectory}/.dot"; # Could be set in a custom module?

            pathRelativeToDots = lib.removePrefix (flakeSourceDir + "/") pathStr;
            pathAbsoluteToDots = "${actualDotsDir}/${pathRelativeToDots}";
          in config.lib.file.mkOutOfStoreSymlink pathAbsoluteToDots;
        in linkToDots ./gitconfig;
      };
    };

    # TODO(idea): expose packages (& apps?) of my tools pre-configured,
    # like tmux-bew (easiest), fzf-bew (easy?), nvim-bew (hard), zsh-bew (hard), ...
    # and finally cli-bew (with all previous packages)
  };
}
