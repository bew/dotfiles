{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-parts.url = "github:hercules-ci/flake-parts";

    systems = {
      url = "github:nix-systems/default";
      flake = false;
    };

    nvim-plenary-plugin = {
      url = "github:nvim-lua/plenary.nvim";
      flake = false;
    };
  };

  outputs = inputs@{ self, flake-parts, systems, nvim-plenary-plugin, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = import systems;
    perSystem = { config, pkgs, ... }: {
      packages.default = pkgs.vimUtils.buildVimPluginFrom2Nix {
        namePrefix = "nvimPlugin-";
        name = "smart-bol.nvim";
        src = ./.;
      };
      checks.default = let
        plenary-plugin = pkgs.vimUtils.buildVimPluginFrom2Nix {
          name = "plenary.nvim";
          src = nvim-plenary-plugin;
        };

        # IDEA: make a flake-parts module to make plenary tests?
        # ==> BUT... why a module and not just have a builder function?
        mkPlenaryTest = {
          name,
          pluginToTest,
          nvim ? pkgs.neovim-unwrapped,
          extraPlugins ? [],
          extraBuildInputs ? [],
        }: let
          nvim-wrapped = pkgs.wrapNeovim nvim {
            configure = {
              customRC = /* vim */ ''
                runtime! plugin/plenary.vim
              '';
              packages.myVimPackage = {
                start = extraPlugins ++ [
                  pluginToTest
                  plenary-plugin
                ];
              };
            };
          };
        in pkgs.stdenv.mkDerivation {
          inherit name;
          src = pluginToTest;
          phases = [ "unpackPhase" "checkPhase" ];
          buildInputs = extraBuildInputs ++ [ nvim-wrapped ];

          doCheck = true;
          checkPhase = /* sh */ ''
            mkdir -p ./fake-home
            export HOME=$(realpath ./fake-home)

            echo "Running tests using plenary"
            nvim --headless --noplugin -c "PlenaryBustedDirectory ./tests {nvim_cmd = 'nvim'}" | tee $out
          '';
        };
      in mkPlenaryTest {
        name = "smart-bol";
        pluginToTest = config.packages.default;
      };
    };
  };
}
