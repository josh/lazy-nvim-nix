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

  # Look up nixpkgs.vimPlugins for GitHub repo name.
  # Return null if the package is not found.
  lookupPackage =
    { pkgs, repo }:
    let
      inherit (pkgs) vimPlugins;
      pluginName = builtins.replaceStrings [ "." ] [ "-" ] repo;
      ok = builtins.hasAttr pluginName vimPlugins;
      notFound = builtins.trace "pkgs.vimPlugins.${pluginName} not found" null;
    in
    if ok then vimPlugins."${pluginName}" else notFound;

  # 
  #
  # Examples
  #
  #   lib.makeLazyPluginSpec pkgs "tokyonight.nvim"
  #   lib.makeLazyPluginSpec pkgs "folke/tokyonight.nvim"
  #
  #   lib.makeLazyPluginSpec pkgs pkgs.vimPlugins.tokyonight-nvim
  #
  #   lib.makeLazyPluginSpec pkgs {
  #     name = "tokyonight.nvim";
  #     dir = pkgs.vimPlugins.tokyonight-nvim;
  #   }
  #
  makeLazyPluginSpec =
    pkgs: spec:
    let
      githubMatches = builtins.match "https://github.com/[^/]+/([^/]+)/?" spec.meta.homepage;
      pluginName = builtins.replaceStrings [ "." ] [ "-" ] spec;
    in
    if builtins.isAttrs spec then
      if (builtins.hasAttr "name" spec) && (builtins.hasAttr "dir" spec) then
        spec
      else if pkgs.lib.attrsets.isDerivation spec then
        if githubMatches != [ ] then
          {
            name = builtins.head githubMatches;
            dir = spec;
          }
        else
          throw "Package must have a GitHub homepage"
      else
        throw "Invalid plugin spec"
    else if builtins.isString spec then
      if builtins.hasAttr pluginName pkgs.vimPlugins then
        {
          name = spec;
          dir = pkgs.vimPlugins."${pluginName}";
        }
      else
        builtins.trace "pkgs.vimPlugins.${pluginName} not found" { name = spec; }
    else
      throw "Invalid plugin spec";

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

  extractLazyVimPackageNamesJSON =
    { pkgs }:
    derivation {
      name = "LazyVim-packages.json";
      builder = "${pkgs.neovim}/bin/nvim";
      args = [
        "-l"
        ./lazyvim-packages.lua
        pkgs.vimPlugins.lazy-nvim
        pkgs.vimPlugins.LazyVim
      ];
      inherit (pkgs) system;
    };
  extractLazyVimPackageNames =
    { pkgs }:
    let
      jsonFile = extractLazyVimPackageNamesJSON { inherit pkgs; };
      jsonData = builtins.readFile jsonFile;
      jsonSet = builtins.fromJSON jsonData;
    in
    jsonSet;

  extractLazyVimPackages =
    { pkgs }:
    let
      packageNames = extractLazyVimPackageNames { inherit pkgs; };
      packageFound = _name: src: src != null;
      mapWithPkgs =
        _: repos:
        pkgs.lib.filterAttrs packageFound (
          pkgs.lib.attrsets.genAttrs repos (repo: lookupPackage { inherit pkgs repo; })
        );
    in
    builtins.mapAttrs mapWithPkgs packageNames;

in
{
  inherit
    extractLazyVimPackageNames
    extractLazyVimPackageNamesJSON
    extractLazyVimPackages
    makeLazyNeovimConfig
    makeLazyNeovimPackage
    makeLazyPluginSpec
    setupLazyLua
    toLua
    ;
}
