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
      jq
    ];
    text = ''
      set -o xtrace
      cd "$(git rev-parse --show-toplevel)"
      install -m 644 ${pkg}/LazyVim.json plugins/LazyVim.json
      jq --sort-keys --slurpfile branches ${pkg}/branches.json '
        (with_entries(.value |= del(.ref)) | with_entries(select(.value | length > 0))) as $kept
        | reduce ($branches[0] | to_entries[]) as $branch ($kept; .[$branch.key].ref = $branch.value)
      ' plugins/sources.json >plugins/sources.json.new
      mv plugins/sources.json.new plugins/sources.json
    '';
  };
  pkg =
    runCommand "lazyvim-plugins"
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

        mkdir "$out"

        ${lib.getExe jq} --sort-keys --null-input '
          reduce inputs as $mod ({};
            reduce ($mod | del(.branches) | to_entries[]) as $e (.;
              if $e.key == "optional" then
                .optional = ((.optional // {}) + $e.value)
              elif has($e.key) then
                error("duplicate module: \($e.key)")
              else
                . + { ($e.key): $e.value }
              end))
        ' scans/*.json >"$out/LazyVim.json"

        ${lib.getExe jq} --sort-keys --null-input '
          reduce inputs as $mod ({};
            reduce (($mod.branches // {}) | to_entries[]) as $b (.;
              if (.[$b.key] // $b.value) != $b.value then
                error("conflicting branch for \($b.key): \(.[$b.key]) and \($b.value)")
              else
                .[$b.key] = $b.value
              end))
        ' scans/*.json >"$out/branches.json"
      '';
in
pkg
