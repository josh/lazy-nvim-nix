{
  callPackage,
  lazy-nvim,
  lazynvimPlugins,
}:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim.override {
    spec = [ lazynvimPlugins."snacks.nvim".spec ];
    inherit (lazynvimPlugins."snacks.nvim") extraPackages;
  };
  pluginName = "snacks";
  loadLazyPluginName = "snacks.nvim";
  ignoreLines = [
    # FIXME: Look into these errors, some may be fixable
    "ERROR is not ready"
    "ERROR {lazygit} not installed"
    "WARNING Image rendering in docs with missing treesitter parsers won't work"
    "WARNING Missing Treesitter languages"
    "WARNING The `latex` treesitter parser is required to render LaTeX math expressions"
    "WARNING setup {disabled}"
    "WARNING {which-key} is not installed"
  ];
}
