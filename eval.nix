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
    mkNixEvalFile {
      inherit pkgs env;
      file = builtins.toFile "default.nix" src;
    };

  # Build Nix evaluation derivation from a file.
  # 
  # Output will be a serialized as JSON.
  #
  # Example:
  #
  #   mkNixEvalFile {
  #     inherit pkgs;
  #     file = ./foo.nix;
  #   }
  #
  mkNixEvalFile =
    {
      file,
      pkgs,
      name ? "nix-eval",
      nixpkgs ? (builtins.storePath pkgs.path),
      system ? pkgs.system,
      env ? { },
    }:
    let
      out = builtins.placeholder "out";
    in
    derivation (
      {
        inherit name system;
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
  # WARN: requires allow-import-from-derivation
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
  inherit mkNixEvalFile mkNixEval nixEval;
}
