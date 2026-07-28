{
  inputs = {
    # https://github.com/renovatebot/renovate/issues/29721
    # "github:NixOS/nixpkgs/nixpkgs-unstable"
    treefmt-nix.url = "github:numtide/treefmt-nix";
    # Safe to drop: treefmt.nix passes pkgs explicitly, and builtins.getFlake
    # resolves treefmt-nix's inputs from its own lock, never from this one
    treefmt-nix.inputs.nixpkgs.follows = "";
  };
  outputs = _inputs: { };
}
