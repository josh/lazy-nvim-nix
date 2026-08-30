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

local function isScannedModule(modname)
	return modname == "lazyvim.plugins" or vim.startswith(modname, "lazyvim.plugins.extras.")
end

if mode == "list" then
	local names = {}
	utils.walkmods(lazyvimpath .. "/lua/lazyvim/plugins", function(modname)
		if isScannedModule(modname) then
			names[modname] = true
		end
	end, "lazyvim.plugins")

	local files = vim.fn.globpath(lazyvimpath .. "/lua/lazyvim/plugins", "**/*.lua", false, true)
	assert(#files > 0, "no lua files found under lazyvim/plugins")
	for _, path in ipairs(files) do
		local rel = path:sub(#lazyvimpath + #"/lua/" + 1)
		local modname = rel:gsub("%.lua$", ""):gsub("/init$", ""):gsub("/", ".")
		if isScannedModule(modname) then
			assert(names[modname], "module file not reached by walkmods: " .. modname .. " (" .. path .. ")")
		end
	end

	local sorted = vim.tbl_keys(names)
	table.sort(sorted)
	local file = assert(io.open(assert(vim.env["SCAN_OUT"], "SCAN_OUT is not set"), "w"))
	for _, modname in ipairs(sorted) do
		assert(file:write(modname .. "\n"))
	end
	assert(file:close())
	os.exit(0)
end

assert(mode == "scan", "unknown mode: " .. mode)
local modname = assert(_G.arg[2], "scan requires a module name")

local failed = false

vim.notify = function(msg, level, _opts)
	io.stderr:write(modname .. ": notify: " .. tostring(msg) .. "\n")
	if (level or vim.log.levels.INFO) >= vim.log.levels.ERROR then
		failed = true
	end
end

LazyVim.lazy_notify = function() end

table.insert(require("lazy.core.config").spec.modules, modname)
require("lazyvim.config").init()
LazyVim.config.get_defaults()

local function scanModule(opts)
	local spec = Plugin.Spec.new({
		name = "LazyVim",
		dir = lazyvimpath,
		import = modname,
	}, opts)

	for _, notif in ipairs(spec.notifs) do
		if notif.level >= vim.log.levels.WARN then
			io.stderr:write(modname .. ": " .. tostring(notif.msg) .. "\n")
		end
		if notif.level >= vim.log.levels.ERROR then
			failed = true
		end
	end

	local plugins = vim.empty_dict()
	local branches = vim.empty_dict()
	for name, plugin in pairs(spec.plugins) do
		local slug = nil
		if name == "LazyVim" or name == "lazy.nvim" then
			-- skip
		elseif plugin.url == nil then
			io.stderr:write(modname .. ":" .. name .. " has no URL\n")
		elseif plugin.url:sub(1, 7) == "github:" then
			slug = plugin.url:sub(8)
		elseif plugin.url:sub(1, 8) == "https://" then
			slug = plugin.url:gsub("%.git$", "")
		else
			io.stderr:write(modname .. ":" .. name .. " has an unsupported URL: " .. plugin.url .. "\n")
			failed = true
		end
		if slug ~= nil then
			plugins[name] = slug
			if plugin.branch ~= nil then
				branches[slug] = plugin.branch
			end
		end
	end
	return plugins, branches
end

local plugins, branches = scanModule(nil)
local withOptional, optionalBranches = scanModule({ optional = true })
if failed then
	os.exit(1)
end

for slug, branch in pairs(optionalBranches) do
	branches[slug] = branch
end

local optional = vim.empty_dict()
for name, slug in pairs(withOptional) do
	if plugins[name] == nil then
		optional[name] = slug
	end
end

local expectedEmpty = {
	["lazyvim.plugins.extras.lang.thrift"] = true,
	["lazyvim.plugins.extras.vscode"] = true,
}
if next(plugins) == nil and next(optional) == nil and not expectedEmpty[modname] then
	io.stderr:write(modname .. ": scanned no plugins\n")
	os.exit(1)
end

local out = { [modname] = plugins }
if next(optional) ~= nil then
	out["optional"] = optional
end
if next(branches) ~= nil then
	out["branches"] = branches
end

local file = assert(io.open(assert(vim.env["SCAN_OUT"], "SCAN_OUT is not set"), "w"))
assert(file:write(vim.fn.json_encode(out)))
assert(file:close())
os.exit(0)
