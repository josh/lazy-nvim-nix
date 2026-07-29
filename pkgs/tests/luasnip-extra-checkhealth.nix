{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.LazyVim.override {
    extras = [ "lazyvim.plugins.extras.coding.luasnip" ];
    extraLuaPackages = ps: [ ps.jsregexp ];
  };
  pluginName = "luasnip";
  loadLazyPluginName = "LuaSnip";
}
