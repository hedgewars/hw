function detectMap()
    if RopePercent == 100 and MinesNum == 0 then
-- challenges with border
        if band(GameFlags, gfBorder) ~= 0 then
            if LandDigest == "M838018718Scripts/Multiplayer/Racer.lua" then
                return("Racer Challenge #1")
            elseif LandDigest == "M-490229244Scripts/Multiplayer/Racer.lua" then
                return("Racer Challenge #2")
            elseif LandDigest == "M806689586Scripts/Multiplayer/Racer.lua" then
                return("Racer Challenge #3")
            end
-- challenges without border
        elseif LandDigest == "M-134869715Scripts/Multiplayer/Racer.lua" then
            return("Racer Challenge #4")
        elseif LandDigest == "M-661895109Scripts/Multiplayer/Racer.lua" then
            return("Racer Challenge #5")
        elseif LandDigest == "M479034891Scripts/Multiplayer/Racer.lua" then
            return("Racer Challenge #6")
        end
    end
end
