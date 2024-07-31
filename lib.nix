let
  initLua = ''
    vim.g.mapleader = " "
    vim.g.maplocalleader = "\\"

    require("lazy").setup({
      root = vim.fn.stdpath("data") .. "/lazy",
      spec = {
        -- { import = "plugins" },
      },
      lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
      install = {
        missing = false,
        colorscheme = { "habamax" }
      },
      checker = {
        enabled = false,
        notify = false
      },
      change_detection = {
        enabled = false,
        notify = false
      },
      performance = {
        rtp = {
          reset = true
        }
      },
      state = vim.fn.stdpath("state") .. "/lazy/state.json"
    })
  '';

  makeLazyNeovimConfig =
    { pkgs }:
    let
      inherit (pkgs) lib;

      extraPackages = [
        pkgs.git
        pkgs.luajitPackages.luarocks
      ];

      config = pkgs.neovimUtils.makeNeovimConfig {
        # See pkgs/applications/editors/neovim/utils.nix # makeNeovimConfig

        withPython3 = false;
        withNodeJs = false;
        withRuby = false;
        plugins = [ { plugin = pkgs.vimPlugins.lazy-nvim; } ];

        # Extra config to pass to
        # pkgs/applications/editors/neovim/wrapper.nix

        luaRcContent = initLua;
      };

      # Unfortunatelly can't pass extraWrapperArgs to makeNeovimConfig
      configExtra =
        let
          binPath = lib.makeBinPath extraPackages;
        in
        {
          wrapperArgs = lib.escapeShellArgs config.wrapperArgs + " '--prefix' 'PATH' : '${binPath}' ";
        };

      finalConfig = config // configExtra;

    in
    finalConfig;

in
{
  inherit makeLazyNeovimConfig;
}
