{ pkgsChannels, lib, mybuilders, myToolConfigs, ... }:

let
  inherit (pkgsChannels) stable;

  nvim-base = stable.neovim.override {
    # python3 & ruby providers are enabled by default..
    # => I won't need them, I want to have vimscript or Lua based plugins ONLY
    withPython3 = false;
    withRuby = false;
  };

  # this is not a config, it's the raw original nvim but as another name
  # 👉 Should be moved out of this file ?
  # .. But then how to access `nvim-base` ? Move `nvim-base` out of this file as well & pass it as input ?
  nvim-original = mybuilders.replaceBinsInPkg {
    # The original nvim Nix package, with another bin name
    name = "nvim-original";
    copyFromPkg = nvim-base;
    bins = { nvim-original = lib.getExe nvim-base; };
    meta.mainProgram = "nvim-original";
  };

  inherit (myToolConfigs) nvim-minimal nvim-bew;
in {
  imports = [
    # Install my setup in HOME, following specific NVIM_APPNAME (not default)
    # Gives binary `nvim-bew`
    nvim-bew.outputs.homeModules.specific
  ];

  home.packages = [
    # Also make a 'default' `nvim` binary pointing to the same specific NVIM_APPNAME
    (nvim-bew.lib.extendWith { useDefaultBinName = true; }).outputs.toolPkg.configured

    nvim-original
    (mybuilders.linkBins "extra-nvim-bins" {
      nvim-minimal = lib.getExe nvim-minimal.outputs.toolPkg.standalone;
    })
  ];
}
