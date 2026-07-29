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
    "WARNING {cargo}:"
    "WARNING {devenv}:"
    "WARNING {mage}:"
    "WARNING {mise}:"
    "WARNING {cargo-make}:"
    "WARNING {composer}:"
    "WARNING {deno}:"
    "WARNING {just}:"
    "WARNING {mix}:"
    "WARNING {npm}:"
    "WARNING {rake}:"
    "WARNING {task}:"
    "WARNING {tox}:"
    "WARNING {vscode}:"
    "WARNING {make}:"
  ];
}
