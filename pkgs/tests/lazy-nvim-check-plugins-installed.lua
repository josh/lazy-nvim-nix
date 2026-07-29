local Config = require("lazy.core.config")

local count = 0
for _, _ in pairs(Config.plugins) do
	count = count + 1
end

local min = tonumber(vim.env["MIN_PLUGINS"] or "1")
assert(count >= min, "expected at least " .. min .. " plugins, found " .. count)

print("1.." .. count)

local idx = 1
local status = 0

for _, plugin in pairs(Config.plugins) do
	if plugin._.installed and (plugin.dir or ""):find("^/nix/store/") then
		print("ok " .. idx .. " - " .. plugin.name .. " is installed from " .. plugin.dir)
	else
		print(
			"not ok "
				.. idx
				.. " - "
				.. plugin.name
				.. " is not installed from the nix store, dir="
				.. tostring(plugin.dir)
		)
		status = 1
	end
	idx = idx + 1
end

print("")
os.exit(status)
