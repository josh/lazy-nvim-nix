{
  lib,
  stdenv,
  writeText,
  runCommand,
  neovim-unwrapped,
  glibcLocales,
  lazy-nvim-nix,
}:
let
  inherit (lazy-nvim-nix) lazy-nvim-config plugins;
  config = lazy-nvim-config.override {
    customLuaRC = ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = "\\"
    '';

    # https://lazy.folke.io/spec/examples
    spec = [
      (
        plugins."tokyonight.nvim".spec
        // {
          lazy = false;
          priority = 1000;
          config = lib.generators.mkLuaInline ''
            function()
              vim.cmd([[colorscheme tokyonight]])
            end
          '';
        }
      )
      (plugins."which-key.nvim".spec // { lazy = true; })
      (
        plugins."neorg".spec
        // {
          ft = "norg";
          opts = {
            load = {
              "core.defaults" = { };
            };
          };
          dependencies = [
            plugins."lua-utils.nvim".spec
            plugins."nui.nvim".spec
            plugins."nvim-nio".spec
            plugins."pathlib.nvim".spec
            plugins."tree-sitter-norg".spec
            plugins."tree-sitter-norg-meta".spec
          ];
        }
      )
    ];

    opts = {
      install = {
        colorscheme = [ "habamax" ];
      };
    };
  };
  vim-script-runner = writeText "lazy-nvim-config-example.vim" ''
    lua if not (vim.g.colors_name or ""):find("^tokyonight") then io.stderr:write("colorscheme not applied\n") vim.cmd("cquit!") end
    lua if require("lazy.core.config").plugins["which-key.nvim"] == nil then io.stderr:write("which-key.nvim not in plugin list\n") vim.cmd("cquit!") end
    lua if require("lazy.core.config").plugins["neorg"] == nil then io.stderr:write("neorg not in plugin list\n") vim.cmd("cquit!") end
    qall!
  '';
in
runCommand "lazy-nvim-config-example"
  {
    __structuredAttrs = true;

    neovimBin = lib.getExe neovim-unwrapped;
    nvimArgs = [
      "--headless"
      "-i"
      "NONE"
      "-u"
      "${config}"
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
