let
  lock = builtins.fromJSON (builtins.readFile ./flake-dev.lock);
  node = lock.nodes.treefmt-nix.locked;
  inherit (node) owner repo rev;
  path = fetchTarball {
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    sha256 = node.narHash;
  };
in
import path
