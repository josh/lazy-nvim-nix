let
  toLuaSrc = builtins.fetchurl {
    # Get latest commit from https://github.com/nix-community/nixvim/commits/main/lib/to-lua.nix
    url = "https://raw.githubusercontent.com/nix-community/nixvim/35788bbc5ab247563e13bad3ce64acd897bca043/lib/to-lua.nix";
    sha256 = "sha256:01kj9z5sp82n6r863jxzszs0qpn30p9c4ws0p84qgw5wr2j4jp17";
  };
  lua = import toLuaSrc;
  toLua = lib: value: (lua { inherit lib; }).toLua value;

  pad = s: if builtins.stringLength s < 2 then "0" + s else s;
  dateFromUnix =
    t:
    let
      days = t / 86400;
      z = days + 719468;
      era = z / 146097;
      doe = z - era * 146097;
      yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
      y = yoe + era * 400;
      doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
      mp = (5 * doy + 2) / 153;
      d = doy - (153 * mp + 2) / 5 + 1;
      m = mp + (if mp < 10 then 3 else -9);
      y' = y + (if m <= 2 then 1 else 0);
    in
    "${toString y'}-${pad (toString m)}-${pad (toString d)}";

  buildLazyNeovimPlugin =
    pkgs: name: node:
    let
      cleanName = builtins.replaceStrings [ "." ] [ "-" ] name;
      version = dateFromUnix node.locked.lastModified;
      drv = pkgs.fetchFromGitHub {
        name = "lazynvimplugin-${cleanName}-${version}";
        inherit (node.locked) owner repo rev;
        sha256 = node.locked.narHash;
      };
      spec = {
        inherit name;
        dir = "${drv}";
        url = "https://github.com/${node.original.owner}/${node.original.repo}";
        branch = node.original.ref;
        commit = node.locked.rev;
        pin = true;
      };
    in
    assert node.original.type == "github";
    drv // { inherit spec; };

  sourcesLock = builtins.fromJSON (builtins.readFile ./sources/flake.lock);

  buildLazyNeovimPlugins =
    pkgs:
    builtins.mapAttrs (buildLazyNeovimPlugin pkgs) (
      builtins.removeAttrs sourcesLock.nodes [
        "root"
        "lazy.nvim"
      ]
    )
    // {
      "lazy.nvim" =
        let
          node = sourcesLock.nodes."lazy.nvim";
        in
        pkgs.vimUtils.buildVimPlugin {
          pname = "lazy.nvim";
          version = dateFromUnix node.locked.lastModified;
          src = pkgs.fetchFromGitHub {
            owner = "folke";
            repo = "lazy.nvim";
            inherit (node.locked) rev;
            sha256 = node.locked.narHash;
          };
          meta.homepage = "https://github.com/folke/lazy.nvim";
        };
    };

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
      lib,
      spec ? [ ],
      opts ? { },
    }:
    let
      # TODO: Something is messed up with the docs dir
      # lazypath = buildLazyNeovimPlugin pkgs "lazy.nvim" sourcesLock.nodes."lazy.nvim";
      lazypath = pkgs.vimPlugins.lazy-nvim;
    in
    ''
      vim.opt.rtp:prepend("${lazypath}");
      require("lazy").setup(${toLua lib spec}, ${toLua lib opts})
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
    buildLazyNeovimPlugins
    defaultLazyOpts
    extractLazyVimPluginImportsJSON
    makeLazyNeovimConfig
    makeLazyNeovimPackage
    mkLazyVimSpecFile
    setupLazyLua
    sourcesLock
    toLua
    ;

  withNixpkgs = nixpkgs: {
    inherit
      buildLazyNeovimPlugins
      defaultLazyOpts
      extractLazyVimPluginImportsJSON
      makeLazyNeovimConfig
      makeLazyNeovimPackage
      sourcesLock
      ;
    mkLazyVimSpecFile = args: mkLazyVimSpecFile ({ inherit nixpkgs; } // args);
    setupLazyLua = args: setupLazyLua ({ inherit (nixpkgs) lib; } // args);
    toLua = toLua nixpkgs.lib;
  };
}
