{
  lib,
  stdenv,
  callPackage,
  lazy-nvim-nix,
  lazygit,
  lazy-nvim ? lazy-nvim-nix.lazy-nvim,
  customLuaRC ? "",
  extras ? [ ],
  extraSpec ? [ ],
  extraPackages ? [ ],
  opts ? { },
}:
let
  inherit (lazy-nvim-nix) plugins;
  excludeSpecs = [
    "recurseForDerivations"
  ];
  moduleSpecs =
    name:
    lib.attrsets.mapAttrsToList (_: drv: drv.spec) (
      builtins.removeAttrs plugins."LazyVim".extras.${name} excludeSpecs
    );

  availableExtras = builtins.filter (lib.strings.hasPrefix "lazyvim.plugins.extras.") (
    builtins.attrNames plugins."LazyVim".extras
  );
  extrasSpec = lib.lists.concatMap (
    name:
    if builtins.hasAttr name plugins."LazyVim".extras then
      [ { "import" = name; } ] ++ moduleSpecs name
    else
      throw ''
        unknown LazyVim extra "${name}", available extras:
        ${lib.strings.concatMapStringsSep "\n" (n: "  ${n}") availableExtras}''
  ) extras;
in
(lazy-nvim.override (
  {
    spec = [
      plugins."LazyVim".spec
      { "import" = "lazyvim.plugins"; }

      # FIXME: Not being picked up by LazyVim.json dependency scan
      plugins."blink.cmp".spec
      plugins."friendly-snippets".spec
      plugins."fzf-lua".spec
      plugins."neo-tree.nvim".spec
      plugins."snacks.nvim".spec

      {
        name = "nvim-treesitter-parsers";
        dir = "${plugins."nvim-treesitter".installDir}";
        lazy = false;
      }

      # lazy.nvim cannot auto-load store-dir plugins on require(); load eagerly
      # so lualine's statusline gets an initialized trouble
      (plugins."trouble.nvim".spec // { lazy = false; })
    ]
    ++ (moduleSpecs "lazyvim.plugins")
    ++ extrasSpec
    ++ extraSpec;

    extraPackages = [
      lazygit
    ]
    ++ plugins."blink.cmp".extraPackages
    ++ plugins."conform.nvim".extraPackages
    ++ plugins."fzf-lua".extraPackages
    ++ plugins."grug-far.nvim".extraPackages
    ++ plugins."mason.nvim".extraPackages
    ++ plugins."neo-tree.nvim".extraPackages
    ++ plugins."nvim-treesitter".extraPackages
    ++ plugins."snacks.nvim".extraPackages
    ++ extraPackages;
  }
  // lib.attrsets.optionalAttrs (customLuaRC != "") { inherit customLuaRC; }
  // lib.attrsets.optionalAttrs (opts != { }) { inherit opts; }
)).overrideAttrs
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
            ignoreLines = [
              # OK: notifier readiness probes vim.notify, which noice routes
              # asynchronously; the roundtrip never completes headless
              "ERROR is not ready"
              # OK: install_dir is the read-only nix store
              "ERROR is not writable."
              # FIXME: nixpkgs packages no ecma/jsx/html_tags component grammars
              "ERROR html(queries):"
              "ERROR javascript(queries):"
              "ERROR svelte(queries):"
              "ERROR tsx(queries):"
              "ERROR typescript(queries):"
              "ERROR vue(queries):"
              # FIXME: nixpkgs diff grammar lags its highlights query
              "ERROR diff(highlights):"
              # OK: snacks sub-features intentionally not enabled by this config
              "WARNING setup {disabled}"
              # OK: only `norg` is missing, no nixpkgs grammar
              "WARNING Missing Treesitter languages"
              "WARNING Image rendering in docs with missing treesitter parsers won't work"
              # OK: inherent to --headless
              "WARNING dashboard did not open: `headless`"
            ]
            ++ lib.lists.optionals stdenv.hostPlatform.isDarwin [
              # OK: osascript is a macOS system binary, not on the sandbox PATH
              "WARNING `osascript` not found (built-in)"
            ]
            ++ lib.lists.optionals stdenv.hostPlatform.isLinux [
              # OK: gio trash needs a DBus session, absent in the sandbox
              "WARNING `gio trash` --list failed, maybe you need `gvfs` installed?"
            ];
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
            optionalIgnoreLines = [
              # OK: mason's live version probe; only reachable without a sandbox
              "WARNING mason.nvim version"
            ];
          };

          checkhealth-neo-tree = neovim-checkhealth.override {
            inherit neovim;
            pluginName = "neo-tree";
            loadLazyPluginName = "neo-tree.nvim";
            ignoreLines =
              lib.lists.optionals stdenv.hostPlatform.isDarwin [
                # OK: osascript is a macOS system binary, not on the sandbox PATH
                "WARNING `osascript` not found (built-in)"
              ]
              ++ lib.lists.optionals stdenv.hostPlatform.isLinux [
                # OK: gio trash needs a DBus session, absent in the sandbox
                "WARNING `gio trash` --list failed, maybe you need `gvfs` installed?"
              ];
          };

          checkhealth-noice = neovim-checkhealth.override {
            inherit neovim;
            pluginName = "noice";
            loadLazyPluginName = "noice.nvim";
          };

          checkhealth-nvim-treesitter = neovim-checkhealth.override {
            inherit neovim;
            pluginName = "nvim-treesitter";
            loadLazyPluginName = "nvim-treesitter";
            ignoreLines = [
              # OK: install_dir is the read-only nix store
              "ERROR is not writable."
              # FIXME: nixpkgs packages no ecma/jsx/html_tags component grammars
              "ERROR html(queries):"
              "ERROR javascript(queries):"
              "ERROR svelte(queries):"
              "ERROR tsx(queries):"
              "ERROR typescript(queries):"
              "ERROR vue(queries):"
              # FIXME: nixpkgs diff grammar lags its highlights query
              "ERROR diff(highlights):"
            ];
          };

          checkhealth-snacks = neovim-checkhealth.override {
            inherit neovim;
            pluginName = "snacks";
            loadLazyPluginName = "snacks.nvim";
            ignoreLines = [
              # OK: notifier readiness probes vim.notify, which noice routes
              # asynchronously; the roundtrip never completes headless
              "ERROR is not ready"
              "WARNING dashboard did not open: `headless`"
              # OK: snacks sub-features intentionally not enabled by this config
              "WARNING setup {disabled}"
              # OK: only `norg` is missing, no nixpkgs grammar
              "WARNING Missing Treesitter languages"
              "WARNING Image rendering in docs with missing treesitter parsers won't work"
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
