{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.LazyVim.override {
    extras = [ "lazyvim.plugins.extras.lang.markdown" ];
  };
  pluginName = "mkdp";
  loadLazyPluginName = "markdown-preview.nvim";
}
