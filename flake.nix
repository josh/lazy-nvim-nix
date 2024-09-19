{
  description = "Lazy Neovim on Nix";

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
      mkLazynvimPlugins = pkgs: {
        "bufferline.nvim" = self.lib.buildVimPlugin pkgs "bufferline.nvim";
        "catppuccin" = self.lib.buildVimPlugin pkgs "catppuccin";
        "lazy.nvim" = self.lib.buildVimPlugin pkgs "lazy.nvim";
        "LazyVim" = self.lib.buildVimPlugin pkgs "LazyVim";
        "lualine.nvim" = self.lib.buildVimPlugin pkgs "lualine.nvim";
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
              # TODO: my wrapped plugin derivation should provide this spec
              {
                name = "bufferline.nvim";
                dir = plugins."bufferline.nvim";
              }
              {
                name = "lualine.nvim";
                dir = plugins."lualine.nvim";
              }
            ];
          };

          LazyVim = self.lib.makeLazyNeovimPackage {
            inherit pkgs;
            spec = [
              # TODO: Add LazyVim plugin module derivation
              # { "import" = lib.mkLazyVimSpecFile { inherit nixpkgs pkgs; }; }
              {
                name = "LazyVim";
                dir = plugins."LazyVim";
                "import" = "lazyvim.plugins";
              }
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
