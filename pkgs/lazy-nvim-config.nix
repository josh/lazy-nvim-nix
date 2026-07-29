{
  lib,
  callPackage,
  writeTextFile,
  lazy-nvim-nix,
  customLuaRC ? "",
  spec ? [ ],
  opts ? { },
}:
let
  lib' = lazy-nvim-nix.lib;
  inherit (lazy-nvim-nix) plugins;
in
writeTextFile {
  name = "lazy-nvim-init.lua";
  text = ''
    vim.opt.rtp:prepend("${plugins."lazy.nvim"}");

    ${lib'.colorschemePreRC}
    ${customLuaRC}
    require("lazy").setup(${lib'.toLua spec}, ${lib'.toLua (lib.recursiveUpdate lib'.defaultLazyOpts opts)})
  '';

  passthru.tests = {
    example = callPackage ./tests/lazy-nvim-config-example.nix { };
  };
}
