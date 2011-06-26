--------------------------------
-- NO JUMPING
--------------------------------

loadfile(GetDataPath() .. "Scripts/Locale.lua")()

function onGameInit()
    Goals = loc("Jumping is disabled")
end

--function onGameStart()
--	ShowMission(LOC_NOT("NO JUMPING"), LOC_NOT("- Jumping is disabled"), LOC_NOT("Good luck out there!"), 0, 0)
--end

function onNewTurn()
	SetInputMask(band(0xFFFFFFFF, bnot(gmLJump + gmHJump)))
end



