{
  lib,
  wrapNeovimUnstable,
  neovim-unwrapped,
  lazynvimUtils,
  neovimUtils,
  pkgs,
  git,
  luajitPackages,
  ripgrep,
  spec ? [ ],
  extraPackages ? [ ],
}:
let
  moreExtraPackages = [
    git
    luajitPackages.luarocks
    ripgrep
  ] ++ extraPackages;

  extrasBinPath = lib.makeBinPath moreExtraPackages;

  luaRcContent = lazynvimUtils.setupLazyLua {
    inherit pkgs spec;
    opts = lazynvimUtils.defaultLazyOpts;
  };

  config = neovimUtils.makeNeovimConfig {
    # See pkgs/applications/editors/neovim/utils.nix # makeNeovimConfig

    withPython3 = false;
    withNodeJs = false;
    withRuby = false;

    # Extra config to pass to
    # pkgs/applications/editors/neovim/wrapper.nix

    inherit luaRcContent;
  };

  # Unfortunately can't pass extraWrapperArgs to makeNeovimConfig
  configExtra = {
    wrapperArgs = lib.escapeShellArgs config.wrapperArgs + " '--prefix' 'PATH' : '${extrasBinPath}' ";
  };

  finalConfig = config // configExtra;
in
wrapNeovimUnstable neovim-unwrapped finalConfig
