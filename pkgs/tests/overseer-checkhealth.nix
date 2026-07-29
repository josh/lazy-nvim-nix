{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.LazyVim.override {
    extras = [ "lazyvim.plugins.extras.editor.overseer" ];
  };
  pluginName = "overseer";
  loadLazyPluginName = "overseer.nvim";
  checkOk = false;
  ignoreLines = [
    # OK: workspace and toolchain probes; the sandbox has no project open and
    # ships none of the optional task runners
    "WARNING {"
  ];
}
