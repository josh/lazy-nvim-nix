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
  stderrIgnoreLines = [
    # OK: the sandbox has no GitHub credentials; gh prints these while octo
    # health probes auth status and project scopes, and nvim reports the
    # scope error with a script-location header on some platforms
    "You are not logged into any GitHub hosts."
    "Cannot request Projects v2: Missing scope"
    ".vim:line"
  ];
}
