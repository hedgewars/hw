HedgewarsScriptLoad("/Scripts/OfficialChallengeHashes.lua")

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
        return(official_racer_maps[mapString])
    end
end
