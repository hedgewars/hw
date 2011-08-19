------------------------------------
-- TUMBLER
-- v.0.6
------------------------------------

loadfile(GetDataPath() .. "Scripts/Locale.lua")()
loadfile(GetDataPath() .. "Scripts/Tracker.lua")()

--local fMod = 1	--.15
local fMod = 1000000 -- use this for dev and .16+ games
local moveTimer = 0
local leftOn = false
local rightOn = false
local upOn = false
local downOn = false

local preciseOn = false
--local HJumpOn = false
--local LJumpON = false
local fireTimer = 0
local scoreTag = nil
local wep = {}
local wepAmmo = {}
local wepIndex = 0
local wepCount = 0
local roundKills = 0

local TimeLeftCounter = 0
local TimeLeft = 0
local stopMovement = false
local tumbleStarted = false

local beam = false

------------------------
-- version 0.4
------------------------

-- removed some old code/comments
-- removed both shell and mortar as the primary and secondary weapons
-- the primary weapon is now an explosive(barrel)

-- added support for picking up barrels scattered about the map (backspace)
-- added support for dragging around mines (enter toggles on/off)
-- added support for primary fire being onAttackUp
-- added a trail to indicate when the player has 5s or less left to tumble
-- updated showmission to reflect changed controls and options

------------------------
-- version 0.5
------------------------

-- changed some of the user feedback
-- i can't remember??
-- substituted onAttackUp for onPrecise()
-- brought in line with new velocity changes

------------------------
-- version 0.6
------------------------

-- reduced starting "ammo"
-- randomly spawn new barrels/mines on new turn
-- updated user feedback
-- better locs and coloured addcaptions
-- added tag for turntime
-- removed tractor beam
-- added two new weapons and changed ammo handling
-- health crates now give tumbler time, and wep/utility give flamer ammo
-- explosives AND mines can be picked up to increase their relative ammo
-- replaced "no weapon" selected message that hw serves
-- modified crate frequencies a bit
-- added some simple kill-based achievements, i think

---------------------------
-- some other ideas/things
---------------------------
--[[
-- fix "ammo extended" message to be non-generic
-- fix flamer "shots remaining" message on start or choose a standard versus %
-- add more sounds
-- make barrels always explode?
-- persistent ammo?
-- allow custom turntime?
-- dont hurt tumblers and restore their health at turn end?
]]

function DrawTags()
	
	zoomL = 1.3

	DeleteVisualGear(scoreTag)
	scoreTag = AddVisualGear(0, 0, vgtHealthTag, 0, false)
	g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(scoreTag)
	SetVisualGearValues	(	
				scoreTag, 		--id
				-(ScreenWidth/2) + 45,	--xoffset
				ScreenHeight - 50, 	--yoffset
				0, 			--dx
				0, 			--dy
				zoomL, 			--zoom
				1, 			--~= 0 means align to screen
				g7, 			--frameticks
				TimeLeft, 		--value
				240000, 		--timer
				0xffba00ff		--GetClanColor( GetHogClan(CurrentHedgehog) )
				)

end

function GetGearDistance(gear)

	g1X, g1Y = GetGearPosition(gear)
	g2X, g2Y = GetGearPosition(CurrentHedgehog)

	q = g1X - g2X
	w = g1Y - g2Y
	return( (q*q) + (w*w) )

end

-- add to your ammo ***WHEN YOU PUSH A KEY*** near them
-- yes that was my justification for a non generic method
function CheckProximityToExplosives(gear)

	if (GetGearDistance(gear) < 1300) then 

		if (GetGearType(gear) == gtExplosives) then
		
			wepAmmo[0] = wepAmmo[0] + 1			
			PlaySound(sndShotgunReload)
			DeleteGear(gear)
			AddCaption(loc("Ammo extended!"))

		elseif (GetGearType(gear) == gtMine) then
			wepAmmo[2] = wepAmmo[2] + 1			
			PlaySound(sndShotgunReload)
			DeleteGear(gear)
			AddCaption(loc("Ammo extended!"))
		end 


	else
		--AddCaption("There is nothing here...")
	end

end

