{
  callPackage,
  lazy-nvim-nix,
  gh,
}:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.LazyVim.override {
    extras = [ "lazyvim.plugins.extras.util.octo" ];
    extraPackages = [ gh ];
  };
  pluginName = "octo";
  loadLazyPluginName = "octo.nvim";
  ignoreLines = [
    # OK: the sandbox has no GitHub credentials, so gh auth status must fail
    "ERROR Error running `gh auth status`"
  ];
}
