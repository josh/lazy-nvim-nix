# Renovate bug
# https://github.com/renovatebot/renovate/issues/29721
# "github:NixOS/nixpkgs/nixpkgs-unstable"
{
  inputs = {
    "bufferline.nvim".flake = false;
    "bufferline.nvim".url = "github:akinsho/bufferline.nvim/main";
    "catppuccin".flake = false;
    "catppuccin".url = "github:catppuccin/nvim/main";
    "cmp-buffer".flake = false;
    "cmp-buffer".url = "github:hrsh7th/cmp-buffer/main";
    "cmp-git".flake = false;
    "cmp-git".url = "github:petertriho/cmp-git/main";
    "cmp-nvim-lsp".flake = false;
    "cmp-nvim-lsp".url = "github:hrsh7th/cmp-nvim-lsp/main";
    "cmp-path".flake = false;
    "cmp-path".url = "github:hrsh7th/cmp-path/main";
    "conform.nvim".flake = false;
    "conform.nvim".url = "github:stevearc/conform.nvim/master";
    "copilot-cmp".flake = false;
    "copilot-cmp".url = "github:zbirenbaum/copilot-cmp/master";
    "copilot.lua".flake = false;
    "copilot.lua".url = "github:zbirenbaum/copilot.lua/master";
    "CopilotChat.nvim".flake = false;
    "CopilotChat.nvim".url = "github:CopilotC-Nvim/CopilotChat.nvim/main";
    "dashboard-nvim".flake = false;
    "dashboard-nvim".url = "github:nvimdev/dashboard-nvim/master";
    "dressing.nvim".flake = false;
    "dressing.nvim".url = "github:stevearc/dressing.nvim/master";
    "flash.nvim".flake = false;
    "flash.nvim".url = "github:folke/flash.nvim/main";
    "friendly-snippets".flake = false;
    "friendly-snippets".url = "github:rafamadriz/friendly-snippets/main";
    "gitsigns.nvim".flake = false;
    "gitsigns.nvim".url = "github:lewis6991/gitsigns.nvim/main";
    "grug-far.nvim".flake = false;
    "grug-far.nvim".url = "github:MagicDuck/grug-far.nvim/main";
    "harpoon".flake = false;
    "harpoon".url = "github:ThePrimeagen/harpoon/master";
    "indent-blankline.nvim".flake = false;
    "indent-blankline.nvim".url = "github:lukas-reineke/indent-blankline.nvim/master";
    "lazy.nvim".flake = false;
    "lazy.nvim".url = "github:folke/lazy.nvim/main";
    "lazydev.nvim".flake = false;
    "lazydev.nvim".url = "github:folke/lazydev.nvim/main";
    "LazyVim".flake = false;
    "LazyVim".url = "github:LazyVim/LazyVim/main";
    "lualine.nvim".flake = false;
    "lualine.nvim".url = "github:nvim-lualine/lualine.nvim/master";
    "luvit-meta".flake = false;
    "luvit-meta".url = "github:Bilal2453/luvit-meta/main";
    "mason-lspconfig.nvim".flake = false;
    "mason-lspconfig.nvim".url = "github:williamboman/mason-lspconfig.nvim/main";
    "mason.nvim".flake = false;
    "mason.nvim".url = "github:williamboman/mason.nvim/main";
    "mini.ai".flake = false;
    "mini.ai".url = "github:echasnovski/mini.ai/main";
    "mini.animate".flake = false;
    "mini.animate".url = "github:echasnovski/mini.animate/main";
    "mini.icons".flake = false;
    "mini.icons".url = "github:echasnovski/mini.icons/main";
    "mini.pairs".flake = false;
    "mini.pairs".url = "github:echasnovski/mini.pairs/main";
    "mini.starter".flake = false;
    "mini.starter".url = "github:echasnovski/mini.starter/main";
    "neo-tree.nvim".flake = false;
    "neo-tree.nvim".url = "github:nvim-neo-tree/neo-tree.nvim/main";
    "noice.nvim".flake = false;
    "noice.nvim".url = "github:folke/noice.nvim/main";
    "none-ls.nvim".flake = false;
    "none-ls.nvim".url = "github:nvimtools/none-ls.nvim/main";
    "nui.nvim".flake = false;
    "nui.nvim".url = "github:MunifTanjim/nui.nvim/main";
    "nvim-cmp".flake = false;
    "nvim-cmp".url = "github:hrsh7th/nvim-cmp/main";
    "nvim-lint".flake = false;
    "nvim-lint".url = "github:mfussenegger/nvim-lint/master";
    "nvim-lspconfig".flake = false;
    "nvim-lspconfig".url = "github:neovim/nvim-lspconfig/master";
    "nvim-notify".flake = false;
    "nvim-notify".url = "github:rcarriga/nvim-notify/master";
    "nvim-snippets".flake = false;
    "nvim-snippets".url = "github:garymjr/nvim-snippets/main";
    "nvim-treesitter-context".flake = false;
    "nvim-treesitter-context".url = "github:nvim-treesitter/nvim-treesitter-context/master";
    "nvim-treesitter-textobjects".flake = false;
    "nvim-treesitter-textobjects".url = "github:nvim-treesitter/nvim-treesitter-textobjects/master";
    "nvim-treesitter".flake = false;
    "nvim-treesitter".url = "github:nvim-treesitter/nvim-treesitter/master";
    "nvim-ts-autotag".flake = false;
    "nvim-ts-autotag".url = "github:windwp/nvim-ts-autotag/main";
    "octo.nvim".flake = false;
    "octo.nvim".url = "github:pwntester/octo.nvim/master";
    "persistence.nvim".flake = false;
    "persistence.nvim".url = "github:folke/persistence.nvim/main";
    "plenary.nvim".flake = false;
    "plenary.nvim".url = "github:nvim-lua/plenary.nvim/master";
    "refactoring.nvim".flake = false;
    "refactoring.nvim".url = "github:ThePrimeagen/refactoring.nvim/master";
    "telescope-fzf-native.nvim".flake = false;
    "telescope-fzf-native.nvim".url = "github:nvim-telescope/telescope-fzf-native.nvim/main";
    "telescope.nvim".flake = false;
    "telescope.nvim".url = "github:nvim-telescope/telescope.nvim/master";
    "todo-comments.nvim".flake = false;
    "todo-comments.nvim".url = "github:folke/todo-comments.nvim/main";
    "tokyonight.nvim".flake = false;
    "tokyonight.nvim".url = "github:folke/tokyonight.nvim/main";
    "trouble.nvim".flake = false;
    "trouble.nvim".url = "github:folke/trouble.nvim/main";
    "ts-comments.nvim".flake = false;
    "ts-comments.nvim".url = "github:folke/ts-comments.nvim/main";
    "vim-helm".flake = false;
    "vim-helm".url = "github:towolf/vim-helm/master";
    "vim-startuptime".flake = false;
    "vim-startuptime".url = "github:dstein64/vim-startuptime/master";
    "which-key.nvim".flake = false;
    "which-key.nvim".url = "github:folke/which-key.nvim/main";
    "yanky.nvim".flake = false;
    "yanky.nvim".url = "github:gbprod/yanky.nvim/main";
  };

  outputs = _inputs: { };
}
