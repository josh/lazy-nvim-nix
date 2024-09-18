# Renovate bug
# https://github.com/renovatebot/renovate/issues/29721
# "github:NixOS/nixpkgs/nixpkgs-unstable"
{
  inputs = {
    "bufferline.nvim".flake = false;
    "bufferline.nvim".url = "github:akinsho/bufferline.nvim";
    "catppuccin".flake = false;
    "catppuccin".url = "github:catppuccin/nvim";
    "lazy.nvim".flake = false;
    "lazy.nvim".url = "github:folke/lazy.nvim";
    "LazyVim".flake = false;
    "LazyVim".url = "github:LazyVim/LazyVim";
    "lualine.nvim".flake = false;
    "lualine.nvim".url = "github:nvim-lualine/lualine.nvim";
  };

  outputs = _inputs: { };
}
