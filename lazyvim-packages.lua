local function load_dir(result, path)
	if vim.fn.isdirectory(path) == 1 then
		for _, name in pairs(vim.fn.readdir(path)) do
			load_dir(result, path .. "/" .. name)
		end
	elseif path:sub(-4) == ".lua" then
		table.insert(result, path)
	end
end

local function module_path(filename)
	assert(filename[0] ~= "/")
	assert(filename:sub(-4) == ".lua")
	return filename:sub(1, -5):gsub("/", "."):gsub("%.init$", "")
end

local lazypath = arg[1]
local lazyvimpath = arg[2]

vim.env["XDG_CONFIG_HOME"] = vim.env["TMPDIR"] .. "/config"
vim.env["XDG_DATA_HOME"] = vim.env["TMPDIR"] .. "/data"
vim.env["XDG_STATE_HOME"] = vim.env["TMPDIR"] .. "/state"
vim.env["XDG_CACHE_HOME"] = vim.env["TMPDIR"] .. "/cache"

-- Init lazy
vim.opt.rtp:prepend(lazypath)
local lazy = require("lazy.minit")
lazy.setup({})

-- defines LazyVim global
vim.opt.rtp:append(lazyvimpath)
require("lazyvim.types")

local Plugin = require("lazy.core.plugin")

local lazyvim_rtp = lazyvimpath .. "/lua"
local plugins_path = lazyvim_rtp .. "/lazyvim/plugins"

local plugin_paths = {}
load_dir(plugin_paths, plugins_path)

local output = {}
for _, path in pairs(plugin_paths) do
	local mod_path = module_path(path:sub(#lazyvim_rtp + 2))
	local raw_spec = require(mod_path)
	local spec = Plugin.Spec.new(raw_spec)

	local names_set = {}
	for name, _ in pairs(spec.plugins) do
		names_set[name] = true
	end
	output[mod_path] = vim.tbl_keys(names_set)
end

local file = io.open(vim.env["out"], "w")
assert(file)
file:write(vim.fn.json_encode(output))
file:close()
