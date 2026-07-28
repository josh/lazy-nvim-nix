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
    set -euo pipefail -o xtrace
    cd "$(git rev-parse --show-toplevel)"
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
        SCAN_OUT=modules.txt timeout --kill-after=10s 120s ${lib.getExe neovim} -l ${./lazyvim-plugins.lua} list

        mkdir scans
        i=0
        while IFS= read -r modname; do
          SCAN_OUT="scans/$i.json" timeout --kill-after=10s 120s ${lib.getExe neovim} -l ${./lazyvim-plugins.lua} scan "$modname"
          i=$((i + 1))
        done <modules.txt

        ${lib.getExe jq} --sort-keys --null-input 'reduce inputs as $mod ({}; . + $mod)' scans/*.json >"$out"
      '';
in
pkg
