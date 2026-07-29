{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.LazyVim.override {
    extras = [ "lazyvim.plugins.extras.lsp.neoconf" ];
  };
  pluginName = "neoconf";
  loadLazyPluginName = "neoconf.nvim";
  ignoreLines = [
    # OK: neoconf reads the legacy lspconfig.util.available_servers table, which
    # stays empty because LazyVim configures servers through vim.lsp.config
    "WARNING **lspconfig jsonls** is not installed? You won't get any auto completion in your settings files"
    "WARNING **lspconfig lua_ls** is not installed? You won't get any auto completion in your lua settings files"
  ];
}
