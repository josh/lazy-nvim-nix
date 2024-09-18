# Renovate bug
# https://github.com/renovatebot/renovate/issues/29721
# "github:NixOS/nixpkgs/nixpkgs-unstable"
{
  inputs = {
    "bufferline.nvim".flake = false;
    "bufferline.nvim".url = "github:akinsho/bufferline.nvim/main";
    "catppuccin".flake = false;
    "catppuccin".url = "github:catppuccin/nvim/main";
    "lazy.nvim".flake = false;
    "lazy.nvim".url = "github:folke/lazy.nvim/main";
    "LazyVim".flake = false;
    "LazyVim".url = "github:LazyVim/LazyVim/main";
    "lualine.nvim".flake = false;
    "lualine.nvim".url = "github:nvim-lualine/lualine.nvim/master";
  };

  outputs = _inputs: { };
}
