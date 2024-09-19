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
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
      # TODO: Generate this mapping instead of hardcoding it
      mkLazynvimPlugins = pkgs: {
        "bufferline.nvim" = self.lib.buildLazyNeovimPlugin pkgs "bufferline.nvim";
        "catppuccin" = self.lib.buildLazyNeovimPlugin pkgs "catppuccin";
        "dashboard-nvim" = self.lib.buildLazyNeovimPlugin pkgs "dashboard-nvim";
        "flash.nvim" = self.lib.buildLazyNeovimPlugin pkgs "flash.nvim";
        "lazy.nvim" = self.lib.buildLazyNeovimPlugin pkgs "lazy.nvim";
        "LazyVim" = self.lib.buildLazyNeovimPlugin pkgs "LazyVim";
        "lualine.nvim" = self.lib.buildLazyNeovimPlugin pkgs "lualine.nvim";
        "mini.ai" = self.lib.buildLazyNeovimPlugin pkgs "mini.ai";
        "mini.icons" = self.lib.buildLazyNeovimPlugin pkgs "mini.icons";
        "mini.pairs" = self.lib.buildLazyNeovimPlugin pkgs "mini.pairs";
        "noice.nvim" = self.lib.buildLazyNeovimPlugin pkgs "noice.nvim";
        "nui.nvim" = self.lib.buildLazyNeovimPlugin pkgs "nui.nvim";
        "nvim-treesitter-textobjects" = self.lib.buildLazyNeovimPlugin pkgs "nvim-treesitter-textobjects";
        "nvim-treesitter" = self.lib.buildLazyNeovimPlugin pkgs "nvim-treesitter";
        "tokyonight.nvim" = self.lib.buildLazyNeovimPlugin pkgs "tokyonight.nvim";
        "trouble.nvim" = self.lib.buildLazyNeovimPlugin pkgs "trouble.nvim";
        "ts-comments.nvim" = self.lib.buildLazyNeovimPlugin pkgs "ts-comments.nvim";
        "which-key.nvim" = self.lib.buildLazyNeovimPlugin pkgs "which-key.nvim";
      };
    in
    {
      lib = (import ./lib.nix).withNixpkgs nixpkgs;

      packages = eachSystem (
        pkgs:
        let
          plugins = self.legacyPackages.${pkgs.system}.lazynvimPlugins;
        in
        {
          default = self.packages.${pkgs.system}.nvim;

          nvim = self.lib.makeLazyNeovimPackage {
            inherit pkgs;
            spec = [
              plugins."bufferline.nvim".spec
              plugins."lualine.nvim".spec
            ];
          };

          LazyVim = self.lib.makeLazyNeovimPackage {
            inherit pkgs;
            spec = [
              # TODO: Add LazyVim plugin module derivation
              # { "import" = lib.mkLazyVimSpecFile { inherit nixpkgs pkgs; }; }
              (plugins."LazyVim".spec // { "import" = "lazyvim.plugins"; })

              plugins."bufferline.nvim".spec
              plugins."catppuccin".spec
              # plugins."dashboard-nvim".spec
              plugins."flash.nvim".spec
              # plugins."lualine.nvim".spec
              plugins."mini.ai".spec
              plugins."mini.pairs".spec
              plugins."noice.nvim".spec
              plugins."nui.nvim".spec
              plugins."nvim-treesitter-textobjects".spec
              # plugins."nvim-treesitter".spec
              plugins."tokyonight.nvim".spec
              # plugins."trouble.nvim".spec
              plugins."ts-comments.nvim".spec
              plugins."which-key.nvim".spec
            ];

            extraPackages = with pkgs; [ lazygit ];
          };
        }
      );

      legacyPackages = eachSystem (pkgs: {
        lazynvimPlugins = mkLazynvimPlugins pkgs;
      });

      overlays.default = _final: prev: { lazynvimPlugins = mkLazynvimPlugins prev; };

      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
      checks = eachSystem (
        pkgs:
        let
          inherit (self.packages.${pkgs.system}) nvim;
        in
        {
          formatting = treefmtEval.${pkgs.system}.config.build.check self;

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
            ${pkgs.jq}/bin/jq <${self.lib.extractLazyVimPluginImportsJSON { inherit pkgs; }} >$out
          '';

          lazyvim-spec-lua = self.lib.mkLazyVimSpecFile { inherit pkgs; };
        }
      );
    };
}
