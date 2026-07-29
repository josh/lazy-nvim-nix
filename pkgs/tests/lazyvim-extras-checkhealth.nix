{
  lib,
  stdenv,
  callPackage,
  lazy-nvim-nix,
  gh,
  kulala-core,
  marksman,
  markdown-toc,
  markdownlint-cli2,
  prettier,
  python312Packages,
  rust-analyzer,
}:
callPackage ./neovim-checkhealth.nix {
  neovim = lazy-nvim-nix.LazyVim.override {
    extras = [
      "lazyvim.plugins.extras.coding.luasnip"
      "lazyvim.plugins.extras.dap.core"
      "lazyvim.plugins.extras.dap.nlua"
      "lazyvim.plugins.extras.editor.neo-tree"
      "lazyvim.plugins.extras.editor.overseer"
      "lazyvim.plugins.extras.editor.telescope"
      "lazyvim.plugins.extras.lang.markdown"
      "lazyvim.plugins.extras.lang.rust"
      "lazyvim.plugins.extras.lsp.neoconf"
      "lazyvim.plugins.extras.lsp.none-ls"
      "lazyvim.plugins.extras.util.octo"
      "lazyvim.plugins.extras.util.rest"
    ];
    extraPackages = [
      gh
      markdown-toc
      markdownlint-cli2
      marksman
      prettier
      python312Packages.pylatexenc
      rust-analyzer
    ];
    extraSpec = [
      (
        lazy-nvim-nix.plugins."mason.nvim".spec
        // {
          opts = lazy-nvim-nix.lib.mkLuaInline ''
            function(_, opts)
              opts.ensure_installed = {}
            end'';
        }
      )
      (
        lazy-nvim-nix.plugins."kulala.nvim".spec
        // {
          opts = {
            kulala_core = {
              path = lib.getExe kulala-core;
            };
          };
        }
      )
    ];
    extraLuaPackages = ps: [ ps.jsregexp ];
    customLuaRC = ''
      vim.system({ "rust-analyzer", "--version" }):wait()
    '';
  };
  loadAllPlugins = true;
  minSections = 28;
  ignoreLines = [
    # OK: notifier readiness probes vim.notify, which noice routes
    # asynchronously; the roundtrip never completes headless
    "ERROR is not ready"
    # OK: install_dir is the read-only nix store
    "nvim-treesitter|ERROR is not writable."
    # OK: unconditional upstream warning, always shown
    "WARNING Some providers may show up as \"disabled\" but are enabled dynamically"
    # OK: catppuccin probes vim.pack on load, which mkdirs an empty site/pack/core
    "WARNING found existing packages"
    "WARNING Lockfile is absent, plugin directory is present."
    # OK: julia is intentionally not shipped; its closure is too large
    "WARNING julia: not available"
    # OK: snacks sub-features intentionally not enabled by this combination
    "WARNING setup {disabled}"
    # OK: inherent to --headless
    "WARNING dashboard did not open: `headless`"
    # OK: the sandbox has no GitHub credentials
    "octo|ERROR Error running `gh auth status`"
    # OK: dressing.nvim from the telescope extra owns vim.ui here, same as upstream
    "snacks|ERROR `vim.ui.input` is not set to `Snacks.input`"
    "snacks|ERROR `vim.ui.select` is not set to `Snacks.picker.select`"
    # OK: these formatters gate on buffer or config-file conditions absent headless
    "conform|WARNING markdown-toc unavailable: Condition failed"
    "conform|WARNING markdownlint-cli2 unavailable: Condition failed"
    # OK: neoconf reads the legacy lspconfig.util.available_servers table, which
    # stays empty because LazyVim configures servers through vim.lsp.config
    "neoconf|WARNING **lspconfig jsonls** is not installed? You won't get any auto completion in your settings files"
    "neoconf|WARNING **lspconfig lua_ls** is not installed? You won't get any auto completion in your lua settings files"
    # OK: workspace and toolchain probes; the sandbox has no project open
    "overseer|WARNING {cargo}:"
    "overseer|WARNING {cargo-make}:"
    "overseer|WARNING {composer}:"
    "overseer|WARNING {deno}:"
    "overseer|WARNING {devenv}:"
    "overseer|WARNING {just}:"
    "overseer|WARNING {mage}:"
    "overseer|WARNING {make}:"
    "overseer|WARNING {mise}:"
    "overseer|WARNING {mix}:"
    "overseer|WARNING {npm}:"
    "overseer|WARNING {rake}:"
    "overseer|WARNING {task}:"
    "overseer|WARNING {tox}:"
    "overseer|WARNING {vscode}:"
  ]
  ++ lib.lists.optionals stdenv.hostPlatform.isDarwin [
    # OK: osascript is a macOS system binary, not on the sandbox PATH
    "neo-tree|WARNING `osascript` not found (built-in)"
  ]
  ++ lib.lists.optionals stdenv.hostPlatform.isLinux [
    # OK: gio is shipped via glib, but the gvfs trash backend is not
    "neo-tree|WARNING `gio trash` --list failed, maybe you need `gvfs` installed?"
  ];
  optionalIgnoreLines = [
    # OK: mason's live version probe; only reachable without a sandbox
    "WARNING mason.nvim version"
  ];
  stderrIgnoreLines = [
    # OK: gh prints auth failures to stderr in the credential-less sandbox
    "You are not logged into any GitHub hosts."
    "Cannot request Projects v2: Missing scope"
    ".vim:line"
  ];
}
