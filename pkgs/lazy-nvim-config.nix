{
  lib,
  writeTextFile,
  lazynvimPlugins,
  lazynvimUtils,
  luaRcContent ? "",
  spec ? [ ],
  opts ? { },
  lazy-nvim-config,
}:
writeTextFile {
  name = "lazy-nvim-init.lua";
  text = ''
    vim.opt.rtp:prepend("${lazynvimPlugins."lazy.nvim"}");

    ${luaRcContent}
    require("lazy").setup(${lazynvimUtils.toLua spec}, ${
      lazynvimUtils.toLua (lazynvimUtils.defaultLazyOpts // opts)
    })
  '';
}
// {
  passthru.tests = {
    example = lazy-nvim-config.override {
      luaRcContent = ''
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
  };
}
