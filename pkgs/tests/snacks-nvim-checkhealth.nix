{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [
      (
        lazy-nvim-nix.plugins."snacks.nvim".spec
        // {
          dependencies = [ (lazy-nvim-nix.plugins."which-key.nvim".spec // { opts = { }; }) ];
        }
      )
    ];
    inherit (lazy-nvim-nix.plugins."snacks.nvim") extraPackages;
  };
  pluginName = "snacks";
  loadLazyPluginName = "snacks.nvim";
  ignoreLines = [
    # OK: headless nvim has no TTY to answer the kitty graphics query
    "ERROR is not ready"
    "ERROR your terminal does not support the kitty graphics protocol"
    # OK: snacks sub-features intentionally not enabled by this config
    "WARNING setup {disabled}"
    # FIXME: These should be fixable if we install treesitter correctly
    "WARNING Image rendering in docs with missing treesitter parsers won't work"
    "WARNING Missing Treesitter languages"
    "WARNING The `latex` treesitter parser is required to render LaTeX math expressions"
  ];
}
