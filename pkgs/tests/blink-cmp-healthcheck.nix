{
  callPackage,
  lazy-nvim,
  lazynvimPlugins,
}:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim.override {
    spec = [ lazynvimPlugins."blink.cmp".spec ];
    inherit (lazynvimPlugins."blink.cmp") extraPackages;
  };
  pluginName = "blink.cmp";
  loadLazyPluginName = "blink.cmp";
  ignoreLines = [
    # OK: Not fixable, this warning is always shown
    "WARNING Some providers may show up as \"disabled\" but are enabled dynamically"
  ];
}
