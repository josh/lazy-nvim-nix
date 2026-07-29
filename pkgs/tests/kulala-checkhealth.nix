{
  lib,
  callPackage,
  lazy-nvim-nix,
  kulala-core,
}:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.LazyVim.override {
    extras = [ "lazyvim.plugins.extras.util.rest" ];
    extraSpec = [
      (
        lazy-nvim-nix.plugins."kulala.nvim".spec
        // {
          opts = {
            kulala_core = {
              path = lib.getExe kulala-core;
            };
          };
        }
      )
    ];
  };
  pluginName = "kulala";
  loadLazyPluginName = "kulala.nvim";
}
