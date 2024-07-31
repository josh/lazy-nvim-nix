{
  description = "Lazy Neovim on Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
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
      lib = import ./lib.nix;
    in
    {
      inherit lib;

      packages = eachSystem (pkgs: {
        default = self.packages.${pkgs.system}.nvim;

        nvim = lib.makeLazyNeovimPackage { inherit pkgs; };
      });

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

          health = pkgs.runCommandLocal "nvim-chechhealth" { } ''
            ${nvim}/bin/nvim --headless "+lua require('lazy').health():wait()" +checkhealth "+w!$out" +qa
          '';

          startuptime = pkgs.runCommandLocal "nvim-startuptime" { } ''
            ${nvim}/bin/nvim --headless "+lua require('lazy').health():wait()" --startuptime "$out" +q
          '';
        }
      );
    };
}
