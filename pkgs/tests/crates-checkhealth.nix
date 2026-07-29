{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.LazyVim.override {
    extras = [ "lazyvim.plugins.extras.lang.rust" ];
  };
  pluginName = "crates";
  loadLazyPluginName = "crates.nvim";
}
