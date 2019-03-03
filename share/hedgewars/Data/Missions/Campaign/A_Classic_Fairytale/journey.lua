--[[
A Classic Fairytale: The Journey Back

= SUMMARY =
This is a very complex and heavily scripted mission with
2 major gameplay variants and 2 sub-variants each.

This mission is mostly about movement and overcoming obstacles,
and not much about fighting.

The player has either 1 or 2 hogs (depending on previous mission)
and must reach the left coast. The cyborg will show up from time
to time and constantly annoys the heroes with obstacles and additional
challenges.

The mission's gameplay is affected by whether Dense Cloud survived
in the previous mission. The mission's dialogues are affected by
the decision of the player in the previous mission.

= GOALS =
- Collect the crate at the left coast
- (Need to accomplish various sub-goals before this is possible)
- Then kill the cyborg

= FLOW CHART =
== Linear events ==

Note: This mission's gameplay is significantly affected by the choices of the previous mission (The Shadow Falls).
There are two major paths, and each of them has two variants.

=== PATH ONE (AL) ===
Condition: Cyborg's offer in ACF2 accepted and Dense Cloud survived.

- Mission starts with Dense Cloud and Leaks a Lot
- Mines time: 5s
- Cut scene: startAnimAL (initial instructions)
- Hog moves past flower (via teamwork)
- Animation: pastFlowerAnimAL
- Player jumps up the tree
- Cut scene: outPutAnimAL
- Cyborg teleports one hog to the pit, while the other hog remains
- TBS
- Trapped hog walks out of pit
- Cut scene: midAnimAL
- Trapped hog is teleported below bridge (and trapped again)
- A huge barricade at the bridge is erected, and mines spawn on bridge
- Now any hog needs to collect the final crate
- TBS
- Final crate collected
- Cut scene: endAnimAL
- Cyborg and princess apear, player must kill cyborg
| Cyborg killed
    - Cut scene: winAnim
    > Victory
| Princess killed
    - Cut scene: endFailAnim
    > Game over

=== PATH TWO (AD) ===
Condition: Cyborg's offer in ACF2 accepted, but Dense Cloud died afterwards.

- Mission starts with Leaks a Lot only
- Cut scene: startAnimAD (initial instructions)
- Hog moves past flower (via blowtorch)
- Animation: pastFlowerAnimAD
- TBS
- Hog proceeds all the way to the bridge
- Cut scene: outPutAnimAD (the “Princess Game”)
- Hog is teleported to the pit
- TBS
- Hog must reach goal crate within a given number of turns
| Hog reaches goal crate within the turn limit
    - Cut scene: endAnimAD
    - Cyborg and princess spawn
    | Cyborg killed
        - Cut scene: winAnim
        > Victory
    | Princess killed
        - Cut scene: endFailAnim
        > Game over
| Turn limit exceeded
    - Cut scene: failAnimAD (princess is caged and killed by cyborg)
    > Game over

=== PATH THREE (RL) ===
Condition: Cyborg's offer in ACF2 rejected.

This is almost identical to Path One, only the dialogues differ.
All AL animations are replaced with RL animations.

=== PATH FOUR (attacked) ===
Condition: Cyborg from ACF2 was attacked.

This is almost identical to Path Two, only the dialogues differ.
Uses startAnim and midAnim from SetupAnimAttacked.


== Non-linear events ==
- Any of the Natives dies
   > Game over

]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

--///////////////////////////////CONSTANTS///////////////////////////

choiceAccepted = 1
choiceRefused = 2
choiceAttacked = 3

endStage = 1

cannibalNum = 8
cannibalNames = {loc("John"), loc("Flesh for Brainz"), loc("Eye Chewer"), loc("Torn Muscle"),
                 loc("Nom-Nom"), loc("Vedgies"), loc("Brain Blower"), loc("Gorkij")}
cannibalPos = {{2471, 1174}, {939, 1019}, {1953, 902}, {3055, 1041},
               {1121, 729}, {1150, 718}, {1149, 680}, {1161, 773}}

startLeaksPosDuo = {3572, 1426}
startEventXDuo = 3300
startDensePosDuo = {3454, 1471}
startCyborgPosDuo = {3202, 1307}
midDensePosDuo = {1464, 1410}
midCyborgPosDuo = {1264, 1390}

--///////////////////////////////VARIABLES///////////////////////////

m2Choice = 0
m2DenseDead = 0

TurnsLeft = 0
stage = 0

nativesTeamName = nil
princessTeamName = nil
cannibalsTeamName = nil
cyborgTeamName = nil

startAnimStarted = false
blowTaken = false
fireTaken = false
gravityTaken = false
sniperTaken = false
leaksDead = false
denseDead = false
princessDead = false
cyborgDead = false
victory = false
cannibalDead = {}
hedgeHidden = {}

startAnim = {}
startAnimAD = {}
startAnimAL = {}
startAnimRL = {}

pastFlowerAnimAL = {}
pastFlowerAnimRL = {}
pastFlowerAnim = {}

outPitAnimAL = {}
outPitAnimRL = {}
outPitAnim = {}

midAnim = {}
midAnimAD = {}

failAnim = {}
failAnimAD = {}

endAnim = {}
endAnimAD = {}
endAnimAL = {}
endAnimRL = {}

endFailAnim = {}

winAnim = {}
winAnimAD = {}

--/////////////////////////Animation Functions///////////////////////
function AfterMidFailAnim()
  DismissTeam(nativesTeamName)
  DismissTeam(princessTeamName)
  EndTurn(true)
end

function AfterMidAnimAlone()
  SetupCourse()
  for i = 5, 8 do
    RestoreHedge(cannibals[i])
    AnimSetGearPosition(cannibals[i], unpack(cannibalPos[i]))
  end

  AddAmmo(cannibals[5], amDEagle, 0)

  AddEvent(CheckOnFirstGirder, {}, DoOnFirstGirder, {}, 0)
  AddEvent(CheckTookSniper, {}, DoTookSniper, {}, 0)
  AddEvent(CheckFailedCourse, {}, DoFailedCourse, {}, 0)
  SetGearMessage(leaks, band(GetGearMessage(leaks), bnot(gmAllStoppable)))
  TurnsLeft = 12
  SetTurnTimeLeft(TurnTime)
  ShowMission(loc("The Journey Back"), loc("Collateral Damage"),
    loc("Save the princess by collecting the crate in under 12 turns!") .. "|" ..
    loc("Mines time: 3 seconds"), 0, 6000)
  -----------------------///////////////------------
end

function SkipEndAnimAlone()
  RestoreHedge(cyborg)
  RestoreHedge(princess)
  AnimSetGearPosition(cyborg, 437, 1700)
  AnimSetGearPosition(princess, 519, 1726)
end

function SkipEndAnimDuo()
  RestoreHedge(cyborg)
  RestoreHedge(princess)
  if princessHidden then
    RestoreHog(princess)
    princessHidden = false
  end
  AnimSetGearPosition(cyborg, 437, 1700)
  AnimSetGearPosition(princess, 519, 1726)
  AnimSetGearPosition(leaks, 763, 1760)
  AnimSetGearPosition(dense, 835, 1519)
  HogTurnLeft(leaks, true)
  HogTurnLeft(dense, true)
end

function AfterEndAnimAlone()
  stage = endStage
  SetGearMessage(dense, band(GetGearMessage(dense), bnot(gmAllStoppable)))
  AnimSwitchHog(leaks)
  SetTurnTimeLeft(MAX_TURN_TIME)
  ShowMission(loc("The Journey Back"), loc("Collateral Damage II"), loc("Save Fell From Heaven!"), 1, 4000)
  AddEvent(CheckLost, {}, DoLost, {}, 0)
  AddEvent(CheckWon, {}, DoWon, {}, 0)
  RemoveEventFunc(CheckFailedCourse)
end

function AfterEndAnimDuo()
  stage = endStage
  SetGearMessage(dense, band(GetGearMessage(dense), bnot(gmAllStoppable)))
  AnimSwitchHog(leaks)
  SetTurnTimeLeft(MAX_TURN_TIME)
  ShowMission(loc("The Journey Back"), loc("Collateral Damage II"), loc("Save Fell From Heaven!"), 1, 4000)
  AddEvent(CheckLost, {}, DoLost, {}, 0)
  AddEvent(CheckWon, {}, DoWon, {}, 0)
end

function SkipMidAnimAlone()
  AnimSetGearPosition(leaks, 2656, 1842)
  AnimSwitchHog(leaks)
  AnimWait(dense, 1)
  AddFunction({func = HideHedge, args = {princess}})
  AddFunction({func = HideHedge, args = {cyborg}})
end

function AfterStartAnim()
  SetGearMessage(leaks, band(GetGearMessage(leaks), bnot(gmAllStoppable)))
  SetTurnTimeLeft(TurnTime)
  local goal = loc("Get the crate on the other side of the island.")
  local hint = loc("Hint: You might want to stay out of sight and take all the crates ...")
  local stuck = loc("If you get stuck, use your Desert Eagle or restart the mission!")
  local conds = loc("Leaks A Lot must survive!")
  if m2DenseDead == 0 then
    conds = loc("Your hogs must survive!")
  end
  ShowMission(loc("The Journey Back"), loc("Adventurous"), goal .. "|" .. hint .. "|" .. stuck .. "|" .. conds, 0, 7000)
end

function SkipStartAnim()
  AnimSwitchHog(leaks)
end

function PlaceCratesDuo()
  SpawnSupplyCrate(3090, 827, amBaseballBat)
  girderCrate1 = SpawnSupplyCrate(2466, 1814, amGirder)
  girderCrate2 = SpawnSupplyCrate(2630, 1278, amGirder)
  SpawnSupplyCrate(2422, 1810, amParachute)
  SpawnSupplyCrate(3157, 1009, amLowGravity)
  sniperCrate = SpawnSupplyCrate(784, 1715, amSniperRifle)
end

function PlaceMinesDuo()
  AddGear(2920, 1448, gtMine, 0, 0, 0, 0)
  AddGear(2985, 1338, gtMine, 0, 0, 0, 0)
  AddGear(3005, 1302, gtMine, 0, 0, 0, 0)
  AddGear(3030, 1270, gtMine, 0, 0, 0, 0)
  AddGear(3046, 1257, gtMine, 0, 0, 0, 0)
  AddGear(2954, 1400, gtMine, 0, 0, 0, 0)
  AddGear(2967, 1385, gtMine, 0, 0, 0, 0)
  AddGear(2849, 1449, gtMine, 0, 0, 0, 0)
  AddGear(2811, 1436, gtMine, 0, 0, 0, 0)
  AddGear(2773, 1411, gtMine, 0, 0, 0, 0)
  AddGear(2732, 1390, gtMine, 0, 0, 0, 0)
  AddGear(2700, 1362, gtMine, 0, 0, 0, 0)
  AddGear(2642, 1321, gtMine, 0, 0, 0, 0)
  AddGear(2172, 1417, gtMine, 0, 0, 0, 0)
  AddGear(2190, 1363, gtMine, 0, 0, 0, 0)
  AddGear(2219, 1332, gtMine, 0, 0, 0, 0)
  AddGear(1201, 1207, gtMine, 0, 0, 0, 0)
  AddGear(1247, 1205, gtMine, 0, 0, 0, 0)
  AddGear(1295, 1212, gtMine, 0, 0, 0, 0)
  AddGear(1356, 1209, gtMine, 0, 0, 0, 0)
  AddGear(1416, 1201, gtMine, 0, 0, 0, 0)
  AddGear(1466, 1201, gtMine, 0, 0, 0, 0)
  AddGear(1678, 1198, gtMine, 0, 0, 0, 0)
  AddGear(1738, 1198, gtMine, 0, 0, 0, 0)
  AddGear(1796, 1198, gtMine, 0, 0, 0, 0)
  AddGear(1637, 1217, gtMine, 0, 0, 0, 0)
  AddGear(1519, 1213, gtMine, 0, 0, 0, 0)
end

function AfterPastFlowerAnim()
  PlaceMinesDuo()
  AddEvent(CheckDensePit, {}, DoDensePit, {}, 0)
  SetGearMessage(dense, band(GetGearMessage(dense), bnot(gmAllStoppable)))
  SetGearMessage(leaks, band(GetGearMessage(leaks), bnot(gmAllStoppable)))
  EndTurn(true)
  ShowMission(loc("The Journey Back"), loc("The Savior"), 
    loc("Get Dense Cloud out of the pit!") .. "|" ..
    loc("Your hogs must survive!") .. "|" ..
    loc("Beware of mines: They explode after 5 seconds."), 1, 5000)
end

function SkipPastFlowerAnim()
  AnimSetGearPosition(dense, 2656, 1842)
  AnimSwitchHog(dense)
  AnimWait(dense, 1)
  AddFunction({func = HideHedge, args = {cyborg}})
end

function AfterOutPitAnim()
  SetupCourseDuo()
  RestoreHedge(cannibals[5])
  AddAmmo(cannibals[5], amDEagle, 0)
  HideHedge(cannibals[5])
  AddEvent(CheckTookFire, {}, DoTookFire, {}, 0)
  SetGearMessage(dense, band(GetGearMessage(dense), bnot(gmAllStoppable)))
  SetGearMessage(leaks, band(GetGearMessage(leaks), bnot(gmAllStoppable)))
  EndTurn(true)
  ShowMission(loc("The Journey Back"), loc("They never learn"),
    loc("Free Dense Cloud and continue the mission!") .. "|" ..
    loc("Collect the weapon crate at the left coast!") .. "|" ..
    loc("Your hogs must survive!") .. "|" ..
    loc("Mines time: 5 seconds"), 1, 5000)
end

function SkipOutPitAnim()
  AnimSetGearPosition(dense, unpack(midDensePosDuo))
  AnimSwitchHog(dense)
  AnimWait(dense, 1)
  AddFunction({func = HideHedge, args = {cyborg}})
end

function RestoreCyborg(x, y, xx, yy)
  RestoreHedge(cyborg)
  RestoreHedge(princess)
  AnimOutOfNowhere(cyborg, x, y)
  AnimOutOfNowhere(princess, xx, yy)
  HogTurnLeft(princess, false)
  return true
end

function RestoreCyborgOnly(x, y)
  RestoreHedge(cyborg)
  SetState(cyborg, 0)
  AnimOutOfNowhere(cyborg, x, y)
  return true
end

function TargetPrincess()
  SetWeapon(amDEagle)
  SetGearMessage(cyborg, gmUp)
  return true
end

function HideCyborg()
  HideHedge(cyborg)
  HideHedge(princess)
end

function HideCyborgOnly()
  HideHedge(cyborg)
end

function SetupKillRoom()
  PlaceGirder(2342, 1814, 2)
  PlaceGirder(2294, 1783, 0)
  PlaceGirder(2245, 1814, 2)
end

function SetupCourseDuo()
  PlaceGirder(1083, 1152, 6)
  PlaceGirder(1087, 1150, 6)
  PlaceGirder(1133, 1155, 0)
  PlaceGirder(1135, 1152, 0)
  PlaceGirder(1135, 1078, 0)
  PlaceGirder(1087, 1016, 2)
  PlaceGirder(1018, 921, 5)
  PlaceGirder(1016, 921, 5)
  PlaceGirder(962, 782, 6)
  PlaceGirder(962, 662, 2)
  PlaceGirder(962, 661, 2)
  PlaceGirder(962, 650, 2)
  PlaceGirder(962, 630, 2)
  PlaceGirder(1033, 649, 0)
  PlaceGirder(952, 650, 0)

  fireCrate = SpawnSupplyCrate(1846, 1100, amFirePunch)
  SpawnSupplyCrate(1900, 1100, amPickHammer)
  SpawnSupplyCrate(950, 674, amDynamite)
  SpawnSupplyCrate(994, 825, amRope)
  SpawnSupplyCrate(570, 1357, amLowGravity)
end

local trackedGears = {}

-- Remove mines and crates for the princess cage scene.
-- Some annoying gears might get in the way for this scene, like a dropped
-- mine, or the crate on the leaf.
function ClearTrashForPrincessCage()
  for gear, _ in pairs(trackedGears) do
    if GetY(gear) > 1600 and GetX(gear) > 1800 and GetX(gear) < 2700 then
      DeleteGear(gear)
    end
  end
end

-- Dump mines in princess cage
function DumpMines(t)
  if not t then
    t = 0
  end
  AddGear(2261, 1835, gtMine, 0, 0, 0, t)
  AddGear(2280, 1831, gtMine, 0, 0, 0, t)
  AddGear(2272, 1809, gtMine, 0, 0, 0, t)
  AddGear(2290, 1815, gtMine, 0, 0, 0, t)
  AddGear(2278, 1815, gtMine, 0, 0, 0, t)
  AddGear(2307, 1811, gtMine, 0, 0, 0, t)
  AddGear(2286, 1820, gtMine, 0, 0, 0, t)
  AddGear(2309, 1813, gtMine, 0, 0, 0, t)
  AddGear(2303, 1822, gtMine, 0, 0, 0, t)
  AddGear(2317, 1827, gtMine, 0, 0, 0, t)
  AddGear(2312, 1816, gtMine, 0, 0, 0, t)
  AddGear(2316, 1812, gtMine, 0, 0, 0, t)
  AddGear(2307, 1802, gtMine, 0, 0, 0, t)
  AddGear(2276, 1818, gtMine, 0, 0, 0, t)
  AddGear(2284, 1816, gtMine, 0, 0, 0, t)
  AddGear(2292, 1811, gtMine, 0, 0, 0, t)
  AddGear(2295, 1814, gtMine, 0, 0, 0, t)
  AddGear(2306, 1811, gtMine, 0, 0, 0, t)
  AddGear(2292, 1815, gtMine, 0, 0, 0, t)
  AddGear(2314, 1815, gtMine, 0, 0, 0, t)
  AddGear(2286, 1813, gtMine, 0, 0, 0, t)
  AddGear(2275, 1813, gtMine, 0, 0, 0, t)
  AddGear(2269, 1814, gtMine, 0, 0, 0, t)
  AddGear(2273, 1812, gtMine, 0, 0, 0, t)
  AddGear(2300, 1808, gtMine, 0, 0, 0, t)
  AddGear(2322, 1812, gtMine, 0, 0, 0, t)
  AddGear(2323, 1813, gtMine, 0, 0, 0, t)
  AddGear(2311, 1811, gtMine, 0, 0, 0, t)
  AddGear(2303, 1809, gtMine, 0, 0, 0, t)
  AddGear(2287, 1808, gtMine, 0, 0, 0, t)
  AddGear(2282, 1808, gtMine, 0, 0, 0, t)
  AddGear(2277, 1809, gtMine, 0, 0, 0, t)
  AddGear(2296, 1809, gtMine, 0, 0, 0, t)
  AddGear(2314, 1818, gtMine, 0, 0, 0, t)
end

function SetupAnimRefusedDied()
  SetupAnimAcceptedDied()
  table.insert(startAnim, {func = AnimSay, args = {leaks, loc("I just wonder where Ramon and Spiky disappeared..."), SAY_THINK, 6000}})
end

function SetupAnimAttacked()
  SetupAnimAcceptedDied()
  startAnim = {}
  table.insert(startAnim, {func = AnimWait, args = {leaks, 3000}})
  table.insert(startAnim, {func = AnimTurn, args = {leaks, "Left"}})
  table.insert(startAnim, {func = AnimSay, args = {leaks, loc("I wonder where Dense Cloud is..."), SAY_THINK, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {leaks, loc("He must be in the village already."), SAY_THINK, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {leaks, loc("I'd better get going myself."), SAY_THINK, 4000}})

  midAnim = {}
  table.insert(midAnim, {func = AnimWait, args = {leaks, 500}})
  table.insert(midAnim, {func = AnimCustomFunction, swh = false, args = {leaks, RestoreCyborg, {1300, 1200, 1390, 1200}}})
  table.insert(midAnim, {func = AnimSwitchHog, args = {cyborg}})
  table.insert(midAnim, {func = AnimCustomFunction, args = {cyborg, TargetPrincess, {}}})
  table.insert(midAnim, {func = AnimSay, args = {cyborg, loc("Welcome, Leaks A Lot!"), SAY_SAY, 3000}})
  table.insert(midAnim, {func = AnimSay, args = {cyborg, loc("I want to play a game..."), SAY_SAY, 3000}})
  table.insert(midAnim, {func = AnimSay, args = {princess, loc("Help me, please!"), SAY_SHOUT, 3000}})
  table.insert(midAnim, {func = AnimSay, args = {cyborg, loc("If you can get that crate fast enough, your beloved \"princess\" may go free."), SAY_SAY, 7000}})
  table.insert(midAnim, {func = AnimSay, args = {cyborg, loc("However, if you fail to do so, she dies a most violent death! Muahahaha!"), SAY_SAY, 8000}})
  table.insert(midAnim, {func = AnimSay, args = {cyborg, loc("Good luck...or else!"), SAY_SAY, 4000}})
  table.insert(midAnim, {func = AnimTeleportGear, args = {leaks, 2656, 1842}})
  table.insert(midAnim, {func = AnimCustomFunction, args = {cyborg, HideCyborg, {}}, swh = false})
  table.insert(midAnim, {func = AnimSay, args = {leaks, loc("Hey! This is cheating!"), SAY_SHOUT, 4000}})
  AddSkipFunction(midAnim, SkipMidAnimAlone, {})
end

function SetupAnimAcceptedDied()
  table.insert(startAnimAD, {func = AnimWait, args = {leaks, 3000}})
  table.insert(startAnimAD, {func = AnimTurn, args = {leaks, "Left"}})
  table.insert(startAnimAD, {func = AnimSay, args = {leaks, loc("I need to get to the other side of this island, fast!"), SAY_THINK, 5000}})
  table.insert(startAnimAD, {func = AnimSay, args = {leaks, loc("With Dense Cloud on the land of shadows, I'm the village's only hope..."), SAY_THINK, 7000}})

  table.insert(midAnimAD, {func = AnimWait, args = {leaks, 500}})
  table.insert(midAnimAD, {func = AnimCustomFunction, swh = false, args = {leaks, RestoreCyborg, {1300, 1200, 1390, 1200}}})
  table.insert(midAnimAD, {func = AnimSwitchHog, args = {cyborg}})
  table.insert(midAnimAD, {func = AnimCustomFunction, args = {cyborg, TargetPrincess, {}}})
  table.insert(midAnimAD, {func = AnimSay, args = {cyborg, loc("Welcome, Leaks A Lot!"), SAY_SAY, 3000}})
  table.insert(midAnimAD, {func = AnimSay, args = {cyborg, loc("I want to play a game..."), SAY_SAY, 3000}})
  table.insert(midAnimAD, {func = AnimSay, args = {princess, loc("Help me, please!"), SAY_SHOUT, 3000}})
  table.insert(midAnimAD, {func = AnimSay, args = {cyborg, loc("If you can get that crate fast enough, your beloved \"princess\" may go free."), SAY_SAY, 7000}})
  table.insert(midAnimAD, {func = AnimSay, args = {cyborg, loc("However, if you fail to do so, she dies a most violent death, just like your friend! Muahahaha!"), SAY_SAY, 8000}})
  table.insert(midAnimAD, {func = AnimSay, args = {cyborg, loc("Good luck...or else!"), SAY_SAY, 4000}})
  table.insert(midAnimAD, {func = AnimTeleportGear, args = {leaks, 2656, 1842}})
  table.insert(midAnimAD, {func = AnimCustomFunction, args = {cyborg, HideCyborg, {}}, swh = false})
  table.insert(midAnimAD, {func = AnimSay, args = {leaks, loc("Hey! This is cheating!"), SAY_SHOUT, 4000}})
  AddSkipFunction(midAnimAD, SkipMidAnimAlone, {})

  table.insert(failAnimAD, {func = AnimCustomFunction, args = {cyborg, ClearTrashForPrincessCage, {}}})
  table.insert(failAnimAD, {func = AnimCustomFunction, swh = false, args = {leaks, RestoreCyborg, {2299, 1687, 2294, 1841}}})
  table.insert(failAnimAD, {func = AnimTeleportGear, args = {leaks, 2090, 1841}})
  table.insert(failAnimAD, {func = AnimCustomFunction, swh = false, args = {cyborg, SetupKillRoom, {}}})
  table.insert(failAnimAD, {func = AnimTurn, swh = false, args = {cyborg, "Left"}})
  table.insert(failAnimAD, {func = AnimTurn, swh = false, args = {princess, "Left"}})
  table.insert(failAnimAD, {func = AnimTurn, swh = false, args = {leaks, "Right"}})
  table.insert(failAnimAD, {func = AnimWait, args = {cyborg, 1000}})
  table.insert(failAnimAD, {func = AnimSay, args = {cyborg, loc("You have failed to complete your task, young one!"), SAY_SAY, 6000}})
  table.insert(failAnimAD, {func = AnimSay, args = {cyborg, loc("It's time you learned that your actions have consequences!"), SAY_SAY, 7000}})
  table.insert(failAnimAD, {func = AnimSay, args = {princess, loc("No! Please, help me!"), SAY_SAY, 4000}})
  table.insert(failAnimAD, {func = AnimSwitchHog, args = {cyborg}})
  table.insert(failAnimAD, {func = AnimCustomFunction, args = {cyborg, DumpMines, {}}})
  table.insert(failAnimAD, {func = AnimCustomFunction, args = {cyborg, KillPrincess, {}}})
  table.insert(failAnimAD, {func = AnimWait, args = {cyborg, 500}})
  table.insert(failAnimAD, {func = AnimSay, args = {leaks, loc("No! What have I done?! What have YOU done?!"), SAY_SHOUT, 3000}})
  table.insert(failAnimAD, {func = AnimSwitchHog, args = {princess}})
  AddSkipFunction(failAnimAD, SkipFailAnimAlone, {})

  table.insert(endAnimAD, {func = AnimCustomFunction, swh = false, args = {leaks, RestoreCyborg, {437, 1700, 519, 1726}}})
  table.insert(endAnimAD, {func = AnimTurn, swh = false, args = {cyborg, "Right"}})
  table.insert(endAnimAD, {func = AnimTurn, swh = false, args = {princess, "Right"}})
  table.insert(endAnimAD, {func = AnimSay, args = {princess, loc("Help me, Leaks!"), SAY_SHOUT, 3000}})
  table.insert(endAnimAD, {func = AnimSay, args = {leaks, loc("But you said you'd let her go!"), SAY_SHOUT, 5000}})
  table.insert(endAnimAD, {func = AnimSay, args = {cyborg, loc("And you believed me? Oh, god, that's cute!"), SAY_SHOUT, 7000}})
  table.insert(endAnimAD, {func = AnimSay, args = {leaks, loc("I won't let you kill her!"), SAY_SHOUT, 4000}})
  AddSkipFunction(endAnimAD, SkipEndAnimAlone, {})
  
  table.insert(endFailAnim, {func = AnimCaption, args = {leaks, loc("Leaks A Lot, depressed for killing his loved one, failed to save the village..."), 3000}})

  table.insert(winAnimAD, {func = AnimCustomFunction, args = {princess, CondNeedToTurn, {leaks, princess}}})
  table.insert(winAnimAD, {func = AnimSay, args = {princess, loc("Thank you, oh, thank you, Leaks A Lot!"), SAY_SAY, 5000}})
  table.insert(winAnimAD, {func = AnimSay, args = {princess, loc("How can I ever repay you for saving my life?"), SAY_SAY, 6000}})
  table.insert(winAnimAD, {func = AnimSay, args = {leaks, loc("There's nothing more satisfying for me than seeing you share your beauty with the world every morning, my princess!"), SAY_SAY, 10000}})
  table.insert(winAnimAD, {func = AnimSay, args = {leaks, loc("Let's go home!"), SAY_SAY, 3000}})
  table.insert(winAnimAD, {func = AnimCaption, args = {leaks, loc("And so they discovered that cyborgs weren't invulnerable..."), 2000}})

  startAnim = startAnimAD
  midAnim = midAnimAD
  failAnim = failAnimAD
  endAnim = endAnimAD
  winAnim = winAnimAD
end

function SetupAnimAcceptedLived()
  table.insert(startAnimAL, {func = AnimWait, args = {leaks, 3000}})
  table.insert(startAnimAL, {func = AnimCustomFunction, args = {dense, CondNeedToTurn, {leaks, dense}}})
  table.insert(startAnimAL, {func = AnimSay, args = {leaks, loc("All right, we just need to get to the other side of the island!"), SAY_SAY, 8000}})
  table.insert(startAnimAL, {func = AnimSay, args = {dense, loc("We have no time to waste..."), SAY_SAY, 4000}})
  table.insert(startAnimAL, {func = AnimSwitchHog, args = {leaks}})
  AddSkipFunction(startAnimAL, SkipStartAnim, {})

  table.insert(pastFlowerAnimAL, {func = AnimCustomFunction, args = {dense, RestoreCyborgOnly, {unpack(startCyborgPosDuo)}}, swh = false})
  table.insert(pastFlowerAnimAL, {func = AnimTurn, args = {cyborg, "Right"}})
  table.insert(pastFlowerAnimAL, {func = AnimSay, args = {cyborg, loc("Well, well! Isn't that the cutest thing you've ever seen?"), SAY_SAY, 7000}})
  table.insert(pastFlowerAnimAL, {func = AnimSay, args = {cyborg, loc("Two little hogs cooperating, getting past obstacles..."), SAY_SAY, 7000}})
  table.insert(pastFlowerAnimAL, {func = AnimSay, args = {cyborg, loc("Let me test your skills a little, will you?"), SAY_SAY, 6000}})
  table.insert(pastFlowerAnimAL, {func = AnimTeleportGear, args = {cyborg, 2456, 1842}})
  table.insert(pastFlowerAnimAL, {func = AnimTeleportGear, args = {dense, 2656, 1842}})
  table.insert(pastFlowerAnimAL, {func = AnimCustomFunction, args = {dense, CondNeedToTurn, {cyborg, dense}}})
  table.insert(pastFlowerAnimAL, {func = AnimSay, args = {dense, loc("Why are you doing this?"), SAY_SAY, 4000}})
  table.insert(pastFlowerAnimAL, {func = AnimSay, args = {cyborg, loc("To help you, of course!"), SAY_SAY, 4000}})
  table.insert(pastFlowerAnimAL, {func = AnimSwitchHog, args = {dense}})
  table.insert(pastFlowerAnimAL, {func = AnimDisappear, swh = false, args = {cyborg, 3781, 1583}})
  table.insert(pastFlowerAnimAL, {func = AnimCustomFunction, swh = false, args = {cyborg, HideCyborgOnly, {}}})
  AddSkipFunction(pastFlowerAnimAL, SkipPastFlowerAnim, {})

  table.insert(outPitAnimAL, {func = AnimCustomFunction, args = {dense, RestoreCyborgOnly, {unpack(midCyborgPosDuo)}}, swh = false})
  table.insert(outPitAnimAL, {func = AnimTurn, args = {cyborg, "Right"}})
  table.insert(outPitAnimAL, {func = AnimTeleportGear, args = {dense, unpack(midDensePosDuo)}})
  table.insert(outPitAnimAL, {func = AnimTurn, args = {dense, "Left"}})
  table.insert(outPitAnimAL, {func = AnimSay, args = {dense, loc("OH, COME ON!"), SAY_SHOUT, 3000}})
  table.insert(outPitAnimAL, {func = AnimSay, args = {cyborg, loc("Let's see what your comrade does now!"), SAY_SAY, 5000}})
  table.insert(outPitAnimAL, {func = AnimSwitchHog, args = {dense}})
  table.insert(outPitAnimAL, {func = AnimDisappear, swh = false, args = {cyborg, 3781, 1583}})
  table.insert(outPitAnimAL, {func = AnimCustomFunction, swh = false, args = {cyborg, HideCyborgOnly, {}}})
  AddSkipFunction(outPitAnimAL, SkipOutPitAnim, {})

  table.insert(endAnim, {func = AnimCustomFunction, swh = false, args = {leaks, RestoreCyborg, {437, 1700, 519, 1726}}})
  table.insert(endAnim, {func = AnimTeleportGear, args = {leaks, 763, 1760}})
  table.insert(endAnim, {func = AnimTeleportGear, args = {dense, 835, 1519}})
  table.insert(endAnim, {func = AnimTurn, swh = false, args = {leaks, "Left"}})
  table.insert(endAnim, {func = AnimTurn, swh = false, args = {dense, "Left"}})
  table.insert(endAnim, {func = AnimTurn, swh = false, args = {cyborg, "Right"}})
  table.insert(endAnim, {func = AnimTurn, swh = false, args = {princess, "Right"}})
  table.insert(endAnim, {func = AnimSay, args = {princess, loc("Help me, please!"), SAY_SHOUT, 3000}})
  table.insert(endAnim, {func = AnimSay, args = {leaks, loc("What are you doing? Let her go!"), SAY_SHOUT, 5000}})
  table.insert(endAnim, {func = AnimSay, args = {cyborg, loc("Yeah? Watcha gonna do? Cry?"), SAY_SHOUT, 5000}})
  table.insert(endAnim, {func = AnimSay, args = {leaks, loc("We won't let you hurt her!"), SAY_SHOUT, 4000}})
  AddSkipFunction(endAnim, SkipEndAnimDuo, {})
  
  table.insert(endFailAnim, {func = AnimCaption, args = {leaks, loc("Leaks A Lot, depressed for killing his loved one, failed to save the village..."), 3000}})

  table.insert(winAnim, {func = AnimCustomFunction, args = {princess, CondNeedToTurn, {leaks, princess}}})
  table.insert(winAnim, {func = AnimSay, args = {princess, loc("Thank you, oh, thank you, my heroes!"), SAY_SAY, 5000}})
  table.insert(winAnim, {func = AnimSay, args = {princess, loc("How can I ever repay you for saving my life?"), SAY_SAY, 6000}})
  table.insert(winAnim, {func = AnimSay, args = {leaks, loc("There's nothing more satisfying to us than seeing you share your beauty..."), SAY_SAY, 7000}})
  table.insert(winAnim, {func = AnimSay, args = {leaks, loc("... share your beauty with the world every morning, my princess!"), SAY_SAY, 7000}})
  table.insert(winAnim, {func = AnimSay, args = {leaks, loc("Let's go home!"), SAY_SAY, 3000}})
  table.insert(winAnim, {func = AnimCaption, args = {leaks, loc("And so they discovered that cyborgs weren't invulnerable..."), 2000}})

  startAnim = startAnimAL
  pastFlowerAnim = pastFlowerAnimAL
  outPitAnim = outPitAnimAL
end

function SetupAnimRefusedLived()
  table.insert(startAnimRL, {func = AnimWait, args = {leaks, 3000}})
  table.insert(startAnimRL, {func = AnimCustomFunction, args = {dense, CondNeedToTurn, {leaks, dense}}})
  table.insert(startAnimRL, {func = AnimSay, args = {leaks, loc("All right, we just need to get to the other side of the island!"), SAY_SAY, 7000}})
  table.insert(startAnimRL, {func = AnimSay, args = {dense, loc("Dude, can you see Ramon and Spiky?"), SAY_SAY, 5000}})
  table.insert(startAnimRL, {func = AnimSay, args = {leaks, loc("No...I wonder where they disappeared?!"), SAY_SAY, 5000}})
  AddSkipFunction(startAnimRL, SkipStartAnim, {})

  table.insert(pastFlowerAnimRL, {func = AnimCustomFunction, args = {dense, RestoreCyborgOnly, {unpack(startCyborgPosDuo)}}, swh = false})
  table.insert(pastFlowerAnimRL, {func = AnimTurn, args = {cyborg, "Right"}})
  table.insert(pastFlowerAnimRL, {func = AnimSay, args = {cyborg, loc("Well, well! Isn't that the cutest thing you've ever seen?"), SAY_SAY, 7000}})
  table.insert(pastFlowerAnimRL, {func = AnimSay, args = {cyborg, loc("Two little hogs cooperating, getting past obstacles..."), SAY_SAY, 7000}})
  table.insert(pastFlowerAnimRL, {func = AnimSay, args = {cyborg, loc("Let me test your skills a little, will you?"), SAY_SAY, 6000}})
  table.insert(pastFlowerAnimRL, {func = AnimTeleportGear, args = {cyborg, 2456, 1842}})
  table.insert(pastFlowerAnimRL, {func = AnimTeleportGear, args = {dense, 2656, 1842}})
  table.insert(pastFlowerAnimRL, {func = AnimCustomFunction, args = {dense, CondNeedToTurn, {cyborg, dense}}})
  table.insert(pastFlowerAnimRL, {func = AnimSay, args = {dense, loc("Why are you doing this?"), SAY_SAY, 4000}})
  table.insert(pastFlowerAnimRL, {func = AnimSay, args = {cyborg, loc("You couldn't possibly believe that after refusing my offer I'd just let you go!"), SAY_SAY, 9000}})
  table.insert(pastFlowerAnimRL, {func = AnimSay, args = {cyborg, loc("You're funny!"), SAY_SAY, 4000}})
  table.insert(pastFlowerAnimRL, {func = AnimSwitchHog, args = {dense}})
  table.insert(pastFlowerAnimRL, {func = AnimDisappear, swh = false, args = {cyborg, 3781, 1583}})
  table.insert(pastFlowerAnimRL, {func = AnimCustomFunction, swh = false, args = {cyborg, HideCyborgOnly, {}}})
  AddSkipFunction(pastFlowerAnimRL, SkipPastFlowerAnim, {})

  table.insert(outPitAnimRL, {func = AnimCustomFunction, args = {dense, RestoreCyborgOnly, {unpack(midCyborgPosDuo)}}, swh = false})
  table.insert(outPitAnimRL, {func = AnimTurn, args = {cyborg, "Right"}})
  table.insert(outPitAnimRL, {func = AnimTeleportGear, args = {dense, unpack(midDensePosDuo)}})
  table.insert(outPitAnimRL, {func = AnimTurn, args = {dense, "Left"}})
  table.insert(outPitAnimRL, {func = AnimSay, args = {dense, loc("OH, COME ON!"), SAY_SHOUT, 3000}})
  table.insert(outPitAnimRL, {func = AnimSay, args = {cyborg, loc("Let's see what your comrade does now!"), SAY_SAY, 5000}})
  table.insert(outPitAnimRL, {func = AnimSwitchHog, args = {dense}})
  table.insert(outPitAnimRL, {func = AnimDisappear, swh = false, args = {cyborg, 3781, 1583}})
  table.insert(outPitAnimRL, {func = AnimCustomFunction, swh = false, args = {cyborg, HideCyborgOnly, {}}})
  AddSkipFunction(outPitAnimRL, SkipOutPitAnim, {})

  table.insert(endAnim, {func = AnimCustomFunction, args = {leaks, RestoreCyborg, {437, 1700, 519, 1726}}})
  table.insert(endAnim, {func = AnimTeleportGear, args = {leaks, 763, 1760}})
  table.insert(endAnim, {func = AnimTeleportGear, args = {dense, 835, 1519}})
  table.insert(endAnim, {func = AnimTurn, swh = false, args = {leaks, "Left"}})
  table.insert(endAnim, {func = AnimTurn, swh = false, args = {dense, "Left"}})
  table.insert(endAnim, {func = AnimTurn, swh = false, args = {cyborg, "Right"}})
  table.insert(endAnim, {func = AnimTurn, swh = false, args = {princess, "Right"}})
  table.insert(endAnim, {func = AnimSay, args = {princess, loc("Help me, please!"), SAY_SHOUT, 3000}})
  table.insert(endAnim, {func = AnimSay, args = {leaks, loc("What are you doing? Let her go!"), SAY_SHOUT, 5000}})
  table.insert(endAnim, {func = AnimSay, args = {cyborg, loc("Yeah? Watcha gonna do? Cry?"), SAY_SHOUT, 5000}})
  table.insert(endAnim, {func = AnimSay, args = {leaks, loc("We won't let you hurt her!"), SAY_SHOUT, 4000}})
  AddSkipFunction(endAnim, SkipEndAnimDuo, {})
  
  table.insert(endFailAnim, {func = AnimCaption, args = {leaks, loc("Leaks A Lot, depressed for killing his loved one, failed to save the village..."), 3000}})

  table.insert(winAnim, {func = AnimCustomFunction, args = {princess, CondNeedToTurn, {leaks, princess}}})
  table.insert(winAnim, {func = AnimSay, args = {princess, loc("Thank you, oh, thank you, my heroes!"), SAY_SAY, 5000}})
  table.insert(winAnim, {func = AnimSay, args = {princess, loc("How can I ever repay you for saving my life?"), SAY_SAY, 6000}})
  table.insert(winAnim, {func = AnimSay, args = {leaks, loc("There's nothing more satisfying to us than seeing you share your beauty with the world every morning, my princess!"), SAY_SAY, 10000}})
  table.insert(winAnim, {func = AnimSay, args = {leaks, loc("Let's go home!"), SAY_SAY, 3000}})
  table.insert(winAnim, {func = AnimCaption, args = {leaks, loc("And so they discovered that cyborgs weren't invulnerable..."), 2000}})

  startAnim = startAnimRL
  pastFlowerAnim = pastFlowerAnimRL
  outPitAnim = outPitAnimRL
end

function KillPrincess()
  EndTurn(true)
end
--/////////////////////////////Misc Functions////////////////////////

function HideHedge(hedge)
  if hedgeHidden[hedge] ~= true then
    HideHog(hedge)
    hedgeHidden[hedge] = true
  end
end

function RestoreHedge(hedge)
  if hedgeHidden[hedge] == true then
    RestoreHog(hedge)
    hedgeHidden[hedge] = false
  end
end

function CondNeedToTurn(hog1, hog2)
  xl, xd = GetX(hog1), GetX(hog2)
  if xl > xd then
    AnimInsertStepNext({func = AnimTurn, args = {hog1, "Left"}})
    AnimInsertStepNext({func = AnimTurn, args = {hog2, "Right"}})
  elseif xl < xd then
    AnimInsertStepNext({func = AnimTurn, args = {hog2, "Left"}})
    AnimInsertStepNext({func = AnimTurn, args = {hog1, "Right"}})
  end
end

function SetupPlaceAlone()
  ------ AMMO CRATE LIST ------
  SpawnSupplyCrate(3124, 952, amBaseballBat)
  SpawnSupplyCrate(2508, 1110, amFirePunch)
  ------ UTILITY CRATE LIST ------
  blowCrate = SpawnSupplyCrate(3675, 1480, amBlowTorch)
  gravityCrate = SpawnSupplyCrate(3448, 1349, amLowGravity)
  SpawnSupplyCrate(3212, 1256, amGirder)
  SpawnSupplyCrate(3113, 911, amParachute)
  sniperCrate = SpawnSupplyCrate(784, 1715, amSniperRifle)
  ------ MINE LIST ------
  AddGear(3328, 1399, gtMine, 0, 0, 0, 0)
  AddGear(3028, 1262, gtMine, 0, 0, 0, 0)
  AddGear(2994, 1274, gtMine, 0, 0, 0, 0)
  AddGear(2956, 1277, gtMine, 0, 0, 0, 0)
  AddGear(2925, 1282, gtMine, 0, 0, 0, 0)
  AddGear(2838, 1276, gtMine, 0, 0, 0, 0)
  AddGear(2822, 1278, gtMine, 0, 0, 0, 0)
  AddGear(2786, 1283, gtMine, 0, 0, 0, 0)
  AddGear(2766, 1270, gtMine, 0, 0, 0, 0)
  AddGear(2749, 1231, gtMine, 0, 0, 0, 0)
  AddGear(2717, 1354, gtMine, 0, 0, 0, 0)
  AddGear(2167, 1330, gtMine, 0, 0, 0, 0)
  AddGear(2201, 1321, gtMine, 0, 0, 0, 0)
  AddGear(2239, 1295, gtMine, 0, 0, 0, 0)

  AnimSetGearPosition(leaks, 3781, 1583)
  AddAmmo(cannibals[1], amShotgun, 100)
  AddAmmo(leaks, amSwitch, 0)
end

function SetupPlaceDuo()
  PlaceCratesDuo()
  AnimSetGearPosition(leaks, unpack(startLeaksPosDuo))
  AnimSetGearPosition(dense, unpack(startDensePosDuo))
end

function SetupEventsDuo()
  AddEvent(CheckPastFlower, {}, DoPastFlower, {}, 0)
  AddEvent(CheckLeaksDead, {}, DoLeaksDead, {}, 0)
  AddEvent(CheckDenseDead, {}, DoDenseDead, {}, 0)
  AddEvent(CheckTookSniper2, {}, DoTookSniper2, {}, 0)
end

function SetupEventsAlone()
  AddEvent(CheckLeaksDead, {}, DoLeaksDead, {}, 0)
  AddEvent(CheckTookBlowTorch, {}, DoTookBlowTorch, {}, 0)
  AddEvent(CheckTookLowGravity, {}, DoTookLowGravity, {}, 0)
  AddEvent(CheckOnBridge, {}, DoOnBridge, {}, 0)
end

function StartMission()
  if m2DenseDead == 1 then
    DeleteGear(dense)
    if m2Choice == choiceAccepted then
      SetupAnimAcceptedDied()
    elseif m2Choice == choiceRefused then
      SetupAnimRefusedDied()
    else
      SetupAnimAttacked()
    end
    SetupPlaceAlone()
    SetupEventsAlone()
  else
    if m2Choice == choiceAccepted then
      SetupAnimAcceptedLived()
    else
      SetupAnimRefusedLived()
    end
    SetupPlaceDuo()
    SetupEventsDuo()
  end
  HideHedge(cyborg)
  HideHedge(princess)
  for i = 5, 8 do
    HideHedge(cannibals[i])
  end

end
  
function SetupCourse()

  ------ GIRDER LIST ------
  PlaceGirder(1091, 1150, 6)
  PlaceGirder(1091, 989, 6)
  PlaceGirder(1091, 829, 6)
  PlaceGirder(1091, 669, 6)
  PlaceGirder(1091, 668, 6)
  PlaceGirder(1091, 669, 6)
  PlaceGirder(1088, 667, 6)
  PlaceGirder(1091, 658, 6)
  PlaceGirder(1091, 646, 6)
  PlaceGirder(1091, 607, 6)
  PlaceGirder(1091, 571, 6)
  PlaceGirder(1376, 821, 6)
  PlaceGirder(1145, 1192, 1)
  PlaceGirder(1169, 1076, 3)
  PlaceGirder(1351, 1082, 4)
  PlaceGirder(1469, 987, 3)
  PlaceGirder(1386, 951, 0)
  PlaceGirder(1465, 852, 3)
  PlaceGirder(1630, 913, 0)
  PlaceGirder(1733, 856, 7)
  PlaceGirder(1688, 713, 5)
  PlaceGirder(1556, 696, 2)
  PlaceGirder(1525, 696, 2)
  PlaceGirder(1457, 697, 2)
  PlaceGirder(1413, 700, 3)
  PlaceGirder(1270, 783, 2)
  PlaceGirder(1207, 825, 2)
  PlaceGirder(1135, 775, 1)

  ------ UTILITY CRATE LIST ------
  SpawnSupplyCrate(1590, 628, amParachute)
  SpawnSupplyCrate(1540, 100, amDynamite)
  SpawnSupplyCrate(2175, 1815, amLowGravity)
  SpawnSupplyCrate(2210, 1499, amFirePunch)
  girderCrate = SpawnSupplyCrate(2300, 1663, amGirder)
  SpawnSupplyCrate(610, 1394, amPickHammer)
  
  ------ BARREL LIST ------
  SetHealth(AddGear(1148, 736, gtExplosives, 0, 0, 0, 0), 20)

end

function PlaceCourseMines()
  AddGear(1215, 1193, gtMine, 0, 0, 0, 0)
  AddGear(1259, 1199, gtMine, 0, 0, 0, 0)
  AddGear(1310, 1198, gtMine, 0, 0, 0, 0)
  AddGear(1346, 1196, gtMine, 0, 0, 0, 0)
  AddGear(1383, 1192, gtMine, 0, 0, 0, 0)
  AddGear(1436, 1196, gtMine, 0, 0, 0, 0)
  AddGear(1487, 1199, gtMine, 0, 0, 0, 0)
  AddGear(1651, 1209, gtMine, 0, 0, 0, 0)
  AddGear(1708, 1209, gtMine, 0, 0, 0, 0)
  AddGear(1759, 1190, gtMine, 0, 0, 0, 0)
  AddGear(1815, 1184, gtMine, 0, 0, 0, 0)
end


--////////////////////////////Event Functions////////////////////////
function CheckTookFire()
  return fireTaken
end

function DoTookFire()
  AddAmmo(leaks, amFirePunch, 100)
end

function CheckDensePit()
  if GetHealth(dense) ~= nil then
    return GetY(dense) < 1250 and StoppedGear(dense)
  else
    return false
  end
end

function DoDensePit()
  EndTurn(true)
  RestoreHedge(cyborg)
  AnimWait(cyborg, 1)
  AddFunction({func = AddAnim, args = {outPitAnim}})
  AddFunction({func = AddFunction, args = {{func = AfterOutPitAnim, args = {}}}})
end

function CheckPastFlower()
  if denseDead == true or leaksDead == true then
    return false
  end
  return (GetX(dense) < startEventXDuo and StoppedGear(dense))
      or (GetX(leaks) < startEventXDuo and StoppedGear(leaks))
end

function DoPastFlower()
  EndTurn(true)
  RestoreHedge(cyborg)
  AnimWait(cyborg, 1)
  AddFunction({func = AddAnim, args = {pastFlowerAnim}})
  AddFunction({func = AddFunction, args = {{func = AfterPastFlowerAnim, args = {}}}})
end


function CheckLeaksDead()
  return leaksDead
end

function DoLeaksDead()
  if not princessDead then
    EndTurn(true)
    AddCaption(loc("The village, unprepared, was destroyed by the cyborgs..."))
    DismissTeam(nativesTeamName)
    DismissTeam(princessTeamName)
  end
end

function CheckDenseDead()
  return denseDead
end

function DoDenseDead()
  if not princessDead then
    EndTurn(true)
    AddCaption(loc("The village, unprepared, was destroyed by the cyborgs..."))
    DismissTeam(nativesTeamName)
    DismissTeam(princessTeamName)
  end
end

function CheckTookBlowTorch()
  return blowTaken
end

function DoTookBlowTorch()
  ShowMission(loc("The Journey Back"), loc("The Tunnel Maker"), 
    loc("Get past the flower.").."|"..
    loc("Hint: Select the blow torch, aim and press [Fire]. Press [Fire] again to stop.").."|"..
    loc("Don't blow up the crate."), 0, 6000)
end

function CheckTookLowGravity()
  return gravityTaken
end

function DoTookLowGravity()
  ShowMission(loc("The Journey Back"), loc("The Moonwalk"),
    loc("Hop on top of the next flower and advance to the left coast.").."|"..
    loc("Hint: Select the low gravity and press [Fire].") .. "|" ..
    loc("Beware of mines: They explode after 3 seconds."), 0, 6000)
end

function CheckOnBridge()
  return leaksDead == false and GetX(leaks) < 1651 and StoppedGear(leaks)
end

function DoOnBridge()
  EndTurn(true)
  RestoreHedge(cyborg)
  RestoreHedge(princess)
  AnimWait(cyborg, 1)
  AddFunction({func = AddAnim, args = {midAnim}})
  AddFunction({func = AddFunction, args = {{func = AfterMidAnimAlone, args = {}}}})
end

function CheckOnFirstGirder()
  return leaksDead == false and GetX(leaks) < 1160 and StoppedGear(leaks)
end

function DoOnFirstGirder()
  PlaceCourseMines()
  ShowMission(loc("The Journey Back"), loc("Slippery"), 
    loc("Collect the weapon crate at the left coast!") .. "|" ..
    loc("You'd better watch your steps...") .. "|" ..
    loc("Mines time: 3 seconds"), 0, 4000)
end

function CheckTookSniper()
  return sniperTaken and StoppedGear(leaks)
end

function DoTookSniper()
  EndTurn(true)
  RestoreHedge(cyborg)
  RestoreHedge(princess)
  AnimWait(cyborg, 1)
  AddFunction({func = AddAnim, args = {endAnim}})
  AddFunction({func = AddFunction, args = {{func = AfterEndAnimAlone, args = {}}}})
end

function CheckTookSniper2()
  return sniperTaken and StoppedGear(leaks) and StoppedGear(dense)
end

function DoTookSniper2()
  EndTurn(true)
  RestoreHedge(cyborg)
  RestoreHedge(princess)
  AnimWait(cyborg, 1)
  AddFunction({func = AddAnim, args = {endAnim}})
  AddFunction({func = AddFunction, args = {{func = AfterEndAnimDuo, args = {}}}})
end

function CheckLost()
  return princessDead
end

function DoLost()
  if not cyborgDead then
    SwitchHog(cyborg)
  end
  if not (leaksDead or denseDead) then
    AddAnim(endFailAnim)
  end
  AddFunction({func = DismissTeam, args = {nativesTeamName}})
  AddFunction({func = DismissTeam, args = {princessTeamName}})
  AddFunction({func = EndTurn, args = {true}})
end

function CheckWon()
  return cyborgDead and not princessDead
end

function DoWon()
  victory = true
  if progress and progress<3 then
    SaveCampaignVar("Progress", "3")
  end
  AddAnim(winAnim)
  AddFunction({func = FinishWon, args = {}})
end

function FinishWon()
  SwitchHog(leaks)
  DismissTeam(cannibalsTeamName)
  DismissTeam(cyborgTeamName)
  EndTurn(true)
end

function CheckFailedCourse()
  return TurnsLeft == 0
end

function DoFailedCourse()
  EndTurn(true)
  RestoreHedge(cyborg)
  RestoreHedge(princess)
  AnimWait(cyborg, 1)
  AddFunction({func = AddAnim, args = {failAnim}})
  AddFunction({func = AddFunction, args = {{func = AfterMidFailAnim, args = {}}}})
end

function SkipFailAnimAlone()
  DumpMines(1)
  KillPrincess()
  AnimSwitchHog(princess)
end

--////////////////////////////Main Functions/////////////////////////

function onGameInit()
  progress = tonumber(GetCampaignVar("Progress"))
  m2Choice = tonumber(GetCampaignVar("M2Choice")) or choiceRefused
  m2DenseDead = tonumber(GetCampaignVar("M2DenseDead")) or 0

	Seed = 0
	GameFlags = gfSolidLand + gfDisableWind
	TurnTime = 40000 
	CaseFreq = 0
	MinesNum = 0

	if m2DenseDead == 1 then
		MinesTime = 3000
	else
		MinesTime = 5000
	end
	Explosives = 0
    Map = "A_Classic_Fairytale_journey"
    Theme = "Nature"

    -- Disable Sudden Death
    HealthDecrease = 0
    WaterRise = 0

  AnimInit(true)

  nativesTeamName = AddMissionTeam(-2)
  leaks = AddHog(loc("Leaks A Lot"), 0, 100, "Rambo")
  dense = AddHog(loc("Dense Cloud"), 0, 100, "RobinHood")

  princessTeamName = AddTeam(loc("Princess"), -2, "Bone", "Island", "HillBilly", "cm_female")
  SetTeamPassive(princessTeamName, true)
  princess = AddHog(loc("Fell From Heaven"), 0, 200, "tiara")

  cannibalsTeamName = AddTeam(loc("Cannibal Sentry"), -1, "skull", "Island", "Pirate","cm_vampire")
  cannibals = {}
  for i = 1, 4 do
    cannibals[i] = AddHog(cannibalNames[i], 3, 40, "Zombi")
    AnimSetGearPosition(cannibals[i], unpack(cannibalPos[i]))
    SetEffect(cannibals[i], heArtillery, 1)
  end

  for i = 5, 8 do
    cannibals[i] = AddHog(cannibalNames[i], 3, 40, "Zombi")
    AnimSetGearPosition(cannibals[i], 0, 0)
    SetEffect(cannibals[i], heArtillery, 1)
  end

  cyborgTeamName = AddTeam(loc("011101001"), -1, "ring", "UFO", "Robot", "cm_binary")
  cyborg = AddHog(loc("Y3K1337"), 0, 200, "cyborg1")

  AnimSetGearPosition(dense, 0, 0)
  AnimSetGearPosition(leaks, 0, 0)
  AnimSetGearPosition(cyborg, 0, 0)
  AnimSetGearPosition(princess, 0, 0)
end

function onGameStart()
  StartMission()
end

function onGameTick()
  AnimUnWait()
  if ShowAnimation() == false then
    return
  end
  ExecuteAfterAnimations()
  CheckEvents()
end

-- Track gears for princess cage cleanup
function onGearAdd(gear)
  local gt = GetGearType(gear)
  if gt == gtCase or gt == gtMine then
    trackedGears[gear] = true
  end
end

function onGearDelete(gear)
  if trackedGears[gear] then
    trackedGears[gear] = nil
  end
  if gear == blowCrate then
    blowTaken = true
  elseif gear == fireCrate then
    fireTaken = true
  elseif gear == gravityCrate then
    gravityTaken = true
  elseif gear == leaks and not victory then
    leaksDead = true
  elseif gear == dense and not victory then
    denseDead = true
  elseif gear == cyborg then
    cyborgDead = true
  elseif gear == princess and not victory then
    princessDead = true
  elseif gear == sniperCrate then
    sniperTaken = true
  else
    for i = 1, 4 do
      if gear == cannibals[i] then
        cannibalDead[i] = true
      end
    end
  end
end

function onAmmoStoreInit()
  SetAmmo(amBlowTorch, 0, 0, 0, 1)
  SetAmmo(amParachute, 0, 0, 0, 1)
  SetAmmo(amGirder, 0, 0, 0, 3)
  SetAmmo(amLowGravity, 0, 0, 0, 1)
  SetAmmo(amBaseballBat, 0, 0, 0, 1)
  SetAmmo(amFirePunch, 1, 0, 0, 1)
  SetAmmo(amSkip, 9, 0, 0, 0)
  SetAmmo(amSwitch, 9, 0, 0, 0)
  SetAmmo(amDEagle, 9, 0, 0, 0)
  SetAmmo(amRope, 0, 0, 0, 1)
  SetAmmo(amSniperRifle, 0, 0, 0, 1)
  SetAmmo(amDynamite, 0, 0, 0, 1)
  SetAmmo(amPickHammer, 0, 0, 0, 1)
end

function onNewTurn()
  if not startAnimStarted then
      AddAnim(startAnim)
      AddFunction({func = AfterStartAnim, args = {}})
      startAnimStarted = true
  end
  if AnimInProgress() then
    SetTurnTimeLeft(MAX_TURN_TIME)
  elseif victory then
    EndTurn(true)
  elseif stage == endStage then
    if GetHogTeamName(CurrentHedgehog) == nativesTeamName and CurrentHedgehog ~= leaks then
      AnimSwitchHog(leaks)
      SetTurnTimeLeft(MAX_TURN_TIME)
    else
      SkipTurn()
    end
  elseif GetHogTeamName(CurrentHedgehog) ~= nativesTeamName then
    SetTurnTimeLeft(20000)
  else
    TurnsLeft = TurnsLeft - 1
    if TurnsLeft >= 1 then
      AddCaption(string.format(loc("Turns left: %d"), TurnsLeft), capcolDefault, capgrpGameState)
    end
  end
end

function onPrecise()
  if GameTime > 2500 and AnimInProgress() then
    SetAnimSkip(true)
    return
  end
end

