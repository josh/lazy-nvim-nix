{
  callPackage,
  lazy-nvim-nix,
}:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [ lazy-nvim-nix.plugins."mason.nvim".spec ];
    inherit (lazy-nvim-nix.plugins."mason.nvim") extraPackages;
  };
  pluginName = "mason";
  loadLazyPluginName = "mason.nvim";
  ignoreLines = [
    # OK: julia is intentionally not shipped; its closure is too large
    "WARNING julia: not available"
  ];
}
