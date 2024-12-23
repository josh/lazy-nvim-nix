{
  lazy-nvim,
  lazynvimPlugins,
  curl,
  fzf,
  lazygit,
  neovim-checkhealth,
}:
let
  plugins = lazynvimPlugins;
in
(lazy-nvim.override {
  spec = [
    (plugins."LazyVim".spec // { "import" = "lazyvim.plugins"; })

    # keep-sorted start
    plugins."bufferline.nvim".spec
    plugins."catppuccin".spec
    plugins."cmp-buffer".spec
    plugins."cmp-nvim-lsp".spec
    plugins."cmp-path".spec
    plugins."conform.nvim".spec
    plugins."dashboard-nvim".spec
    plugins."dressing.nvim".spec
    plugins."flash.nvim".spec
    plugins."friendly-snippets".spec
    plugins."gitsigns.nvim".spec
    plugins."grug-far.nvim".spec
    plugins."indent-blankline.nvim".spec
    plugins."lazydev.nvim".spec
    plugins."lualine.nvim".spec
    plugins."luvit-meta".spec
    plugins."mason-lspconfig.nvim".spec
    plugins."mason.nvim".spec
    plugins."mini.ai".spec
    plugins."mini.icons".spec
    plugins."mini.pairs".spec
    plugins."neo-tree.nvim".spec
    plugins."noice.nvim".spec
    plugins."nui.nvim".spec
    plugins."nvim-cmp".spec
    plugins."nvim-lint".spec
    plugins."nvim-lspconfig".spec
    plugins."nvim-notify".spec
    plugins."nvim-snippets".spec
    plugins."nvim-ts-autotag".spec
    plugins."persistence.nvim".spec
    plugins."plenary.nvim".spec
    plugins."snacks.nvim".spec
    plugins."telescope-fzf-native.nvim".spec
    plugins."telescope.nvim".spec
    plugins."todo-comments.nvim".spec
    plugins."tokyonight.nvim".spec
    plugins."trouble.nvim".spec
    plugins."ts-comments.nvim".spec
    plugins."which-key.nvim".spec
    # keep-sorted end

    # FIXME: Tries to write to /nix/store/.../parser directory
    {
      name = "nvim-treesitter";
      url = "https://github.com/nvim-treesitter/nvim-treesitter";
      enabled = false;
    }
    {
      name = "nvim-treesitter-textobjects";
      url = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects";
      enabled = false;
    }

    # FIXME: trouble.nvim doesn't like be loaded from /nix/store
    {
      name = "trouble.nvim";
      url = "https://github.com/folke/trouble.nvim";
      enabled = false;
    }
  ];

  extraPackages = [
    curl
    fzf
    lazygit
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

        checkhealth-lspconfig = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "lspconfig";
          loadLazyPluginName = "nvim-lspconfig";
          checkError = true;
          checkWarning = true;
        };

        checkhealth-mason = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "mason";
          loadLazyPluginName = "mason.nvim";
          # ERROR Registry `github.com/mason-org/mason-registry [uninstalled]` is not installed.
          # ERROR curl: not available
          checkError = false;
          # WARNING unzip: not available
          # WARNING wget: not available
          # WARNING pip: not available
          # WARNING python venv: not available
          # WARNING cargo: not available
          # WARNING Ruby: not available
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

        checkhealth-telescope = neovim-checkhealth.override {
          inherit neovim;
          pluginName = "telescope";
          loadLazyPluginName = "telescope.nvim";
          checkError = true;
          # WARNING nvim-treesitter not found. (Required for `:Telescope treesitter`.)
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
