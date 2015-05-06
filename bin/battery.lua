#!/usr/bin/env lua

function first_line(file)
	local f = io.open(file)
	if f then
		local line = f:read()
		f:close()
		return line
	else
		return ""
	end
end

function usage()
	print("Usage: " .. arg[0] .. " <cmd>")
	print "TODO"
end

if #arg == 0 then
	usage() return
end

local cmd = arg[1]

local cmd_file = {
	status = "status",
	present = "present",
	percentage = "capacity",
	perc = "capacity",
}

local bat_info_path = "/sys/class/power_supply/BAT0/"

if not cmd_file[cmd] then
	usage()
	return
end

print(first_line(bat_info_path .. cmd_file[cmd]))
