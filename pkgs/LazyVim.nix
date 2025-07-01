{
  lib,
  stdenv,
  lazy-nvim,
  lazynvimPlugins,
  # keep-sorted start
  cargo,
  chafa,
  curl,
  fzf,
  gnutar,
  go,
  gzip,
  julia,
  lazygit,
  nodePackages,
  php83,
  php83Packages,
  python312Packages,
  ruby,
  ueberzugpp,
  unzip,
  viu,
  wget,
  # keep-sorted end
  neovim-checkhealth,
}:
let
  plugins = lazynvimPlugins;
  juliaAvailable = lib.meta.availableOn stdenv.hostPlatform julia;
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

  extraPackages = [
    curl
    fzf
    lazygit

    # fzf-lua
    chafa
    viu
    ueberzugpp

    # mason
    unzip
    wget
    curl
    gzip
    gnutar
    go
    php83
    php83Packages.composer
    (python312Packages.python.withPackages (ps: with ps; [ pip ]))
    cargo
    ruby
    nodePackages.nodejs
  ] ++ (lib.lists.optionals juliaAvailable [ julia ]);
}).overrideAttrs
  (
    finalAttrs: previousAttrs:
    let
      neovim = finalAttrs.finalPackage;
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
          checkError = true;
          checkWarning = true;
        };

        checkhealth-blink-cmp = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "blink.cmp";
          loadLazyPluginName = "blink.cmp";
          checkError = true;
          checkWarning = true;
          ignoreLines = [
            # OK: Not fixable, this warning is always shown
            "WARNING Some providers may show up as \"disabled\" but are enabled dynamically"
          ];
        };

        checkhealth-fzf-lua = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "fzf_lua";
          loadLazyPluginName = "fzf-lua";
          checkError = true;
          checkWarning = true;
          ignoreLines = [
            # FIXME: I think we should be able to install these plugins
            "WARNING `nvim-web-devicons` or `mini.icons` not found"
          ];
        };

        checkhealth-mason = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "mason";
          loadLazyPluginName = "mason.nvim";
          checkError = true;
          checkWarning = true;
          ignoreLines =
            [
              # FIXME: These errors should be fixable if we install the correct dependencies
              "ERROR Registry `github.com/mason-org/mason-registry [uninstalled]` is not installed"
              "WARNING javac: not available"
              "WARNING java: not available"
              # OK: Nix build sandbox will always prevent access to github API
              "WARNING Failed to check GitHub API rate limit status"
            ]
            ++ (lib.lists.optionals (!juliaAvailable) [
              "WARNING julia: not available"
            ]);
        };

        checkhealth-noice = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "noice";
          loadLazyPluginName = "noice.nvim";
          checkError = true;
          checkWarning = true;
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
          checkError = true;
          checkWarning = true;
          ignoreLines =
            [
              # FIXME: Look into these errors, some may be fixable
              "ERROR setup did not run"
              "WARNING setup {disabled}"
              "ERROR None of the tools found: 'kitty', 'wezterm', 'ghostty'"
              "ERROR None of the tools found: 'magick', 'convert'"
              "ERROR `magick` is required to convert images. Only PNG files will be displayed."
              "WARNING Image rendering in docs with missing treesitter parsers won't work"
              "ERROR Tool not found: 'gs'"
              "WARNING `gs` is required to render PDF files"
              "ERROR None of the tools found: 'tectonic', 'pdflatex'"
              "WARNING `tectonic` or `pdflatex` is required to render LaTeX math expressions"
              "ERROR Tool not found: 'mmdc'"
              "WARNING `mmdc` is required to render Mermaid diagrams"
              "ERROR your terminal does not support the kitty graphics protocol"
              "ERROR `vim.ui.input` is not set to `Snacks.input`"
              "ERROR is not ready"
              "ERROR `vim.ui.select` is not set to `Snacks.picker.select`"
              "WARNING Missing Treesitter languages"
            ]
            ++ (lib.lists.optionals stdenv.isLinux [
              # FIXME: Should be fixable if we install sqlite3
              "WARNING `SQLite3` is not available"
            ]);
        };

        checkhealth-which-key = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "which-key";
          loadLazyPluginName = "which-key.nvim";
          checkError = true;
          checkWarning = true;
        };
      };
    }
  )
