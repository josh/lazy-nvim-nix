-- usage:
--   LAZY_PATH=./lazy.nvim
--   LAZYVIM_PATH=./LazyVim
--   TMPDIR=/tmp
--   nvim -l lazyvim-plugins.lua list
--   SCAN_OUT=mod.json nvim -l lazyvim-plugins.lua scan <modname>

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
	performance = {
		rtp = {
			reset = false,
		},
	},
})

local Plugin = require("lazy.core.plugin")
local utils = require("lazy.core.util")

_G.LazyVim = require("lazyvim.util")

local mode = assert(_G.arg[1], "usage: lazyvim-plugins.lua list|scan <modname>")

if mode == "list" then
	local file = assert(io.open(assert(vim.env["SCAN_OUT"], "SCAN_OUT is not set"), "w"))
	utils.walkmods(lazyvimpath .. "/lua/lazyvim/plugins", function(modname)
		if modname == "lazyvim.plugins" or vim.startswith(modname, "lazyvim.plugins.extras.") then
			assert(file:write(modname .. "\n"))
		end
	end, "lazyvim.plugins")
	assert(file:close())
	os.exit(0)
end

assert(mode == "scan", "unknown mode: " .. mode)
local modname = assert(_G.arg[2], "scan requires a module name")

table.insert(require("lazy.core.config").spec.modules, modname)
require("lazyvim.config").init()
LazyVim.config.get_defaults()

local spec = Plugin.Spec.new({
	name = "LazyVim",
	dir = lazyvimpath,
	import = modname,
})

local failed = false
for _, notif in ipairs(spec.notifs) do
	if notif.level >= vim.log.levels.ERROR then
		io.stderr:write(modname .. ": " .. tostring(notif.msg) .. "\n")
		failed = true
	end
end
if failed then
	os.exit(1)
end

local plugins = vim.empty_dict()
for name, plugin in pairs(spec.plugins) do
	if name == "LazyVim" or name == "lazy.nvim" then
		-- skip
	elseif plugin.url == nil then
		io.stderr:write(modname .. ":" .. name .. " has no URL\n")
	elseif plugin.url:sub(1, 7) == "github:" then
		plugins[name] = plugin.url:sub(8)
	else
		io.stderr:write(modname .. ":" .. name .. " has an invalid URL: " .. plugin.url .. "\n")
	end
end

local file = assert(io.open(assert(vim.env["SCAN_OUT"], "SCAN_OUT is not set"), "w"))
assert(file:write(vim.fn.json_encode({ [modname] = plugins })))
assert(file:close())
os.exit(0)
