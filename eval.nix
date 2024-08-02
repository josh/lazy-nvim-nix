let
  # Build Nix evaluation derivation.
  #
  # Output will be a serialized as JSON.
  #
  # Example:
  #
  #   mkNixEval {
  #     inherit pkgs;
  #     src = ''{ message = "Hello, World!"; }'';
  #   } 
  #
  mkNixEval =
    {
      pkgs,
      src,
      env ? { },
    }:
    let
      nixpkgs = builtins.storePath pkgs.path;
      file = builtins.toFile "default.nix" src;
      out = builtins.placeholder "out";
    in
    derivation (
      {
        name = "nix-eval";
        inherit (pkgs) system;
        builder = "${pkgs.nix}/bin/nix";
        NIX_PATH = "nixpkgs=${nixpkgs}";
        args = [
          "--extra-experimental-features"
          "nix-command"
          "eval"
          "--store"
          "dummy://"
          "--eval-store"
          "dummy://"
          "--read-only"
          "--show-trace"
          "--file"
          file
          "--apply"
          "builtins.toJSON"
          "--write-to"
          out
        ];
      }
      // env
    );

  # Evaluate a Nix expression string.
  #
  # NOTE: requires allow-import-from-derivation
  #
  # Example:
  #
  #   nixEval {
  #     inherit pkgs;
  #     src = ''{ message = "Hello, World!"; }'';
  #   } 
  #
  #   nixEval {
  #     inherit pkgs;
  #     src = ''
  #       let pkgs = import <nixpkgs> { }; in
  #       { nixpkgs = pkgs.lib.version; }
  #     '';
  #   }
  #
  nixEval = inputs: builtins.fromJSON (builtins.readFile (mkNixEval inputs));
in
{
  inherit mkNixEval nixEval;
}
