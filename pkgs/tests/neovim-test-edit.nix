{
  lib,
  stdenv,
  writeText,
  runCommand,
  neovim,
  glibcLocales,
  editFile,
}:
let
  vim-script-runner = writeText "test-edit-${builtins.baseNameOf editFile}.vim" ''
    sleep 3
    edit ${editFile}
    qall!
  '';
in
runCommand "test-edit-${builtins.baseNameOf editFile}"
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

    if [ $exit_code -eq 124 ] || [ $exit_code -eq 137 ]; then
      echo "Test timed out (exit $exit_code)"
      exit 1
    elif [ $exit_code -ne 0 ]; then
      echo "Neovim exited with code $exit_code"
      exit 1
    elif [ -s out.txt ]; then
      echo "messages written to stdout"
      exit 1
    elif [ -s err.txt ]; then
      echo "messages written to stderr"
      exit 1
    fi

    touch $out
  ''
