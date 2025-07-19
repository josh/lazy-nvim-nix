{
  lib,
  callPackage,
  stdenv,
  lazy-nvim-nix,
  julia,
}:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [ lazy-nvim-nix.plugins."mason.nvim".spec ];
    inherit (lazy-nvim-nix.plugins."mason.nvim") extraPackages;
  };
  pluginName = "mason";
  loadLazyPluginName = "mason.nvim";
  ignoreLines = [
    # OK: Nix build sandbox will always prevent access to github API
    "WARNING Failed to check GitHub API rate limit status"
  ]
  ++ (lib.lists.optional (
    !lib.meta.availableOn stdenv.hostPlatform julia
  ) "WARNING julia: not available");
}
