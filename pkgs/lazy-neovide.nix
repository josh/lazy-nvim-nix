{
  lib,
  buildEnv,
  writeShellScriptBin,
  neovim,
  neovide,
}:
let
  wrapper = writeShellScriptBin "neovide" ''
    export NEOVIM_BIN='${lib.getExe neovim}'
    exec -a "$0" "${lib.getExe neovide}" "$@"
  '';
in
buildEnv {
  inherit (neovide) name;
  paths = [
    wrapper
    neovide
  ];
  ignoreCollisions = true;
  postBuild = ''
    rm -f $out/bin/.neovide-wrapped
  '';
}
