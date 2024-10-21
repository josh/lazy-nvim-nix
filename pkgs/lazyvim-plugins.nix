{
  system,
  neovim,
  lazynvimPlugins,
  lazy-nvim ? lazynvimPlugins."lazy.nvim",
  LazyVim ? lazynvimPlugins."LazyVim",
}:
derivation {
  inherit system;
  name = "lazyvim-plugins.json";
  builder = "${neovim}/bin/nvim";
  args = [
    "-l"
    ./lazyvim-plugins.lua
  ];
  LAZY_PATH = lazy-nvim;
  LAZYVIM_PATH = LazyVim;
}
