{
  callPackage,
  lazy-nvim-nix,
  rust-analyzer,
}:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.LazyVim.override {
    extras = [
      "lazyvim.plugins.extras.dap.core"
      "lazyvim.plugins.extras.lang.rust"
    ];
    extraPackages = [ rust-analyzer ];
    customLuaRC = ''
      vim.system({ "rust-analyzer", "--version" }):wait()
    '';
  };
  pluginName = "rustaceanvim";
  loadLazyPluginName = "rustaceanvim";
}
