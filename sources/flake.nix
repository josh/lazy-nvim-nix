# Renovate bug
# https://github.com/renovatebot/renovate/issues/29721
# "github:NixOS/nixpkgs/nixpkgs-unstable"
{
  inputs = {
    "lazy.nvim" = {
      url = "github:folke/lazy.nvim";
      flake = false;
    };
    LazyVim = {
      url = "github:LazyVim/LazyVim";
      flake = false;
    };
  };

  outputs = _inputs: { };
}
