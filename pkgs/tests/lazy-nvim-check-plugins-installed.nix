{
  lib,
  runCommand,
  neovim,
}:
runCommand "lazy-nvim-check-plugins-installed"
  {
    __structuredAttrs = true;

    neovimBin = lib.getExe neovim;
    nvimArgs = [
      "--headless"
      "-S"
      "${./lazy-nvim-check-plugins-installed.lua}"
    ];
  }
  ''
    exit_code=0
    timeout --kill-after=10s 120s "$neovimBin" "''${nvimArgs[@]}" || exit_code=$?

    if [ "$exit_code" -eq 124 ] || [ "$exit_code" -eq 137 ]; then
      echo "Test timed out (exit $exit_code)"
      exit 1
    elif [ "$exit_code" -ne 0 ]; then
      echo "Neovim exited with code $exit_code"
      exit 1
    fi

    touch $out
  ''
