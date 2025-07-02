local Config = require("lazy.core.config")

local count = 0
for _, _ in pairs(Config.plugins) do
	count = count + 1
end

print("1.." .. count)

local idx = 1
local status = 0

for _, plugin in pairs(Config.plugins) do
	if plugin._.installed then
		print("ok " .. idx .. " - " .. plugin.name .. " is installed")
	else
		print("not ok " .. idx .. " - " .. plugin.name .. " is not installed")
		status = 1
	end
	idx = idx + 1
end

print("")
os.exit(status)
