{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.LazyVim.override {
    extras = [ "lazyvim.plugins.extras.editor.telescope" ];
  };
  pluginName = "telescope";
  loadLazyPluginName = "telescope.nvim";
}
