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
    # FIXME: Add pip back to mason.nvim extraPackages
    "WARNING pip: not available"
    "WARNING julia: not available"
  ];
}
