{
  lib,
  stdenv,
  writeText,
  runCommand,
  glibcLocales,
  hello,
  lazy-nvim-nix,
}:
let
  inherit (lazy-nvim-nix) plugins;
  lib' = lazy-nvim-nix.lib;
  neovim = lazy-nvim-nix.LazyVim.override {
    customLuaRC = ''
      vim.g.rc_before_setup = package.loaded["lazy"] == nil
      vim.keymap.set("n", "<Space>zz", function() end, { desc = "rc-mapping" })
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimKeymaps",
        callback = function()
          vim.keymap.set("n", "<leader>l", function() end, { desc = "rc-override" })
        end,
      })
    '';
    extras = [ "lazyvim.plugins.extras.coding.mini-surround" ];
    extraSpec = [
      (plugins."dial.nvim".spec // { lazy = false; })
      (plugins."persistence.nvim".spec // { enabled = false; })
      (
        plugins."trouble.nvim".spec
        // {
          opts = {
            use_diagnostic_signs = true;
          };
        }
      )
      (
        plugins."LazyVim".spec
        // {
          opts = {
            colorscheme = "catppuccin";
          };
        }
      )
      (
        plugins."grug-far.nvim".spec
        // {
          keys = [
            [
              "<leader>sr"
              false
            ]
          ];
        }
      )
      (
        plugins."nvim-lspconfig".spec
        // {
          opts = {
            servers = {
              lua_ls = {
                mason = false;
                settings = {
                  Lua = {
                    hint = {
                      enable = true;
                    };
                  };
                };
              };
              jsonls = {
                settings = {
                  json = {
                    validate = {
                      enable = true;
                    };
                  };
                };
              };
            };
          };
        }
      )
      (
        plugins."gitsigns.nvim".spec
        // {
          opts = lib'.mkLuaInline ''
            function(_, opts)
              opts.rc_sentinel = true
              return opts
            end'';
        }
      )
    ];
    extraPackages = [ hello ];
    opts = {
      ui = {
        border = "double";
      };
    };
  };
  vim-script-runner = writeText "lazyvim-config-hooks.vim" ''
    doautocmd UIEnter
    lua vim.wait(3000, function() return vim.g.did_very_lazy == true end, 50)
    lua if vim.g.rc_before_setup ~= true then io.stderr:write("customLuaRC did not run before setup\n") vim.cmd("cquit!") end
    lua local ms = require("lazy.core.config").plugins["mini.surround"] if ms == nil or not (ms.dir or ""):find("^/nix/store/") then io.stderr:write("extras entry not store-wired\n") vim.cmd("cquit!") end
    lua local dl = require("lazy.core.config").plugins["dial.nvim"] if dl == nil or not (dl.dir or ""):find("^/nix/store/") then io.stderr:write("extraSpec entry not store-wired\n") vim.cmd("cquit!") end
    lua if require("lazy.core.config").plugins["persistence.nvim"] ~= nil then io.stderr:write("enabled = false fragment ignored\n") vim.cmd("cquit!") end
    lua if vim.fn.executable("hello") ~= 1 then io.stderr:write("extraPackages not on PATH\n") vim.cmd("cquit!") end
    lua if require("lazy.core.config").options.ui.border ~= "double" then io.stderr:write("opts not merged\n") vim.cmd("cquit!") end
    lua local tr = require("lazy.core.plugin").values(require("lazy.core.config").plugins["trouble.nvim"], "opts", false) if tr.use_diagnostic_signs ~= true then io.stderr:write("extraSpec opts not merged into bundled plugin\n") vim.cmd("cquit!") end if (((tr.modes or {}).lsp or {}).win or {}).position ~= "right" then io.stderr:write("LazyVim default opts lost in merge\n") vim.cmd("cquit!") end
    lua if not (vim.g.colors_name or ""):find("^catppuccin") then io.stderr:write("colorscheme opt not applied, got " .. tostring(vim.g.colors_name) .. "\n") vim.cmd("cquit!") end
    lua if require("lazy.core.config").plugins["catppuccin"]._.loaded == nil then io.stderr:write("catppuccin plugin did not load for its colorscheme\n") vim.cmd("cquit!") end
    lua if vim.fn.maparg("<Space>zz", "n") == "" then io.stderr:write("customLuaRC mapping missing\n") vim.cmd("cquit!") end
    lua local m = vim.fn.maparg("<Space>l", "n", false, true) if m.desc ~= "rc-override" then io.stderr:write("LazyVimKeymaps override lost, desc=" .. tostring(m.desc) .. "\n") vim.cmd("cquit!") end
    lua if vim.fn.maparg("<Space>sr", "n") ~= "" then io.stderr:write("keys disable entry ignored\n") vim.cmd("cquit!") end
    edit t.lua
    lua vim.wait(2000, function() return package.loaded["lspconfig"] ~= nil or (vim.lsp.config["lua_ls"] or {}).settings ~= nil end, 50)
    lua local c = vim.lsp.config["lua_ls"] if not c or (((c.settings or {}).Lua or {}).hint or {}).enable ~= true then io.stderr:write("servers opts not applied to vim.lsp.config\n") vim.cmd("cquit!") end
    lua if not vim.lsp.is_enabled("lua_ls") then io.stderr:write("lua_ls with mason=false not enabled\n") vim.cmd("cquit!") end
    lua if not vim.lsp.is_enabled("jsonls") then io.stderr:write("mason-known jsonls no longer auto-enabled; README LSP guidance needs revisiting\n") vim.cmd("cquit!") end
    lua local j = vim.lsp.config["jsonls"] if not j or (((j.settings or {}).json or {}).validate or {}).enable ~= true then io.stderr:write("jsonls settings not applied\n") vim.cmd("cquit!") end
    lua local gs = require("lazy.core.plugin").values(require("lazy.core.config").plugins["gitsigns.nvim"], "opts", false) if gs.rc_sentinel ~= true then io.stderr:write("opts function fragment not applied\n") vim.cmd("cquit!") end if ((gs.signs or {}).add or {}).text == nil then io.stderr:write("gitsigns default opts lost\n") vim.cmd("cquit!") end
    qall!
  '';
in
runCommand "lazyvim-config-hooks"
  {
    __structuredAttrs = true;

    neovimBin = lib.getExe neovim;
    nvimArgs = [
      "--headless"
      "-i"
      "NONE"
      "-S"
      "${vim-script-runner}"
    ];

    env = {
      DISPLAY = lib.optionalString stdenv.hostPlatform.isLinux ":0";
      LOCALE_ARCHIVE = lib.optionalString stdenv.hostPlatform.isLinux "${glibcLocales}/lib/locale/locale-archive";
      LANG = "en_US.UTF-8";
    };
  }
  ''
    mkdir -p .config/nvim
    touch .config/nvim/init.lua

    exit_code=0
    HOME="$PWD" timeout --kill-after=10s 120s "$neovimBin" "''${nvimArgs[@]}" 1>out.txt 2>err.txt || exit_code=$?

    echo "== stdout =="
    cat out.txt
    echo "== stderr =="
    cat err.txt
    echo "=="

    if [ "$exit_code" -eq 124 ] || [ "$exit_code" -eq 137 ]; then
      echo "Test timed out (exit $exit_code)"
      exit 1
    elif [ "$exit_code" -ne 0 ]; then
      echo "Neovim exited with code $exit_code"
      exit 1
    elif grep "^E[0-9]\+: " err.txt; then
      exit 1
    fi

    touch $out
  ''
