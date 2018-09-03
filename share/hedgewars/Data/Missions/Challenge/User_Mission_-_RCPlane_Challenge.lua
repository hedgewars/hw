HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Achievements.lua")

local player = nil
local RCGear = nil
local planesUsed = 0
local planeTimer = 0
local planeUhOh = false
local cratesLeft = 0
local crateStreak = 0
local longestCrateStreak = 0
local commentTimer = 0
local missiles = 0
local totalMissiles = 0
local missileScanTimer = 0
local nextComment = sndNone

function onGameInit()

	Seed = 1
	GameFlags = gfInfAttack + gfInvulnerable + gfOneClanMode + gfSolidLand

	-- Basically unlimited turn time
	TurnTime = MAX_TURN_TIME

	Map = "Ropes"
	Theme = "Eyes"

	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0

	CaseFreq = 0
	MinesNum = 0
	Explosives = 0

	AddTeam(loc("Wannabe Flyboys"), -1, "Simple", "Island", "Default", "cm_scout")
	player = AddHog(loc("Ace"), 0, 80, "Gasmask")
	SetGearPosition(player, 1380, 1500)

end



function onGameStart()

	SendHealthStatsOff()

	ShowMission     (
                                loc("RC Plane Challenge"),
                                loc("Challenge"),

                                loc("Collect or destroy all the health crates.") .. "|" ..
                                loc("Compete to use as few planes as possible!") .. "|" ..
								"", -amRCPlane, 4000
                                )
	SetTeamLabel(loc("Wannabe Flyboys"), "0")

	PlaceGirder(2192, 508, 6)
	PlaceGirder(2192, 670, 6)
	PlaceGirder(2193, 792, 2)
	PlaceGirder(2100, 825, 4)
	PlaceGirder(2009, 899, 6)
	PlaceGirder(2084, 992, 4)
	PlaceGirder(2145, 1087, 6)
	PlaceGirder(2199, 1235, 5)
	PlaceGirder(2308, 1296, 0)
	PlaceGirder(2424, 1234, 7)
	PlaceGirder(2473, 1129, 2)
	PlaceGirder(2437, 1046, 1)
	PlaceGirder(2409, 927, 6)
	PlaceGirder(2408, 763, 6)
	PlaceGirder(2404, 540, 6)
	PlaceGirder(2426, 423, 3)
	PlaceGirder(2550, 400, 4)
	PlaceGirder(2668, 425, 1)
	PlaceGirder(2707, 541, 6)
	PlaceGirder(2706, 703, 6)
	PlaceGirder(2705, 867, 6)
	PlaceGirder(2779, 962, 4)
	PlaceGirder(2894, 924, 3)
	PlaceGirder(2908, 802, 6)
	PlaceGirder(2907, 639, 6)
	PlaceGirder(3052, 566, 4)
	PlaceGirder(2971, 394, 4)
	PlaceGirder(3103, 448, 7)
	PlaceGirder(3047, 654, 0)
	PlaceGirder(3043, 746, 6)
	PlaceGirder(3265, 1583, 6)
	PlaceGirder(3256, 1491, 4)
	PlaceGirder(3187, 1401, 6)
	PlaceGirder(3326, 1400, 6)
	PlaceGirder(774, 530, 5)
	PlaceGirder(922, 595, 4)
	PlaceGirder(1079, 533, 7)
	PlaceGirder(1139, 386, 6)
	PlaceGirder(1074, 237, 5)
	PlaceGirder(723, 381, 6)
	PlaceGirder(781, 229, 7)
	PlaceGirder(927, 746, 6)
	PlaceGirder(874, 736, 0)
	PlaceGirder(982, 737, 0)
	PlaceGirder(2430, 1730, 4)

	PlaceGirder(1613, 1104, 7)
	PlaceGirder(1564, 1256, 6)
	PlaceGirder(1643, 1341, 5)
	PlaceGirder(1780, 1372, 4)
	PlaceGirder(1869, 1296, 7)
	PlaceGirder(1858, 1163, 5)
	PlaceGirder(1739, 1044, 5)
	PlaceGirder(1621, 926, 5)
	PlaceGirder(1597, 985, 5)
	PlaceGirder(1449, 939, 4)
	PlaceGirder(1473, 874, 4)
	PlaceGirder(2092, 1352, 7)
	PlaceGirder(2145, 1444, 7)
	PlaceGirder(2004, 1443, 3)
	PlaceGirder(1978, 1523, 2)
	PlaceGirder(2021, 1596, 1)
	PlaceGirder(2103, 1625, 0)
	PlaceGirder(2208, 1551, 7)
	PlaceGirder(2327, 1431, 7)
	PlaceGirder(2395, 1478, 6)
	PlaceGirder(2396, 1600, 2)
	PlaceGirder(2495, 1285, 6)
	PlaceGirder(2494, 1408, 2)
	PlaceGirder(2547, 530, 0)

	PlaceGirder(2451, 1551, 0)
	PlaceGirder(2551, 706, 6)
	PlaceGirder(2551, 869, 6)
	PlaceGirder(2623, 1016, 5)
	PlaceGirder(2773, 1083, 4)
	PlaceGirder(2924, 1019, 7)
	PlaceGirder(2568, 1491, 7)
	PlaceGirder(2618, 1346, 6)
	PlaceGirder(2674, 1195, 7)
	PlaceGirder(2822, 1142, 4)
	PlaceGirder(2963, 1069, 7)
	PlaceGirder(3067, 938, 5)
	PlaceGirder(2803, 1373, 2)
	PlaceGirder(2811, 1559, 2)

	SpawnFakeHealthCrate(930, 557, false, false)
	SpawnFakeHealthCrate(979, 692, false, false)
	SpawnFakeHealthCrate(876, 703, false, false)
	SpawnFakeHealthCrate(2309, 1260, false, false)
	SpawnFakeHealthCrate(1733, 1127, false, false)
	SpawnFakeHealthCrate(1738, 1320, false, false)
	SpawnFakeHealthCrate(3249, 1460, false, false)
	SpawnFakeHealthCrate(3051, 617, false, false)
	SpawnFakeHealthCrate(2972, 353, false, false)
	SpawnFakeHealthCrate(2548, 358, false, false)

	SpawnFakeHealthCrate(2090, 1580, false, false)
	SpawnFakeHealthCrate(1752, 1753, false, false)
	SpawnFakeHealthCrate(1865, 1758, false, false)
	SpawnFakeHealthCrate(1985, 1760, false, false)
	SpawnFakeHealthCrate(2429, 1760, false, false)
	SpawnFakeHealthCrate(2810, 1480, false, false)
	SpawnFakeHealthCrate(2800, 1277, false, false)
	SpawnFakeHealthCrate(2806, 1107, false, false)

	PlaceGirder(1897, 903, 6)
	PlaceGirder(1916, 784, 3)
	PlaceGirder(2010, 732, 4)
	PlaceGirder(2082, 639, 6)
	PlaceGirder(2081, 516, 2)
	PlaceGirder(1985, 487, 4)
	PlaceGirder(1862, 407, 5)
	PlaceGirder(1855, 224, 7)
	PlaceGirder(2006, 163, 4)
	PlaceGirder(2128, 187, 1)
	PlaceGirder(2251, 213, 4)
	PlaceGirder(2413, 213, 4)
	PlaceGirder(1952, 618, 0)
	PlaceGirder(957, 1068, 4)
	PlaceGirder(794, 1069, 4)
	PlaceGirder(728, 1163, 6)
	PlaceGirder(728, 1287, 2)
	PlaceGirder(802, 1342, 4)
	PlaceGirder(966, 1342, 4)
	PlaceGirder(674, 1032, 1)
	PlaceGirder(554, 1011, 4)
	PlaceGirder(445, 1056, 3)
	PlaceGirder(422, 1174, 6)
	PlaceGirder(369, 1341, 5)
	PlaceGirder(495, 1313, 5)
	PlaceGirder(568, 1379, 3)
	PlaceGirder(577, 1202, 2)
	PlaceGirder(744, 1490, 5)
	PlaceGirder(760, 1617, 7)
	PlaceGirder(622, 1693, 4)
	PlaceGirder(476, 1623, 5)
	PlaceGirder(376, 1697, 1)
	PlaceGirder(955, 1746, 2)
	PlaceGirder(1025, 1746, 2)
	PlaceGirder(1090, 1745, 2)
	PlaceGirder(1156, 1746, 2)
	PlaceGirder(3806, 1530, 2)
	PlaceGirder(3880, 1464, 2)
	PlaceGirder(3738, 1458, 2)
	PlaceGirder(3806, 1390, 2)
	PlaceGirder(3805, 1588, 0)
	PlaceGirder(3676, 1609, 3)
	PlaceGirder(3930, 1615, 1)
	PlaceGirder(3719, 1295, 0)
	PlaceGirder(3888, 1294, 0)
	PlaceGirder(3661, 1385, 2)
	PlaceGirder(3955, 1377, 2)
	PlaceGirder(3982, 1518, 0)
	PlaceGirder(3378, 440, 2)
	PlaceGirder(3447, 492, 4)
	PlaceGirder(3564, 529, 1)
	PlaceGirder(3596, 647, 6)
	PlaceGirder(3521, 740, 4)
	PlaceGirder(3524, 838, 4)
	PlaceGirder(3644, 819, 3)
	PlaceGirder(3691, 708, 6)
	PlaceGirder(3690, 545, 6)
	PlaceGirder(3612, 433, 5)
	PlaceGirder(3463, 383, 4)
	PlaceGirder(2815, 122, 7)
	PlaceGirder(2960, 72, 4)
	PlaceGirder(3032, 123, 2)
	PlaceGirder(3063, 174, 0)
	PlaceGirder(3095, 124, 2)
	PlaceGirder(3169, 71, 4)
	PlaceGirder(3320, 124, 5)
	PlaceGirder(3210, 179, 2)
	PlaceGirder(2932, 181, 2)

	SpawnFakeHealthCrate(3804, 1461, false, false)
	SpawnFakeHealthCrate(3269, 1742, false, false)
	SpawnFakeHealthCrate(3066, 121, false, false)
	SpawnFakeHealthCrate(3207, 104, false, false)
	SpawnFakeHealthCrate(2928, 103, false, false)
	SpawnFakeHealthCrate(1997, 202, false, false)
	SpawnFakeHealthCrate(2253, 159, false, false)
	SpawnFakeHealthCrate(2132, 774, false, false)
	SpawnFakeHealthCrate(2549, 490, false, false)
	SpawnFakeHealthCrate(3527, 694, false, false)
	SpawnFakeHealthCrate(3777, 78, false, false)
	SpawnFakeHealthCrate(1124, 1746, false, false)
	SpawnFakeHealthCrate(1056, 1740, false, false)
	SpawnFakeHealthCrate(993, 1742, false, false)
	SpawnFakeHealthCrate(799, 1298, false, false)
	SpawnFakeHealthCrate(577, 1126, false, false)
	SpawnFakeHealthCrate(596, 1463, false, false)
	SpawnFakeHealthCrate(3854, 1043, false, false)
	SpawnFakeHealthCrate(1944, 567, false, false)
	SpawnFakeHealthCrate(338, 1748, false, false)

