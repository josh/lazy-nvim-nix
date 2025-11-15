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
    # FIXME: mason not finding pip3 in $PATH for some reason
    "WARNING pip: not available"
  ]
  ++ lib.lists.optional (
    !lib.meta.availableOn stdenv.hostPlatform julia
  ) "WARNING julia: not available";
}
