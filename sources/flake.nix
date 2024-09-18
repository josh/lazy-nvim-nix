# Renovate bug
# https://github.com/renovatebot/renovate/issues/29721
# "github:NixOS/nixpkgs/nixpkgs-unstable"
{
  inputs = {
    "bufferline.nvim" = {
      url = "github:akinsho/bufferline.nvim";
      flake = false;
    };
    "catppuccin" = {
      url = "github:catppuccin/nvim";
      flake = false;
    };
    "lazy.nvim" = {
      url = "github:folke/lazy.nvim";
      flake = false;
    };
    "LazyVim" = {
      url = "github:LazyVim/LazyVim";
      flake = false;
    };
    "lualine.nvim" = {
      url = "github:nvim-lualine/lualine.nvim";
      flake = false;
    };
  };

  outputs = _inputs: { };
}
