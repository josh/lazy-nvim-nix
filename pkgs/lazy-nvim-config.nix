{
  lib,
  callPackage,
  runCommand,
  writeTextFile,
  lazynvimPlugins,
  lazynvimUtils,
  customLuaRC ? "",
  spec ? [ ],
  opts ? { },
}:
writeTextFile {
  name = "lazy-nvim-init.lua";
  text = ''
    vim.opt.rtp:prepend("${lazynvimPlugins."lazy.nvim"}");

    ${customLuaRC}
    require("lazy").setup(${lazynvimUtils.toLua spec}, ${
      lazynvimUtils.toLua (lazynvimUtils.defaultLazyOpts // opts)
    })
  '';

  passthru.tests =
    let
      example = callPackage ./lazy-nvim-config.nix {
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
    {
      example = runCommand "lazy-nvim-config-example" {
        CONFIG = example;
      } "touch $out";
    };
}