-- check proximity on crates
function CheckProximity(gear)

	dist = GetGearDistance(gear)
				--15000
	if ((dist < 15000) and (beam == true)) and
	( (GetGearType(gear) == gtMine) or (GetGearType(gear) == gtExplosives) ) then
	--	ndx, ndy = GetGearVelocity(CurrentHedgehog)
	--	SetGearVelocity(gear, ndx, ndy)
		--AddCaption("hello???")
	elseif (dist < 1600) and (GetGearType(gear) == gtCase) then
	
		if GetHealth(gear) > 0 then		

			AddCaption(loc("Tumbling Time Extended!"))
			TimeLeft = TimeLeft + 5 --5s
			DrawTags()
			--PlaySound(sndShotgunReload)
		else
			wepAmmo[1] = wepAmmo[1] + 800	
			PlaySound(sndShotgunReload)
			AddCaption(loc("Ammo extended!"))
		end
		
		DeleteGear(gear)

	end

end

--[[function ProjectileTrack(gear)

	if (GetGearType(gear) == gtMine) or (GetGearType(gear) == gtExplosives) then

		dist = GetGearDistance(gear)

		alt = 1
		if (dist < 30000) then
			alt = -1
		end

		if (dist < 60000)
		--and (dist > 16000)
		then

			--if (GetGearType(gear) == gtShell) then
				turningSpeed = 0.1*fMod*alt
			--end

			dx, dy = GetGearVelocity(gear)

			if GetX(gear) > GetX(CurrentHedgehog) then
				dx = dx - turningSpeed
			else
				dx = dx + turningSpeed
			end

			if GetY(gear) > GetY(CurrentHedgehog) then
				dy = dy - turningSpeed
			else
				dy = dy + turningSpeed
			end


			if (GetGearType(gear) == gtShell) then
				dxlimit = 0.4*fMod
				dylimit = 0.4*fMod
			end

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

			SetGearVelocity(gear, dx, dy)

		end

	end

end]]


function ChangeWeapon()

	--new
	wepIndex = wepIndex + 1
	if wepIndex == wepCount then
		wepIndex = 0	
	end

	AddCaption(wep[wepIndex] .. " " .. loc("selected!"), GetClanColor(GetHogClan(CurrentHedgehog)),capgrpAmmoinfo )
	AddCaption(wepAmmo[wepIndex] .. " " .. loc("shots remaining."), GetClanColor(GetHogClan(CurrentHedgehog)),capgrpMessage2)

end

---------------
-- action keys
---------------

function onPrecise()

	if (CurrentHedgehog ~= nil) and (stopMovement == false) and (tumbleStarted == true) and (wepAmmo[wepIndex] > 0) then

		wepAmmo[wepIndex] = wepAmmo[wepIndex] - 1
		AddCaption(wepAmmo[wepIndex] .. " " .. loc("shots remaining."), GetClanColor(GetHogClan(CurrentHedgehog)),capgrpMessage2)		

		if wep[wepIndex] == loc("Barrel Launcher") then
			morte = AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtExplosives, 0, 0, 0, 1)
			CopyPV(CurrentHedgehog, morte) -- new addition
			x,y = GetGearVelocity(morte)
			x = x*2
			y = y*2
			SetGearVelocity(morte, x, y)
		
		elseif wep[wepIndex] == loc("Mine Deployer") then
			morte = AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtMine, 0, 0, 0, 0)
			SetTimer(morte, 1000)
		end

	end

	preciseOn = true

end

function onPreciseUp()
	preciseOn = false
end

function onHJump()
	-- pick up explosives if nearby them
	if (CurrentHedgehog ~= nil) and (stopMovement == false) and (tumbleStarted == true) then
		runOnGears(CheckProximityToExplosives)
	end
end

function onLJump()
	-- for attracting mines and explosives if the beam is on
	--[[if (CurrentHedgehog ~= nil) and (stopMovement == false) and (tumbleStarted == true) then
		if beam == false then
			beam = true
			AddCaption(loc("Mine-attractor on!"))
		else
			beam = false
			AddCaption(loc("Mine-attractor off!"))
		end
	end]]

	ChangeWeapon()

end

