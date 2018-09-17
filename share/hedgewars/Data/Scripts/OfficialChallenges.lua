local maps = {
    ["Border,60526986531,M1979096843Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #1"
    , ["Border,71022545335,M1840529040Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #2"
    , ["Border,40469748943,M1784791362Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #3"
    , ["85940488650,M-495887001Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #4"
    , ["62080348735,M2094159595Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #5"
    , ["56818170733,M-156349274Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #6"
    , ["Border,25372705797,M1597723310Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #7"
    , ["Border,10917540013,M740011665Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #8"
    , ["Border,43890274319,M849820937Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #9"
    , ["Border,27870148394,M1979096843Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #10"
    , ["Border,22647869226,M1979096843Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #11"
    , ["Border,46954401793,M1979096843Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #12"
    , ["Border,60760377667,M1979096843Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #13"
    , ["Border,51825989393,M1979096843Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #14"
    , ["81841189250,M1979096843Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #15"
    , ["Border,44246064625,M1979096843Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #16"
    , ["60906776802,M1979096843Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #17"
    , ["Border,70774747774,M1979096843Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #18"
    , ["Border,50512019610,M1979096843Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #19"
    , ["60715683005,M1840529040Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #20"
-- tech racer
    , ["Border,19661006772,M80452408Scripts/Multiplayer/TechRacer.lua"] = "Tech Racer #1"
    , ["Border,19661306766,M80452408Scripts/Multiplayer/TechRacer.lua"] = "Tech Racer #2"
    , ["Border,19661606760,M80452408Scripts/Multiplayer/TechRacer.lua"] = "Tech Racer #3"
    , ["Border,19661906754,M80452408SScripts/Multiplayer/TechRacer.lua"] = "Tech Racer #4"
    , ["Border,19662206748,M80452408SScripts/Multiplayer/TechRacer.lua"] = "Tech Racer #5"
    , ["Border,19662506742,M80452408SScripts/Multiplayer/TechRacer.lua"] = "Tech Racer #6"
    , ["Border,19662806736,M80452408SScripts/Multiplayer/TechRacer.lua"] = "Tech Racer #7"
    , ["Border,19663106730,M80452408SScripts/Multiplayer/TechRacer.lua"] = "Tech Racer #8"
    }

-- modified Adler hash
local hashA = 0
local hashB = 0
local hashModule = 299993

function resetHash()
    hashA = 0
    hashB = 0
end

function addHashData(i)
    hashA = (hashA + i + 65536) % hashModule
    hashB = (hashB + hashA) % hashModule
end

function hashDigest()
    return(hashB * hashModule + hashA)
end

function detectMapWithDigest()
    if RopePercent == 100 and MinesNum == 0 then
        mapString = hashDigest() .. "," .. LandDigest

        if band(GameFlags, gfBorder) ~= 0 then
            mapString = "Border," .. mapString
        end

        --WriteLnToConsole(mapString)
        return(maps[mapString])
    end
end
