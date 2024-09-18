let
  toLuaSrc = builtins.fetchurl {
    # Get latest commit from https://github.com/nix-community/nixvim/commits/main/lib/to-lua.nix
    url = "https://raw.githubusercontent.com/nix-community/nixvim/35788bbc5ab247563e13bad3ce64acd897bca043/lib/to-lua.nix";
    sha256 = "sha256:01kj9z5sp82n6r863jxzszs0qpn30p9c4ws0p84qgw5wr2j4jp17";
  };
  lua = import toLuaSrc;
  toLua = lib: value: (lua { inherit lib; }).toLua value;

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
      extraPackages ? [ ],
    }:
    let
      inherit (pkgs) lib;

      moreExtraPackages = [
        pkgs.git
        pkgs.luajitPackages.luarocks
      ] ++ extraPackages;

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
          opts = defaultLazyOpts;
        };
      };

      # Unfortunately can't pass extraWrapperArgs to makeNeovimConfig
      configExtra =
        let
          binPath = lib.makeBinPath moreExtraPackages;
        in
        {
          wrapperArgs = lib.escapeShellArgs config.wrapperArgs + " '--prefix' 'PATH' : '${binPath}' ";
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

  mkLazyVimSpecFile =
    {
      nixpkgs,
      pkgs,
      extras ? [ ],
    }:
    derivation {
      inherit (pkgs) system;
      name = "lazyvim.lua";
      builder = "/bin/sh";
      LAZYVIM_PLUGINS = extractLazyVimPluginImportsJSON { inherit pkgs; };
      LAZYVIM_EXTRAS = builtins.toJSON extras;
      NIX_PATH = "nixpkgs=${nixpkgs}:to-lua=${toLuaSrc}";
      args = [
        "-c"
        ''
          set -e
          ${pkgs.nix}/bin/nix \
            --extra-experimental-features nix-command \
            eval \
            --store dummy:// \
            --eval-store dummy:// \
            --read-only \
            --show-trace \
            --file ${./lazyvim-spec.nix} \
            --raw >out.lua
          ${pkgs.stylua}/bin/stylua \
            --indent-type Spaces \
            --indent-width 2 \
            --column-width 120 \
            out.lua
          ${pkgs.coreutils}/bin/cp out.lua "$out"
        ''
      ];
    };

in
{
  inherit
    defaultLazyOpts
    extractLazyVimPluginImportsJSON
    makeLazyNeovimConfig
    makeLazyNeovimPackage
    mkLazyVimSpecFile
    setupLazyLua
    toLua
    ;

  withNixpkgs = nixpkgs: {
    inherit defaultLazyOpts;
    inherit extractLazyVimPluginImportsJSON;
    inherit makeLazyNeovimConfig;
    inherit makeLazyNeovimPackage;
    mkLazyVimSpecFile = args: mkLazyVimSpecFile ({ inherit nixpkgs; } // args);
    setupLazyLua = args: setupLazyLua ({ inherit (nixpkgs) lib; } // args);
    toLua = toLua nixpkgs.lib;
  };
}
