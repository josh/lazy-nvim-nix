{
  lib,
  stdenv,
  runCommand,
  writeScript,
  neovim,
  jq,
  lazynvimPlugins,
  lazy-nvim ? lazynvimPlugins."lazy.nvim",
  LazyVim ? lazynvimPlugins."LazyVim",
}:
let
  updateScript = writeScript "update-LazyVim-json.sh" ''
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
        ${lib.getExe jq} --sort-keys <out.json >$out
      '';
in
pkg
