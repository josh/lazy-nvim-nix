{
  inputs = {
    # https://github.com/renovatebot/renovate/issues/29721
    # "github:NixOS/nixpkgs/nixpkgs-unstable"
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
  outputs = _inputs: { };
}
