-- usage:
--   LAZY_PATH=./lazy.nvim
--   LAZYVIM_PATH=./LazyVim
--   TMPDIR=/tmp
--   out=/dev/stdout
--   nvim -l lazyvim-plugins.lua

local tmpdir = assert(vim.env["TMPDIR"], "TMPDIR is not set")
vim.env["XDG_CONFIG_HOME"] = tmpdir .. "/config"
vim.env["XDG_DATA_HOME"] = tmpdir .. "/data"
vim.env["XDG_STATE_HOME"] = tmpdir .. "/state"
vim.env["XDG_CACHE_HOME"] = tmpdir .. "/cache"

local lazypath = assert(vim.env["LAZY_PATH"], "LAZY_PATH is not set")
local lazyvimpath = assert(vim.env["LAZYVIM_PATH"], "LAZYVIM_PATH is not set")

vim.opt.rtp:prepend(lazypath)
vim.opt.rtp:prepend(lazyvimpath)

-- Init lazy
local lazy = require("lazy.minit")
lazy.setup({
	git = {
		-- Make GitHub URLs easier to parse
		url_format = "github:%s",
	},
})

local Plugin = require("lazy.core.plugin")
local utils = require("lazy.core.util")

local function import_plugins(modname)
	local spec = Plugin.Spec.new({
		name = "LazyVim",
		dir = lazyvimpath,
		import = modname,
	})
	spec:import(spec)

	local plugins = vim.empty_dict()
	for name, plugin in pairs(spec.plugins) do
		if name == "LazyVim" then
			-- skip
		elseif plugin.url == nil then
			print(modname .. ":" .. name .. " has no URL")
		elseif plugin.url:sub(1, 7) == "github:" then
			plugins[name] = plugin.url:sub(8)
		else
			print(modname .. ":" .. name .. " has an invalid URL: " .. plugin.url)
		end
	end
	return plugins
end

local output = vim.empty_dict()

-- Discover plugins
utils.walkmods(lazyvimpath .. "/lua/lazyvim/plugins", function(modname)
	output[modname] = import_plugins(modname)
end, "lazyvim.plugins")

local file = assert(io.open(assert(vim.env["out"], "out is not set"), "w"))
assert(file:write(vim.fn.json_encode(output)))
assert(file:close())
