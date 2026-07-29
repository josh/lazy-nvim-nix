{
  lib,
  callPackage,
  runCommand,
  wrapNeovimUnstable,
  neovim-unwrapped,
  lazy-nvim-nix,
  bash,
  curl,
  git,
  fd,
  lua5_1,
  luajitPackages,
  ripgrep,
  xdg-utils,
  customLuaRC ? "",
  spec ? [ ],
  opts ? { },
  extraPackages ? [ ],
  extraLuaPackages ? (_: [ ]),
}:
let
  lib' = lazy-nvim-nix.lib;
  inherit (lazy-nvim-nix) plugins;
  lazypath = plugins."lazy.nvim";

  finalOpts = lib.recursiveUpdate lib'.defaultLazyOpts opts;

  moreExtraPackages = [
    bash
    curl
    fd
    git
    lua5_1
    luajitPackages.luarocks
    ripgrep
    xdg-utils
  ]
  ++ extraPackages;

  extrasBinPath = lib.makeBinPath moreExtraPackages;

  luaRcContent = ''
    vim.opt.rtp:prepend("${lazypath}");

    ${customLuaRC}
    require("lazy").setup(${lib'.toLua spec}, ${lib'.toLua finalOpts})
  '';

  finalConfig = {
    withPython3 = false;
    withNodeJs = false;
    withRuby = false;
    inherit extraLuaPackages luaRcContent;
    wrapperArgs = [
      "--suffix"
      "PATH"
      ":"
      extrasBinPath
    ];
  };
in
(wrapNeovimUnstable neovim-unwrapped finalConfig).overrideAttrs (
  finalAttrs: previousAttrs: {
    passthru = previousAttrs.passthru // {
      tests =
        let
          neovim = finalAttrs.finalPackage;
          neovim-checkhealth = callPackage ./tests/neovim-checkhealth.nix { inherit neovim; };
        in
        {
          help = runCommand "nvim-help" { nativeBuildInputs = [ neovim ]; } ''
            timeout --kill-after=10s 30s nvim --help 2>&1
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

          checkhealth-vim-pack = neovim-checkhealth.override {
            inherit neovim;
            pluginName = "vim.pack";
            optionalIgnoreLines = [
              # OK: appears only when something probes vim.pack.get, which
              # mkdirs an empty site/pack/core as a side effect
              "WARNING found existing packages"
              "WARNING Lockfile is absent, plugin directory is present."
            ];
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
            exit_code=0
            HOME="$PWD" timeout --kill-after=10s 120s nvim --headless "+Lazy! home" --startuptime out +q 2>&1 | tee err || exit_code=$?

            if [ "$exit_code" -eq 124 ] || [ "$exit_code" -eq 137 ]; then
              echo "nvim timed out (exit $exit_code)"
              exit 1
            elif [ "$exit_code" -ne 0 ]; then
              echo "nvim exited with code $exit_code"
              exit 1
            fi

            if grep "^E[0-9]\\+: " err; then
              exit 1
            fi
            cat out
            touch $out
          '';

          check-plugins-installed = callPackage ./tests/lazy-nvim-check-plugins-installed.nix {
            inherit neovim;
            minPlugins = if spec == [ ] then 0 else 1;
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
    };
  }
)
