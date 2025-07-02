{
  callPackage,
  lazy-nvim,
  lazynvimPlugins,
}:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim.override {
    spec = [ lazynvimPlugins."fzf-lua".spec ];
    inherit (lazynvimPlugins."fzf-lua") extraPackages;
  };
  pluginName = "fzf_lua";
  loadLazyPluginName = "fzf-lua";
  ignoreLines = [
    # FIXME: I added mini.icons to spec dependencies, not sure why
    "WARNING `nvim-web-devicons` or `mini.icons` not found"
  ];
}
