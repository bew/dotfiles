# This file must be in ~/.config/nixpkgs/config.nix
# Ref: https://nixos.org/nixpkgs/manual/#sec-modify-via-packageOverrides
#
# Note: `nix` should always be 'manually' installed in user env, not in my custom cli env here.

let
  mypkgsFn = basePkgs: {
    delta-bin = let
      version = "0.4.3"; # out on 4 sept 2020
      asset = fetchTarball {
        url =
          "https://github.com/dandavison/delta/releases/download/${version}/delta-${version}-x86_64-unknown-linux-musl.tar.gz";
          sha256 = "0an33yncn34xb47cr3spmq38fkghw719k8airjaac3nksigxkkd4";
      };
    in basePkgs.runCommand "delta-bin-${version}" {} ''
      mkdir -p $out/bin
      ln -s ${asset}/delta $out/bin/
    '';
  };

  # Ref: https://nixos.org/nixpkgs/manual/#sec-declarative-package-management
  bewCliEnvFn = pkgs:
    let mypkgs = mypkgsFn pkgs;
    in pkgs.buildEnv {
      name = "bew-cli-env";
      paths = with pkgs; [
        neovim

        zsh
        fd
        fzf
        ripgrep
        jq

        git
        git-lfs
        mypkgs.delta-bin # for enhanced git diffs

        watchexec
      ];
    };

in {
  packageOverrides = pkgs: rec {
    # Then install it with: `nix-env -iA nixpkgs.bew-cli-env` to install all my cli packages
    bew-cli-env = bewCliEnvFn pkgs;
    mypkgs = mypkgsFn pkgs;
  };

  # IDEA: this could go to a separate NIX_PATH entry 'mypkgs',
  # so installs would be `mypkgs.bew-cli-env` (cooool!)
}
