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
      nixpkgs' = nixpkgs.lib.genAttrs systems (
        system: nixpkgs.legacyPackages.${system}.extend self.overlays.default
      );
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs'.${system});
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      inherit lib;

      packages = eachSystem (
        pkgs:
        let
          inherit (pkgs) system callPackage;
        in
        {
          default = self.packages.${system}.lazy-nvim;
          LazyVimPlugins = callPackage ./pkgs/lazyvim-plugins.nix { };
          lazy-nvim-config = callPackage ./pkgs/lazy-nvim-config.nix {
            inherit (self.packages.${system}) lazy-nvim-config;
          };
          lazy-nvim = callPackage ./pkgs/lazy-nvim.nix { };
          LazyVim = callPackage ./pkgs/LazyVim.nix { inherit (self.packages.${system}) lazy-nvim; };
        }
      );

      legacyPackages = eachSystem (pkgs: {
        inherit (pkgs) lazynvimPlugins lazynvimUtils;
      });

      overlays.default = final: prev: {
        lazynvimPlugins = final.callPackage ./plugins.nix { };
        lazynvimUtils = self.lib;

        writers = prev.writers // {
          writeLuaTable =
            name: obj:
            final.writers.writeText name ''
              return ${lib.toLua obj}
            '';
        };
      };

      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
      checks = eachSystem (
        pkgs:
        let
          inherit (pkgs) system;
          packages = self.packages.${system};
          plugins = pkgs.lazynvimPlugins;
        in
        {
          formatting = treefmtEval.${system}.config.build.check self;

          plugins = pkgs.runCommandLocal "plugins" {
            buildInputs = lib.flattenDerivations plugins;
          } ''echo "ok" >$out'';

          # TODO: Automatically expose all tests
          lazy-nvim-config = packages.lazy-nvim-config.passthru.tests.example;

          help = pkgs.runCommandLocal "nvim-help" { } ''
            ${packages.lazy-nvim}/bin/nvim --help 2>&1 >$out 
          '';

          checkhealth = pkgs.runCommandLocal "nvim-checkhealth" { } ''
            ${packages.lazy-nvim}/bin/nvim --headless "+Lazy! home" +checkhealth "+w!$out" +qa
          '';

          startuptime = pkgs.runCommandLocal "nvim-startuptime" { } ''
            ${packages.lazy-nvim}/bin/nvim --headless "+Lazy! home" --startuptime "$out" +q
          '';

          lazyvim-plugins-json = pkgs.runCommandLocal "lazyvim-plugins-json" { } ''
            ${pkgs.jq}/bin/jq <${packages.LazyVimPlugins} >$out
          '';

          LazyVim-extras-catppuccin = plugins.LazyVim.extras."lazyvim.plugins".catppuccin;
          LazyVim-extras-all = pkgs.runCommandLocal "LazyVim-extras-all" {
            buildInputs = lib.flattenDerivations plugins.LazyVim.extras;
          } ''echo "ok" >$out'';
        }
      );
    };
}
