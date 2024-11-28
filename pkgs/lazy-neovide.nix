{
  lib,
  buildEnv,
  writeShellApplication,
  neovim,
  neovide,
  neovide-config ? { },
}:
let
  boolToStr = v: if v then "1" else "";
  mkRuntimeEnv =
    {
      fork ? false,
      frame ? "full",
      idle ? true,
      maximized ? false,
      neovim-bin ? (lib.getExe neovim),
      no-multigrid ? false,
      srgb ? false,
      tabs ? true,
      mouse-cursor-icon ? "arrow",
      title-hidden ? true,
      vsync ? true,
    }:
    {
      NEOVIDE_FRAME = frame;
      NEOVIDE_MAXIMIZED = boolToStr maximized;
      NEOVIDE_NO_MULTIGRID = boolToStr no-multigrid;
      NEOVIDE_FORK = boolToStr fork;
      NEOVIDE_IDLE = boolToStr idle;
      NEOVIDE_MOUSE_CURSOR_ICON = mouse-cursor-icon;
      NEOVIDE_TITLE_HIDDEN = boolToStr title-hidden;
      NEOVIDE_SRGB = boolToStr srgb;
      NEOVIDE_TABS = boolToStr tabs;
      NEOVIDE_VSYNC = boolToStr vsync;
      NEOVIM_BIN = neovim-bin;
    };
  wrapper = writeShellApplication {
    name = "neovide";
    runtimeInputs = [ ];
    runtimeEnv = mkRuntimeEnv neovide-config;
    text = ''
      exec -a "$0" "${lib.getExe neovide}" "$@"
    '';
  };
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
