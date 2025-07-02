{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [ lazy-nvim-nix.plugins."fzf-lua".spec ];
    inherit (lazy-nvim-nix.plugins."fzf-lua") extraPackages;
  };
  pluginName = "fzf_lua";
  loadLazyPluginName = "fzf-lua";
  ignoreLines = [
    # FIXME: I added mini.icons to spec dependencies, not sure why
    "WARNING `nvim-web-devicons` or `mini.icons` not found"
  ];
}
