{
  lib,
  runCommand,
  neovim,
  jq,
  lazynvimPlugins,
  lazy-nvim ? lazynvimPlugins."lazy.nvim",
  LazyVim ? lazynvimPlugins."LazyVim",
}:
runCommand "lazyvim-plugins.json"
  {
    LAZY_PATH = lazy-nvim;
    LAZYVIM_PATH = LazyVim;
  }
  ''
    out=out.json ${lib.getExe neovim} -l ${./lazyvim-plugins.lua}
    ${lib.getExe jq} --sort-keys <out.json >$out
  ''
