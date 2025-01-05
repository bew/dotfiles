{ pkgsChannels, lib, mybuilders, ... }:

let
  inherit (pkgsChannels) stable bleedingedge;
in {
  home.packages = [
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
