--------------------------------
-- NO JUMPING
--------------------------------

loadfile(GetDataPath() .. "Scripts/Locale.lua")()

local specialGear = nil

function onGameInit()
    Goals = loc("Jumping is disabled")
end

function onNewTurn()
	SetInputMask(band(0xFFFFFFFF, bnot(gmLJump + gmHJump)))
end

function onGearAdd(gear)

	if (GetGearType(gear) == gtJetpack) or (GetGearType(gear) == gtRope) or (GetGearType(gear) == gtParachute) then
		specialGear = gear
		SetInputMask(band(0xFFFFFFFF, bnot(gmHJump)))
	end

end

function onGearDelete(gear)

	if (GetGearType(gear) == gtJetpack) or (GetGearType(gear) == gtRope) or (GetGearType(gear) == gtParachute) then
		specialGear = nil
		SetInputMask(band(0xFFFFFFFF, bnot(gmLJump + gmHJump)))
	end

end

