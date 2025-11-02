local SHOW_WARNINGS = false

local function scandir(directory)
	local i, t, popen = 0, {}, io.popen
	local pfile = popen('ls -a "'..directory..'"')
	for filename in pfile:lines() do
		i = i + 1
		t[i] = filename
	end
	pfile:close()
	return t
end

local locale_dir = "../share/hedgewars/Data/Locale"

local files = scandir(locale_dir)

for f = 1, #files do
	local filename = files[f]
	if string.match(filename, "^[a-zA-Z_]+%.lua$") ~= nil and filename ~= "stub.lua" then

		print("== "..filename.." ==")
		dofile(locale_dir .. "/" .. filename)
		local errors = 0
		for eng, transl in pairs(locale) do
			local example = "[\""..tostring(eng).."\"] = \""..tostring(transl).."\""

			-- Check for obvious errors
			if transl == "" then
				print("[EE] Empty translation: "..example)
				errors = errors + 1
			end
			if eng == "" then
				print("[EE] Empty source string: "..example)
				errors = errors + 1
			end
			if type(transl) ~= "string" then
				print("[EE] Translation is not a string: "..example)
				errors = errors + 1
			end
			if type(eng) ~= "string" then
				print("[EE] Source is not a string: "..example)
				errors = errors + 1
			end

			-- Check parameters
			local ne, nt = 0, 0
			local patterns = { "c", "d", "E", "e", "f", "g", "G", "i", "o", "u", "X", "x", "q", "s", "%.%df", "%.f", "" }
			for p = 1, #patterns do
				for w in string.gmatch(eng, "%%"..patterns[p]) do
					ne = ne + 1
				end
				for w in string.gmatch(transl, "%%"..patterns[p]) do
					nt = nt + 1
				end
			end
			if ne ~= nt then
				print("[EE] Param mismatch!: [\""..eng.."\"] = \""..transl.."\"")
				errors = errors + 1
			end

			-- Warnings
			if SHOW_WARNINGS and eng == transl then
				print("[WW] Translation unchanged: "..example)
			end
		end
		if errors == 0 then
			print("OK")
		end
	end
end
