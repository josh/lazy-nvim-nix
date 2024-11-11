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

          localPkgs = lib'.flattenDerivations (
            self.packages.${system} // { inherit (pkgs) lazynvimPlugins; }
          );
          localTests = lib.concatMap (
            pkg:
            if (builtins.hasAttr "passthru" pkg) && (builtins.hasAttr "tests" pkg.passthru) then
              (builtins.attrValues pkg.passthru.tests)
            else
              [ ]
          ) localPkgs;
        in
        {
          formatting = treefmtEval.${system}.config.build.check self;

          build = pkgs.runCommandLocal "build-packages" { inherit localPkgs; } "touch $out";
          tests = pkgs.runCommandLocal "run-tests" { inherit localTests; } "touch $out";

          checkhealth = pkgs.runCommand "nvim-checkhealth" { } ''
            ${lib.getExe packages.lazy-nvim} --headless "+Lazy! home" +checkhealth "+w!$out" +qa
          '';

          checkhealth-LazyVim = pkgs.runCommand "nvim-checkhealth" { } ''
            ${lib.getExe packages.LazyVim} --headless "+Lazy! home" +checkhealth "+w!$out" +qa
          '';

          startuptime = pkgs.runCommand "nvim-startuptime" { } ''
            ${lib.getExe packages.lazy-nvim} --headless "+Lazy! home" --startuptime "$out" +q
          '';

          LazyVimPlugins-outdated = pkgs.testers.testEqualContents {
            assertion = "plugins/LazyVim.json out of date";
            expected = self.packages.${system}.LazyVimPlugins;
            actual = pkgs.runCommandLocal "git-LazyVim-json" { } ''
              cp ${./plugins/LazyVim.json} $out
            '';
          };

          LazyVim-extras-catppuccin = plugins.LazyVim.extras."lazyvim.plugins".catppuccin;
          LazyVim-extras-all = pkgs.runCommandLocal "LazyVim-extras-all" {
            buildInputs = lib'.flattenDerivations plugins.LazyVim.extras;
          } "touch $out";
        }
      );
    };
}
