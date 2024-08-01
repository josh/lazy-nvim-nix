let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  node = lock.nodes.nixpkgs.locked;
  inherit (node) owner repo rev;
  path = fetchTarball {
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    sha256 = node.narHash;
  };
in
import path
