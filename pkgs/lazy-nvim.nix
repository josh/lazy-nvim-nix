{
  wrapNeovimUnstable,
  neovim-unwrapped,
  lazynvimUtils,
  pkgs,
  spec ? [ ],
  extraPackages ? [ ],
}:
wrapNeovimUnstable neovim-unwrapped (
  lazynvimUtils.makeLazyNeovimConfig {
    inherit pkgs spec extraPackages;
  }
)
