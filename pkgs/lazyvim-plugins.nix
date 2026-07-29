{
  lazy-nvim-nix,
  lib,
  runCommand,
  writeShellApplication,
  coreutils,
  git,
  neovim,
  jq,
  lazy-nvim ? lazy-nvim-nix.plugins."lazy.nvim",
  LazyVim ? lazy-nvim-nix.plugins."LazyVim",
}:
let
  updateScript = writeShellApplication {
    name = "update-LazyVim-json.sh";
    runtimeInputs = [
      coreutils
      git
    ];
    text = ''
      set -o xtrace
      cd "$(git rev-parse --show-toplevel)"
      install -m 644 ${pkg} plugins/LazyVim.json
    '';
  };
  pkg =
    runCommand "lazyvim-plugins.json"
      {
        LAZY_PATH = lazy-nvim;
        LAZYVIM_PATH = LazyVim;
        LAZY_OFFLINE = "1";

        passthru.updateScript = updateScript;
      }
      ''
        SCAN_OUT=modules.txt timeout --kill-after=10s 120s ${lib.getExe neovim} -l ${./lazyvim-plugins.lua} list </dev/null

        [ -s modules.txt ]

        mkdir scans
        i=0
        while IFS= read -r modname; do
          SCAN_OUT="scans/$i.json" timeout --kill-after=10s 120s ${lib.getExe neovim} -l ${./lazyvim-plugins.lua} scan "$modname" </dev/null
          i=$((i + 1))
        done <modules.txt

        ${lib.getExe jq} --sort-keys --null-input '
          reduce inputs as $mod ({};
            ($mod | keys[]) as $k
            | if has($k) then error("duplicate module: \($k)") else . end
            | . + $mod)
        ' scans/*.json >"$out"
      '';
in
pkg
