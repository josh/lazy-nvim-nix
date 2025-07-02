{
  lib,
  stdenv,
  callPackage,
  lazy-nvim,
  lazynvimPlugins,
  # keep-sorted start
  cargo,
  chafa,
  curl,
  fzf,
  ghostscript,
  gnutar,
  go,
  gzip,
  imagemagick,
  jdk,
  julia,
  lazygit,
  mermaid-cli,
  nodePackages,
  php83,
  php83Packages,
  python312Packages,
  ruby,
  tectonic,
  ueberzugpp,
  unzip,
  viu,
  wget,
# keep-sorted end
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
    plugins."neo-tree.nvim".spec
    plugins."snacks.nvim".spec

    # Fix "mini.icons not found" warning
    (plugins."fzf-lua".spec // { dependencies = [ plugins."mini.icons".spec ]; })

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
    cargo
    curl
    gnutar
    go
    gzip
    jdk
    nodePackages.nodejs
    php83
    php83Packages.composer
    (python312Packages.python.withPackages (ps: with ps; [ pip ]))
    ruby
    unzip
    wget

    # snacks
    ghostscript
    imagemagick
    mermaid-cli
    tectonic
  ] ++ (lib.lists.optionals (lib.meta.availableOn stdenv.hostPlatform julia) [ julia ]);
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
              # OK: Nix build sandbox will always prevent access to github API
              "WARNING Failed to check GitHub API rate limit status"
            ]
            ++ (lib.lists.optionals (!lib.meta.availableOn stdenv.hostPlatform julia) [
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
          checkError = true;
          checkWarning = true;
        };
      };
    }
  )
