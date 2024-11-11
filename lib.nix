{ nixpkgs }:
let
  inherit (nixpkgs) lib;

  # flattenDerivations :: AttrSet -> [ Derivation ]
  flattenDerivations =
    attrset:
    lib.lists.flatten (
      lib.mapAttrsToList (
        _name: value:
        if lib.attrsets.isDerivation value then
          [ value ]
        else if builtins.isAttrs value then
          flattenDerivations value
        else
          [ ]
      ) attrset
    );

  toLua = lib.generators.toLua { };
  inherit (lib.generators) mkLuaInline;

  defaultLazyOpts = {
    root = mkLuaInline ''vim.fn.stdpath("data") .. "/lazy"'';
    lockfile = mkLuaInline ''vim.fn.stdpath("config") .. "/lazy-lock.json"'';
    state = mkLuaInline ''vim.fn.stdpath("state") .. "/lazy/state.json"'';
    install = {
      missing = false;
      colorscheme = [ "habamax" ];
    };
    checker = {
      enabled = false;
      notify = false;
    };
    change_detection = {
      enabled = false;
      notify = false;
    };
    performance = {
      reset_packpath = true;
      rtp = {
        reset = true;
      };
    };
    readme = {
      enabled = false;
    };
  };

  setupLazyLua =
    {
      pkgs,
      spec ? [ ],
      opts ? { },
    }:
    let
      lazypath = (pkgs.callPackage ./plugins.nix { })."lazy.nvim";
    in
    ''
      vim.opt.rtp:prepend("${lazypath}");
      require("lazy").setup(${toLua spec}, ${toLua opts})
    '';

in
{
  inherit
    defaultLazyOpts
    flattenDerivations
    mkLuaInline
    setupLazyLua
    toLua
    ;
}
