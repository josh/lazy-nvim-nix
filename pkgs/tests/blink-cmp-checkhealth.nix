{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [ lazy-nvim-nix.plugins."blink.cmp".spec ];
    inherit (lazy-nvim-nix.plugins."blink.cmp") extraPackages;
  };
  pluginName = "blink.cmp";
  loadLazyPluginName = "blink.cmp";
  ignoreLines = [
    # OK: Not fixable, this warning is always shown
    "WARNING Some providers may show up as \"disabled\" but are enabled dynamically"
  ];
}
