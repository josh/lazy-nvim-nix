{
  lib,
  callPackage,
  stdenv,
  lazy-nvim,
  lazynvimPlugins,
  julia,
}:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim.override {
    spec = [ lazynvimPlugins."mason.nvim".spec ];
    inherit (lazynvimPlugins."mason.nvim") extraPackages;
  };
  pluginName = "mason";
  loadLazyPluginName = "mason.nvim";
  ignoreLines =
    [
      # OK: Nix build sandbox will always prevent access to github API
      "WARNING Failed to check GitHub API rate limit status"
    ]
    ++ (lib.lists.optional (
      !lib.meta.availableOn stdenv.hostPlatform julia
    ) "WARNING julia: not available");
}
