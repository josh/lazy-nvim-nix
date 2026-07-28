{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [
      (
        lazy-nvim-nix.plugins."noice.nvim".spec
        // {
          dependencies = [ lazy-nvim-nix.plugins."snacks.nvim".spec ];
        }
      )
      {
        name = "nvim-treesitter-parsers";
        dir = "${lazy-nvim-nix.plugins."nvim-treesitter".installDir}";
        lazy = false;
      }
    ];
  };
  pluginName = "noice";
  loadLazyPluginName = "noice.nvim";
}
