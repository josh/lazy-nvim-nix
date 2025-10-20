{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [ lazy-nvim-nix.plugins."nvim-treesitter".spec ];
    inherit (lazy-nvim-nix.plugins."nvim-treesitter") extraPackages;
  };
  pluginName = "nvim-treesitter";
}
