let
  lua = import (
    builtins.fetchurl {
      # Get latest commit from https://github.com/nix-community/nixvim/commits/main/lib/to-lua.nix
      url = "https://raw.githubusercontent.com/nix-community/nixvim/6dc0bda459bcfb2a38cf7b6ed1d6a5d6a8105f00/lib/to-lua.nix";
      sha256 = "sha256:19a22zp89d1xiff7zpzk016z8dv3jsvfnzsyl53b3i7apz75c2yr";
    }
  );
  toLua = lib: value: (lua { inherit lib; }).toLua value;

  lazyOpts = {
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
    performance = {
      reset_packpath = false;
      rtp = {
        reset = false;
      };
    };
  };

  setupLazyLua =
    {
      lib,
      spec ? [ ],
      opts ? { },
    }:
    ''require("lazy").setup(${toLua lib spec}, ${toLua lib opts})'';

  makeLazyNeovimPackage =
    { pkgs, ... }@args: pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped (makeLazyNeovimConfig args);

  makeLazyNeovimConfig =
    {
      pkgs,
      spec ? [ ],
    }:
    let
      inherit (pkgs) lib;

      extraPackages = [
        pkgs.git
        pkgs.luajitPackages.luarocks
      ];

      config = pkgs.neovimUtils.makeNeovimConfig {
        # See pkgs/applications/editors/neovim/utils.nix # makeNeovimConfig

        withPython3 = false;
        withNodeJs = false;
        withRuby = false;
        plugins = [ { plugin = pkgs.vimPlugins.lazy-nvim; } ];

        # Extra config to pass to
        # pkgs/applications/editors/neovim/wrapper.nix

        luaRcContent = setupLazyLua {
          inherit (pkgs) lib;
          inherit spec;
          opts = lazyOpts;
        };
      };

      # Unfortunately can't pass extraWrapperArgs to makeNeovimConfig
      configExtra =
        let
          binPath = lib.makeBinPath extraPackages;
        in
        {
          wrapperArgs = lib.escapeShellArgs config.wrapperArgs + " '--prefix' 'PATH' : '${binPath}' ";
        };

      finalConfig = config // configExtra;

    in
    finalConfig;

in
{
  inherit
    makeLazyNeovimConfig
    makeLazyNeovimPackage
    setupLazyLua
    toLua
    ;
}
