-- usage:
--   LAZY_PATH=./lazy.nvim
--   LAZYVIM_PATH=./LazyVim
--   TMPDIR=/tmp
--   out=/dev/stdout
--   nvim -l lazyvim-plugins.lua

vim.env["XDG_CONFIG_HOME"] = vim.env["TMPDIR"] .. "/config"
vim.env["XDG_DATA_HOME"] = vim.env["TMPDIR"] .. "/data"
vim.env["XDG_STATE_HOME"] = vim.env["TMPDIR"] .. "/state"
vim.env["XDG_CACHE_HOME"] = vim.env["TMPDIR"] .. "/cache"

local lazypath = vim.env["LAZY_PATH"]
local lazyvimpath = vim.env["LAZYVIM_PATH"]

vim.opt.rtp:prepend(lazypath)
vim.opt.rtp:prepend(lazyvimpath)

-- Init lazy
local lazy = require("lazy.minit")
lazy.setup({})

local Plugin = require("lazy.core.plugin")
local utils = require("lazy.core.util")

function import_plugins(modname)
	local spec = Plugin.Spec.new({
		name = "LazyVim",
		dir = lazyvimpath,
		import = modname,
	})
	spec:import(spec)

	local plugins = {}
	for name, plugin in pairs(spec.plugins) do
		plugins[name] = plugin.url
	end
	return plugins
end

local output = {}

-- Discover plugins
utils.walkmods(lazyvimpath .. "/lua/lazyvim/plugins", function(modname)
	output[modname] = import_plugins(modname)
end, "lazyvim.plugins")

local file = io.open(vim.env["out"], "w")
assert(file)
file:write(vim.fn.json_encode(output))
file:close()
