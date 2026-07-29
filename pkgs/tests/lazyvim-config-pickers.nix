{
  lib,
  stdenv,
  writeText,
  runCommand,
  glibcLocales,
  lazy-nvim-nix,
}:
let
  neovim = lazy-nvim-nix.LazyVim.override {
    customLuaRC = ''
      vim.g.lazyvim_picker = "telescope"
      vim.g.lazyvim_cmp = "nvim-cmp"
    '';
    extras = [
      "lazyvim.plugins.extras.coding.nvim-cmp"
      "lazyvim.plugins.extras.editor.telescope"
    ];
  };
  vim-script-runner = writeText "lazyvim-config-pickers.vim" ''
    doautocmd UIEnter
    lua vim.wait(3000, function() return vim.g.did_very_lazy == true end, 50)
    lua if not LazyVim.pick.picker or LazyVim.pick.picker.name ~= "telescope" then io.stderr:write("picker is " .. tostring(LazyVim.pick.picker and LazyVim.pick.picker.name) .. ", expected telescope\n") vim.cmd("cquit!") end
    lua local ts = require("lazy.core.config").plugins["telescope.nvim"] if ts == nil or not (ts.dir or ""):find("^/nix/store/") then io.stderr:write("telescope.nvim not store-wired\n") vim.cmd("cquit!") end
    lua local cmp = require("lazy.core.config").plugins["nvim-cmp"] if cmp == nil or not (cmp.dir or ""):find("^/nix/store/") then io.stderr:write("nvim-cmp not store-wired\n") vim.cmd("cquit!") end
    lua local ok = pcall(require, "cmp") if not ok then io.stderr:write("nvim-cmp not loadable\n") vim.cmd("cquit!") end
    qall!
  '';
in
runCommand "lazyvim-config-pickers"
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
