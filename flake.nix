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
        check-plugin-sources = pkgs.callPackage ./pkgs/check-plugin-sources.nix { };
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
          inherit (pkgs.lazy-nvim-nix) plugins;

          buildPkg = name: pkg: pkgs.runCommand "${name}-build" { env.PKG = pkg; } "touch $out";
          addAttrsetPrefix = prefix: lib.attrsets.concatMapAttrs (n: v: { "${prefix}${n}" = v; });
          localTests = lib.attrsets.concatMapAttrs (
            pkgName: pkg:
            if (builtins.hasAttr "tests" pkg) then
              ({ "${pkgName}-build" = buildPkg pkgName pkg; } // (addAttrsetPrefix "${pkgName}-tests-" pkg.tests))
            else
              { "${pkgName}-build" = buildPkg pkgName pkg; }
          ) (builtins.removeAttrs self.packages.${system} [ "default" ]);
        in
        {
          formatting = treefmt-nix.${system}.check self;

          LazyVimPlugins-outdated =
            pkgs.runCommand "LazyVimPlugins-outdated"
              {
                nativeBuildInputs = [ pkgs.diffutils ];
                actual = self.packages.${system}.LazyVimPlugins;
                expected = ./plugins/LazyVim.json;
              }
              ''
                diff --unified $expected $actual
                touch $out
              '';

          blink-cmp-checkhealth = pkgs.callPackage ./pkgs/tests/blink-cmp-checkhealth.nix { };
          LazyVim-config-hooks = pkgs.callPackage ./pkgs/tests/lazyvim-config-hooks.nix { };
          LazyVim-config-json = pkgs.callPackage ./pkgs/tests/lazyvim-config-json.nix { };
          LazyVim-config-options = pkgs.callPackage ./pkgs/tests/lazyvim-config-options.nix { };
          LazyVim-config-pickers = pkgs.callPackage ./pkgs/tests/lazyvim-config-pickers.nix { };
          crates-checkhealth = pkgs.callPackage ./pkgs/tests/crates-checkhealth.nix { };
          fzf-lua-checkhealth = pkgs.callPackage ./pkgs/tests/fzf-lua-checkhealth.nix { };
          kulala-checkhealth = pkgs.callPackage ./pkgs/tests/kulala-checkhealth.nix { };
          luasnip-checkhealth = pkgs.callPackage ./pkgs/tests/luasnip-checkhealth.nix { };
          luasnip-extra-checkhealth = pkgs.callPackage ./pkgs/tests/luasnip-extra-checkhealth.nix { };
          markdown-preview-checkhealth = pkgs.callPackage ./pkgs/tests/markdown-preview-checkhealth.nix { };
          mason-nvim-checkhealth = pkgs.callPackage ./pkgs/tests/mason-nvim-checkhealth.nix { };
          mason-registry-load = pkgs.callPackage ./pkgs/tests/mason-registry-load.nix { };
          neoconf-checkhealth = pkgs.callPackage ./pkgs/tests/neoconf-checkhealth.nix { };
          noice-checkhealth = pkgs.callPackage ./pkgs/tests/noice-checkhealth.nix { };
          none-ls-checkhealth = pkgs.callPackage ./pkgs/tests/none-ls-checkhealth.nix { };
          nvim-dap-checkhealth = pkgs.callPackage ./pkgs/tests/nvim-dap-checkhealth.nix { };
          nvim-treesitter = pkgs.callPackage ./pkgs/tests/nvim-treesitter.nix { };
          octo-checkhealth = pkgs.callPackage ./pkgs/tests/octo-checkhealth.nix { };
          overseer-checkhealth = pkgs.callPackage ./pkgs/tests/overseer-checkhealth.nix { };
          render-markdown-checkhealth = pkgs.callPackage ./pkgs/tests/render-markdown-checkhealth.nix { };
          rustaceanvim-checkhealth = pkgs.callPackage ./pkgs/tests/rustaceanvim-checkhealth.nix { };
          snacks-nvim-checkhealth = pkgs.callPackage ./pkgs/tests/snacks-nvim-checkhealth.nix { };
          telescope-checkhealth = pkgs.callPackage ./pkgs/tests/telescope-checkhealth.nix { };
          telescope-extra-checkhealth = pkgs.callPackage ./pkgs/tests/telescope-extra-checkhealth.nix { };

          LazyVim-extras-eval = pkgs.runCommandLocal "LazyVim-extras-eval" {
            env.extrasHash = builtins.hashString "sha256" (
              lib.strings.concatMapStringsSep ";" (
                name:
                builtins.unsafeDiscardStringContext
                  (pkgs.lazy-nvim-nix.LazyVim.override { extras = [ name ]; }).drvPath
              ) pkgs.lazy-nvim-nix.LazyVim.availableExtras
            );
          } "touch $out";

          LazyVim-extras-leap-plugins-installed =
            (pkgs.lazy-nvim-nix.LazyVim.override {
              extras = [ "lazyvim.plugins.extras.editor.leap" ];
            }).tests.check-plugins-installed;

          LazyVim-extras-combo-plugins-installed =
            (pkgs.lazy-nvim-nix.LazyVim.override {
              extras = builtins.filter (
                n:
                n != "lazyvim.plugins.extras.ai.copilot-native"
                && (
                  lib.strings.hasPrefix "lazyvim.plugins.extras.lang." n
                  || lib.strings.hasPrefix "lazyvim.plugins.extras.ai." n
                  || builtins.elem n [
                    "lazyvim.plugins.extras.dap.core"
                    "lazyvim.plugins.extras.test.core"
                  ]
                )
              ) pkgs.lazy-nvim-nix.LazyVim.availableExtras;
            }).tests.check-plugins-installed;

          LazyVim-extras-catppuccin =
            buildPkg "LazyVim-extras-catppuccin"
              plugins.LazyVim.extras."lazyvim.plugins".catppuccin;
          LazyVim-extras-all = pkgs.runCommandLocal "LazyVim-extras-all" {
            nativeBuildInputs = lib'.flattenDerivations plugins.LazyVim.extras;
          } "touch $out";
        }
        // localTests
      );
    };
}
