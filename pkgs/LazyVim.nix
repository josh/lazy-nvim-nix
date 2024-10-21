{
  pkgs,
  lazynvimPlugins,
  lazynvimUtils,
  lazygit,
}:
let
  plugins = lazynvimPlugins;
in
lazynvimUtils.makeLazyNeovimPackage {
  inherit pkgs;
  spec = [
    (plugins."LazyVim".spec // { "import" = "lazyvim.plugins"; })

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
    plugins."telescope-fzf-native.nvim".spec
    plugins."telescope.nvim".spec
    plugins."todo-comments.nvim".spec
    plugins."tokyonight.nvim".spec
    plugins."trouble.nvim".spec
    plugins."ts-comments.nvim".spec
    plugins."which-key.nvim".spec

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

  extraPackages = with pkgs; [ lazygit ];
}
