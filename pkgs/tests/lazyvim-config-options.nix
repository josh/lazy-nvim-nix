{
  lib,
  stdenv,
  writeText,
  runCommand,
  glibcLocales,
  lazy-nvim-nix,
}:
let
  inherit (lazy-nvim-nix) plugins;
  lib' = lazy-nvim-nix.lib;
  neovim = lazy-nvim-nix.LazyVim.override {
    globals = {
      autoformat = false;
      snacks_animate = false;
      root_spec = [ "cwd" ];
      opt = {
        relativenumber = false;
      };
    };
    customLuaRC = ''
      vim.g.trouble_lualine = false
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimKeymaps",
        callback = function()
          vim.keymap.del("n", "<leader>ur")
        end,
      })
    '';
    extraSpec = [
      (
        plugins."LazyVim".spec
        // {
          opts = {
            colorscheme = "catppuccin";
          };
        }
      )
      (
        plugins."catppuccin".spec
        // {
          opts = {
            transparent_background = true;
          };
        }
      )
      (
        plugins."tokyonight.nvim".spec
        // {
          opts = {
            style = "day";
          };
        }
      )
      (
        plugins."flash.nvim".spec
        // {
          keys = lib'.mkLuaInline "function() return {} end";
        }
      )
      (
        plugins."nvim-treesitter".spec
        // {
          opts = lib'.mkLuaInline ''
            function(_, opts)
              opts.ensure_installed = opts.ensure_installed or {}
              table.insert(opts.ensure_installed, "zig")
            end'';
        }
      )
      (
        plugins."blink.cmp".spec
        // {
          opts = {
            keymap = {
              preset = "super-tab";
            };
          };
        }
      )
      (
        plugins."lualine.nvim".spec
        // {
          opts = lib'.mkLuaInline ''
            function(_, opts)
              table.insert(opts.sections.lualine_x, function()
                return "RCSENTINEL"
              end)
            end'';
        }
      )
    ];
    opts = {
      performance = {
        rtp = {
          disabled_plugins = [
            "netrwPlugin"
            "tutor"
          ];
        };
      };
    };
  };
  vim-script-runner = writeText "lazyvim-config-options.vim" ''
    doautocmd UIEnter
    lua vim.wait(3000, function() return vim.g.did_very_lazy == true end, 50)
    lua if vim.g.trouble_lualine ~= true then io.stderr:write("expected naive customLuaRC global to be clobbered by LazyVim options\n") vim.cmd("cquit!") end
    lua if LazyVim.format.enabled() ~= false then io.stderr:write("globals.autoformat=false not effective\n") vim.cmd("cquit!") end
    lua if vim.g.snacks_animate ~= false then io.stderr:write("globals.snacks_animate=false not effective\n") vim.cmd("cquit!") end
    lua if vim.opt.relativenumber:get() ~= false then io.stderr:write("globals.opt.relativenumber=false not effective\n") vim.cmd("cquit!") end
    lua if LazyVim.root() ~= vim.uv.cwd() then io.stderr:write("globals.root_spec not effective, root=" .. tostring(LazyVim.root()) .. "\n") vim.cmd("cquit!") end
    lua if vim.fn.exists(":Explore") ~= 0 or vim.fn.exists(":Tutor") ~= 0 then io.stderr:write("performance.rtp.disabled_plugins ignored\n") vim.cmd("cquit!") end
    lua if vim.fn.maparg("<Space>ur", "n") ~= "" then io.stderr:write("core keymap not deleted in LazyVimKeymaps hook\n") vim.cmd("cquit!") end
    lua if vim.fn.maparg("s", "n") ~= "" or vim.fn.maparg("S", "n") ~= "" then io.stderr:write("flash keys function did not clear plugin keymaps\n") vim.cmd("cquit!") end
    lua if vim.g.colors_name ~= "catppuccin" then io.stderr:write("colorscheme not applied\n") vim.cmd("cquit!") end
    lua require("tokyonight") if require("lazy.core.config").plugins["tokyonight.nvim"]._.loaded == nil then io.stderr:write("require did not auto-load tokyonight from the store dir\n") vim.cmd("cquit!") end
    lua if require("tokyonight.config").options.style ~= "day" then io.stderr:write("tokyonight opts not applied through auto-load, style=" .. tostring(require("tokyonight.config").options.style) .. "\n") vim.cmd("cquit!") end
    lua require("trouble") if require("lazy.core.config").plugins["trouble.nvim"]._.loaded == nil then io.stderr:write("require did not auto-load trouble from the store dir\n") vim.cmd("cquit!") end
    lua local cv = require("lazy.core.plugin").values(require("lazy.core.config").plugins["catppuccin"], "opts", false) if cv.transparent_background ~= true then io.stderr:write("colorscheme opts fragment not merged\n") vim.cmd("cquit!") end
    lua local o = require("lazy.core.plugin").values(require("lazy.core.config").plugins["nvim-treesitter"], "opts", false) if not (o.install_dir or ""):find("^/nix/store/") then io.stderr:write("install_dir lost through opts fragment\n") vim.cmd("cquit!") end if not vim.tbl_contains(o.ensure_installed or {}, "zig") then io.stderr:write("ensure_installed not extended\n") vim.cmd("cquit!") end
    Lazy! load blink.cmp
    lua if require("blink.cmp.config").keymap.preset ~= "super-tab" then io.stderr:write("blink keymap preset not applied\n") vim.cmd("cquit!") end
    lua local found = false for _, c in ipairs(require("lualine").get_config().sections.lualine_x) do if type(c) == "function" then local ok, v = pcall(c) if ok and v == "RCSENTINEL" then found = true end end end if not found then io.stderr:write("lualine opts function not composed\n") vim.cmd("cquit!") end
    qall!
  '';
in
runCommand "lazyvim-config-options"
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
