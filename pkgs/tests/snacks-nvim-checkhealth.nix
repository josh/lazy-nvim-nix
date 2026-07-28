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
    # OK: headless nvim has no TTY to answer the kitty graphics query
    "ERROR your terminal does not support the kitty graphics protocol"
    # OK: snacks sub-features intentionally not enabled by this config
    "WARNING setup {disabled}"
    # OK: only `norg` is missing, no nixpkgs grammar
    "WARNING Missing Treesitter languages"
    "WARNING Image rendering in docs with missing treesitter parsers won't work"
  ];
}