-----------------
-- movement keys
-----------------

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

--------------------------
-- other event handlers
--------------------------

function onGameInit()
	--Theme = "Hell"
	CaseFreq = 0
	HealthCaseProb = 0 
end

function onGameStart()
	
	ShowMission	(
			"TUMBLER",
			loc("a Hedgewars mini-game"),
			loc("Eliminate the enemy hogs to win.") .. "|" ..
			" " .. "|" ..

			--loc("Round Limit") .. ": " .. roundLimit .. "|" ..
			--loc("Turn Time") .. ": " .. (TurnTime/1000) .. loc("sec") .. "|" ..
			--" " .. "|" ..

			loc("Movement: [Up], [Down], [Left], [Right]") .. "|" ..
			loc("Fire") .. ": " .. loc("[Left Shift]") .. "|" ..
			loc("Change Weapon") .. ": " .. loc("[Enter]") .. "|" ..
			loc("Grab Mines/Explosives") .. ": " .. loc("[Backspace]") .. "|" ..

			" " .. "|" ..

			loc("Health crates extend your time.") .. "|" ..
			loc("Ammo is reset at the end of your turn.") .. "|" ..

			"", 4, 4000
			)	

	scoreTag = AddVisualGear(0, 0, vgtHealthTag, 0, false)
	--DrawTags()

	SetVisualGearValues(scoreTag,0,0,0,0,0,1,0, 0, 240000, 0xffffff00)

	wep[0] = loc("Barrel Launcher")
	wep[1] = loc("Flamer")
	wep[2] = loc("Mine Deployer")
	wepCount = 3

end


function onNewTurn()
	
	stopMovement = false
	tumbleStarted = false
	beam = false

	-- randomly create 2 new barrels and 3 mines on the map every turn
	for i = 0, 1 do
		gear = AddGear(0, 0, gtExplosives, 0, 0, 0, 0)
		SetHealth(gear, 100)
		FindPlace(gear, false, 0, LAND_WIDTH)
		tempE = AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)
	end
	for i = 0, 2 do
		gear = AddGear(0, 0, gtMine, 0, 0, 0, 0)
		FindPlace(gear, false, 0, LAND_WIDTH)
		tempE = AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)
	end

	r = GetRandom(100)
	if r > 50 then
		SpawnHealthCrate(0, 0)
	end
	r = GetRandom(100)
	if r > 70 then
		SpawnAmmoCrate(0, 0, amSkip)
	end

	--DrawTags()
	SetVisualGearValues(scoreTag,0,0,0,0,0,1,0, 0, 240000, 0xffffff00)

	--reset ammo counts
	wepAmmo[0] = 2
	wepAmmo[1] = 50
	wepAmmo[2] = 1
	wepIndex = 2
	ChangeWeapon()

	roundKills = 0

end


function DisableTumbler()
	stopMovement = true
	beam = false
	upOn = false
	down = false
	leftOn = false
	rightOn = false
	SetVisualGearValues(scoreTag,0,0,0,0,0,1,0, 0, 240000, 0xffffff00)
end

