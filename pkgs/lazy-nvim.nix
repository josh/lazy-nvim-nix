{
  lib,
  runCommand,
  wrapNeovimUnstable,
  neovim-unwrapped,
  lazynvimPlugins,
  lazynvimUtils,
  neovimUtils,
  neovim-checkhealth,
  bash,
  git,
  fd,
  lua5_1,
  luajitPackages,
  ripgrep,
  spec ? [ ],
  extraPackages ? [ ],
}:
let
  lazypath = lazynvimPlugins."lazy.nvim";

  opts = lazynvimUtils.defaultLazyOpts;

  moreExtraPackages = [
    bash
    fd
    git
    lua5_1
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
    passthru.tests =
      let
        neovim = finalAttrs.finalPackage;
      in
      {
        help = runCommand "nvim-help" { nativeBuildInputs = [ neovim ]; } ''
          nvim --help 2>&1 >out~
          mv out~ "$out"
        '';

        checkhealth = neovim-checkhealth.override {
          inherit neovim;
          checkError = true;
          checkWarning = true;
        };

        checkhealth-lazy = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "lazy";
          checkError = true;
          checkWarning = true;
        };

        checkhealth-vim-deprecated = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "vim.deprecated";
          checkError = true;
          checkWarning = true;
        };

        checkhealth-vim-health = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "vim.health";
          checkError = true;
          checkWarning = true;
        };

        checkhealth-vim-lsp = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "vim.lsp";
          checkError = true;
          checkWarning = true;
          checkOk = false;
        };

        checkhealth-vim-provider = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "vim.provider";
          checkError = true;
          checkWarning = true;
        };

        checkhealth-vim-treesitter = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "vim.treesitter";
          checkError = true;
          checkWarning = true;
        };

        startuptime = runCommand "nvim-startuptime" { nativeBuildInputs = [ neovim ]; } ''
          HOME="$PWD" nvim --headless "+Lazy! home" --startuptime out~ +q 2>&1 | tee err
          if grep "^E[0-9]\\+: " err; then
            cat err
            exit 1
          fi
          mv out~ "$out"
        '';
      };
  }
)
