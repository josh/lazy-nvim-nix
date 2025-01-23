# Renovate bug
# https://github.com/renovatebot/renovate/issues/29721
# "github:NixOS/nixpkgs/nixpkgs-unstable"
{
  inputs = {
    # keep-sorted start
    "CopilotChat.nvim".flake = false;
    "CopilotChat.nvim".url = "github:CopilotC-Nvim/CopilotChat.nvim/main";
    "LazyVim".flake = false;
    "LazyVim".url = "github:LazyVim/LazyVim/main";
    "LuaSnip".flake = false;
    "LuaSnip".url = "github:L3MON4D3/LuaSnip/master";
    "R.nvim".flake = false;
    "R.nvim".url = "github:R-nvim/R.nvim/main";
    "SchemaStore.nvim".flake = false;
    "SchemaStore.nvim".url = "github:b0o/SchemaStore.nvim/main";
    "aerial.nvim".flake = false;
    "aerial.nvim".url = "github:stevearc/aerial.nvim/master";
    "alpha-nvim".flake = false;
    "alpha-nvim".url = "github:goolord/alpha-nvim/main";
    "baleia.nvim".flake = false;
    "baleia.nvim".url = "github:m00qek/baleia.nvim/main";
    "blink.cmp".flake = false;
    "blink.cmp".url = "github:saghen/blink.cmp/main";
    "bufferline.nvim".flake = false;
    "bufferline.nvim".url = "github:akinsho/bufferline.nvim/main";
    "catppuccin".flake = false;
    "catppuccin".url = "github:catppuccin/nvim/main";
    "chezmoi.nvim".flake = false;
    "chezmoi.nvim".url = "github:xvzc/chezmoi.nvim/main";
    "chezmoi.vim".flake = false;
    "chezmoi.vim".url = "github:alker0/chezmoi.vim/main";
    "clangd_extensions.nvim".flake = false;
    "clangd_extensions.nvim".url = "github:p00f/clangd_extensions.nvim/main";
    "cmake-tools.nvim".flake = false;
    "cmake-tools.nvim".url = "github:Civitasv/cmake-tools.nvim/master";
    "cmp-buffer".flake = false;
    "cmp-buffer".url = "github:hrsh7th/cmp-buffer/main";
    "cmp-git".flake = false;
    "cmp-git".url = "github:petertriho/cmp-git/main";
    "cmp-nvim-lsp".flake = false;
    "cmp-nvim-lsp".url = "github:hrsh7th/cmp-nvim-lsp/main";
    "cmp-path".flake = false;
    "cmp-path".url = "github:hrsh7th/cmp-path/main";
    "codeium.nvim".flake = false;
    "codeium.nvim".url = "github:Exafunction/codeium.nvim/main";
    "conform.nvim".flake = false;
    "conform.nvim".url = "github:stevearc/conform.nvim/master";
    "conjure".flake = false;
    "conjure".url = "github:Olical/conjure/main";
    "copilot-cmp".flake = false;
    "copilot-cmp".url = "github:zbirenbaum/copilot-cmp/master";
    "copilot.lua".flake = false;
    "copilot.lua".url = "github:zbirenbaum/copilot.lua/master";
    "crates.nvim".flake = false;
    "crates.nvim".url = "github:Saecki/crates.nvim/main";
    "dashboard-nvim".flake = false;
    "dashboard-nvim".url = "github:nvimdev/dashboard-nvim/master";
    "dial.nvim".flake = false;
    "dial.nvim".url = "github:monaqa/dial.nvim/master";
    "dressing.nvim".flake = false;
    "dressing.nvim".url = "github:stevearc/dressing.nvim/master";
    "edgy.nvim".flake = false;
    "edgy.nvim".url = "github:folke/edgy.nvim/main";
    "flash.nvim".flake = false;
    "flash.nvim".url = "github:folke/flash.nvim/main";
    "flit.nvim".flake = false;
    "flit.nvim".url = "github:ggandor/flit.nvim/main";
    "friendly-snippets".flake = false;
    "friendly-snippets".url = "github:rafamadriz/friendly-snippets/main";
    "fzf-lua".flake = false;
    "fzf-lua".url = "github:ibhagwan/fzf-lua/main";
    "gitsigns.nvim".flake = false;
    "gitsigns.nvim".url = "github:lewis6991/gitsigns.nvim/main";
    "grug-far.nvim".flake = false;
    "grug-far.nvim".url = "github:MagicDuck/grug-far.nvim/main";
    "harpoon".flake = false;
    "harpoon".url = "github:ThePrimeagen/harpoon/master";
    "haskell-snippets.nvim".flake = false;
    "haskell-snippets.nvim".url = "github:mrcjkb/haskell-snippets.nvim/master";
    "haskell-tools.nvim".flake = false;
    "haskell-tools.nvim".url = "github:mrcjkb/haskell-tools.nvim/master";
    "inc-rename.nvim".flake = false;
    "inc-rename.nvim".url = "github:smjonas/inc-rename.nvim/main";
    "indent-blankline.nvim".flake = false;
    "indent-blankline.nvim".url = "github:lukas-reineke/indent-blankline.nvim/master";
    "kulala.nvim".flake = false;
    "kulala.nvim".url = "github:mistweaverco/kulala.nvim/main";
    "lazy.nvim".flake = false;
    "lazy.nvim".url = "github:folke/lazy.nvim/main";
    "lazydev.nvim".flake = false;
    "lazydev.nvim".url = "github:folke/lazydev.nvim/main";
    "lean.nvim".flake = false;
    "lean.nvim".url = "github:Julian/lean.nvim/main";
    "leap.nvim".flake = false;
    "leap.nvim".url = "github:ggandor/leap.nvim/main";
    "lualine.nvim".flake = false;
    "lualine.nvim".url = "github:nvim-lualine/lualine.nvim/master";
    "luvit-meta".flake = false;
    "luvit-meta".url = "github:Bilal2453/luvit-meta/main";
    "mason-lspconfig.nvim".flake = false;
    "mason-lspconfig.nvim".url = "github:williamboman/mason-lspconfig.nvim/main";
    "mason-nvim-dap.nvim".flake = false;
    "mason-nvim-dap.nvim".url = "github:jay-babu/mason-nvim-dap.nvim/main";
    "mason.nvim".flake = false;
    "mason.nvim".url = "github:williamboman/mason.nvim/main";
    "mini.ai".flake = false;
    "mini.ai".url = "github:echasnovski/mini.ai/main";
    "mini.animate".flake = false;
    "mini.animate".url = "github:echasnovski/mini.animate/main";
    "mini.comment".flake = false;
    "mini.comment".url = "github:echasnovski/mini.comment/main";
    "mini.diff".flake = false;
    "mini.diff".url = "github:echasnovski/mini.diff/main";
    "mini.files".flake = false;
    "mini.files".url = "github:echasnovski/mini.files/main";
    "mini.hipatterns".flake = false;
    "mini.hipatterns".url = "github:echasnovski/mini.hipatterns/main";
    "mini.icons".flake = false;
    "mini.icons".url = "github:echasnovski/mini.icons/main";
    "mini.indentscope".flake = false;
    "mini.indentscope".url = "github:echasnovski/mini.indentscope/main";
    "mini.move".flake = false;
    "mini.move".url = "github:echasnovski/mini.move/main";
    "mini.pairs".flake = false;
    "mini.pairs".url = "github:echasnovski/mini.pairs/main";
    "mini.snippets".flake = false;
    "mini.snippets".url = "github:echasnovski/mini.snippets/main";
    "mini.starter".flake = false;
    "mini.starter".url = "github:echasnovski/mini.starter/main";
    "mini.surround".flake = false;
    "mini.surround".url = "github:echasnovski/mini.surround/main";
    "neo-tree.nvim".flake = false;
    "neo-tree.nvim".url = "github:nvim-neo-tree/neo-tree.nvim/main";
    "neoconf.nvim".flake = false;
    "neoconf.nvim".url = "github:folke/neoconf.nvim/main";
    "neodev.nvim".flake = false;
    "neodev.nvim".url = "github:folke/neodev.nvim/main";
    "neogen".flake = false;
    "neogen".url = "github:danymat/neogen/main";
    "neotest".flake = false;
    "neotest".url = "github:nvim-neotest/neotest/master";
    "noice.nvim".flake = false;
    "noice.nvim".url = "github:folke/noice.nvim/main";
    "none-ls.nvim".flake = false;
    "none-ls.nvim".url = "github:nvimtools/none-ls.nvim/main";
    "nui.nvim".flake = false;
    "nui.nvim".url = "github:MunifTanjim/nui.nvim/main";
    "nvim-ansible".flake = false;
    "nvim-ansible".url = "github:mfussenegger/nvim-ansible/main";
    "nvim-cmp".flake = false;
    "nvim-cmp".url = "github:hrsh7th/nvim-cmp/main";
    "nvim-dap".flake = false;
    "nvim-dap".url = "github:mfussenegger/nvim-dap/master";
    "nvim-dap-ui".flake = false;
    "nvim-dap-ui".url = "github:rcarriga/nvim-dap-ui/master";
    "nvim-dap-virtual-text".flake = false;
    "nvim-dap-virtual-text".url = "github:theHamsta/nvim-dap-virtual-text/master";
    "nvim-jdtls".flake = false;
    "nvim-jdtls".url = "github:mfussenegger/nvim-jdtls/master";
    "nvim-lint".flake = false;
    "nvim-lint".url = "github:mfussenegger/nvim-lint/master";
    "nvim-lspconfig".flake = false;
    "nvim-lspconfig".url = "github:neovim/nvim-lspconfig/master";
    "nvim-metals".flake = false;
    "nvim-metals".url = "github:scalameta/nvim-metals/main";
    "nvim-navic".flake = false;
    "nvim-navic".url = "github:SmiteshP/nvim-navic/master";
    "nvim-nio".flake = false;
    "nvim-nio".url = "github:nvim-neotest/nvim-nio/master";
    "nvim-notify".flake = false;
    "nvim-notify".url = "github:rcarriga/nvim-notify/master";
    "nvim-snippets".flake = false;
    "nvim-snippets".url = "github:garymjr/nvim-snippets/main";
    "nvim-treesitter".flake = false;
    "nvim-treesitter".url = "github:nvim-treesitter/nvim-treesitter/master";
    "nvim-treesitter-context".flake = false;
    "nvim-treesitter-context".url = "github:nvim-treesitter/nvim-treesitter-context/master";
    "nvim-treesitter-sexp".flake = false;
    "nvim-treesitter-sexp".url = "github:PaterJason/nvim-treesitter-sexp/master";
    "nvim-treesitter-textobjects".flake = false;
    "nvim-treesitter-textobjects".url = "github:nvim-treesitter/nvim-treesitter-textobjects/master";
    "nvim-ts-autotag".flake = false;
    "nvim-ts-autotag".url = "github:windwp/nvim-ts-autotag/main";
    "nvim-ts-context-commentstring".flake = false;
    "nvim-ts-context-commentstring".url = "github:JoosepAlviste/nvim-ts-context-commentstring/main";
    "octo.nvim".flake = false;
    "octo.nvim".url = "github:pwntester/octo.nvim/master";
    "one-small-step-for-vimkind".flake = false;
    "one-small-step-for-vimkind".url = "github:jbyuki/one-small-step-for-vimkind/main";
    "outline.nvim".flake = false;
    "outline.nvim".url = "github:hedyhli/outline.nvim/main";
    "overseer.nvim".flake = false;
    "overseer.nvim".url = "github:stevearc/overseer.nvim/master";
    "persistence.nvim".flake = false;
    "persistence.nvim".url = "github:folke/persistence.nvim/main";
    "plenary.nvim".flake = false;
    "plenary.nvim".url = "github:nvim-lua/plenary.nvim/master";
    "project.nvim".flake = false;
    "project.nvim".url = "github:ahmedkhalf/project.nvim/main";
    "refactoring.nvim".flake = false;
    "refactoring.nvim".url = "github:ThePrimeagen/refactoring.nvim/master";
    "rustaceanvim".flake = false;
    "rustaceanvim".url = "github:mrcjkb/rustaceanvim/master";
    "smear-cursor.nvim".flake = false;
    "smear-cursor.nvim".url = "github:sphamba/smear-cursor.nvim/main";
    "snacks.nvim".flake = false;
    "snacks.nvim".url = "github:folke/snacks.nvim/main";
    "supermaven-nvim".flake = false;
    "supermaven-nvim".url = "github:supermaven-inc/supermaven-nvim/main";
    "tailwindcss-colorizer-cmp.nvim".flake = false;
    "tailwindcss-colorizer-cmp.nvim".url = "github:roobert/tailwindcss-colorizer-cmp.nvim/main";
    "telescope-fzf-native.nvim".flake = false;
    "telescope-fzf-native.nvim".url = "github:nvim-telescope/telescope-fzf-native.nvim/main";
    "telescope.nvim".flake = false;
    "telescope.nvim".url = "github:nvim-telescope/telescope.nvim/master";
    "telescope_hoogle".flake = false;
    "telescope_hoogle".url = "github:luc-tielen/telescope_hoogle/master";
    "todo-comments.nvim".flake = false;
    "todo-comments.nvim".url = "github:folke/todo-comments.nvim/main";
    "tokyonight.nvim".flake = false;
    "tokyonight.nvim".url = "github:folke/tokyonight.nvim/main";
    "tree-sitter-nu".flake = false;
    "tree-sitter-nu".url = "github:nushell/tree-sitter-nu/main";
    "trouble.nvim".flake = false;
    "trouble.nvim".url = "github:folke/trouble.nvim/main";
    "ts-comments.nvim".flake = false;
    "ts-comments.nvim".url = "github:folke/ts-comments.nvim/main";
    "vim-dadbod".flake = false;
    "vim-dadbod".url = "github:tpope/vim-dadbod/master";
    "vim-dadbod-completion".flake = false;
    "vim-dadbod-completion".url = "github:kristijanhusak/vim-dadbod-completion/master";
    "vim-dadbod-ui".flake = false;
    "vim-dadbod-ui".url = "github:kristijanhusak/vim-dadbod-ui/master";
    "vim-helm".flake = false;
    "vim-helm".url = "github:towolf/vim-helm/master";
    "vim-illuminate".flake = false;
    "vim-illuminate".url = "github:RRethy/vim-illuminate/master";
    "vim-repeat".flake = false;
    "vim-repeat".url = "github:tpope/vim-repeat/master";
    "vim-startuptime".flake = false;
    "vim-startuptime".url = "github:dstein64/vim-startuptime/master";
    "vimtex".flake = false;
    "vimtex".url = "github:lervag/vimtex/master";
    "which-key.nvim".flake = false;
    "which-key.nvim".url = "github:folke/which-key.nvim/main";
    "yanky.nvim".flake = false;
    "yanky.nvim".url = "github:gbprod/yanky.nvim/main";
    # keep-sorted end
  };

  outputs = _inputs: { };
}
