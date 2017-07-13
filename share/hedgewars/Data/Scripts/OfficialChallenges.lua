local maps = {
    ["Border,60526986531,M838018718Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #1"
    , ["Border,71022545335,M-490229244Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #2"
    , ["Border,40469748943,M806689586Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #3"
    , ["85940488650,M-134869715Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #4"
    , ["62080348735,M-661895109Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #5"
    , ["56818170733,M479034891Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #6"
    , ["Border,25372705797,M1770509913Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #7"
    , ["Border,10917540013,M1902370941Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #8"
    , ["Border,43890274319,M185940363Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #9"
    , ["Border,27870148394,M751885839Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #10"
    , ["Border,22647869226,M178845011Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #11"
    , ["Border,46954401793,M706743197Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #12"
    , ["Border,60760377667,M157242054Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #13"
    , ["Border,51825989393,M-1585582638Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #14"
    , ["81841189250,M256715557Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #15"
    , ["Border,44246064625,M-528106034Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #16"
    , ["60906776802,M-1389184823Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #17"
    , ["Border,70774747774,M-534640804Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #18"
    , ["Border,50512019610,M-1839546856Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #19"
    , ["60715683005,M-281312897Scripts/Multiplayer/Racer.lua"] = "Racer Challenge #20"
-- tech racer
    , ["Border,19661006772,M-975391975Scripts/Multiplayer/TechRacer.lua"] = "Tech Racer #1"
    , ["Border,19661306766,M-975391975Scripts/Multiplayer/TechRacer.lua"] = "Tech Racer #2"
    , ["Border,19661606760,M-975391975Scripts/Multiplayer/TechRacer.lua"] = "Tech Racer #3"
    , ["Border,19661906754,M-975391975Scripts/Multiplayer/TechRacer.lua"] = "Tech Racer #4"
    , ["Border,19662206748,M-975391975Scripts/Multiplayer/TechRacer.lua"] = "Tech Racer #5"
    , ["Border,19662506742,M-975391975Scripts/Multiplayer/TechRacer.lua"] = "Tech Racer #6"
    , ["Border,19662806736,M-975391975Scripts/Multiplayer/TechRacer.lua"] = "Tech Racer #7"
    , ["Border,19663106730,M-975391975Scripts/Multiplayer/TechRacer.lua"] = "Tech Racer #8"
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
