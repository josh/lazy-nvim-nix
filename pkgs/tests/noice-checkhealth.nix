{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [
      (
        lazy-nvim-nix.plugins."noice.nvim".spec
        // {
          dependencies = [ lazy-nvim-nix.plugins."snacks.nvim".spec ];
        }
      )
    ];
  };
  pluginName = "noice";
  loadLazyPluginName = "noice.nvim";
  ignoreLines = [
    # FIXME: These should be fixable if we install treesitter correctly
    "WARNING {TreeSitter} `bash` parser is not installed"
    "WARNING {TreeSitter} `regex` parser is not installed"
  ];
}
