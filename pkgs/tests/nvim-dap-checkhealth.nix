{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [ lazy-nvim-nix.plugins."nvim-dap".spec ];
  };
  pluginName = "dap";
  loadLazyPluginName = "nvim-dap";
}
