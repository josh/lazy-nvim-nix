{
  lib,
  stdenv,
  runCommand,
  neovim,
  glibcLocales,
  editFile,
}:
runCommand "test-edit-${builtins.baseNameOf editFile}"
  {
    __structuredAttrs = true;

    neovimBin = lib.getExe neovim;
    nvimArgs = [
      "--headless"

      "-c"
      "edit ${editFile}"

      "-c"
      "sleep 3"

      "-c"
      "qall!"
    ];

    env = {
      DISPLAY = lib.optionalString stdenv.isLinux ":0";
      LOCALE_ARCHIVE = lib.optionalString stdenv.isLinux "${glibcLocales}/lib/locale/locale-archive";
      LANG = "en_US.UTF-8";
    };
  }
  ''
    mkdir -p .config/nvim
    touch .config/nvim/init.lua

    HOME="$PWD" timeout 30s "$neovimBin" "''${nvimArgs[@]}" 1>out.txt 2>err.txt
    exit_code=$?

    echo "== stdout =="
    cat out.txt
    echo "== stderr =="
    cat err.txt
    echo "=="

    if [ $exit_code -eq 124 ]; then
      echo "Test timed out after 30 seconds"
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
