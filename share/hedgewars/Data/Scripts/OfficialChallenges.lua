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
            elseif LandDigest == "M1770509913Scripts/Multiplayer/Racer.lua" then
                return("Racer Challenge #7")
            elseif LandDigest == "M1902370941Scripts/Multiplayer/Racer.lua" then
                return("Racer Challenge #8")
            elseif LandDigest == "M185940363Scripts/Multiplayer/Racer.lua" then
                return("Racer Challenge #9")
            elseif LandDigest == "M751885839Scripts/Multiplayer/Racer.lua" then
                return("Racer Challenge #10")
            elseif LandDigest == "M178845011Scripts/Multiplayer/Racer.lua" then
                return("Racer Challenge #11")
            elseif LandDigest == "M706743197Scripts/Multiplayer/Racer.lua" then
                return("Racer Challenge #12")
            elseif LandDigest == "M157242054Scripts/Multiplayer/Racer.lua" then
                return("Racer Challenge #13")
            elseif LandDigest == "M-1585582638Scripts/Multiplayer/Racer.lua" then
                return("Racer Challenge #14")
            elseif LandDigest == "M-528106034Scripts/Multiplayer/Racer.lua" then
                return("Racer Challenge #16")
            end
-- challenges without border
        elseif LandDigest == "M-134869715Scripts/Multiplayer/Racer.lua" then
            return("Racer Challenge #4")
        elseif LandDigest == "M-661895109Scripts/Multiplayer/Racer.lua" then
            return("Racer Challenge #5")
        elseif LandDigest == "M479034891Scripts/Multiplayer/Racer.lua" then
            return("Racer Challenge #6")
        elseif LandDigest == "M256715557Scripts/Multiplayer/Racer.lua" then
            return("Racer Challenge #15")
        elseif LandDigest == "M-1389184823Scripts/Multiplayer/Racer.lua" then
            return("Racer Challenge #17")
        end
    end
end
