--[[
A Classic Fairytale: The enemy of my enemy

= SUMMARY =
Simple deathmatch on the Islands map.

= GOAL =
Wipe out the Hedge-cogs and Leader teams

= FLOW CHART =
- Cut scene: startAnim
- Player starts with 3-4 natives and 4 cannibals
- Player plays with 4 natives if m5DeployedNum ~= leaksNum and m8DeployedLeader == 0
- Enemy starts with 5 cyborgs
- TBS
- Goal completed
- Cut scene: finalAnim
> Victory

]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")


--------------------------------------------Constants------------------------------------
choiceAccepted = 1
choiceRefused = 2
choiceAttacked = 3

choiceEliminate = 1
choiceSpare = 2

leaksNum = 1
denseNum = 2
waterNum = 3
buffaloNum = 4
chiefNum = 5
girlNum = 6
wiseNum = 7
ramonNum = 8
spikyNum = 9

denseScene = 1
princessScene = 2
waterScene = 3
cyborgScene = 4

nativeNames = {loc("Leaks A Lot"), loc("Dense Cloud"), loc("Fiery Water"), 
               loc("Raging Buffalo"), loc("Righteous Beard"), loc("Fell From Grace"),
               loc("Wise Oak"), loc("Ramon"), loc("Spiky Cheese")
              }

nativeHats = {"Rambo", "RobinHood", "pirate_jack", "zoo_Bunny", "IndianChief",
              "tiara", "AkuAku", "rasta", "hair_yellow"}

nativePos = {{1259, 120}, {2378, 796}, {424, 1299}, {3322, 260}, {1022, 1550}}
nativeDir = {"Right", "Left", "Right", "Left", "Right"}

cannibalNames = {loc("Honest Lee"), loc("Vegan Jack"), loc("Sirius Lee"),
                 loc("Brutal Lily")}
cannibalPos = {{162, 266}, {2159, 1517}, {3311, 1621}, {1180, 1560}}
cannibalDir = {"Right", "Left", "Left", "Right"}
cannibalsNum = 4

playersDir = {"Right", "Left", "Right", "Left", "Right", "Right", "Left", "Left", "Right"}
playersAntiDir = {"Left", "Right", "Left", "Right", "Left", "Left", "Right", "Right", "Left"}

cyborgNames = {loc("Smith 0.97"), loc("Smith 0.98"), loc("Smith 0.99a"),
               loc("Smith 0.99b"), loc("Smith 0.99f"), loc("Smith 1.0")}
cyborgPos = {{2162, 20}, {2458, 564}, {542, 1133}, {3334, 1427}}
cyborgDir = "Right"
cyborgsNum = 6
cyborgsPos = {{1490, 330}, {1737, 1005}, {2972, 922}, {1341, 1571},
              {751, 543}, {3889, 907}}
cyborgsDir = {"Right", "Right", "Left", "Right", "Right", "Left"}

leaderPos = {3474, 151}
leaderDir = "Left"

cyborgTeamName = nil
nativesTeamName = nil
cannibalsTeamName = nil
hedgecogsTeamName = nil
leaderTeamName = nil

-----------------------------Variables---------------------------------
natives = {}
origNatives = {}

cyborgs = {}
cyborg = nil

cannibals = {}
players = {}
leader = nil

gearDead = {}
hedgeHidden = {}
trackedMines = {}

startAnim = {}
finalAnim = {}
-----------------------------Animations--------------------------------
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

function CondNeedToTurn2(hog1, hog2)
  xl, xd = GetX(hog1), GetX(hog2)
  if xl > xd then
    AnimTurn(hog1, "Left")
    AnimTurn(hog2, "Right")
  elseif xl < xd then
    AnimTurn(hog2, "Left")
    AnimTurn(hog1, "Right")
  end
end

function EmitDenseClouds(dir)
  local dif
  if dir == "Left" then
    dif = 10
  else
    dif = -10
  end
  if dir == nil then
    dx, dy = GetGearVelocity(dense)
    if dx < 0 then 
      dif = 10
    else 
      dif = -10
    end
  end
  AnimInsertStepNext({func = AnimVisualGear, args = {dense, GetX(dense) + dif, GetY(dense) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimVisualGear, args = {dense, GetX(dense) + dif, GetY(dense) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimVisualGear, args = {dense, GetX(dense) + dif, GetY(dense) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimWait, args = {dense, 800}})
  AnimInsertStepNext({func = AnimVisualGear, args = {dense, GetX(dense) + dif, GetY(dense) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimVisualGear, args = {dense, GetX(dense) + dif, GetY(dense) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimWait, args = {dense, 800}})
  AnimInsertStepNext({func = AnimVisualGear, args = {dense, GetX(dense) + dif, GetY(dense) + dif, vgtSteam, 0, true}, swh = false})
end

function RestoreNatives(cgi)
  for i = 1, playersNum do
    RestoreHedge(players[i])
    AnimOutOfNowhere(players[i], GetGearPosition(players[i]))
  end
end

function AnimationSetup()
  SetupCyborgStartAnim()
  SetupPeopleStartAnim()
  SetupEnemyStartAnim()
  AddSkipFunction(startAnim, SkipStartAnim, {})
end

function SetupCyborgStartAnim()
  table.insert(startAnim, {func = AnimWait, args = {cyborg, 3000}})
  table.insert(startAnim, {func = AnimTurn, args = {cyborg, "Left"}})
  table.insert(startAnim, {func = AnimWait, args = {cyborg, 800}})
  table.insert(startAnim, {func = AnimTurn, args = {cyborg, "Right"}})
  table.insert(startAnim, {func = AnimWait, args = {cyborg, 800}})
  table.insert(startAnim, {func = AnimTurn, args = {cyborg, "Left"}})
  table.insert(startAnim, {func = AnimWait, args = {cyborg, 800}})
  table.insert(startAnim, {func = AnimTeleportGear, args = {cyborg, unpack(cyborgPos[2])}})
  table.insert(startAnim, {func = AnimWait, args = {cyborg, 800}})
  table.insert(startAnim, {func = AnimTurn, args = {cyborg, "Right"}})
  table.insert(startAnim, {func = AnimWait, args = {cyborg, 800}})
  table.insert(startAnim, {func = AnimTurn, args = {cyborg, "Left"}})
  table.insert(startAnim, {func = AnimWait, args = {cyborg, 800}})
  table.insert(startAnim, {func = AnimTeleportGear, args = {cyborg, unpack(cyborgPos[3])}})
  table.insert(startAnim, {func = AnimWait, args = {cyborg, 1800}})
  table.insert(startAnim, {func = AnimTeleportGear, args = {cyborg, unpack(cyborgPos[4])}})
  table.insert(startAnim, {func = AnimWait, args = {cyborg, 800}})
  table.insert(startAnim, {func = AnimSay, args = {cyborg, loc("Everything looks OK..."), SAY_THINK, 2500}})
  table.insert(startAnim, {func = AnimSay, args = {cyborg, loc("This will be fun!"), SAY_THINK, 2500}})
  table.insert(startAnim, {func = AnimJump, args = {cyborg, "high"}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {cyborg, RestoreNatives, {true}}})
  table.insert(startAnim, {func = AnimSay, args = {cyborg, loc("HAHA!"), SAY_SHOUT, 2000}})
  table.insert(startAnim, {func = AnimSwitchHog, args = {players[1]}})
  table.insert(startAnim, {func = AnimDisappear, swh = false, args = {cyborg, unpack(cyborgPos[4])}})
  table.insert(startAnim, {func = HideHedge, swh = false, args = {cyborg}})
end

function SetupPeopleStartAnim()
  for i = 1, playersNum do
    table.insert(startAnim, {func = AnimTurn, swh = false, args = {players[i], playersAntiDir[i]}})
  end
  table.insert(startAnim, {func = AnimWait, args = {players[1], 800}})
  for i = 1, playersNum do
    table.insert(startAnim, {func = AnimTurn, swh = false, args = {players[i], playersDir[i]}})
  end
  table.insert(startAnim, {func = AnimWait, args = {players[1], 800}})
  table.insert(startAnim, {func = AnimSay, args = {players[1], loc("What is this place?"), SAY_SHOUT, 2500}})
  if m5LeaksDead == 1 then
    table.insert(startAnim, {func = AnimSay, args = {players[1], loc("And how am I alive?!"), SAY_SAY, 3000}})
  end
  local playerTalker
  -- There are 3 or 4 natives in this mission. The last one takes part in the dialog
  if nativesNum >= 4 then
     playerTalker = players[4]
  else
     playerTalker = players[3]
  end
  table.insert(startAnim, {func = AnimCustomFunction, args = {players[1], CondNeedToTurn, {players[1], players[2]}}})
  table.insert(startAnim, {func = AnimSay, args = {players[2], loc("It must be the cyborgs again!"), SAY_SAY, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {players[3], loc("Looks like the whole world is falling apart!"), SAY_SAY, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {cannibals[1], loc("Look out! We're surrounded by cannibals!"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {playerTalker, CondNeedToTurn, {playerTalker, cannibals[1]}}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {playerTalker, CondNeedToTurn, {players[1], cannibals[1]}}})
  table.insert(startAnim, {func = AnimSay, args = {playerTalker, loc("Cannibals?! You're the cannibals!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {cannibals[1], loc("WHAT?! You're the ones attacking us!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {playerTalker, loc("You have kidnapped our whole tribe!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {players[1], loc("You've been assaulting us, we have been just defending ourselves!"), SAY_SHOUT, 8000}})
  table.insert(startAnim, {func = AnimSay, args = {cannibals[1], loc("I can't believe this!"), SAY_SHOUT, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {cannibals[1], loc("Have we ever attacked you first?"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {playerTalker, loc("Yes!"), SAY_SHOUT, 2000}})
  table.insert(startAnim, {func = AnimSay, args = {cannibals[1], loc("When?"), SAY_SHOUT, 2000}})
  table.insert(startAnim, {func = AnimSay, args = {playerTalker, loc("Uhmm...ok no."), SAY_SHOUT, 2000}})
  table.insert(startAnim, {func = AnimSay, args = {players[1], loc("But you're cannibals. It's what you do."), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {cannibals[1], loc("Again with the 'cannibals' thing!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {cannibals[1], loc("Where do you get that?!"), SAY_SHOUT, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {playerTalker, loc("Everyone knows this."), SAY_SHOUT, 2500}})
  table.insert(startAnim, {func = AnimSay, args = {players[1], loc("I didn't until about a month ago."), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {playerTalker, loc("Hmmm...actually...I didn't either."), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {cannibals[1], loc("About a month ago, a cyborg came and told us that you're the cannibals!"), SAY_SHOUT, 8000}})
  table.insert(startAnim, {func = AnimSay, args = {players[1], loc("A cy-what?"), SAY_SHOUT, 2000}})
  table.insert(startAnim, {func = AnimSay, args = {cannibals[1], loc("Cyborg. It's what the aliens call themselves."), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {cannibals[1], loc("They told us to wear these clothes. They said that this is the newest trend."), SAY_SHOUT, 8000}})
  table.insert(startAnim, {func = AnimSay, args = {players[1], loc("They've been manipulating us all this time!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {cannibals[1], loc("They must be trying to weaken us!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {players[1], loc("We have to unite and defeat those cylergs!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {cannibals[1], loc("We can't let them take over our little island!"), SAY_SHOUT, 5000}})
end

function RestoreCyborgs(cgi)
  if cyborgsRestored == true then
    return
  end
  for i = 1, cyborgsNum do
    RestoreHedge(cyborgs[i])
    if cgi == true then
      AnimOutOfNowhere(cyborgs[i], unpack(cyborgsPos[i]))
    end
  end
  RestoreHedge(leader)
  AnimOutOfNowhere(leader, unpack(leaderPos))
  cyborgsRestored = true
end

function SetupEnemyStartAnim()
  local gear
  table.insert(startAnim, {func = AnimCustomFunction, args = {cannibals[1], RestoreCyborgs, {true}}})
  if m8EnemyFled == 1 then
    gear = leader
  else
    gear = cyborgs[2]
  end
  local turnPlayer
  if nativesNum >= 4 then
    turnPlayer = players[4]
  else
    turnPlayer = players[3]
  end
  table.insert(startAnim, {func = AnimCustomFunction, args = {players[1], CondNeedToTurn, {turnPlayer, gear}}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {players[1], CondNeedToTurn, {players[1], gear}}})
  table.insert(startAnim, {func = AnimSay, args = {gear, loc("You have finally figured it out!"), SAY_SHOUT, 4500}})
  table.insert(startAnim, {func = AnimSay, args = {gear, loc("You meatbags are pretty slow, you know!"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {players[1], loc("Why do you want to take over our island?"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {gear, loc("Do you have any idea how valuable grass is?"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {gear, loc("This island is the only place left on Earth with grass on it!"), SAY_SHOUT, 7000}})
  table.insert(startAnim, {func = AnimSay, args = {gear, loc("It's worth more than wood!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {gear, loc("That makes it almost invaluable!"), SAY_SHOUT, 4500}})
  table.insert(startAnim, {func = AnimSay, args = {players[1], loc("We have nowhere else to live!"), SAY_SHOUT, 4500}})
  table.insert(startAnim, {func = AnimSay, args = {gear, loc("That's not our problem!"), SAY_SHOUT, 4500}})
  table.insert(startAnim, {func = AnimSay, args = {players[1], loc("We'll give you a problem then!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSwitchHog, args = {gear}})
end

function SetupFinalAnim()
  finalAnim = {
    {func = AnimGearWait, args = {cyborg, 1000}},
    {func = AnimSay, args = {cyborg, loc("Nicely done, meatbags!"), SAY_SAY, 3000}},
    {func = AnimSay, args = {cyborg, loc("You have won the game by proving true cooperative skills!"), SAY_SAY, 7000}},
    {func = AnimSay, args = {cyborg, loc("You have proven yourselves worthy!"), SAY_SAY, 4000}},
    {func = AnimSay, args = {players[1], loc("Game? Was this a game to you?!"), SAY_SAY, 4000}},
    {func = AnimSay, args = {cyborg, loc("Well, yes. This was a cyborg television show."), SAY_SAY, 5500}},
    {func = AnimSay, args = {cyborg, loc("It is called 'Hogs of Steel'."), SAY_SAY, 4000}},
    {func = AnimSay, args = {players[1], loc("Are you saying that many of us have died for your entertainment?"), SAY_SAY, 8000}},
    {func = AnimSay, args = {players[1], loc("Our tribe, our beautiful island!"), SAY_SAY, 4000}},
    {func = AnimSay, args = {players[1], loc("All gone...everything!"), SAY_SAY, 3000}},
    {func = AnimSay, args = {cyborg, loc("But the ones alive are stronger in their heart!"), SAY_SAY, 6000}},
    {func = AnimSay, args = {cyborg, loc("Just kidding, none of you have died!"), SAY_SAY, 5000}},
    {func = AnimSay, args = {cyborg, loc("I mean, none of you ceased to live."), SAY_SAY, 5000}},
    {func = AnimSay, args = {cyborg, loc("You'll see what I mean!"), SAY_SAY, 4000}},
    {func = AnimSay, args = {cyborg, loc("They are all waiting back in the village, haha."), SAY_SAY, 7000}},
    {func = AnimSay, args = {players[1], loc("You are playing with our lives here!"), SAY_SAY, 6000}},
    {func = AnimSay, args = {players[1], loc("Do you think you're some kind of god?"), SAY_SAY, 6000}},
    {func = AnimSay, args = {cyborg, loc("Interesting idea, haha!"), SAY_SAY, 2000}},
    {func = AnimSwitchHog, args = {players[1]}},
    {func = AnimWait, args = {players[1], 1}},
    {func = AnimDisappear, swh = false, args = {cyborg, unpack(cyborgPos[4])}},
    {func = HideHedge, swh = false, args = {cyborg}},
    {func = AnimSay, args = {players[1], loc("What a douche!"), SAY_SAY, 2000}},
  }
end
--------------------------Anim skip functions--------------------------
function SkipStartAnim()
  RestoreNatives()
  RestoreCyborgs()
  SetGearMessage(CurrentHedgehog, 0)
  AnimSwitchHog(cyborgs[1])
  AnimWait(cyborg, 1)
  AddFunction({func = HideHedge, args = {cyborg}})
end

function AfterStartAnim()
  ShowMission(loc("The Enemy Of My Enemy"), loc("The Union"), loc("Defeat the cyborgs!"), 1, 0)
  PutWeaponCrates()
  PutHealthCrates()
  EndTurn(true)
end

function PutHealthCrates()
  for i = 1, 10 do
    SpawnHealthCrate(0, 0)
  end
end

function PutWeaponCrates()
  SpawnSupplyCrate(2399, 622, amNapalm, 2)
  SpawnSupplyCrate(2199, -18, amBee, 2)
  SpawnSupplyCrate(2088, 430, amBee, 2)
  SpawnSupplyCrate(237, 20, amMortar, 4)
  SpawnSupplyCrate(312, 1107, amMolotov, 3)
  SpawnSupplyCrate(531, 1123, amWatermelon, 2)
  SpawnSupplyCrate(1253, 1444, amFlamethrower, 5)
  SpawnSupplyCrate(994, 1364, amBaseballBat, 3)
  SpawnSupplyCrate(1104, 1553, amMine, 6)
  SpawnSupplyCrate(2277, 803, amDynamite, 2)
  SpawnSupplyCrate(1106, 184, amRCPlane, 3)
  SpawnSupplyCrate(1333, 28, amSMine, 4)
  SpawnSupplyCrate(90, 279, amAirAttack, 2)
  SpawnSupplyCrate(288, 269, amBee, 2)
  SpawnSupplyCrate(818, 1633, amBaseballBat, 2)
end
-----------------------------Events------------------------------------
function CheckNativesDead()
  return nativesLeft == 0
end

function CheckCannibalsDead()
  return cannibalsLeft == 0
end

function CheckPlayersDead()
  return playersLeft == 0
end

function CheckCyborgsDead()
  return (cyborgsLeft == 0 and (leader == nil or gearDead[leader] == true))
end

function DoNativesDead()
  nativesDeadFresh = true
  EndTurn(true)
end

function DoCannibalsDead()
  cannibalsDeadFresh = true
  EndTurn(true)
end

function DoPlayersDead()
  RemoveEventFunc(CheckNativesDead)
  RemoveEventFunc(CheckCannibalsDead)
  RemoveEventFunc(CheckCyborgsDead)
  playersDeadFresh = true
  EndTurn(true)
end

function DoCyborgsDead()
--  RemoveEventFunc(CheckNativesDead)
--  RemoveEventFunc(CheckCannibalsDead)
  cyborgsDeadFresh= true
  EndTurn(true)
end

function CheckGearsDead(gearList)
  for i = 1, # gearList do
    if gearDead[gearList[i]] ~= true then
      return false
    end
  end
  return true
end

function CheckGearDead(gear)
  return gearDead[gear]
end

function FailedMission()
  RestoreHedge(cyborg)
  AnimOutOfNowhere(cyborg, unpack(cyborgPos[1]))
  ClearMinesAroundCyborg()
  if CheckCyborgsDead() then
    AnimSay(cyborg, loc("Hmmm...it's a draw. How unfortunate!"), SAY_THINK, 6000)
  elseif leader ~= nil then
    CondNeedToTurn2(cyborg, leader)
    AddAnim({{func = AnimSay, args = {leader, loc("Yay, we won!"), SAY_SAY, 2000}},
             {func = AnimSay, args = {cyborg, loc("Nice work!"), SAY_SAY, 2000}}})
  else
    CondNeedToTurn2(cyborg, cyborgs[1])
    AddAnim({{func = AnimSay, args = {cyborgs[1], loc("Yay, we won!"), SAY_SAY, 2000}},
             {func = AnimSay, args = {cyborg, loc("Nice work!"), SAY_SAY, 2000}}})
  end
  AddFunction({func = LoseMission, args = {}})
end

function LoseMission()
  DismissTeam(nativesTeamName)
  DismissTeam(cannibalsTeamName)
  DismissTeam(cyborgTeamName)
  EndTurn(true)
end

function WonMission()
  RestoreHedge(cyborg)
  CondNeedToTurn2(cyborg, players[1])
  SetupFinalAnim()
  ClearMinesAroundCyborg()
  AddAnim(finalAnim)
  AddFunction({func = WinMission, args = {}})
end

function WinMission()
  if progress and progress<9 then
    SaveCampaignVar("Progress", "9")
  end
  DismissTeam(cyborgTeamName)
  EndTurn(true)
end
-----------------------------Misc--------------------------------------
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

function ClearMinesAroundCyborg()
  if GetHealth(cyborg) then
    local vaporized = 0
    for mine, _ in pairs(trackedMines) do
       if GetHealth(mine) and GetHealth(cyborg) and gearIsInBox(mine, GetX(cyborg) - 50, GetY(cyborg) - 50, 100, 100) == true then
          AddVisualGear(GetX(mine), GetY(mine), vgtSmoke, 0, false)
          DeleteGear(mine)
          vaporized = vaporized + 1
       end
    end
    if vaporized > 0 then
       PlaySound(sndVaporize)
    end
  end
end

function GetVariables()
  progress = tonumber(GetCampaignVar("Progress"))
  m5DeployedNum = tonumber(GetCampaignVar("M5DeployedNum")) or leaksNum
  m2Choice = tonumber(GetCampaignVar("M2Choice")) or choiceRefused
  m5Choice = tonumber(GetCampaignVar("M5Choice")) or choiceEliminate
  m5LeaksDead = tonumber(GetCampaignVar("M5LeaksDead")) or 0
  m8DeployedLeader = tonumber(GetCampaignVar("M8DeployedLeader")) or 0
  m8PrincessLeader = tonumber(GetCampaignVar("M8PrincessLeader")) or 1
  m8EnemyFled = tonumber(GetCampaignVar("M8EnemyFled")) or 0
  m8Scene = tonumber(GetCampaignVar("M8Scene")) or princessScene
end

function SetupPlace()
  for i = 1, playersNum do
    HideHedge(players[i])
  end
  for i = 1, cyborgsNum do
    HideHedge(cyborgs[i])
  end
  if leader ~= nil then
    HideHedge(leader)
  end
end

function SetupEvents()
  AddNewEvent(CheckPlayersDead, {}, DoPlayersDead, {}, 0)
  AddNewEvent(CheckNativesDead, {}, DoNativesDead, {}, 0)
  AddNewEvent(CheckCannibalsDead, {}, DoCannibalsDead, {}, 0)
  AddNewEvent(CheckCyborgsDead, {}, DoCyborgsDead, {}, 0)
end

function SetupAmmo()
  AddAmmo(cyborgs[1], amClusterBomb, 100)
  AddAmmo(cyborgs[1], amMortar, 100)
  AddAmmo(cyborgs[1], amDynamite, 2)
  AddAmmo(cyborgs[1], amAirAttack, 2)
  AddAmmo(cyborgs[1], amTeleport, 100)

  if leader ~= nil then
    AddAmmo(leader, amClusterBomb, 100)
    AddAmmo(leader, amMortar, 100)
    AddAmmo(leader, amDynamite, 100)
    AddAmmo(leader, amAirAttack, 3)
    AddAmmo(leader, amTeleport, 100)
  end
end

function AddHogs()
  cyborgTeamName = AddTeam(loc("011101001"), -1, "ring", "UFO", "Robot_qau", "cm_binary")
  cyborg = AddHog(loc("Unit 334a$7%;.*"), 0, 200, "cyborg1")

  nativesTeamName = AddMissionTeam(-2)
  -- There are 3-4 natives in this mission
  natives[1] = AddHog(nativeNames[leaksNum], 0, 100, nativeHats[leaksNum])
  if m5DeployedNum ~= leaksNum and m8DeployedLeader == 0 then
    natives[2] = AddHog(nativeNames[m5DeployedNum], 0, 100, nativeHats[m5DeployedNum])
  end
  table.insert(natives, AddHog(nativeNames[ramonNum], 0, 100, nativeHats[ramonNum]))
  table.insert(natives, AddHog(nativeNames[spikyNum], 0, 100, nativeHats[spikyNum]))
  if m8PrincessLeader == 0 then
    table.insert(natives, AddHog(loc("Fell From Heaven"), 0, 100, "tiara"))
  end
  nativesNum = #natives
  nativesLeft = nativesNum
  cannibalsLeft = cannibalsNum
  for i = 1, nativesNum do
    table.insert(players, natives[i])
  end

  cannibalsTeamName = AddTeam(loc("Cannibals"), -2, "skull", "Island", "Pirate_qau", "cm_vampire")
  for i = 1, cannibalsNum do
    cannibals[i] = AddHog(cannibalNames[i], 0, 100, "Zombi")
    table.insert(players, cannibals[i])
  end
  playersNum = #players
  playersLeft = playersNum

  hedgecogsTeamName = AddTeam(loc("Hedge-cogs"), -9, "ring", "UFO", "Robot_qau", "cm_cyborg")
  for i = 1, cyborgsNum do
    cyborgs[i] = AddHog(cyborgNames[i], 2, 80, "cyborg2")
  end

  if m8EnemyFled == 1 then
    leaderTeamName = AddTeam(loc("Leader"), -9, "ring", "UFO", "Robot_qau", "cm_cyborg")
    if m8Scene == denseScene then
      leader = AddHog(loc("Dense Cloud"), 2, 200, nativeHats[denseNum])
    elseif m8Scene == waterScene then
      leader = AddHog(loc("Fiery Water"), 2, 200, nativeHats[waterNum])
    elseif m8Scene == princessScene then
      leader = AddHog(loc("Fell From Heaven"), 2, 200, "tiara")
    else
      leader = AddHog(loc("Nancy Screw"), 2, 200, "cyborg2")
    end
  end

  cyborgsLeft = cyborgsNum

  for i = 1, nativesNum do
    AnimSetGearPosition(natives[i], unpack(nativePos[i]))
    AnimTurn(natives[i], nativeDir[i])
  end
  for i = 1, cannibalsNum do
    AnimSetGearPosition(cannibals[i], unpack(cannibalPos[i]))
    AnimTurn(cannibals[i], cannibalDir[i])
  end
  for i = 1, cyborgsNum do
    AnimSetGearPosition(cyborgs[i], unpack(cyborgsPos[i]))
    AnimTurn(cyborgs[i], cyborgsDir[i])
  end
  AnimSetGearPosition(cyborg, unpack(cyborgPos[1]))
  AnimTurn(cyborg, cyborgDir)
  if leader ~= nil then
    AnimSetGearPosition(leader, unpack(leaderPos))
    AnimTurn(leader, leaderDir[i])
  end
end

-----------------------------Main Functions----------------------------

function onGameInit()
	Seed = 0
	GameFlags = gfSolidLand
	TurnTime = 60000 
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 3000
	Explosives = 0
  Map = "Islands"
	Theme = "EarthRise"
  SuddenDeathTurns = 20

  GetVariables()
  AnimInit()
  AddHogs()
end

function onGameStart()
  SetupAmmo()
  SetupPlace()
  AnimationSetup()
  SetupEvents()
  AddAnim(startAnim)
  AddFunction({func = AfterStartAnim, args = {}})
end

function onGameTick()
  AnimUnWait()
  if ShowAnimation() == false then
    return
  end
  ExecuteAfterAnimations()
  CheckEvents()
end

function onGearAdd(gear)
  local gt = GetGearType(gear)
  if gt == gtMine or gt == gtSMine or gt == gtAirMine then
    trackedMines[gear] = true
  end
end

function onGearDelete(gear)
  local gt = GetGearType(gear)
  if gt == gtMine or gt == gtSMine or gt == gtAirMine then
    trackedMines[gear] = nil
  end
  gearDead[gear] = true
  if gt == gtHedgehog then
    if GetHogTeamName(gear) == nativesTeamName then
      for i = 1, nativesLeft do
        if natives[i] == gear then
          table.remove(natives, i)
          table.remove(players, i)
          nativesLeft = nativesLeft - 1
          playersLeft = playersLeft - 1
        end
      end
    elseif GetHogTeamName(gear) == cannibalsTeamName then
      for i = 1, cannibalsLeft do
        if cannibals[i] == gear then
          table.remove(cannibals, i)
          table.remove(players, nativesLeft + i)
          cannibalsLeft = cannibalsLeft - 1
          playersLeft = playersLeft - 1
        end
      end
    elseif GetHogTeamName(gear) == hedgecogsTeamName then
      for i = 1, cyborgsLeft do
        if cyborgs[i] == gear then
          table.remove(cyborgs, i)
        end
      end
      cyborgsLeft = cyborgsLeft - 1
    end
  end
end

function onAmmoStoreInit()
  SetAmmo(amSkip, 9, 0, 0, 0)
  SetAmmo(amSwitch, 9, 0, 0, 0)
  SetAmmo(amDEagle, 9, 0, 0, 0)
  SetAmmo(amSniperRifle, 9, 0, 0, 0)
  SetAmmo(amBazooka, 8, 0, 0, 0)
  SetAmmo(amGrenade, 7, 0, 0, 0)
  SetAmmo(amFirePunch, 9, 0, 0, 0)
  SetAmmo(amShotgun, 9, 0, 0, 0)

  SetAmmo(amParachute, 9, 0, 0, 0)
  SetAmmo(amRope, 9, 0, 0, 0)
  SetAmmo(amPickHammer, 9, 0, 0, 0)
  SetAmmo(amBlowTorch, 9, 0, 0, 0)
end

function onNewTurn()
  if AnimInProgress() then
    SetTurnTimeLeft(MAX_TURN_TIME)
    return
  end
  if playersDeadFresh then
    playersDeadFresh = false
    FailedMission()
  elseif cyborgsDeadFresh then
    cyborgsDeadFresh = false
    WonMission()
  elseif nativesDeadFresh and GetHogTeamName(CurrentHedgehog) == cannibalsTeamName then
    AnimSay(CurrentHedgehog, string.format(loc("Your deaths will be avenged, %s!"), nativesTeamName), SAY_SHOUT, 0)
    nativesDeadFresh = false
  elseif cannibalsDeadFresh and GetHogTeamName(CurrentHedgehog) == nativesTeamName then
    AnimSay(CurrentHedgehog, string.format(loc("Your deaths will be avenged, %s!"), cannibalsTeamName), SAY_SHOUT, 0)
    cannibalsDeadFresh = false
  end
end

function onPreciseLocal()
  if GameTime > 3000 and AnimInProgress() then
    SetAnimSkip(true)
  end
end
