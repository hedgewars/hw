--------------------------------
-- NO JUMPING
--------------------------------

loadfile(GetDataPath() .. "Scripts/Locale.lua")()

function onGameStart()
	ShowMission(loc("NO JUMPING"), loc("- Jumping is disabled"), loc("Good luck out there!"), 0, 0)
end

function onNewTurn()
	SetInputMask(band(0xFFFFFFFF, bnot(gmLJump + gmHJump)))
end



