{
  description = "Lazy Neovim on Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      lib' = import ./lib.nix { inherit nixpkgs; };
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      eachSystem = lib.genAttrs systems;
      eachPkgs =
        f: lib.genAttrs systems (system: f (nixpkgs.legacyPackages.${system}.extend self.overlays.default));
      treefmt-nix = eachSystem (system: import ./internal/treefmt.nix nixpkgs.legacyPackages.${system});
    in
    {
      lib = lib';

      packages = eachPkgs (pkgs: {
        inherit (pkgs.lazy-nvim-nix)
          lazy-nvim-config
          lazy-nvim
          LazyVim
          lazy-neovide
          LazyVim-neovide
          ;
        default = pkgs.lazy-nvim-nix.LazyVim;
        LazyVimPlugins = pkgs.callPackage ./pkgs/lazyvim-plugins.nix { };
      });

      overlays.default = final: _prev: {
        lazy-nvim-nix = {
          lib = lib';
          plugins = final.callPackage ./plugins.nix { };
          lazy-nvim-config = final.callPackage ./pkgs/lazy-nvim-config.nix { };
          lazy-nvim = final.callPackage ./pkgs/lazy-nvim.nix { };
          LazyVim = final.callPackage ./pkgs/LazyVim.nix { };
          lazy-neovide = final.callPackage ./pkgs/lazy-neovide.nix {
            neovim = final.lazy-nvim-nix.lazy-nvim;
          };
          LazyVim-neovide = final.callPackage ./pkgs/lazy-neovide.nix {
            neovim = final.lazy-nvim-nix.LazyVim;
          };
        };
      };

      formatter = eachSystem (system: treefmt-nix.${system}.wrapper);
      checks = eachPkgs (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          packages = self.packages.${system};
          inherit (pkgs.lazy-nvim-nix) plugins;

          buildPkg = pkg: pkgs.runCommand "${pkg.name}-build" { env.PKG = pkg; } "touch $out";
          addAttrsetPrefix = prefix: lib.attrsets.concatMapAttrs (n: v: { "${prefix}${n}" = v; });
          localTests = lib.attrsets.concatMapAttrs (
            pkgName: pkg:
            if (builtins.hasAttr "tests" pkg) then
              ({ "${pkgName}-build" = buildPkg pkg; } // (addAttrsetPrefix "${pkgName}-tests-" pkg.tests))
            else
              { "${pkgName}-build" = buildPkg pkg; }
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
                HOME="$PWD" nvim --headless "+Lazy! home" --startuptime out +q 2>&1 | tee err
                if grep "^E[0-9]\\+: " err; then
                  cat err
                  exit 1
                fi
                cat out
                touch $out
              '';

          LazyVimPlugins-outdated =
            pkgs.runCommand "LazyVimPlugins-outdated"
              {
                buildInputs = [ pkgs.diffutils ];
                actual = self.packages.${system}.LazyVimPlugins;
                expected = ./plugins/LazyVim.json;
              }
              ''
                diff --unified $expected $actual
                touch $out
              '';

          blink-cmp-checkhealth = pkgs.callPackage ./pkgs/tests/blink-cmp-checkhealth.nix { };
          fzf-lua-checkhealth = pkgs.callPackage ./pkgs/tests/fzf-lua-checkhealth.nix { };
          mason-nvim-checkhealth = pkgs.callPackage ./pkgs/tests/mason-nvim-checkhealth.nix { };
          noice-checkhealth = pkgs.callPackage ./pkgs/tests/noice-checkhealth.nix { };
          nvim-treesitter = pkgs.callPackage ./pkgs/tests/nvim-treesitter.nix { };
          snacks-nvim-checkhealth = pkgs.callPackage ./pkgs/tests/snacks-nvim-checkhealth.nix { };

          LazyVim-extras-catppuccin = buildPkg plugins.LazyVim.extras."lazyvim.plugins".catppuccin;
          LazyVim-extras-all = pkgs.runCommandLocal "LazyVim-extras-all" {
            buildInputs = lib'.flattenDerivations plugins.LazyVim.extras;
          } "touch $out";
        }
        // localTests
      );
    };
}
