{
  callPackage,
  lazy-nvim-nix,
  python312Packages,
}:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.LazyVim.override {
    extras = [ "lazyvim.plugins.extras.lang.markdown" ];
    extraPackages = [ python312Packages.pylatexenc ];
  };
  pluginName = "render-markdown";
  loadLazyPluginName = "render-markdown.nvim";
}
