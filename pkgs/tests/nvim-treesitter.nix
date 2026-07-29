{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [ lazy-nvim-nix.plugins."nvim-treesitter".spec ];
    inherit (lazy-nvim-nix.plugins."nvim-treesitter") extraPackages;
  };
  pluginName = "nvim-treesitter";
  ignoreLines = [
    # OK: install_dir is the read-only nix store
    "nvim-treesitter|ERROR is not writable."
  ];
}
