{
  lib,
  stdenv,
  writeText,
  writeShellScriptBin,
  runCommand,
  glibcLocales,
  lazy-nvim-nix,
}:
let
  neovim = lazy-nvim-nix.lazy-nvim.override {
    spec = [ lazy-nvim-nix.plugins."mason.nvim".spec ];
    inherit (lazy-nvim-nix.plugins."mason.nvim") extraPackages;
  };
  # an incompatible yq flavor that shadows the bundled one via PATH
  yq-impostor = writeShellScriptBin "yq" ''
    echo "yq: unknown arguments" >&2
    exit 2
  '';
  vim-script-runner = writeText "mason-registry-load.vim" ''
    doautocmd UIEnter
    Lazy! load mason.nvim
    lua local reg = require("mason-registry") local done = false reg.refresh(function() done = true end) vim.wait(60000, function() return done end, 100) local n = #reg.get_all_package_names() io.stdout:write("packages=" .. n .. "\n") if n == 0 then io.stderr:write("mason registry failed to load\n") vim.cmd("cquit!") end
    qall!
  '';
in
runCommand "mason-registry-load"
  {
    __structuredAttrs = true;

    neovimBin = lib.getExe neovim;
    nvimArgs = [
      "--headless"
      "-S"
      "${vim-script-runner}"
    ];

    nativeBuildInputs = [ yq-impostor ];

    env = {
      DISPLAY = lib.optionalString stdenv.hostPlatform.isLinux ":0";
      LANG = "en_US.UTF-8";
      LOCALE_ARCHIVE = lib.optionalString stdenv.hostPlatform.isLinux "${glibcLocales}/lib/locale/locale-archive";
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
    fi

    if grep "EPIPE" err.txt; then
      exit 1
    fi
    grep -q "packages=" out.txt

    touch $out
  ''
