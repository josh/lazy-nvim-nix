{
  lib,
  callPackage,
  runCommand,
  wrapNeovimUnstable,
  neovim-unwrapped,
  neovimUtils,
  lazy-nvim-nix,
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
  lib' = lazy-nvim-nix.lib;
  inherit (lazy-nvim-nix) plugins;
  lazypath = plugins."lazy.nvim";

  opts = lib'.defaultLazyOpts;

  moreExtraPackages = [
    bash
    fd
    git
    lua5_1
    luajitPackages.luarocks
    ripgrep
  ] ++ extraPackages;

  extrasBinPath = lib.makeBinPath moreExtraPackages;

  customLuaRC = ''
    vim.opt.rtp:prepend("${lazypath}");
    require("lazy").setup(${lib'.toLua spec}, ${lib'.toLua opts})
  '';

  config = neovimUtils.makeNeovimConfig {
    # See pkgs/applications/editors/neovim/utils.nix # makeNeovimConfig

    withPython3 = false;
    withNodeJs = false;
    withRuby = false;

    # Extra config to pass to
    # pkgs/applications/editors/neovim/wrapper.nix

    inherit customLuaRC;
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
        neovim-checkhealth = callPackage ./tests/neovim-checkhealth.nix { inherit neovim; };
      in
      {
        help = runCommand "nvim-help" { nativeBuildInputs = [ neovim ]; } ''
          nvim --help 2>&1
          touch $out
        '';

        checkhealth = neovim-checkhealth.override {
          inherit neovim;
        };

        checkhealth-lazy = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "lazy";
        };

        checkhealth-vim-deprecated = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "vim.deprecated";
        };

        checkhealth-vim-health = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "vim.health";
        };

        checkhealth-vim-lsp = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "vim.lsp";
          checkOk = false;
        };

        checkhealth-vim-provider = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "vim.provider";
        };

        checkhealth-vim-treesitter = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "vim.treesitter";
        };

        startuptime = runCommand "nvim-startuptime" { nativeBuildInputs = [ neovim ]; } ''
          HOME="$PWD" nvim --headless "+Lazy! home" --startuptime out +q 2>&1 | tee err
          if grep "^E[0-9]\\+: " err; then
            cat err
            exit 1
          fi
          cat out
          touch $out
        '';

        check-plugins-installed = callPackage ./tests/lazy-nvim-check-plugins-installed.nix {
          inherit neovim;
        };

        edit-txt = callPackage ./tests/neovim-test-edit.nix {
          inherit neovim;
          editFile = runCommand "hello.txt" { } ''
            echo "Hello, world!" >$out
          '';
        };

        edit-md = callPackage ./tests/neovim-test-edit.nix {
          inherit neovim;
          editFile = ../README.md;
        };

        edit-nix = callPackage ./tests/neovim-test-edit.nix {
          inherit neovim;
          editFile = ../flake.nix;
        };
      };
  }
)