end

function onGameTick20()
	if RCGear ~= nil then
		if(GetTimer(RCGear) < 3000 and planeUhOh == false) then
			PlaySound(sndUhOh, player)
			planeUhOh = true
		end
		planeTimer = planeTimer + 20
	end
	if commentTimer > 0 then
		commentTimer = commentTimer - 20
	elseif(nextComment ~= sndNone) then
		PlaySound(nextComment, player)
		nextComment = sndNone
	end
	if missileScanTimer > 0 then
		missileScanTimer = missileScanTimer - 20
	else
		if crateStreak == 0 and missiles == 3 then
			PlaySound(sndMissed, player)
			missiles = 4
		end
	end
end

function onNewTurn()
	SetTurnTimeLeft(MAX_TURN_TIME)
end

function onGearAdd(gear)

	if GetGearType(gear) == gtRCPlane then
		RCGear = gear
		planesUsed = planesUsed + 1
		SetTeamLabel(loc("Wannabe Flyboys"), tostring(planesUsed))
		planeTimer = 0
		missiles = 0
	end

	if GetGearType(gear) == gtCase then
		cratesLeft = cratesLeft + 1
	end

	if GetGearType(gear) == gtAirBomb then
		totalMissiles = totalMissiles + 1
	end
end

function onGearDelete(gear)

	if GetGearType(gear) == gtRCPlane then

		RCGear = nil
		planeUhOh = false
		missiles = 0

		if(planeTimer < 2000 and crateStreak == 0) then
			nextComment = sndStupid
			commentTimer = math.min(2000-planeTimer, 800)
		elseif(planeTimer < 5000 and crateStreak == 0) then
			PlaySound(sndOops, player)
		elseif(planesUsed == 72) then
			PlaySound(sndStupid, player)
		elseif(planesUsed == 50) then
			PlaySound(sndNutter, player)
		elseif(planesUsed == 30) then
			PlaySound(sndOops, player)
		end

		crateStreak = 0

	elseif GetGearType(gear) == gtAirBomb then
		missiles = missiles + 1
		missileScanTimer = 500

	elseif GetGearType(gear) == gtCase then

		cratesLeft = cratesLeft - 1
		crateStreak = crateStreak + 1
		if(crateStreak > longestCrateStreak) then
			longestCrateStreak = crateStreak
		end

		if band(GetGearMessage(gear), gmDestroy) ~= 0 then
			-- Crate collection sound
			PlaySound(sndShotgunReload)
		end
		AddCaption(string.format(loc("Crates left: %d"), cratesLeft))

		if cratesLeft == 0 then

			local rank = "unknown"
			local color = capcolDefault
			local sound = sndVictory
			if planesUsed >= 156 then
				rank = loc("Destroyer of planes")	
				color = 0xD06700FF
				sound = sndLaugh
			elseif planesUsed >= 98 then
				rank = loc("Hopeless case")
				color = 0xFF0000FF
			elseif planesUsed >= 72 then
				rank = loc("Drunk greenhorn")
				color = 0xFF0040FF
			elseif planesUsed >= 50 then
				rank = loc("Greenhorn") -- a.k.a. "absolute beginner"
				color = 0xFF0080FF
			elseif planesUsed >= 39 then
				rank = loc("Beginner")
				color = 0xFF00BFFF
			elseif planesUsed >= 30 then
				rank = loc("Experienced beginner")
				color = 0xFF00CCFF
			elseif planesUsed >= 21 then
				rank = loc("Below-average pilot")
				color = 0xFF00FFFF
			elseif planesUsed >= 17 then
				rank = loc("Average pilot")				
				color = 0xBF00FFFF
			elseif planesUsed >= 13 then
				rank = loc("Above-average pilot")
				color = 0x8000FFFF
			elseif planesUsed >= 8 then
				rank = loc("Professional pilot")
				color = 0x4000FFFF
			elseif planesUsed >= 5 then
				rank = loc("Professional stunt pilot")
				color = 0x0000FFFF
			elseif planesUsed >= 3 then
				rank = loc("Elite pilot")
				color = 0x0040FFFF
			elseif planesUsed == 2 then
				rank = loc("Upper-class elite pilot")
				color = 0x0080FFFF
			elseif planesUsed == 1 then
				rank = loc("Top-class elite pilot")
				color = 0x00FFFFFF
				sound = sndFlawless
			else
				rank = loc("Cheater")
				color = 0xFF0000FF
				sound = sndCoward
			end
			AddCaption(string.format(loc("Rank: %s"), rank), color, capgrpMessage2)
			SendStat(siCustomAchievement, string.format(loc("Your rank: %s"), rank))
			if planesUsed == 1 then
				AddCaption(loc("Flawless victory!"))
				SendStat(siGameResult, loc("You have perfectly beaten the challenge!"))
				SendStat(siCustomAchievement, loc("You have used only 1 RC plane. Outstanding!"))
			else
				AddCaption(loc("Victory!"))
				SendStat(siGameResult, loc("You have finished the challenge!"))
				SendStat(siCustomAchievement, string.format(loc("You have used %d RC planes."), planesUsed))
			end
		
			if(totalMissiles > 1) then
				SendStat(siCustomAchievement, string.format(loc("You have dropped %d missiles."), totalMissiles))
			end

			if(longestCrateStreak > 5) then
				if(planesUsed == 1) then
					SendStat(siCustomAchievement, string.format(loc("In your best (and only) flight you took out %d crates with one RC plane!"), longestCrateStreak))
				else
					SendStat(siCustomAchievement, string.format(loc("In your best flight you took out %d crates with one RC plane."), longestCrateStreak))
				end
			end

			if(planesUsed == 2) then
				SendStat(siCustomAchievement, loc("This was an awesome performance! But this challenge can be finished with even just one RC plane. Can you figure out how?"))
			end
			if(planesUsed == 1) then
				SendStat(siCustomAchievement, loc("Congratulations! You have truly mastered this challenge! Don't forget to save the demo."))
				awardAchievement(loc("Prestigious Pilot"), nil, false)
			end

			ShowMission     (
                                loc("CHALLENGE COMPLETE"),
                                loc("Congratulations!"),
                                string.format(loc("Planes used: %d"), planesUsed) .. "|" ..
                                "", 0, 0
                                )
			SetState(player, gstWinner)
			PlaySound(sound, player)


			DismissTeam(loc("Wannabe Flyboys"))
			EndGame()
		end

		if RCGear ~= nil then
			SetTimer(RCGear, GetTimer(RCGear) + 10000)
		end
	end

end

function onAmmoStoreInit()
	SetAmmo(amRCPlane, 9, 0, 0, 0)
end

function onNewTurn()
 	SetWeapon(amRCPlane)
end
