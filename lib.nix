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

  tryFilter =
    fn: lst:
    builtins.filter (
      pkg:
      let
        result = builtins.tryEval (fn pkg);
      in
      result.success && result.value
    ) lst;

  tryFind =
    fn: lst:
    let
      results = tryFilter fn lst;
    in
    if results == [ ] then null else builtins.head results;

  isDerivation = value: value.type or null == "derivation";

  # Extract GitHub name with owner info from string.
  #
  # Examples
  #
  #  githubNameWithOwner "https://github.com/folke/lazy.nvim/"
  #  # => { owner = "folke"; name = "lazy.nvim"; }
  #
  #  githubNameWithOwner "github:folke/lazy.nvim"
  #  # => { owner = "folke"; name = "lazy.nvim"; }
  #
  #  githubNameWithOwner "folke/lazy.nvim"
  #  # => { owner = "folke"; name = "lazy.nvim"; }
  #
  #  githubNameWithOwner "lazy.nvim"
  #  # => { owner = null; name = "lazy.nvim"; }
  #
  #  githubNameWithOwner pkgs.vimPlugins.lazy-nvim
  #  # => { owner = null; name = "lazy.nvim"; }
  #
  githubNameWithOwner =
    path:
    if isDerivation path then
      let
        pkg = path;
        hasMeta = builtins.hasAttr "meta" pkg;
        hasHomepage = builtins.hasAttr "homepage" pkg.meta;
      in
      if hasMeta && hasHomepage then githubNameWithOwner pkg.meta.homepage else null
    else if builtins.isString path then
      let
        fullMatches = builtins.match "(https://github.com/|github:)?([^/]+)/([^/]+)/?" path;
        repoMatches = builtins.match "([^/]+)" path;
      in
      if builtins.isList fullMatches then
        {
          owner = builtins.elemAt fullMatches 1;
          name = builtins.elemAt fullMatches 2;
        }
      else if builtins.isList repoMatches then
        {
          owner = null;
          name = builtins.elemAt repoMatches 0;
        }
      else
        null
    else
      null;

  # Look up nixpkgs.vimPlugins by GitHub owner and name.
  # Returns null if not found.
  #
  #   lookupVimPluginByGitHub {
  #     pkgs = pkgs;
  #     owner = "folke";
  #     name = "lazy.nvim";
  #   }
  #
  lookupVimPluginByGitHub =
    {
      pkgs,
      owner ? null,
      name,
    }:
    let
      didMatch =
        pkg:
        let
          nwo = githubNameWithOwner pkg;
        in
        nwo != null && (owner == null || nwo.owner == owner) && (nwo.name == name);
    in
    tryFind didMatch (builtins.attrValues pkgs.vimPlugins);

  # 
  #
  # Examples
  #
  #   makeLazyPluginSpec pkgs "tokyonight.nvim"
  #   makeLazyPluginSpec pkgs "folke/tokyonight.nvim"
  #
  #   makeLazyPluginSpec pkgs pkgs.vimPlugins.tokyonight-nvim
  #
  #   makeLazyPluginSpec pkgs {
  #     name = "tokyonight.nvim";
  #     dir = pkgs.vimPlugins.tokyonight-nvim;
  #   }
  #
  makeLazyPluginSpec =
    pkgs: spec:
    if builtins.isAttrs spec then
      if (builtins.hasAttr "name" spec) && (builtins.hasAttr "dir" spec) then
        spec
      else if isDerivation spec then
        let
          pkg = spec;
          nwo = githubNameWithOwner pkg;
        in
        if nwo != null then
          {
            inherit (nwo) name;
            dir = pkg;
          }
        else
          throw "Package must have a GitHub homepage"
      else
        throw "Invalid plugin spec"
    else if builtins.isString spec then
      let
        nwo = githubNameWithOwner spec;
        pkg = lookupVimPluginByGitHub {
          inherit pkgs;
          inherit (nwo) owner name;
        };
      in
      if nwo.name != null && pkg != null then
        {
          inherit (nwo) name;
          dir = pkg;
        }
      else
        builtins.trace "${spec} plugin not found" { name = spec; }
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
      inherit (pkgs) system;
      name = "LazyVim-packages.json";
      builder = "${pkgs.neovim}/bin/nvim";
      args = [
        "-l"
        ./lazyvim-packages.lua
      ];
      LAZY_PATH = pkgs.vimPlugins.lazy-nvim;
      LAZYVIM_PATH = pkgs.vimPlugins.LazyVim;
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
          pkgs.lib.attrsets.genAttrs repos (
            repo:
            lookupVimPluginByGitHub {
              inherit pkgs;
              name = repo;
            }
          )
        );
    in
    builtins.mapAttrs mapWithPkgs packageNames;

in
{
  inherit
    extractLazyVimPackageNames
    extractLazyVimPackageNamesJSON
    extractLazyVimPackages
    githubNameWithOwner
    lookupVimPluginByGitHub
    makeLazyNeovimConfig
    makeLazyNeovimPackage
    makeLazyPluginSpec
    setupLazyLua
    toLua
    ;
}
