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
    if timeout --kill-after=10s 10s "$neovimBin" "''${nvimArgs[@]}"; then
      touch $out
    fi
  ''
