{
  description = "Lazy Neovim on Nix";

  nixConfig = {
    extra-substituters = [ "https://lazy-nvim-nix.cachix.org" ];
    extra-trusted-public-keys = [
      "lazy-nvim-nix.cachix.org-1:hVfO46ldDlMsuON1A44DpCdZmtBOH6SCMXIPKmsVSGA="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # to-lua = {
    #   url = "https://raw.githubusercontent.com/nix-community/nixvim/abcd123/lib/to-lua.nix";
    #   flake = false;
    # };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let
      lib = import ./lib.nix { inherit nixpkgs; };
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      inherit lib;

      packages = eachSystem (
        pkgs:
        let
          inherit (pkgs) system;
          plugins = self.legacyPackages.${pkgs.system}.lazynvimPlugins;
        in
        {
          default = self.packages.${system}.nvim;

          LazyVimPlugins = pkgs.callPackage ./lazyvim-plugins.nix {
            lazy-nvim = plugins."lazy.nvim";
            LazyVim = plugins."LazyVim";
          };

          nvim = self.lib.makeLazyNeovimPackage {
            inherit pkgs;
            spec = [ ];
          };

          LazyVim = self.lib.makeLazyNeovimPackage {
            inherit pkgs;
            spec = [
              (plugins."LazyVim".spec // { "import" = "lazyvim.plugins"; })

              plugins."bufferline.nvim".spec
              plugins."catppuccin".spec
              plugins."cmp-buffer".spec
              plugins."cmp-nvim-lsp".spec
              plugins."cmp-path".spec
              plugins."conform.nvim".spec
              plugins."dashboard-nvim".spec
              plugins."dressing.nvim".spec
              plugins."flash.nvim".spec
              plugins."friendly-snippets".spec
              plugins."gitsigns.nvim".spec
              plugins."grug-far.nvim".spec
              plugins."indent-blankline.nvim".spec
              plugins."lazydev.nvim".spec
              plugins."lualine.nvim".spec
              plugins."luvit-meta".spec
              plugins."mason-lspconfig.nvim".spec
              plugins."mason.nvim".spec
              plugins."mini.ai".spec
              plugins."mini.icons".spec
              plugins."mini.pairs".spec
              plugins."neo-tree.nvim".spec
              plugins."noice.nvim".spec
              plugins."nui.nvim".spec
              plugins."nvim-cmp".spec
              plugins."nvim-lint".spec
              plugins."nvim-lspconfig".spec
              plugins."nvim-notify".spec
              plugins."nvim-snippets".spec
              plugins."nvim-ts-autotag".spec
              plugins."persistence.nvim".spec
              plugins."plenary.nvim".spec
              plugins."telescope-fzf-native.nvim".spec
              plugins."telescope.nvim".spec
              plugins."todo-comments.nvim".spec
              plugins."tokyonight.nvim".spec
              plugins."trouble.nvim".spec
              plugins."ts-comments.nvim".spec
              plugins."which-key.nvim".spec

              # FIXME: Tries to write to /nix/store/.../parser directory
              {
                name = "nvim-treesitter";
                url = "https://github.com/nvim-treesitter/nvim-treesitter";
                enabled = false;
              }
              {
                name = "nvim-treesitter-textobjects";
                url = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects";
                enabled = false;
              }

              # FIXME: trouble.nvim doesn't like be loaded from /nix/store
              {
                name = "trouble.nvim";
                url = "https://github.com/folke/trouble.nvim";
                enabled = false;
              }
            ];

            extraPackages = with pkgs; [ lazygit ];
          };
        }
      );

      legacyPackages = eachSystem (pkgs: {
        lazynvimPlugins = pkgs.callPackage ./plugins.nix { };
      });

      overlays.default = _final: prev: {
        lazynvimPlugins = prev.callPackage ./plugins.nix { };
        lazynvimUtils = self.lib;
      };

      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
      checks = eachSystem (
        pkgs:
        let
          inherit (pkgs) system;
          inherit (self.packages.${system}) nvim;
        in
        {
          formatting = treefmtEval.${pkgs.system}.config.build.check self;

          plugins = pkgs.runCommandLocal "plugins" {
            buildInputs = lib.attrDerivations self.legacyPackages.${system}.lazynvimPlugins;
          } ''echo "ok" >$out'';

          help = pkgs.runCommandLocal "nvim-help" { } ''
            ${nvim}/bin/nvim --help 2>&1 >$out 
          '';

          checkhealth = pkgs.runCommandLocal "nvim-checkhealth" { } ''
            ${nvim}/bin/nvim --headless "+Lazy! home" +checkhealth "+w!$out" +qa
          '';

          startuptime = pkgs.runCommandLocal "nvim-startuptime" { } ''
            ${nvim}/bin/nvim --headless "+Lazy! home" --startuptime "$out" +q
          '';

          lazyvim-plugins-json = pkgs.runCommandLocal "lazyvim-plugins-json" { } ''
            ${pkgs.jq}/bin/jq <${self.packages.${system}.LazyVimPlugins} >$out
          '';
        }
      );
    };
}
