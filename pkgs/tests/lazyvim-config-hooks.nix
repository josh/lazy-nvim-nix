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
  neovim = lazy-nvim-nix.LazyVim.override {
    customLuaRC = ''
      vim.g.rc_before_setup = package.loaded["lazy"] == nil
    '';
    extras = [ "lazyvim.plugins.extras.coding.mini-surround" ];
    extraSpec = [
      (plugins."dial.nvim".spec // { lazy = false; })
      (plugins."persistence.nvim".spec // { enabled = false; })
    ];
    extraPackages = [ hello ];
    opts = {
      ui = {
        border = "double";
      };
    };
  };
  vim-script-runner = writeText "lazyvim-config-hooks.vim" ''
    lua if vim.g.rc_before_setup ~= true then io.stderr:write("customLuaRC did not run before setup\n") vim.cmd("cquit!") end
    lua if require("lazy.core.config").plugins["mini.surround"] == nil then io.stderr:write("extras entry not wired\n") vim.cmd("cquit!") end
    lua if require("lazy.core.config").plugins["dial.nvim"] == nil then io.stderr:write("extraSpec entry not wired\n") vim.cmd("cquit!") end
    lua if require("lazy.core.config").plugins["persistence.nvim"] ~= nil then io.stderr:write("enabled = false fragment ignored\n") vim.cmd("cquit!") end
    lua if vim.fn.executable("hello") ~= 1 then io.stderr:write("extraPackages not on PATH\n") vim.cmd("cquit!") end
    lua if require("lazy.core.config").options.ui.border ~= "double" then io.stderr:write("opts not merged\n") vim.cmd("cquit!") end
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
