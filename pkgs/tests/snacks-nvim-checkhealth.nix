{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [ lazy-nvim-nix.plugins."snacks.nvim".spec ];
    inherit (lazy-nvim-nix.plugins."snacks.nvim") extraPackages;
  };
  pluginName = "snacks";
  loadLazyPluginName = "snacks.nvim";
  ignoreLines = [
    # FIXME: Look into these errors, some may be fixable
    "ERROR is not ready"
    "WARNING Image rendering in docs with missing treesitter parsers won't work"
    "WARNING Missing Treesitter languages"
    "WARNING The `latex` treesitter parser is required to render LaTeX math expressions"
    "WARNING setup {disabled}"
    "WARNING {which-key} is not installed"
  ];
}
