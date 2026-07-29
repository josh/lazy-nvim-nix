{ nixpkgs }:
let
  inherit (nixpkgs) lib;

  # flattenDerivations :: AttrSet -> [ Derivation ]
  flattenDerivations =
    attrset:
    lib.lists.flatten (
      lib.mapAttrsToList (
        _name: value:
        if lib.attrsets.isDerivation value then
          [ value ]
        else if builtins.isAttrs value then
          flattenDerivations value
        else
          [ ]
      ) attrset
    );

  toLua = lib.generators.toLua { };
  inherit (lib.generators) mkLuaInline;

  colorschemePreRC = ''
    vim.api.nvim_create_autocmd("ColorSchemePre", {
      callback = function(ev)
        local ok, plugins = pcall(function()
          return require("lazy.core.config").plugins
        end)
        if not ok or type(plugins) ~= "table" then
          return
        end
        for _, plugin in pairs(plugins) do
          if plugin._.loaded == nil and plugin.dir then
            for _, ext in ipairs({ "lua", "vim" }) do
              if vim.uv.fs_stat(plugin.dir .. "/colors/" .. ev.match .. "." .. ext) then
                require("lazy.core.loader").load(plugin, { colorscheme = ev.match })
                return
              end
            end
          end
        end
      end,
    })
  '';

  defaultLazyOpts = {
    pkg = {
      enabled = false;
    };
    root = mkLuaInline ''vim.fn.stdpath("data") .. "/lazy"'';
    lockfile = mkLuaInline ''vim.fn.stdpath("config") .. "/lazy-lock.json"'';
    state = mkLuaInline ''vim.fn.stdpath("state") .. "/lazy/state.json"'';
    install = {
      missing = false;
      colorscheme = [ "habamax" ];
    };
    checker = {
      enabled = false;
      notify = false;
    };
    change_detection = {
      enabled = false;
      notify = false;
    };
    performance = {
      reset_packpath = true;
      rtp = {
        reset = true;
      };
    };
    readme = {
      enabled = false;
    };
  };

in
{
  inherit
    colorschemePreRC
    defaultLazyOpts
    flattenDerivations
    mkLuaInline
    toLua
    ;
}
