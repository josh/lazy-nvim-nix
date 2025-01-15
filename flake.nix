{
  description = "Lazy Neovim on Nix";

  nixConfig = {
    extra-substituters = [
      "https://josh.cachix.org"
    ];
    extra-trusted-public-keys = [
      "josh.cachix.org-1:qc8IeYlP361V9CSsSVugxn3o3ZQ6w/9dqoORjm0cbXk="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      inherit (nixpkgs) lib;
      lib' = import ./lib.nix { inherit nixpkgs; };
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      nixpkgs' = lib.genAttrs systems (
        system: nixpkgs.legacyPackages.${system}.extend self.overlays.default
      );
      eachSystem = f: lib.genAttrs systems (system: f nixpkgs'.${system});
      treefmt-nix = eachSystem (pkgs: import ./internal/treefmt.nix pkgs);
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

      formatter = eachSystem (pkgs: treefmt-nix.${pkgs.system}.wrapper);
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
          formatting = treefmt-nix.${system}.check self;

          startuptime =
            pkgs.runCommand "nvim-startuptime"
              {
                nativeBuildInputs = [ packages.lazy-nvim ];
              }
              ''
                HOME="$PWD" nvim --headless "+Lazy! home" --startuptime out~ +q 2>&1 | tee err
                if grep "^E[0-9]\\+: " err; then
                  cat err
                  exit 1
                fi
                mv out~ "$out"
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
