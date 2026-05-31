local home = os.getenv("HOME")
local mpv_conf = home .. "/.config/mpv/mpv.conf"

local settings = {
	"keep-open=yes",
	"target-colorspace-hint=no",
	"save-position-on-quit=yes",
	"cursor-autohide=1000",
	"geometry=50%:50%",
	"autofit-larger=100%x100%",
	"ao=pulse",
}

os.execute("mkdir -p " .. home .. "/.config/mpv")

local existing = {}

local file = io.open(mpv_conf, "r")

if file then
	for line in file:lines() do
		existing[line] = true
	end
	file:close()
end

file = io.open(mpv_conf, "a")

for _, setting in ipairs(settings) do
	if not existing[setting] then
		file:write(setting .. "\n")
	end
end

file:close()
