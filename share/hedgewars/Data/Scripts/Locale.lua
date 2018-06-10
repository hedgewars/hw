-- Library for localizing strings in lua scripts

local lang = HedgewarsScriptLoad("Locale/" .. tostring(LOCALE) .. ".lua")

function loc(text)
    if locale ~= nil and locale[text] ~= nil then return locale[text]
    else return text
    end
end

function loc_noop(text)
    return text
end
