{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.LazyVim.override {
    extras = [ "lazyvim.plugins.extras.lsp.none-ls" ];
  };
  pluginName = "null-ls";
  loadLazyPluginName = "none-ls.nvim";
}
