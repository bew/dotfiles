# Run with:
#   nix build -L -f impure-pkg-build.nix packages.zsh-bew
(builtins.getFlake "pkgs").legacyPackages.x86_64-linux.callPackage ./zsh-bew-pkg.nix {}

# vim:set ft=conf sw=2:
