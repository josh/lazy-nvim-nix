{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [
      (
        lazy-nvim-nix.plugins."telescope.nvim".spec
        // {
          dependencies = [ lazy-nvim-nix.plugins."plenary.nvim".spec ];
        }
      )
    ];
  };
  pluginName = "telescope";
  loadLazyPluginName = "telescope.nvim";
}
