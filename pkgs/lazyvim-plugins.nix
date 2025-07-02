{
  lazy-nvim-nix,
  lib,
  stdenv,
  runCommand,
  writeScriptBin,
  neovim,
  jq,
  lazy-nvim ? lazy-nvim-nix.plugins."lazy.nvim",
  LazyVim ? lazy-nvim-nix.plugins."LazyVim",
}:
let
  updateScript = writeScriptBin "update-LazyVim-json.sh" ''
    #!${stdenv.shell}
    set -o xtrace
    install -m 644 ${pkg} plugins/LazyVim.json
  '';
  pkg =
    runCommand "lazyvim-plugins.json"
      {
        LAZY_PATH = lazy-nvim;
        LAZYVIM_PATH = LazyVim;

        passthru.updateScript = updateScript;
      }
      ''
        out=out.json ${lib.getExe neovim} -l ${./lazyvim-plugins.lua}
        ${lib.getExe jq} --sort-keys <out.json >out~
        mv out~ "$out"
      '';
in
pkg
