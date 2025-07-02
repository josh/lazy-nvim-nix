{
  lib,
  stdenv,
  callPackage,
  lazy-nvim,
  lazynvimPlugins,
  julia,
  lazygit,
}:
let
  plugins = lazynvimPlugins;
  excludeSpecs = [
    "recurseForDerivations"
    "nvim-treesitter"
    "nvim-treesitter-textobjects"
    "trouble.nvim"
  ];
  extraSpecs =
    name:
    lib.attrsets.mapAttrsToList (_: drv: drv.spec) (
      builtins.removeAttrs plugins."LazyVim".extras.${name} excludeSpecs
    );
in
(lazy-nvim.override {
  spec = [
    plugins."LazyVim".spec
    { "import" = "lazyvim.plugins"; }

    # FIXME: Not being picked up by LazyVim.json dependency scan
    plugins."blink.cmp".spec
    plugins."friendly-snippets".spec
    plugins."fzf-lua".spec
    plugins."neo-tree.nvim".spec
    plugins."snacks.nvim".spec

    # FIXME: Tries to write to /nix/store/.../parser directory
    (plugins."nvim-treesitter".spec // { enabled = false; })
    (plugins."nvim-treesitter-textobjects".spec // { enabled = false; })

    # FIXME: trouble.nvim doesn't like be loaded from /nix/store
    (plugins."trouble.nvim".spec // { enabled = false; })
  ] ++ (extraSpecs "lazyvim.plugins");

  extraPackages =
    [
      lazygit
    ]
    ++ plugins."blink.cmp".extraPackages
    ++ plugins."fzf-lua".extraPackages
    ++ plugins."mason.nvim".extraPackages
    ++ plugins."snacks.nvim".extraPackages;
}).overrideAttrs
  (
    finalAttrs: previousAttrs:
    let
      neovim = finalAttrs.finalPackage;
      neovim-checkhealth = callPackage ./tests/neovim-checkhealth.nix { inherit neovim; };
    in
    {
      passthru.tests = previousAttrs.passthru.tests // {
        checkhealth = neovim-checkhealth.override {
          inherit neovim;
          checkError = false;
          checkWarning = false;
        };

        checkhealth-lazyvim = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "lazyvim";
        };

        checkhealth-blink-cmp = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "blink.cmp";
          loadLazyPluginName = "blink.cmp";
          ignoreLines = [
            # OK: Not fixable, this warning is always shown
            "WARNING Some providers may show up as \"disabled\" but are enabled dynamically"
          ];
        };

        checkhealth-fzf-lua = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "fzf_lua";
          loadLazyPluginName = "fzf-lua";
        };

        checkhealth-mason = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "mason";
          loadLazyPluginName = "mason.nvim";
          ignoreLines =
            [
              # FIXME: These errors should be fixable if we install the correct dependencies
              "ERROR Registry `github.com/mason-org/mason-registry [uninstalled]` is not installed"
              # OK: Nix build sandbox will always prevent access to github API
              "WARNING Failed to check GitHub API rate limit status"
            ]
            ++ (lib.lists.optional (
              !lib.meta.availableOn stdenv.hostPlatform julia
            ) "WARNING julia: not available");
        };

        checkhealth-noice = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "noice";
          loadLazyPluginName = "noice.nvim";
          ignoreLines = [
            # FIXME: These should be fixable if we install treesitter correctly
            "WARNING {TreeSitter} `regex` parser is not installed"
            "WARNING {TreeSitter} `bash` parser is not installed"
          ];
        };

        checkhealth-snacks = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "snacks";
          loadLazyPluginName = "snacks.nvim";
          ignoreLines = [
            # FIXME: Look into these errors, some may be fixable
            "WARNING dashboard did not open: `headless`"
            "WARNING setup {disabled}"
            "WARNING Image rendering in docs with missing treesitter parsers won't work"
            "WARNING The `latex` treesitter parser is required to render LaTeX math expressions"
            "ERROR is not ready"
            "WARNING Missing Treesitter languages"
          ];
        };

        checkhealth-which-key = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "which-key";
          loadLazyPluginName = "which-key.nvim";
        };
      };
    }
  )
