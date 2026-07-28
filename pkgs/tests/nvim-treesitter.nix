{ callPackage, lazy-nvim-nix }:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [ lazy-nvim-nix.plugins."nvim-treesitter".spec ];
    inherit (lazy-nvim-nix.plugins."nvim-treesitter") extraPackages;
  };
  pluginName = "nvim-treesitter";
  ignoreLines = [
    # OK: install_dir is the read-only nix store
    "ERROR is not writable."
    # FIXME: nixpkgs packages no ecma/jsx/html_tags component grammars
    "ERROR html(queries):"
    "ERROR javascript(queries):"
    "ERROR svelte(queries):"
    "ERROR tsx(queries):"
    "ERROR typescript(queries):"
    "ERROR vue(queries):"
    # FIXME: nixpkgs diff grammar lags its highlights query
    "ERROR diff(highlights):"
  ];
}
