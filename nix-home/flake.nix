# Docs on flakes:
# - https://nixos.wiki/wiki/Flakes
# - https://www.tweag.io/blog/2020-05-25-flakes/
# - https://www.tweag.io/blog/2020-07-31-nixos-flakes/
# 
# Example configs:
# - https://github.com/mjlbach/nix-dotfiles/blob/master/nixpkgs/flake.nix
# - https://discourse.nixos.org/t/example-use-nix-flakes-with-home-manager-on-non-nixos-systems/10185

{
  description = "[WIP] Nix flake for bew's home config [WIP]";

  # NOTE: inputs url can be written using the flake reference syntax,
  # documented at https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html#flake-references

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  inputs.homeManager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, homeManager }: {
    homeConfig = homeManager.lib.homeManagerConfiguration {
      configuration = { pkgs, lib, ... }: {
        imports = [ ./home.nix ];
        # also save the homeManager & nixpkgs sources for reading
        home.file.".home-current/self".source = self.outPath;
        home.file.".home-current/nixpkgs".source = nixpkgs.outPath;
        home.file.".home-current/homeManager".source = homeManager.outPath;
      };
      system = "x86_64-linux";
      homeDirectory = "/home/bew";
      username = "bew";
    };
  };

}
