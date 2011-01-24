-- enable awesome translaction support so we can use loc() wherever we want
loadfile(GetDataPath() .. "Scripts/Locale.lua")()

local moveTimer = 0
local leftOn = false
local rightOn = false
local upOn = false
local downOn = false

local shotsMax = 10
local shotsLeft = 50

local TimeLeftCounter = 0
local TimeLeft = 30--000
local stopMovement = false
local tumbleStarted = false

------------------------

function GetSpeed()

	dx, dy = GetGearVelocity(CurrentHedgehog)

	x = dx*dx
	y = dy*dy
	z = x+y

	z = z*100

	k = z%1

	if k ~= 0 then
	 z = z - k
	end

	return(z)

end

function onGameInit()
	--Theme = "Hell"
end


function onGameStart()
	ShowMission(loc("TUMBLER"), "a Hedgewars mini-game", "- Use the arrow keys to move|- Use [enter] and [backspace] to fire", 4, 4000)
end

function onHJump()
	if (shotsLeft > 0) and (CurrentHedgehog ~= nil) and (stopMovement == false) and (tumbleStarted == true) then -- seems to not work with a hedgehog nil chek
		shotsLeft = shotsLeft - 1
		AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtMortar, 0, 0, 0, 1)
		AddCaption(loc("Shots Left: ") .. shotsLeft)
	end
end

function onLJump()
	if (shotsLeft > 0) and (CurrentHedgehog ~= nil) and (stopMovement == false) and (tumbleStarted == true) then -- seems to not work with a hedgehog nil chek

		dx, dy = GetGearVelocity(CurrentHedgehog)

		--boosts in the direction you're already going
		--[[if dx >= 0 then
			x = -15
		elseif dx < 0 then
			x = 15
		end

		if dy >= 0 then
			y = -15
		elseif dy < 0 then
			y = 15
		end]]


		-- this repositions where the explosions are going to appear
		-- based on the users INTENDED (keypress) direction
		-- thus allowing to boost yourself or change direction with
		-- a blast

		-- naturally, it's also an anti-hog weapon

		x = 0
		y = 0

		if leftOn == true then
			x = x + 15
		end
		if rightOn == true then
			x = x - 15
		end

		if upOn == true then
			y = y + 15
		end
		if downOn == true then
			y = y - 15
		end


		shotsLeft = shotsLeft - 1
		AddGear((GetX(CurrentHedgehog) + x), (GetY(CurrentHedgehog) + y), gtGrenade, 0, 0, 0, 1)
		AddCaption(loc("Shots Left: ") .. shotsLeft)

	end
end

function onLeft()
	if (CurrentHedgehog ~= nil) and (stopMovement == false) then
		leftOn = true
	end
end

function onRight()
	if (CurrentHedgehog ~= nil) and (stopMovement == false) then
		rightOn = true
	end
end

function onUp()
	if (CurrentHedgehog ~= nil) and (stopMovement == false) then
		upOn = true
	end
end

function onDown()
	if (CurrentHedgehog ~= nil) and (stopMovement == false) then
		downOn = true
	end
end

function onDownUp()
	downOn = false
end
function onUpUp()
	upOn = false
end
function onLeftUp()
	leftOn = false
end
function onRightUp()
	rightOn = false
end

function onNewTurn()
	shotsLeft = shotsMax
	stopMovement = false
	tumbleStarted = false
	--SetInputMask(band(0xFFFFFFFF, bnot(gmAnimate+gmAttack+gmDown+gmHJump+gmLeft+gmLJump+gmPrecise+gmRight+gmSlot+gmSwitch+gmTimer+gmUp+gmWeapon)))
	--AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtGrenade, 0, 0, 0, 1)
end

function onGameTick()

	-- start the player tumbling with a boom once their turn has actually begun
	if tumbleStarted == false then
		if (TurnTimeLeft > 0) and (TurnTimeLeft ~= TurnTime) then
			AddCaption("Good to go!")
			tumbleStarted = true
			TimeLeft = 45
			AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtGrenade, 0, 0, 0, 1)
		end
	end

	if (CurrentHedgehog ~= nil) and (tumbleStarted == true) then

		--AddCaption(loc("Speed: ") .. GetSpeed())

		-- Calculate and display turn time
		TimeLeftCounter = TimeLeftCounter + 1
		if TimeLeftCounter == 1000 then
			TimeLeftCounter = 0
			TimeLeft = TimeLeft - 1

			if TimeLeft >= 0 then
				--TurnTimeLeft = TimeLeft
				AddCaption(loc("Time Left: ") .. TimeLeft)
			end

		end

		--if TimeLeft >= 0 then
		--	--TurnTimeLeft = TimeLeft
		--	AddCaption(loc("Time Left: ") .. TimeLeft)
		--end

		--ShowMission(loc("TUMBLER"), loc("v0.2"), loc("Speed: ") .. GetSpeed() .. "|" .. loc("Ammo: ") .. shotsLeft, 4, 0)

		if TimeLeft == 0 then
			stopMovement = true
			upOn = false
			down = false
			leftOn = false
			rightOn = false
		end




		-- handle movement based on IO
		moveTimer = moveTimer + 1
		if moveTimer == 100 then -- 100
			moveTimer = 0

			dx, dy = GetGearVelocity(CurrentHedgehog)

			dxlimit = 0.4
			dylimit = 0.4

			if dx > dxlimit then
				dx = dxlimit
			end
			if dy > dylimit then
				dy = dylimit
			end
			if dx < -dxlimit then
				dx = -dxlimit
			end
			if dy < -dylimit then
				dy = -dylimit
			end


			if leftOn == true then
				dx = dx - 0.1
			end
			if rightOn == true then
				dx = dx + 0.1
			end

			if upOn == true then
				dy = dy - 0.1
			end
			if downOn == true then
				dy = dy + 0.1
			end

			--if leftOn == true then
			--	dx = dx - 0.04
			--end
			--if rightOn == true then
			--	dx = dx + 0.04
			--end

			--if upOn == true then
			--	dy = dy - 0.1
			--end
			--if downOn == true then
			--	dy = dy + 0.06
			--end

			SetGearVelocity(CurrentHedgehog, dx, dy)

		end







	end



end


function onGearDamage(gear, damage)
	if gear == CurrentHedgehog then
		-- You are now tumbling
	end
end


function onGearAdd(gear)
end

function onGearDelete(gear)

	if CurrentHedgehog ~= nil then
		FollowGear(CurrentHedgehog)
	end

end
