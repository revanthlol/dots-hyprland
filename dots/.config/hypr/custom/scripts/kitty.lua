local home = os.getenv("HOME")

local custom_conf = home .. "/.config/hypr/custom/kitty.conf"
local kitty_conf = home .. "/.config/kitty/kitty.conf"

os.execute("mkdir -p " .. home .. "/.config/kitty")
os.execute("mkdir -p " .. home .. "/.config/hypr/custom")

local include_line = "include " .. custom_conf

local found = false

local file = io.open(kitty_conf, "r")

if file then
	for line in file:lines() do
		if line == include_line then
			found = true
			break
		end
	end
	file:close()
end

if not found then
	file = io.open(kitty_conf, "a")
	file:write("\n" .. include_line .. "\n")
	file:close()
end

os.execute("pgrep -x kitty >/dev/null && kitty @ set-background-opacity 0.3 >/dev/null 2>&1")
