{
  lib,
  runCommand,
  wrapNeovimUnstable,
  neovim-unwrapped,
  lazynvimPlugins,
  lazynvimUtils,
  neovimUtils,
  neovim-checkhealth,
  git,
  fd,
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
    fd
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
    mainProgram = "nvim";
    wrapperArgs = lib.escapeShellArgs config.wrapperArgs + " '--prefix' 'PATH' : '${extrasBinPath}' ";
  };

  finalConfig = config // configExtra;
in
(wrapNeovimUnstable neovim-unwrapped finalConfig).overrideAttrs (
  finalAttrs: _previousAttrs: {
    passthru.tests = {
      help = runCommand "nvim-help" { nativeBuildInputs = [ finalAttrs.finalPackage ]; } ''
        nvim --help 2>&1 >$out 
      '';

      checkhealth = neovim-checkhealth.override {
        neovim = finalAttrs.finalPackage;
        checkError = false;
        checkWarning = false;
      };

      startuptime = runCommand "nvim-startuptime" { nativeBuildInputs = [ finalAttrs.finalPackage ]; } ''
        nvim --headless "+Lazy! home" --startuptime "$out" +q
      '';
    };
  }
)
