{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [ lazy-nvim-nix.plugins."LuaSnip".spec ];
    extraLuaPackages = ps: [ ps.jsregexp ];
  };
  pluginName = "luasnip";
  loadLazyPluginName = "LuaSnip";
}
