{
  lib,
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
    python312Packages.python
    python312Packages.pip
    cargo
    ruby
    nodePackages.nodejs
  ];
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
          # WARNING Some providers may show up as "disabled" but are enabled dynamically (i.e. cmdline)
          checkWarning = false;
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
          # ERROR Registry `github.com/mason-org/mason-registry [uninstalled]` is not installed.
          checkError = false;
          # WARNING java: not available
          # WARNING julia: not available
          checkWarning = false;
        };

        checkhealth-noice = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "noice";
          loadLazyPluginName = "noice.nvim";
          checkError = true;
          # WARNING *Neovim* >= 0.11 is highly recommended
          # WARNING {TreeSitter} `regex` parser is not installed
          # WARNING {TreeSitter} `bash` parser is not installed
          checkWarning = false;
        };

        checkhealth-snacks = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "snacks";
          loadLazyPluginName = "snacks.nvim";
          # Snacks.notifier: ERROR is not ready
          checkError = false;
          # Snacks.statuscolumn: WARNING setup {disabled}
          checkWarning = false;
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
