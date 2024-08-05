let
  system = builtins.currentSystem;
  pkgs = import ./nixpkgs.nix { inherit system; };
  lib = import ./lib.nix;
in
{
  githubNameWithOwner = {
    testURL = {
      expr = lib.githubNameWithOwner "https://github.com/folke/lazy.nvim/";
      expected = {
        owner = "folke";
        name = "lazy.nvim";
      };
    };
    testNameWithOwner = {
      expr = lib.githubNameWithOwner "folke/lazy.nvim";
      expected = {
        owner = "folke";
        name = "lazy.nvim";
      };
    };
    testRepoName = {
      expr = lib.githubNameWithOwner "lazy.nvim";
      expected = {
        owner = null;
        name = "lazy.nvim";
      };
    };
    testPackage = {
      expr = lib.githubNameWithOwner pkgs.vimPlugins.lazy-nvim;
      expected = {
        owner = "folke";
        name = "lazy.nvim";
      };
    };
  };

  makeLazyPluginSpec =
    let
      safeSpec = spec: spec // { dir = spec.dir.outPath; };
    in
    {
      lazy-nvim = {
        testPackage = {
          expr = safeSpec (lib.makeLazyPluginSpec pkgs pkgs.vimPlugins.lazy-nvim);
          expected = {
            name = "lazy.nvim";
            dir = pkgs.vimPlugins.lazy-nvim.outPath;
          };
        };
        testNameWithOwner = {
          expr = safeSpec (lib.makeLazyPluginSpec pkgs "folke/lazy.nvim");
          expected = {
            name = "lazy.nvim";
            dir = pkgs.vimPlugins.lazy-nvim.outPath;
          };
        };
        testName = {
          expr = safeSpec (lib.makeLazyPluginSpec pkgs "lazy.nvim");
          expected = {
            name = "lazy.nvim";
            dir = pkgs.vimPlugins.lazy-nvim.outPath;
          };
        };
      };

      LazyVim = {
        testPackage = {
          expr = safeSpec (lib.makeLazyPluginSpec pkgs pkgs.vimPlugins.LazyVim);
          expected = {
            name = "LazyVim";
            dir = pkgs.vimPlugins.LazyVim.outPath;
          };
        };
        testNameWithOwner = {
          expr = safeSpec (lib.makeLazyPluginSpec pkgs "LazyVim/LazyVim");
          expected = {
            name = "LazyVim";
            dir = pkgs.vimPlugins.LazyVim.outPath;
          };
        };
        testName = {
          expr = safeSpec (lib.makeLazyPluginSpec pkgs "LazyVim");
          expected = {
            name = "LazyVim";
            dir = pkgs.vimPlugins.LazyVim.outPath;
          };
        };
      };

      tokyonight-nvim = {
        testPackage = {
          expr = safeSpec (lib.makeLazyPluginSpec pkgs pkgs.vimPlugins.tokyonight-nvim);
          expected = {
            name = "tokyonight.nvim";
            dir = pkgs.vimPlugins.tokyonight-nvim.outPath;
          };
        };
        testNameWithOwner = {
          expr = safeSpec (lib.makeLazyPluginSpec pkgs "folke/tokyonight.nvim");
          expected = {
            name = "tokyonight.nvim";
            dir = pkgs.vimPlugins.tokyonight-nvim.outPath;
          };
        };
        testName = {
          expr = safeSpec (lib.makeLazyPluginSpec pkgs "tokyonight.nvim");
          expected = {
            name = "tokyonight.nvim";
            dir = pkgs.vimPlugins.tokyonight-nvim.outPath;
          };
        };
      };

      catppuccin-nvim = {
        testPackage = {
          expr = safeSpec (lib.makeLazyPluginSpec pkgs pkgs.vimPlugins.catppuccin-nvim);
          expected = {
            # FIXME: Not ideal name, but repo is an edge case.
            name = "nvim";
            dir = pkgs.vimPlugins.catppuccin-nvim.outPath;
          };
        };
        testNameWithOwner = {
          expr = safeSpec (lib.makeLazyPluginSpec pkgs "catppuccin/nvim");
          expected = {
            # FIXME: Not ideal name, but repo is an edge case.
            name = "nvim";
            dir = pkgs.vimPlugins.catppuccin-nvim.outPath;
          };
        };
        # FIXME: testName not possible, "nvim" is too generic
      };
    };

  extractLazyVimPluginRepos =
    let
      pluginRepos = lib.extractLazyVimPluginRepos { inherit pkgs; };
    in
    {
      testCorePluginCount = {
        expr = builtins.length (builtins.attrValues pluginRepos."lazyvim.plugins") >= 10;
        expected = true;
      };

      testCorePluginIncludesTokyonight = {
        expr = pluginRepos."lazyvim.plugins"."tokyonight.nvim";
        expected = "folke/tokyonight.nvim";
      };

      testCopilotPluginExtraCount = {
        expr =
          builtins.length (builtins.attrValues pluginRepos."lazyvim.plugins.extras.coding.copilot") >= 1;
        expected = true;
      };
    };
}
