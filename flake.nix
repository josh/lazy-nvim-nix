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
      inherit (nixpkgs) lib;
      lib' = import ./lib.nix { inherit nixpkgs; };
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      nixpkgs' = lib.genAttrs systems (
        system: nixpkgs.legacyPackages.${system}.extend self.overlays.default
      );
      eachSystem = f: lib.genAttrs systems (system: f nixpkgs'.${system});
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      lib = lib';

      packages = eachSystem (
        pkgs:
        let
          inherit (pkgs) system callPackage;
          packages = self.packages.${system};
        in
        {
          default = packages.lazy-nvim;
          LazyVimPlugins = callPackage ./pkgs/lazyvim-plugins.nix { };
          lazy-nvim-config = callPackage ./pkgs/lazy-nvim-config.nix { };
          lazy-nvim = callPackage ./pkgs/lazy-nvim.nix {
            inherit (packages) neovim-checkhealth;
          };
          LazyVim = callPackage ./pkgs/LazyVim.nix {
            inherit (packages) lazy-nvim neovim-checkhealth;
          };
          neovim-checkhealth = callPackage ./pkgs/neovim-checkhealth.nix { };
          lazy-neovide = callPackage ./pkgs/lazy-neovide.nix {
            neovim = packages.lazy-nvim;
          };
          LazyVim-neovide = callPackage ./pkgs/lazy-neovide.nix {
            neovim = packages.LazyVim;
          };
        }
      );

      legacyPackages = eachSystem (pkgs: {
        inherit (pkgs) lazynvimPlugins lazynvimUtils;
      });

      overlays.default = final: prev: {
        lazynvimPlugins = final.callPackage ./plugins.nix { };
        lazynvimUtils = lib';

        writers = prev.writers // {
          writeLuaTable =
            name: obj:
            final.writers.writeText name ''
              return ${lib'.toLua obj}
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

          addAttrsetPrefix = prefix: lib.attrsets.concatMapAttrs (n: v: { "${prefix}${n}" = v; });
          localTests = lib.attrsets.concatMapAttrs (
            pkgName: pkg:
            if (builtins.hasAttr "tests" pkg) then
              ({ "${pkgName}-build" = pkg; } // (addAttrsetPrefix "${pkgName}-tests-" pkg.tests))
            else
              { "${pkgName}-build" = pkg; }
          ) self.packages.${system};
        in
        {
          formatting = treefmtEval.${system}.config.build.check self;

          startuptime = pkgs.runCommand "nvim-startuptime" { } ''
            ${lib.getExe packages.lazy-nvim} --headless "+Lazy! home" --startuptime "$out" +q
          '';

          LazyVimPlugins-outdated =
            pkgs.runCommand "LazyVimPlugins-outdated"
              {
                buildInputs = [ pkgs.diffutils ];
                actual = self.packages.${system}.LazyVimPlugins;
                expected = ./plugins/LazyVim.json;
              }
              ''
                diff --unified $actual $expected
                touch "$out"
              '';

          LazyVim-extras-catppuccin = plugins.LazyVim.extras."lazyvim.plugins".catppuccin;
          LazyVim-extras-all = pkgs.runCommandLocal "LazyVim-extras-all" {
            buildInputs = lib'.flattenDerivations plugins.LazyVim.extras;
          } "touch $out";
        }
        // localTests
      );
    };
}