function onGameTick()

	-- start the player tumbling with a boom once their turn has actually begun
	if tumbleStarted == false then
		if (TurnTimeLeft > 0) and (TurnTimeLeft ~= TurnTime) then
			--AddCaption(loc("Good to go!"))
			tumbleStarted = true
			TimeLeft = 30
			AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtGrenade, 0, 0, 0, 1)
			DrawTags()
		end
	end

	if (CurrentHedgehog ~= nil) and (tumbleStarted == true) then

		--AddCaption(GetX(CurrentHedgehog) .. ";" .. GetY(CurrentHedgehog) )

		runOnGears(CheckProximity) -- crates and mines

		--if beam == true then
		--	runOnGears(ProjectileTrack)
		--end

		-- Calculate and display turn time
		TimeLeftCounter = TimeLeftCounter + 1
		if TimeLeftCounter == 1000 then
			TimeLeftCounter = 0
			TimeLeft = TimeLeft - 1
		
			

			if TimeLeft >= 0 then
				--AddCaption(TimeLeft)
				DrawTags()
			end

		end

		if TimeLeft == 0 then
			DisableTumbler()
		end

		-- handle movement based on IO
		moveTimer = moveTimer + 1
		if moveTimer == 100 then -- 100
			moveTimer = 0

			---------------
			-- new trail code
			---------------
			-- the trail lets you know you have 5s left to pilot, akin to birdy feathers
			if (TimeLeft <= 5) and (TimeLeft > 0) then
				tempE = AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmoke, 0, false)
				g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
				SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, g8, g9, GetClanColor(GetHogClan(CurrentHedgehog)) )
			end
			--------------

			dx, dy = GetGearVelocity(CurrentHedgehog)

			dxlimit = 0.4*fMod
			dylimit = 0.4*fMod

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
				dx = dx - 0.1*fMod
			end
			if rightOn == true then
				dx = dx + 0.1*fMod
			end

			if upOn == true then
				dy = dy - 0.1*fMod
			end
			if downOn == true then
				dy = dy + 0.1*fMod
			end

		

			SetGearVelocity(CurrentHedgehog, dx, dy)

		end

		--
		--flamer
		--
		fireTimer = fireTimer + 1
		if fireTimer == 5 then	-- 5 --10
			fireTimer = 0

			if (wep[wepIndex] == loc("Flamer") ) and (preciseOn == true) and (wepAmmo[wepIndex] > 0) and (stopMovement == false) and (tumbleStarted == true) then

				wepAmmo[wepIndex] = wepAmmo[wepIndex] - 1	
				AddCaption(	
						loc("Flamer") .. ": " .. 
						(wepAmmo[wepIndex]/800*100) - (wepAmmo[wepIndex]/800*100)%2 .. "%", 
						GetClanColor(GetHogClan(CurrentHedgehog)),
						capgrpMessage2
						)	

				dx, dy = GetGearVelocity(CurrentHedgehog)
				shell = AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtFlame, 0, 0, 0, 0)

				xdev = 1 + GetRandom(25)	--15
				xdev = xdev / 100

				r = GetRandom(2)
				if r == 1 then
					xdev = xdev*-1
				end

				ydev = 1 + GetRandom(25)	--15
				ydev = ydev / 100

				r = GetRandom(2)
				if r == 1 then
					ydev = ydev*-1
				end

				--*13	--8
				SetGearVelocity(shell, (dx*4)+(xdev*fMod), (dy*4)+(ydev*fMod))	--10

			end

		end
		--



	end


end

function isATrackedGear(gear)
	if 	(GetGearType(gear) == gtExplosives) or
		(GetGearType(gear) == gtMine) or
		(GetGearType(gear) == gtShell) or	-- new -- gtBall
		(GetGearType(gear) == gtCase)
	then
		return(true)
	else
		return(false)
	end
end


--[[function onGearDamage(gear, damage)
	if gear == CurrentHedgehog then
		-- You are now tumbling
	end
end]]

function onGearAdd(gear)

	if isATrackedGear(gear) then
		trackGear(gear)
	end

	--if GetGearType(gear) == gtBall then
	--	SetTimer(gear, 15000)
	--end

end

function onGearDelete(gear)

	if isATrackedGear(gear) then
		trackDeletion(gear)
	end

	if CurrentHedgehog ~= nil then
		FollowGear(CurrentHedgehog)
	end

	if gear == CurrentHedgehog then
		DisableTumbler()
	end


	-- achievements? prototype
	if GetGearType(gear) == gtHedgehog then	
		if GetHogTeamName(gear) ~= GetHogTeamName(CurrentHedgehog) then
						
			roundKills = roundKills + 1 		
			if roundKills == 2 then
				AddCaption(loc("Double Kill!"),0xffba00ff,capgrpMessage2)
			elseif roundKills == 3 then
				AddCaption(loc("Killing spree!"),0xffba00ff,capgrpMessage2)
			elseif roundKills >= 4 then
				AddCaption(loc("Unstoppable!"),0xffba00ff,capgrpMessage2)			
			end		
	
		elseif gear ~= CurrentHedgehog then
			AddCaption(loc("Friendly Fire!"),0xffba00ff,capgrpMessage2)
		end

	end



end
