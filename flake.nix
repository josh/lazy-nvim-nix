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
        inherit (pkgs) hello;
        default = self.packages.${pkgs.system}.hello;

        lazy-nvim = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped (
          lib.makeLazyNeovimConfig { inherit pkgs; }
        );
      });

      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
      checks = eachSystem (
        pkgs:
        let
          inherit (self.packages.${pkgs.system}) lazy-nvim;
        in
        {
          formatting = treefmtEval.${pkgs.system}.config.build.check self;

          help = pkgs.runCommandLocal "nvim-help" { } ''
            ${lazy-nvim}/bin/nvim --help 2>&1 >$out 
          '';

          health = pkgs.runCommandLocal "nvim-chechhealth" { } ''
            ${lazy-nvim}/bin/nvim --headless +checkhealth "+w!$out" +qa
          '';

          startuptime = pkgs.runCommandLocal "nvim-startuptime" { } ''
            ${lazy-nvim}/bin/nvim --headless --startuptime "$out" +q
          '';
        }
      );
    };
}
