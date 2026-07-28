{
  lib,
  stdenv,
  buildEnv,
  runCommand,
  writeShellApplication,
  neovim,
  neovide,
  neovide-config ? { },
}:
let
  envNames = {
    fork = "NEOVIDE_FORK";
    frame = "NEOVIDE_FRAME";
    idle = "NEOVIDE_IDLE";
    maximized = "NEOVIDE_MAXIMIZED";
    mouse-cursor-icon = "NEOVIDE_MOUSE_CURSOR_ICON";
    neovim-bin = "NEOVIM_BIN";
    no-multigrid = "NEOVIDE_NO_MULTIGRID";
    srgb = "NEOVIDE_SRGB";
    tabs = "NEOVIDE_TABS";
    title-hidden = "NEOVIDE_TITLE_HIDDEN";
    vsync = "NEOVIDE_VSYNC";
  };
  unknownKeys = builtins.attrNames (
    builtins.removeAttrs neovide-config (builtins.attrNames envNames)
  );
  toEnvValue = v: if builtins.isBool v then (if v then "1" else "") else v;
  config = {
    neovim-bin = lib.getExe neovim;
  }
  // neovide-config;
  exportLine = key: value: ''
    if [ -z "''${${envNames.${key}}+x}" ]; then export ${envNames.${key}}=${lib.escapeShellArg (toEnvValue value)}; fi
  '';
  wrapper = writeShellApplication {
    name = "neovide";
    text = lib.concatStrings (lib.mapAttrsToList exportLine config) + ''
      exec -a "$0" "${lib.getExe neovide}" "$@"
    '';
  };
in
assert lib.assertMsg (unknownKeys == [ ]) ''
  lazy-neovide: unknown neovide-config keys: ${toString unknownKeys}
  valid keys: ${toString (builtins.attrNames envNames)}'';
buildEnv {
  inherit (neovide) name;
  paths = [
    wrapper
    neovide
  ];
  ignoreCollisions = true;
  postBuild = ''
    rm -f $out/bin/.neovide-wrapped
    grep -q "NEOVIM_BIN" $out/bin/neovide
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    app=$out/Applications/Neovide.app
    contents="$(readlink -f "$app")/Contents"
    rm -rf $out/Applications
    mkdir -p "$app/Contents"
    for entry in "$contents"/*; do
      [ "$(basename "$entry")" = MacOS ] || ln -s "$entry" "$app/Contents/"
    done
    ln -s $out/bin "$app/Contents/MacOS"
    grep -q "NEOVIM_BIN" "$app/Contents/MacOS/neovide"
  '';
  meta = {
    inherit (neovide.meta)
      description
      homepage
      license
      platforms
      ;
    mainProgram = "neovide";
  };
  passthru.tests = {
    wrapper-env = runCommand "neovide-wrapper-env" { } ''
      grep -q "NEOVIM_BIN" ${wrapper}/bin/neovide
      ! grep -q "NEOVIDE_MAXIMIZED" ${wrapper}/bin/neovide
      touch $out
    '';
  };
}
