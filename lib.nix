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

  # lua = import to-lua.outPath { inherit (nixpkgs) lib; };
  toLuaSrc = builtins.fetchurl {
    # Get latest commit from https://github.com/nix-community/nixvim/commits/main/lib/to-lua.nix
    url = "https://raw.githubusercontent.com/nix-community/nixvim/4e2a0221653da2e541dd1197d2afdf87b1c14255/lib/to-lua.nix";
    sha256 = "1wwh106s6dna9jyhi7qmqn8zr2b32lfj9xns927apnxdwygl7a4v";
  };
  lua = import toLuaSrc { inherit lib; };
  inherit (lua) toLua;

  defaultLazyOpts = {
    root.__raw = ''vim.fn.stdpath("data") .. "/lazy"'';
    lockfile.__raw = ''vim.fn.stdpath("config") .. "/lazy-lock.json"'';
    state.__raw = ''vim.fn.stdpath("state") .. "/lazy/state.json"'';
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
      require("lazy").setup(${lua.toLua spec}, ${lua.toLua opts})
    '';

  makeLazyNeovimPackage =
    { pkgs, ... }@args: pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped (makeLazyNeovimConfig args);

  makeLazyNeovimConfig =
    {
      pkgs,
      spec ? [ ],
      extraPackages ? [ ],
    }:
    let
      inherit (pkgs) lib;

      moreExtraPackages = [
        pkgs.git
        pkgs.luajitPackages.luarocks
        pkgs.ripgrep
      ] ++ extraPackages;

      config = pkgs.neovimUtils.makeNeovimConfig {
        # See pkgs/applications/editors/neovim/utils.nix # makeNeovimConfig

        withPython3 = false;
        withNodeJs = false;
        withRuby = false;

        # Extra config to pass to
        # pkgs/applications/editors/neovim/wrapper.nix

        luaRcContent = setupLazyLua {
          inherit pkgs;
          inherit spec;
          opts = defaultLazyOpts;
        };
      };

      # Unfortunately can't pass extraWrapperArgs to makeNeovimConfig
      configExtra =
        let
          binPath = pkgs.lib.makeBinPath moreExtraPackages;
        in
        {
          wrapperArgs = pkgs.lib.escapeShellArgs config.wrapperArgs + " '--prefix' 'PATH' : '${binPath}' ";
        };

      finalConfig = config // configExtra;

    in
    finalConfig;

in
{
  inherit
    flattenDerivations
    defaultLazyOpts
    makeLazyNeovimConfig
    makeLazyNeovimPackage
    setupLazyLua
    toLua
    ;
}
