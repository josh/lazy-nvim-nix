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
    "ERROR None of the tools found: 'tectonic', 'pdflatex'"
    "ERROR is not ready"
    "WARNING Image rendering in docs with missing treesitter parsers won't work"
    "WARNING Missing Treesitter languages"
    "WARNING `tectonic` or `pdflatex` is required to render LaTeX math expressions"
    "WARNING setup {disabled}"
    "WARNING {which-key} is not installed"
  ];
}
