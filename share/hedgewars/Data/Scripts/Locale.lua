-- Library for localizing strings in lua scripts

local lang = loadfile(GetDataPath() .. "Locale/" .. tostring(L) .. ".lua")

if lang ~= nil then
    lang()
end

function loc(text)
    if lang ~= nil and locale ~= nil and locale[text] ~= nil then return locale[text]
    else return text
    end
end
