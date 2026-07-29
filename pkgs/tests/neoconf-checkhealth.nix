{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.LazyVim.override {
    extras = [ "lazyvim.plugins.extras.lsp.neoconf" ];
  };
  pluginName = "neoconf";
  loadLazyPluginName = "neoconf.nvim";
  ignoreLines = [
    # OK: no jsonc grammar exists in nixpkgs or nvim-treesitter
    "WARNING **jsonc** parser for tree-sitter is not installed. Jsonc highlighting might be broken"
    # OK: lspconfig servers register on LspAttach, which never fires headless
    "WARNING **lspconfig jsonls** is not installed? You won't get any auto completion in your settings files"
    "WARNING **lspconfig lua_ls** is not installed? You won't get any auto completion in your lua settings files"
  ];
}
