{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [
      (
        lazy-nvim-nix.plugins."snacks.nvim".spec
        // {
          dependencies = [ (lazy-nvim-nix.plugins."which-key.nvim".spec // { opts = { }; }) ];
          opts = (lazy-nvim-nix.plugins."snacks.nvim".spec.opts or { }) // {
            notifier.enabled = true;
          };
        }
      )
      {
        name = "nvim-treesitter-parsers";
        dir = "${lazy-nvim-nix.plugins."nvim-treesitter".installDir}";
        lazy = false;
      }
    ];
    inherit (lazy-nvim-nix.plugins."snacks.nvim") extraPackages;
  };
  pluginName = "snacks";
  loadLazyPluginName = "snacks.nvim";
  ignoreLines = [
    # OK: snacks sub-features intentionally not enabled by this config
    "WARNING setup {disabled}"
  ];
}
