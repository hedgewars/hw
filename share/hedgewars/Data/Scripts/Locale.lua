-- Library for localizing strings in lua scripts

if LOCALE ~= "en" then
    HedgewarsScriptLoad("Locale/" .. tostring(LOCALE) .. ".lua", false)
end

function loc(text)
    if locale ~= nil and locale[text] ~= nil then return locale[text]
    else return text
    end
end

function loc_noop(text)
    return text
end
