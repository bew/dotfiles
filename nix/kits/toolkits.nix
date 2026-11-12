{ kitsys, flakeInputs }:

let
  # A toolkit is a kit specialized for a tool, it always gets:
  # - the shared tool base module
  # - the dynpaths toolkit module
  # - the tool-specific `baseModule`
  newToolkit = { tool, baseModule, meta ? {} }:
    kitsys.newKit {
      inherit meta;
      baseModules = [
        ./kit-modules/toolkit-base.kit-module.nix
        ./toolkit-modules/dir.toolkit-module.nix
        flakeInputs.dynpaths.modules.kitsys.dynpaths
        baseModule
      ];
      class = "tool.${tool}";

      # The toolkit base modules read `pkgs`, so report an omitted one early.
      requirePkgs = true;

      # `lib` option is already defined in the tool base module
      declareLibOption = false;
    };
in {
  lib = { inherit newToolkit; };

  toolkits = {
    zshkit = newToolkit {
      tool = "zsh";
      baseModule = ./toolkit-modules/zshkit-base.toolkit-module.nix;
      meta.name = "Zsh tool kit";
    };
    nvimkit = newToolkit {
      tool = "nvim";
      baseModule = ./toolkit-modules/nvimkit-base.toolkit-module.nix;
      meta.name = "Nvim tool kit";
    };
    tmuxkit = newToolkit {
      tool = "tmux";
      baseModule = ./toolkit-modules/tmuxkit-base.toolkit-module.nix;
      meta.name = "Tmux tool kit";
    };
  };
}
