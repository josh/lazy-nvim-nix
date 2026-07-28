{
  lib,
  callPackage,
  lazy-nvim-nix,
  lazygit,
  lazy-nvim ? lazy-nvim-nix.lazy-nvim,
}:
let
  inherit (lazy-nvim-nix) plugins;
  excludeSpecs = [
    "recurseForDerivations"
    "nvim-treesitter"
    "nvim-treesitter-textobjects"
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

    # lazy.nvim cannot auto-load store-dir plugins on require(); load eagerly
    # so lualine's statusline gets an initialized trouble
    (plugins."trouble.nvim".spec // { lazy = false; })
  ]
  ++ (extraSpecs "lazyvim.plugins");

  extraPackages = [
    lazygit
  ]
  ++ plugins."blink.cmp".extraPackages
  ++ plugins."conform.nvim".extraPackages
  ++ plugins."fzf-lua".extraPackages
  ++ plugins."grug-far.nvim".extraPackages
  ++ plugins."mason.nvim".extraPackages
  ++ plugins."nvim-treesitter".extraPackages
  ++ plugins."snacks.nvim".extraPackages;
}).overrideAttrs
  (
    finalAttrs: previousAttrs:
    let
      neovim = finalAttrs.finalPackage;
      neovim-checkhealth = callPackage ./tests/neovim-checkhealth.nix { inherit neovim; };
    in
    {
      passthru = previousAttrs.passthru // {
        tests = previousAttrs.passthru.tests // {
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

          checkhealth-conform = neovim-checkhealth.override {
            inherit neovim;
            pluginName = "conform";
            loadLazyPluginName = "conform.nvim";
          };

          checkhealth-fzf-lua = neovim-checkhealth.override {
            inherit neovim;
            pluginName = "fzf_lua";
            loadLazyPluginName = "fzf-lua";
          };

          checkhealth-grug-far = neovim-checkhealth.override {
            inherit neovim;
            pluginName = "grug-far";
            loadLazyPluginName = "grug-far.nvim";
          };

          checkhealth-lspconfig = neovim-checkhealth.override {
            inherit neovim;
            pluginName = "lspconfig";
            loadLazyPluginName = "nvim-lspconfig";
            checkOk = false;
          };

          checkhealth-mason-lspconfig = neovim-checkhealth.override {
            inherit neovim;
            pluginName = "mason-lspconfig";
            loadLazyPluginName = "mason-lspconfig.nvim";
          };

          checkhealth-mason = neovim-checkhealth.override {
            inherit neovim;
            pluginName = "mason";
            loadLazyPluginName = "mason.nvim";
            ignoreLines = [
              # OK: julia is intentionally not shipped; its closure is too large
              "WARNING julia: not available"
            ];
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
              # OK: headless nvim has no TTY to answer the kitty graphics query
              "ERROR is not ready"
              "ERROR your terminal does not support the kitty graphics protocol"
              "WARNING dashboard did not open: `headless`"
              # OK: snacks sub-features intentionally not enabled by this config
              "WARNING setup {disabled}"
              # FIXME: These should be fixable if we install treesitter correctly
              "WARNING Image rendering in docs with missing treesitter parsers won't work"
              "WARNING Missing Treesitter languages"
              "WARNING The `latex` treesitter parser is required to render LaTeX math expressions"
            ];
          };

          checkhealth-which-key = neovim-checkhealth.override {
            inherit neovim;
            pluginName = "which-key";
            loadLazyPluginName = "which-key.nvim";
          };
        };
      };
    }
  )
