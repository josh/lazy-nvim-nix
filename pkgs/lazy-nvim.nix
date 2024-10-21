{
  lib,
  wrapNeovimUnstable,
  neovim-unwrapped,
  lazynvimPlugins,
  lazynvimUtils,
  neovimUtils,
  git,
  luajitPackages,
  ripgrep,
  spec ? [ ],
  extraPackages ? [ ],
}:
let
  lazypath = lazynvimPlugins."lazy.nvim";

  opts = lazynvimUtils.defaultLazyOpts;

  moreExtraPackages = [
    git
    luajitPackages.luarocks
    ripgrep
  ] ++ extraPackages;

  extrasBinPath = lib.makeBinPath moreExtraPackages;

  luaRcContent = ''
    vim.opt.rtp:prepend("${lazypath}");
    require("lazy").setup(${lazynvimUtils.toLua spec}, ${lazynvimUtils.toLua opts})
  '';

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
