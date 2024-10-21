{ pkgs, lazynvimUtils }:
lazynvimUtils.makeLazyNeovimPackage {
  inherit pkgs;
  spec = [ ];
}
