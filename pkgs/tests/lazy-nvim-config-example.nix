{
  lib,
  runCommand,
  lazy-nvim-nix,
}:
let
  inherit (lazy-nvim-nix) lazy-nvim-config;
  config = lazy-nvim-config.override {
    customLuaRC = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = "\\"
    '';

    # https://lazy.folke.io/spec/examples
    spec = [
      {
        url = "folke/tokyonight.nvim";
        lazy = false;
        priority = 1000;
        config = lib.generators.mkLuaInline ''
          function()
            -- load the colorscheme here
            vim.cmd([[colorscheme tokyonight]])
          end
        '';
      }
      {
        url = "folke/which-key.nvim";
        lazy = true;
      }
      {
        url = "nvim-neorg/neorg";
        ft = "norg";
        opts = {
          load = {
            "core.defaults" = { };
          };
        };
      }
    ];

    opts = {
      install = {
        colorscheme = [ "habamax" ];
      };
      checker = {
        enabled = true;
      };
    };
  };
in
runCommand "lazy-nvim-config-example" {
  CONFIG = config;
} "touch $out"
