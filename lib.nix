{ nixpkgs, to-lua }:
let
  inherit (nixpkgs) lib;

  lua = import to-lua.outPath { inherit (nixpkgs) lib; };
  inherit (lua) toLua;

  defaultLazyOpts = {
    root.__raw = ''vim.fn.stdpath("data") .. "/lazy"'';
    lockfile.__raw = ''vim.fn.stdpath("config") .. "/lazy-lock.json"'';
    state.__raw = ''vim.fn.stdpath("state") .. "/lazy/state.json"'';
    install = {
      missing = true;
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
      pkgs,
      spec ? [ ],
      opts ? { },
    }:
    let
      lazypath = (import ./plugins.nix { inherit pkgs; })."lazy.nvim";
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

  extractLazyVimPluginImportsJSON =
    { pkgs }:
    derivation {
      inherit (pkgs) system;
      name = "lazyvim-plugins.json";
      builder = "${pkgs.neovim}/bin/nvim";
      args = [
        "-l"
        ./lazyvim-plugins.lua
      ];
      LAZY_PATH = pkgs.vimPlugins.lazy-nvim;
      LAZYVIM_PATH = pkgs.vimPlugins.LazyVim;
    };

in
{
  inherit
    extractLazyVimPluginImportsJSON
    makeLazyNeovimConfig
    makeLazyNeovimPackage
    toLua
    ;
}
