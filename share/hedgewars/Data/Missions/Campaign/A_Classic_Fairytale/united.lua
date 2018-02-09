--[[
A Classic Fairytale: United we stand

= SUMMARY =
Simple Deathmatch against cannibals in two waves.

= GOAL =
Kill both Cannfantery (cannibal) teams.

= FLOW CHART =

- Light Cannfantery and player hogs spawn
- Cut scene: startAnim
- TBS
- Light Cannfantery defeated
- Cut scene: wave2Anim
- Heavy Cannfantery spawns
- TBS
- Heavy Cannfantery defeated
- Cut scene: finalAnim
> Victory

]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

-----------------------------Constants---------------------------------
choiceAccept = 1
choiceRefuse = 2
choiceAttack = 3

leaksPos = {2067, 509}
densePos = {1882, 503}
waterPos = {3100, 930}
buffaloPos = {2609, 494}
chiefPos = {2538, 617}
cannibalPos = {{2219, 1339}, {2322, 1357}, {805, 784}, {3876, 1048},
              {1101, 916}, {2854, 1408}, {1974, 486}, {1103, 961}}

HogNames = {loc("Olive"), loc("Brain Stu"), loc("Brainila"), loc("Salivaslurper"),
            loc("Spleenlover"), loc("Thighlicker"), loc("NomNom"), loc("Mindy")}

natives = {}
-----------------------------Variables---------------------------------
cannibals = {}
cannibalDead = {}
cannibalHidden = {}
cratesSpawned = {}
healthCratesSpawned = {}

sdrmv = 0
denseDead = false
leaksDead = false
waterDead = false
buffaloDead = false
chiefDead = false
nativesDead = {}

m2Choice = 0
m2DenseDead = 0

startAnim = {}
wave2Anim = {}
finalAnim = {}
--------------------------Anim skip functions--------------------------
function AfterHogDeadAnim()
  freshDead = nil
  TurnTimeLeft = TurnTime
end

function AfterStartAnim()
  local goal = loc("Defeat the cannibals!|")
  local chiefgoal = loc("Try to protect the chief! You won't lose if he dies, but it is advised that he survives.")
  TurnTimeLeft = TurnTime
  ShowMission(loc("United We Stand"), loc("Invasion"), goal .. chiefgoal, 1, 6000)
end

function SkipStartAnim()
  AnimSetGearPosition(water, 2467, 754)
  if cratesSpawned[1] ~= true then
    SpawnCrates(1)
  end
  if healthCratesSpawned[1] ~= true then
    SpawnHealthCrates(1)
  end
  if cannibalHidden[1] == true then
    RestoreWave(1)
  end
  AnimSwitchHog(leaks)
end

function SkipWave2Anim()
  if cratesSpawned[2] ~= true then
    SpawnCrates(2)
  end
  if healthCratesSpawned[2] ~= true then
    SpawnHealthCrates(2)
  end
  if cannibalHidden[5] == true then
    RestoreWave(2)
  end
  AnimSwitchHog(cannibals[5])
end

function AfterWave2Anim()
  EndTurn(true)
end

function AfterFinalAnim()
  if leaksDead == true then
    SaveCampaignVar("M4LeaksDead", "1")
  else
    SaveCampaignVar("M4LeaksDead", "0")
  end
  if chiefDead == true then
    SaveCampaignVar("M4ChiefDead", "1")
  else
    SaveCampaignVar("M4ChiefDead", "0")
  end
  if buffaloDead == true then
    SaveCampaignVar("M4BuffaloDead", "1")
  else
    SaveCampaignVar("M4BuffaloDead", "0")
  end
  if waterDead == true then
    SaveCampaignVar("M4WaterDead", "1")
  else
    SaveCampaignVar("M4WaterDead", "0")
  end
  if denseDead == true then
    SaveCampaignVar("M4DenseDead", "1")
  else
    SaveCampaignVar("M4DenseDead", "0")
  end
  if progress and progress<4 then
    SaveCampaignVar("Progress", "4")
  end
  DismissTeam(loc("011101001"))
  EndTurn(true)
end
-----------------------------Animations--------------------------------
function Wave2Reaction()
  local i = 1
  local gearr = nil
  while nativesDead[i] == true do
    i = i + 1
  end
  gearr = natives[i]
  if denseDead ~= true and band(GetState(dense), gstDrowning) == 0 then
    AnimInsertStepNext({func = AnimSay, args = {dense, loc("I'm so scared!"), SAY_SAY, 3000}})
    AnimInsertStepNext({func = AnimCustomFunction, args = {dense, EmitDenseClouds, {"Left"}}})
    AnimInsertStepNext({func = AnimTurn, args = {dense, "Left"}})
  end
  AnimInsertStepNext({func = AnimSay, args = {gearr, loc("There's more of them? When did they become so hungry?"), SAY_SHOUT, 8000}}) 
end

function EmitDenseClouds(dir)
  local dif
  if dir == "Left" then
    dif = 10
  else
    dif = -10
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

function AnimationSetup()
  table.insert(startAnim, {func = AnimWait, args = {leaks, 4000}})
  table.insert(startAnim, {func = AnimCaption, args = {leaks, loc("Back in the village, after telling the villagers about the threat..."), 5000}})
  table.insert(startAnim, {func = AnimCaption, args = {leaks, loc("Their buildings were very primitive back then, even for an uncivilised island."), 7000}})
  table.insert(startAnim, {func = AnimSay, args = {chief, loc("Young one, you are telling us that they can instantly change location without a shaman?"), SAY_SAY, 8000}})
  table.insert(startAnim, {func = AnimSay, args = {chief, loc("That is, indeed, very weird..."), SAY_SAY, 3500}})
  table.insert(startAnim, {func = AnimSay, args = {buffalo, loc("If they try coming here, they can have a taste of my delicious knuckles!"), SAY_SHOUT, 8000}})
  table.insert(startAnim, {func = AnimSay, args = {buffalo, loc("Haha!"), SAY_SHOUT, 2000}})
  if denseDead == false then
    table.insert(startAnim, {func = AnimSay, args = {dense, loc("I'm not sure about that!"), SAY_SAY, 3400}})
    table.insert(startAnim, {func = AnimSay, args = {dense, loc("They have weapons we've never seen before!"), SAY_SAY, 5000}})
    table.insert(startAnim, {func = AnimSay, args = {dense, loc("Luckily, I've managed to snatch some of them."), SAY_SAY, 5000}})
    table.insert(startAnim, {func = AnimCustomFunction, args = {dense, SpawnCrates, {1}}})
    table.insert(startAnim, {func = AnimSay, args = {dense, loc("Oops...I dropped them."), SAY_SAY, 3000}})
  else
    table.insert(startAnim, {func = AnimSay, args = {leaks, loc("I'm not sure about that!"), SAY_SAY, 3400}})
    table.insert(startAnim, {func = AnimSay, args = {leaks, loc("They have weapons we've never seen before!"), SAY_SAY, 5000}})
    table.insert(startAnim, {func = AnimCustomFunction, args = {leaks, SpawnCrates, {1}}})
    table.insert(startAnim, {func = AnimWait, args = {leaks, 1000}})
    table.insert(startAnim, {func = AnimSay, args = {leaks, loc("They keep appearing like this. It's weird!"), SAY_SAY, 5000}})
  end
  table.insert(startAnim, {func = AnimSay, args = {chief, loc("Did anyone follow you?"), SAY_SAY, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {leaks, loc("No, we made sure of that!"), SAY_SAY, 3500}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {leaks, SpawnHealthCrates, {1}}})
  table.insert(startAnim, {func = AnimWait, args = {leaks, 1000}})
  table.insert(startAnim, {func = AnimSay, args = {chief, loc("First aid kits?!"), SAY_SAY, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {leaks, loc("I've seen this before. They just appear out of thin air."), SAY_SAY, 7000}})
  table.insert(startAnim, {func = AnimMove, args = {water, "Left", 3000, 0}})
  table.insert(startAnim, {func = AnimJump, args = {water, "long"}})
  table.insert(startAnim, {func = AnimMove, args = {water, "Left", 2655, 0}})
  table.insert(startAnim, {func = AnimTurn, args = {water, "Right"}})
  table.insert(startAnim, {func = AnimJump, args = {water, "back"}})
  table.insert(startAnim, {func = AnimJump, args = {water, "back"}})
  table.insert(startAnim, {func = AnimTurn, args = {water, "Left"}})
  table.insert(startAnim, {func = AnimMove, args = {water, "Left", 2467, 754}})
  table.insert(startAnim, {func = AnimSay, args = {water, loc("Hey guys!"), SAY_SAY, 2500}})
  table.insert(startAnim, {func = AnimSay, args = {chief, loc("..."), SAY_THINK, 1500}})
  table.insert(startAnim, {func = AnimSay, args = {chief, loc("Where have you been?"), SAY_SAY, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {water, loc("Just on a walk."), SAY_SAY, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {chief, loc("You have chosen the perfect moment to leave."), SAY_SAY, 6000}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {chief, RestoreWave, {1}}})
  for i = 1, 4 do
    table.insert(startAnim, {func = AnimOutOfNowhere, args = {cannibals[i], unpack(cannibalPos[i])}})
  end
  table.insert(startAnim, {func = AnimWait, args = {chief, 1500}})
  table.insert(startAnim, {func = AnimSay, args = {leaks, loc("HOW DO THEY KNOW WHERE WE ARE?"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {chief, loc("We have to protect the village!"), SAY_SAY, 5000}})
  table.insert(startAnim, {func = AnimSwitchHog, args = {leaks}})
  AddSkipFunction(startAnim, SkipStartAnim, {})

  table.insert(wave2Anim, {func = AnimCustomFunction, args = {leaks, RestoreWave, {2}}, swh = false})
  for i = 5, 8 do
    table.insert(wave2Anim, {func = AnimOutOfNowhere, args = {cannibals[i], unpack(cannibalPos[i])}})
  end
  table.insert(wave2Anim, {func = AnimCustomFunction, args = {leaks, Wave2Reaction, {}}, swh = false})
  table.insert(wave2Anim, {func = AnimCustomFunction, args = {leaks, SpawnCrates, {2}}, swh = false})
  table.insert(wave2Anim, {func = AnimCustomFunction, args = {leaks, SpawnHealthCrates, {2}}, swh = false})
  table.insert(wave2Anim, {func = AnimSwitchHog, args = {cannibals[5]}})
  AddSkipFunction(wave2Anim, SkipWave2Anim, {})
end

function SetupHogDeadAnim(gear)
  hogDeadAnim = {}
  if nativesNum == 0 then
    return
  end
  local hogDeadStrings = {string.format(loc("They killed %s! You bastards!"), gear), 
                          string.format(loc("%s! Why?!"), gear), 
                          loc("That was just mean!"), 
                          string.format(loc("Oh no, not %s!"), gear)}
  table.insert(hogDeadAnim, {func = AnimSay, args = {CurrentHedgehog, hogDeadStrings[nativesNum], SAY_SHOUT, 4000}})
end

function SetupFinalAnim()
  local found = 0
  local hogs = {}
  local i = 1
  if nativesNum >= 2 then
    while found < 2 do
      if  nativesDead[i] ~= true then
        found = found + 1
        hogs[found] = natives[i]
      end
      i = i + 1
    end
    if chiefDead ~= true then
      hogs[2] = chief
    end
    table.insert(finalAnim, {func = AnimCustomFunction, args = {hogs[1], CondNeedToTurn, {hogs[1], hogs[2]}}})
    table.insert(finalAnim, {func = AnimSay, args = {hogs[1], loc("We can't hold them up much longer!"), SAY_SAY, 5000}})
    table.insert(finalAnim, {func = AnimSay, args = {hogs[1], loc("We need to move!"), SAY_SAY, 3000}})
    table.insert(finalAnim, {func = AnimSay, args = {hogs[2], loc("But where can we go?"), SAY_SAY, 3000}})
    table.insert(finalAnim, {func = AnimSay, args = {hogs[1], loc("To the caves..."), SAY_SAY, 2500}})
    table.insert(finalAnim, {func = AnimSay, args = {hogs[2], loc("Good idea, they'll never find us there!"), SAY_SAY, 5000}})
  else
    for i = 1, 5 do
      if nativesDead[i] ~= true then
        hogs[1] = natives[i]
      end
    end
    table.insert(finalAnim, {func = AnimSay, args = {hogs[1], loc("I need to move the tribe!"), SAY_THINK, 4000}})
    table.insert(finalAnim, {func = AnimSay, args = {hogs[1], loc("The caves are well hidden, they won't find us there!"), SAY_THINK, 7000}})
  end
end
-----------------------------Misc--------------------------------------
function RestoreWave(index)
  for i = (index - 1) * 4 + 1, index * 4 do
    RestoreHog(cannibals[i])
    cannibalHidden[i] = false
  end
end

function GetVariables()
  m2DenseDead = tonumber(GetCampaignVar("M2DenseDead"))
  if m2DenseDead == 1 then
    denseDead = true
  end
  m2Choice = tonumber(GetCampaignVar("M2Choice"))
end

function SetupPlace()
  if m2DenseDead == 1 then
    sdrmv = 1
    DeleteGear(dense)
  end
  for i = 1, 8 do
    HideHog(cannibals[i])
    cannibalHidden[i] = true
  end
  HideHog(cyborg)
end

function SetupEvents()
  AddEvent(CheckWaveDead, {1}, DoWaveDead, {1}, 0)
  AddEvent(CheckWaveDead, {2}, DoWaveDead, {2}, 0)
end

function SetupAmmo()
  AddAmmo(cannibals[1], amGrenade, 4)
  AddAmmo(cannibals[1], amBazooka, 4)
  AddAmmo(cannibals[1], amShotgun, 4)
  AddAmmo(cannibals[1], amMine, 2)
  AddAmmo(cannibals[5], amGrenade, 4)
  AddAmmo(cannibals[5], amBazooka, 4)
  AddAmmo(cannibals[5], amShotgun, 4)
  AddAmmo(cannibals[5], amMine, 2)
  AddAmmo(cannibals[5], amMolotov, 2)
  AddAmmo(cannibals[5], amFlamethrower, 3)
end

function AddHogs()
	AddTeam(loc("Natives"), 29439, "Bone", "Island", "HillBilly", "cm_birdy")
	leaks = AddHog(loc("Leaks A Lot"), 0, 100, "Rambo")
  dense = AddHog(loc("Dense Cloud"), 0, 100, "RobinHood")
  water = AddHog(loc("Fiery Water"), 0, 100, "pirate_jack")
  buffalo = AddHog(loc("Raging Buffalo"), 0, 100, "zoo_Bunny")
  chief = AddHog(loc("Righteous Beard"), 0, 100, "IndianChief")
  natives = {leaks, dense, water, buffalo, chief}
  nativesNum = 5

  AddTeam(loc("Light Cannfantry"), 14483456, "skull", "Island", "Pirate", "cm_vampire")
  for i = 1, 4 do
    cannibals[i] = AddHog(HogNames[i], 2, 40, "Zombi")
  end

  AddTeam(loc("Heavy Cannfantry"), 14483456, "skull", "Island", "Pirate", "cm_vampire")
  for i = 5, 8 do
    cannibals[i] = AddHog(HogNames[i], 2, 55, "vampirichog")
  end

  AddTeam(loc("011101001"), 14483456, "ring", "UFO", "Robot", "cm_binary")
  cyborg = AddHog(loc("Unit 334a$7%;.*"), 0, 200, "cyborg1")

  AnimSetGearPosition(leaks,   unpack(leaksPos))
  AnimSetGearPosition(dense,   unpack(densePos))
  AnimSetGearPosition(water,   unpack(waterPos))
  HogTurnLeft(water, true)
  AnimSetGearPosition(buffalo, unpack(buffaloPos))
  HogTurnLeft(buffalo, true)
  AnimSetGearPosition(chief,   unpack(chiefPos))
  HogTurnLeft(chief, true)
  AnimSetGearPosition(cyborg, 0, 0)
  for i = 1, 8 do
    AnimSetGearPosition(cannibals[i], unpack(cannibalPos[i]))
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

function SpawnHealthCrates(index)
  SetHealth(SpawnHealthCrate(0, 0), 25)
  SetHealth(SpawnHealthCrate(0, 0), 25)
  SetHealth(SpawnHealthCrate(0, 0), 25)
  healthCratesSpawned[index] = true
end

function SpawnCrates(index)
  if index == 1 then
    SpawnSupplyCrate(1943, 408, amBazooka)
    SpawnSupplyCrate(1981, 464, amGrenade)
    SpawnSupplyCrate(1957, 459, amShotgun)
    SpawnSupplyCrate(1902, 450, amDynamite)
    SpawnSupplyCrate(1982, 405, amPickHammer)
    SpawnSupplyCrate(2028, 455, amRope)
    SpawnSupplyCrate(2025, 464, amTeleport)
  else
    SpawnSupplyCrate(1982, 405, amBlowTorch)
    SpawnSupplyCrate(2171, 428, amMolotov)
    SpawnSupplyCrate(2364, 346, amFlamethrower)
    SpawnSupplyCrate(2521, 303, amBazooka)
    SpawnSupplyCrate(2223, 967, amGrenade)
    SpawnSupplyCrate(1437, 371, amShotgun)
 end
  cratesSpawned[index] = true
end

-----------------------------Events------------------------------------

function CheckWaveDead(index)
  for i = (index - 1) * 4 + 1, index * 4 do
    if cannibalDead[i] ~= true then
      return false
    end
  end
  return true
end

function DoWaveDead(index)
  SetGearMessage(CurrentHedgehog, 0)
  SetState(CurrentHedgehog, 0)
  if index == 1 then
    AddAnim(wave2Anim)
    AddFunction({func = AfterWave2Anim, args = {}})
  elseif index == 2 then
    SetupFinalAnim()
    AddAnim(finalAnim)
    AddFunction({func = AfterFinalAnim, args = {}})
  end
end


-----------------------------Main Functions----------------------------

function onGameInit()
	Seed = 1
	GameFlags = 0
	TurnTime = 60000 
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 3000
	Explosives = 2
	Delay = 10 
  Map = "Hogville"
	Theme = "Nature"
	-- Disable Sudden Death
	HealthDecrease = 0
	WaterRise = 0

  AddHogs()
  AnimInit()
end

function onGameStart()
  progress = tonumber(GetCampaignVar("Progress"))
  GetVariables()
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

function onGearDelete(gear)
  if gear == dense then
    denseDead = true
    nativesNum = nativesNum - 1
    nativesDead[2] = true
    if sdrmv == 1 then
      freshDead = nil
    else
      freshDead = loc("Dense Cloud")
    end
  elseif gear == leaks then
    leaksDead = true
    nativesNum = nativesNum - 1
    nativesDead[1] = true
    freshDead = loc("Leaks A Lot")
  elseif gear == chief then
    chiefDead = true
    nativesNum = nativesNum - 1
    nativesDead[5] = true
    freshDead = loc("Righteous Beard")
  elseif gear == water then
    waterDead = true
    nativesNum = nativesNum - 1
    nativesDead[3] = true
    freshDead = loc("Fiery Water")
  elseif gear == buffalo then
    buffaloDead = true
    nativesNum = nativesNum - 1
    nativesDead[4] = true
    freshDead = loc("Raging Buffalo")
  else
    for i = 1, 8 do
      if gear == cannibals[i] then
        cannibalDead[i] = true
      end
    end
  end
end

function onAmmoStoreInit()
  SetAmmo(amDEagle, 9, 0, 0, 0)
  SetAmmo(amSniperRifle, 4, 0, 0, 0)
  SetAmmo(amFirePunch, 9, 0, 0, 0)
  SetAmmo(amWhip, 9, 0, 0, 0)
  SetAmmo(amBaseballBat, 9, 0, 0, 0)
  SetAmmo(amHammer, 9, 0, 0, 0)
  SetAmmo(amLandGun, 9, 0, 0, 0)
  SetAmmo(amSnowball, 8, 0, 0, 0)
  SetAmmo(amGirder, 4, 0, 0, 2)
  SetAmmo(amParachute, 4, 0, 0, 2)
  SetAmmo(amSwitch, 8, 0, 0, 2)
  SetAmmo(amSkip, 9, 0, 0, 0)
  SetAmmo(amRope, 5, 0, 0, 3)
  SetAmmo(amBlowTorch, 3, 0, 0, 3)
  SetAmmo(amPickHammer, 0, 0, 0, 3)
  SetAmmo(amLowGravity, 0, 0, 0, 2)
  SetAmmo(amDynamite, 0, 0, 0, 3)
  SetAmmo(amBazooka, 0, 0, 0, 4)
  SetAmmo(amGrenade, 0, 0, 0, 5)
  SetAmmo(amMine, 0, 0, 0, 2)
  SetAmmo(amMolotov, 0, 0, 0, 3)
  SetAmmo(amFlamethrower, 0, 0, 0, 3)
  SetAmmo(amShotgun, 0, 0, 0, 3)
  SetAmmo(amTeleport, 0, 0, 0, 2)
  SetAmmo(amFlamethrower, 0, 0, 0, 3)
end

function onNewTurn()
  if AnimInProgress() then
    TurnTimeLeft = -1
    return
  end
  if freshDead ~= nil and GetHogTeamName(CurrentHedgehog) == loc("Natives") then
    SetupHogDeadAnim(freshDead)
    AddAnim(hogDeadAnim)
    AddFunction({func = AfterHogDeadAnim, args = {}})
  end
end

function onPrecise()
  if GameTime > 2500 then
    SetAnimSkip(true)
  end
end

