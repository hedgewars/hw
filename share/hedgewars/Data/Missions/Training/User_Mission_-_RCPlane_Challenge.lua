loadfile(GetDataPath() .. "Scripts/Locale.lua")()

local player = nil
local RCGear = nil
local planesUsed = 0
local cratesLeft = 0

function onGameInit()

	Seed = 1
	GameFlags = gfInfAttack + gfInvulnerable + gfOneClanMode + gfSolidLand

	TurnTime = 90 * 1000

	Map = "Ropes"
	Theme = "Eyes"

	CaseFreq = 0
	MinesNum = 0
	Explosives = 0

	AddTeam(loc("Wannabe Flyboys"), 14483456, "Simple", "Island", "Default", "Hedgewars")
	player = AddHog(loc("Ace"), 0, 80, "Gasmask") --NoHat
	SetGearPosition(player, 1380, 1500)

end



function onGameStart()

	ShowMission     (
                                loc("RC PLANE TRAINING"),
                                loc("a Hedgewars challenge"),

                                loc("Collect or destroy all the health crates.") .. "|" ..
                                loc("Compete to use as few planes as possible!") .. "|" ..
								"", -amRCPlane, 4000
                                )

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

	tempG = SpawnHealthCrate(930, 557)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(979, 692)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(876, 703)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(2309, 1260)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(1733, 1127)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(1738, 1320)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(3249, 1460)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(3051, 617)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(2972, 353)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(2548, 358)

	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(2090, 1580)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(1752, 1753)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(1865, 1758)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(1985, 1760)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(2429, 1760)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(2810, 1480)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(2800, 1277)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(2806, 1107)
	SetHealth(tempG, 25)

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

	tempG = SpawnHealthCrate(3804, 1461)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(3269, 1742)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(3066, 121)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(3207, 104)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(2928, 103)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(1997, 202)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(2253, 159)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(2132, 774)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(2549, 490)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(3527, 694)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(3777, 78)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(1124, 1746)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(1056, 1740)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(993, 1742)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(799, 1298)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(577, 1126)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(596, 1463)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(3854, 1043)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(1944, 567)
	SetHealth(tempG, 25)
	tempG = SpawnHealthCrate(338, 1748)
	SetHealth(tempG, 25)


end

--function onGameTick()

	--if RCGear ~= nil then
	--	AddCaption(GetTimer(RCGear))
	--end

--end

function onNewTurn()
	TurnTimeLeft = -1
end

function onGearAdd(gear)

	if GetGearType(gear) == gtRCPlane then
		RCGear = gear
		planesUsed = planesUsed + 1
	end

	if GetGearType(gear) == gtCase then
		cratesLeft = cratesLeft + 1
	end

end

function onGearDelete(gear)

	if GetGearType(gear) == gtRCPlane then

		RCGear = nil
		AddCaption(loc("Planes Used:") .. " " .. planesUsed)

	elseif GetGearType(gear) == gtCase then

		AddCaption(loc("Crates Left:") .. " " .. cratesLeft)
		cratesLeft = cratesLeft - 1

		if cratesLeft == 0 then

			ShowMission     (
                                loc("CHALLENGE COMPLETE"),
                                loc("Congratulations!"),
                                loc("Planes Used") .. ": " .. planesUsed .. "|" ..
                                "", 0, 0
                                )


			ParseCommand("teamgone Wannabe Flyboys")
		end

		if RCGear ~= nil then
			SetTimer(RCGear, GetTimer(RCGear) + 10000)
		end

	end

end

function onAmmoStoreInit()
	SetAmmo(amRCPlane, 9, 0, 0, 0)
end
