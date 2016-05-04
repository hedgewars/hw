HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

-----------------------------Constants---------------------------------
leaksNum = 1
denseNum = 2
waterNum = 3
buffaloNum = 4
chiefNum = 5
girlNum = 6
wiseNum = 7
ramonNum = 8
spikyNum = 9
princessNum = 10

denseScene = 1
princessScene = 2
waterScene = 3
cyborgScene = 4

nativeNames = {loc("Leaks A Lot"), loc("Dense Cloud"), loc("Fiery Water"), 
               loc("Raging Buffalo"), loc("Righteous Beard"), loc("Fell From Grace"),
               loc("Wise Oak"), loc("Ramon"), loc("Spiky Cheese"),
               loc("Fell From Heaven")
              }
nativeHats = {"Rambo", "RobinHood", "pirate_jack", "zoo_Bunny", "IndianChief",
              "tiara", "AkuAku", "rasta", "hair_yellow", "tiara"}

nativePosCyborg = {{1900, 508}, {480, 1321}, {2927, 873},
             {1325, 905}, {3190, 1424}, {1442, 857},
             {1134, 1278}, {2881, 853}, {2974, 897},
             {2033, 511}}
nativeDirCyborg = {"Right", "Right", "Left", "Right", "Right", "Left", "Right", "Right", "Left", "Left"}

nativePosPrincess = {{1930, 508}, {480, 1321}, {2927, 873},
             {1325, 905}, {3190, 1424}, {2033, 511},
             {1134, 1278}, {2881, 853}, {2974, 897},
             {1900, 508}}
nativeDirPrincess = {"Right", "Right", "Left", "Right", "Right", "Left", "Right", "Right", "Left", "Right"}

nativePosDense = {{1930, 508}, {2285, 772}, {2927, 873},
             {1325, 905}, {3190, 1424}, {1442, 857},
             {1134, 1278}, {480, 1321}, {2974, 897},
             {2033, 511}}
nativeDirDense = {"Right", "Left", "Left", "Right", "Right", "Left", "Right", "Right", "Left", "Left"}

nativePosWater = {{1900, 508}, {2033, 511}, {2285, 772},
             {1325, 905}, {3190, 1424}, {1442, 857},
             {1134, 1278}, {480, 1321}, {2974, 897},
             {1980, 511}}
nativeDirWater = {"Right", "Left", "Left", "Right", "Right", "Left", "Right", "Right", "Left", "Left"}

prisonPos = {2285, 772}

brainNum = 1
corpseNum = 2
brutalNum = 3
earNum = 4
hanniNum = 5

cannibalNames = {loc("Brainiac"), loc("Corpse Thrower"), loc("Brutal Lily"), loc("Ear Sniffer"), loc("Hannibal")}
cannibalHats = {"Zombi", "AkuAku", "Zombi", "Zombi", "IndianChief"}
cannibalPos = {{533, 1304}, {1184, 1282}, {1386, 883}, {2854, 834}, {3243, 1415}}
cannibalDir = {"Left", "Left", "Left", "Right", "Left"}
-----------------------------Variables---------------------------------
natives = {}
cannibals = {}
traitor = nil
crate = nil

startAnim = {}

gearDead = {}
--------------------------Anim skip functions--------------------------
function SkipStartAnim()
  SetGearMessage(CurrentHedgehog, 0)
  AnimSwitchHog(natives[1])
end

function AfterStartAnim()
  crate = SpawnHealthCrate(0, 0)
  SetGearMessage(CurrentHedgehog, 0)
  AddNewEvent(CheckCrateTaken, {}, DoCrateTaken, {}, 1)
  TurnTimeLeft = 0
  ShowMission("Epilogue", "That's all folks!", "You have successfully finished the campaign!|If you wish to replay, there are other possible endings, too!|You can practice moving around and using utilities in this mission.|However, it will never end!", 1, 0)
  SaveCampaignVar("Won", "true")
end

---------------------------Events-------------------------------------
function CheckCrateTaken()
  return gearDead[crate]
end

function DoCrateTaken()
  crate = SpawnHealthCrate(0, 0)
end
-----------------------------Animations--------------------------------
function AnimationSetup()
  if m8Scene == cyborgScene then 
    SetupAnimCyborg()
  elseif m8Scene == princessScene then
    SetupAnimPrincess()
  elseif m8Scene == waterScene then
    SetupAnimWater()
  else
    SetupAnimDense()
  end
  AddSkipFunction(startAnim, SkipStartAnim, {})
end

function SetupAnimWater()
  startAnim = {
    {func = AnimWait, args = {natives[1], 3000}},
    {func = AnimCaption, args = {natives[ramonNum], "Back in the village, the two tribes finally started to live in harmony.", 5000}},
    {func = AnimSay, args = {natives[ramonNum], "You got a killer mask there, amigo!", SAY_SAY, 5500}},
    {func = AnimSay, args = {cannibals[brainNum], "Thanks, man! It really means a lot to me.", SAY_SAY, 6000}},
    {func = AnimSay, args = {natives[wiseNum], "So, uhmm, how did you manage to teleport them so far?", SAY_SAY, 8000}},
    {func = AnimSay, args = {cannibals[corpseNum], "It's all about the right carrots, you know.", SAY_SAY, 7000}},
    {func = AnimSay, args = {natives[wiseNum], "Of course! It's all obvious now!", SAY_SAY, 4500}},
    {func = AnimSay, args = {natives[chiefNum], "I can't believe how blind we were...", SAY_SAY, 4500}},
    {func = AnimSay, args = {natives[chiefNum], "Fighting instead of cultivating a beautiful friendship.", SAY_SAY, 8500}},
    {func = AnimSay, args = {cannibals[hanniNum], "One shall not judge one by one's appearance!", SAY_SAY, 7000}},
    {func = AnimSay, args = {natives[chiefNum], "You speak great truth, Hannibal. Here, take a sip!", SAY_SAY, 7500}},
    {func = AnimVisualGear, args = {cannibals[hanniNum], cannibalPos[hanniNum][1], cannibalPos[hanniNum][2], vgtSmoke, 0, true}},
    {func = AnimWait, args = {natives[1], 1000}},
    {func = AnimVisualGear, args = {cannibals[hanniNum], cannibalPos[hanniNum][1], cannibalPos[hanniNum][2], vgtSmoke, 0, true}},
    {func = AnimWait, args = {natives[1], 1000}},
    {func = AnimVisualGear, args = {cannibals[hanniNum], cannibalPos[hanniNum][1], cannibalPos[hanniNum][2], vgtSmoke, 0, true}},
    {func = AnimWait, args = {natives[1], 1000}},
    {func = AnimSay, args = {natives[leaksNum], "It's amazing how quickly our lives can change...", SAY_SAY, 7000}},
    {func = AnimSay, args = {natives[waterNum], "Aye! Fellow! Let me exit this chamber of doom!", SAY_SAY, 7000}},
    {func = AnimTurn, args = {natives[princessNum], "Right"}},
    {func = AnimSay, args = {natives[princessNum], "It's your fault you're there!", SAY_SAY, 5000}},
    {func = AnimTurn, args = {natives[princessNum], "Left"}},
    {func = AnimSay, args = {natives[leaksNum], "I always suspected him!", SAY_SAY, 3000}},
    {func = AnimSay, args = {natives[leaksNum], "Nobody takes walks every day!", SAY_SAY, 4000}},
    {func = AnimSay, args = {natives[princessNum], "I don't know who I can trust anymore.", SAY_SAY, 6000}},
    {func = AnimSay, args = {natives[princessNum], "Everywhere I look, I see hogs walking around...", SAY_SAY, 7000}},
    {func = AnimSay, args = {natives[princessNum], "...and I think they are up to something. Something bad!", SAY_SAY, 8000}},
    {func = AnimMove, args = {natives[leaksNum], "Right", nativePosWater[princessNum][1] - 30, nativePosWater[princessNum][2]}},
    {func = AnimSay, args = {natives[leaksNum], "You can always trust me! I love you!", SAY_SAY, 6000}},
    {func = AnimSay, args = {natives[princessNum], "I know and I'm terribly sorry!", SAY_SAY, 5000}},
    {func = AnimSay, args = {natives[princessNum], "I love Dense Cloud now!", SAY_SAY, 4000}},
    {func = AnimTurn, args = {natives[princessNum], "Right"}},
    {func = AnimMove, args = {natives[denseNum], "Left", nativePosWater[princessNum][1] + 20, nativePosWater[princessNum][2]}},
    {func = AnimSay, args = {natives[denseNum], "Problems, dude? Chillax!", SAY_SAY, 4000}},
    {func = AnimTurn, args = {natives[leaksNum], "Left"}},
    {func = AnimSay, args = {natives[leaksNum], "(T_T)", SAY_SAY, 6000}},
    {func = AnimSwitchHog, args = {natives[leaksNum]}},
  }
end

function SetupAnimDense()
  startAnim = {
    {func = AnimWait, args = {natives[1], 3000}},
    {func = AnimCaption, args = {natives[ramonNum], "Back in the village, the two tribes finally started to live in harmony.", 5000}},
    {func = AnimSay, args = {natives[ramonNum], "You got a killer mask there, amigo!", SAY_SAY, 5500}},
    {func = AnimSay, args = {cannibals[brainNum], "Thanks, man! It really means a lot to me.", SAY_SAY, 6000}},
    {func = AnimSay, args = {natives[wiseNum], "So, uhmm, how did you manage to teleport them so far?", SAY_SAY, 8000}},
    {func = AnimSay, args = {cannibals[corpseNum], "It's all about the right carrots, you know.", SAY_SAY, 7000}},
    {func = AnimSay, args = {natives[wiseNum], "Of course! It's all obvious now!", SAY_SAY, 4500}},
    {func = AnimSay, args = {natives[chiefNum], "I can't believe how blind we were...", SAY_SAY, 4500}},
    {func = AnimSay, args = {natives[chiefNum], "Fighting instead of cultivating a beautiful friendship.", SAY_SAY, 8500}},
    {func = AnimSay, args = {cannibals[hanniNum], "One shall not judge one by one's appearance!", SAY_SAY, 7000}},
    {func = AnimSay, args = {natives[chiefNum], "You speak great truth, Hannibal. Here, take a sip!", SAY_SAY, 7500}},
    {func = AnimVisualGear, args = {cannibals[hanniNum], cannibalPos[hanniNum][1], cannibalPos[hanniNum][2], vgtSmoke, 0, true}},
    {func = AnimWait, args = {natives[1], 1000}},
    {func = AnimVisualGear, args = {cannibals[hanniNum], cannibalPos[hanniNum][1], cannibalPos[hanniNum][2], vgtSmoke, 0, true}},
    {func = AnimWait, args = {natives[1], 1000}},
    {func = AnimVisualGear, args = {cannibals[hanniNum], cannibalPos[hanniNum][1], cannibalPos[hanniNum][2], vgtSmoke, 0, true}},
    {func = AnimWait, args = {natives[1], 1000}},
    {func = AnimSay, args = {natives[waterNum], "...And then I took a stroll...", SAY_SAY, 4000}},
    {func = AnimSay, args = {natives[leaksNum], "It's amazing how quickly our lives can change...", SAY_SAY, 7000}},
    {func = AnimSay, args = {natives[denseNum], "Dude, let me out!", SAY_SAY, 3000}},
    {func = AnimSay, args = {natives[denseNum], "I already said I'm sorry!", SAY_SAY, 4000}},
    {func = AnimTurn, args = {natives[princessNum], "Right"}},
    {func = AnimSay, args = {natives[princessNum], "Traitors don't get to shout around here!", SAY_SAY, 7000}},
    {func = AnimTurn, args = {natives[princessNum], "Left"}},
    {func = AnimSay, args = {natives[leaksNum], "I still can't believe he sold us out like that.", SAY_SAY, 8000}},
    {func = AnimSay, args = {natives[princessNum], "I don't know who I can trust anymore.", SAY_SAY, 6000}},
    {func = AnimMove, args = {natives[leaksNum], "Right", nativePosDense[princessNum][1] - 30, nativePosDense[princessNum][2]}},
    {func = AnimSay, args = {natives[leaksNum], "You can always trust me!", SAY_SAY, 4000}},
    {func = AnimSay, args = {natives[princessNum], "I know, my hero!", SAY_SAY, 3000}},
    {func = AnimSay, args = {natives[princessNum], "...xoxo...", SAY_SAY, 2000}},
    {func = AnimSwitchHog, args = {natives[leaksNum]}},
  }
end

function SetupAnimCyborg()
  startAnim = {
    {func = AnimWait, args = {natives[1], 3000}},
    {func = AnimCaption, args = {natives[denseNum], "Back in the village, the two tribes finally started to live in harmony.", 5000}},
    {func = AnimSay, args = {natives[denseNum], "Dude, that outfit is so kool!", SAY_SAY, 4500}},
    {func = AnimSay, args = {cannibals[brainNum], "Thanks, dude! It really means a lot to me.", SAY_SAY, 6000}},
    {func = AnimSay, args = {natives[wiseNum], "So, uhmm, how did you manage to teleport them so far?", SAY_SAY, 8000}},
    {func = AnimSay, args = {cannibals[corpseNum], "It's all about the right carrots, you know.", SAY_SAY, 7000}},
    {func = AnimSay, args = {natives[wiseNum], "Of course! It's all obvious now!", SAY_SAY, 4500}},
    {func = AnimSay, args = {natives[chiefNum], "I can't believe how blind we were...", SAY_SAY, 4500}},
    {func = AnimSay, args = {natives[chiefNum], "Fighting instead of cultivating a beautiful friendship.", SAY_SAY, 8500}},
    {func = AnimSay, args = {cannibals[hanniNum], "One shall not judge one by one's appearance!", SAY_SAY, 7000}},
    {func = AnimSay, args = {natives[chiefNum], "You speak great truth, Hannibal. Here, take a sip!", SAY_SAY, 7500}},
    {func = AnimVisualGear, args = {cannibals[hanniNum], cannibalPos[hanniNum][1], cannibalPos[hanniNum][2], vgtSmoke, 0, true}},
    {func = AnimWait, args = {natives[1], 1000}},
    {func = AnimVisualGear, args = {cannibals[hanniNum], cannibalPos[hanniNum][1], cannibalPos[hanniNum][2], vgtSmoke, 0, true}},
    {func = AnimWait, args = {natives[1], 1000}},
    {func = AnimVisualGear, args = {cannibals[hanniNum], cannibalPos[hanniNum][1], cannibalPos[hanniNum][2], vgtSmoke, 0, true}},
    {func = AnimWait, args = {natives[1], 1000}},
    {func = AnimSay, args = {natives[waterNum], "...And then I took a stroll...", SAY_SAY, 4000}},
    {func = AnimSay, args = {natives[leaksNum], "I'm glad this is over!", SAY_SAY, 4000}},
    {func = AnimMove, args = {natives[princessNum], "Right", nativePosCyborg[princessNum][1] + 30, nativePosCyborg[princessNum][2]}},
    {func = AnimSay, args = {natives[princessNum], "I was so scared.", SAY_SAY, 2500}},
    {func = AnimMove, args = {natives[leaksNum], "Right", nativePosCyborg[princessNum][1], nativePosCyborg[princessNum][2]}},
    {func = AnimSay, args = {natives[leaksNum], "You have nothing to be afraid of now.", SAY_SAY, 6000}},
    {func = AnimSay, args = {natives[leaksNum], "I'll protect you!", SAY_SAY, 3000}},
    {func = AnimTurn, args = {natives[princessNum], "Left"}},
    {func = AnimSay, args = {natives[princessNum], "You're so brave...I feel safe with you.", SAY_SAY, 6500}},
    {func = AnimSay, args = {natives[princessNum], "I think I love you!", SAY_SAY, 3500}},
    {func = AnimSay, args = {natives[leaksNum], "I...like being with you too.", SAY_SAY, 4500}},
  }
end

function SetupAnimPrincess()
  startAnim = {
    {func = AnimWait, args = {natives[1], 3000}},
    {func = AnimCaption, args = {natives[denseNum], "Back in the village, the two tribes finally started to live in harmony.", 5000}},
    {func = AnimSay, args = {natives[denseNum], "Dude, that outfit is so kool!", SAY_SAY, 4500}},
    {func = AnimSay, args = {cannibals[brainNum], "Thanks, dude! It really means a lot to me.", SAY_SAY, 6000}},
    {func = AnimSay, args = {natives[wiseNum], "So, uhmm, how did you manage to teleport them so far?", SAY_SAY, 8000}},
    {func = AnimSay, args = {cannibals[corpseNum], "It's all about the right carrots, you know.", SAY_SAY, 7000}},
    {func = AnimSay, args = {natives[wiseNum], "Of course! It's all obvious now!", SAY_SAY, 4500}},
    {func = AnimSay, args = {natives[chiefNum], "I can't believe how blind we were...", SAY_SAY, 4500}},
    {func = AnimSay, args = {natives[chiefNum], "Fighting instead of cultivating a beautiful friendship.", SAY_SAY, 8500}},
    {func = AnimSay, args = {cannibals[hanniNum], "One shall not judge one by one's appearance!", SAY_SAY, 7000}},
    {func = AnimSay, args = {natives[chiefNum], "You speak great truth, Hannibal. Here, take a sip!", SAY_SAY, 7500}},
    {func = AnimVisualGear, args = {cannibals[hanniNum], cannibalPos[hanniNum][1], cannibalPos[hanniNum][2], vgtSmoke, 0, true}},
    {func = AnimWait, args = {natives[1], 1000}},
    {func = AnimVisualGear, args = {cannibals[hanniNum], cannibalPos[hanniNum][1], cannibalPos[hanniNum][2], vgtSmoke, 0, true}},
    {func = AnimWait, args = {natives[1], 1000}},
    {func = AnimVisualGear, args = {cannibals[hanniNum], cannibalPos[hanniNum][1], cannibalPos[hanniNum][2], vgtSmoke, 0, true}},
    {func = AnimWait, args = {natives[1], 1000}},
    {func = AnimSay, args = {natives[buffaloNum], "So I shook my fist in the air!", SAY_SAY, 5000}},
    {func = AnimSay, args = {cannibals[brutalNum], "Well that was an unnecessary act of violence.", SAY_SAY, 7000}},
    {func = AnimSay, args = {natives[waterNum], "...And then I took a stroll...", SAY_SAY, 4000}},
    {func = AnimSay, args = {natives[leaksNum], "I'm glad this is over!", SAY_SAY, 4000}},
    {func = AnimSay, args = {natives[girlNum], "I still can't believe you forgave her!", SAY_SAY, 6000}},
    {func = AnimSay, args = {natives[girlNum], "She endangered the whole tribe!", SAY_SAY, 5000}},
    {func = AnimSay, args = {natives[leaksNum], "It wasn't her fault!", SAY_SAY, 4000}},
    {func = AnimSay, args = {natives[leaksNum], "We oppressed her, the only woman in the tribe!", SAY_SAY, 7000}},
    {func = AnimSay, args = {natives[girlNum], "The only woman, huh?", SAY_SAY, 4000}},
    {func = AnimSay, args = {natives[girlNum], "Then what am I?", SAY_SAY, 4000}},
    {func = AnimSay, args = {natives[leaksNum], "Of course, but you're...special.", SAY_SAY, 5000}},
    {func = AnimSay, args = {natives[girlNum], "Sure!", SAY_SAY, 2000}},
    {func = AnimTurn, args = {natives[leaksNum], "Left"}},
    {func = AnimSay, args = {natives[leaksNum], "We're terribly sorry!", SAY_SAY, 4000}},
    {func = AnimSay, args = {natives[princessNum], "I don't know if I can forget what you've done!", SAY_SAY, 7000}},
    {func = AnimTurn, args = {natives[princessNum], "Left"}},
    {func = AnimMove, args = {natives[princessNum], "Left", nativePosPrincess[princessNum][1] - 10, nativePosPrincess[princessNum][2]}},
    {func = AnimSwitchHog, args = {natives[leaksNum]}}
  }
end
-----------------------------Misc--------------------------------------
function GetVariables()
  m8Scene = tonumber(GetCampaignVar("M8Scene"))
end

function AddHogs()
	AddTeam(loc("Natives"), 29439, "Bone", "Island", "HillBilly", "cm_birdy")
  for i = 1, 5 do
    natives[i] = AddHog(nativeNames[i], 0, 100, nativeHats[i])
  end

	AddTeam(loc("More Natives"), 29439, "Bone", "Island", "HillBilly", "cm_birdy")
  for i = 6, 10 do
    natives[i] = AddHog(nativeNames[i], 0, 100, nativeHats[i])
  end

	AddTeam(loc("Cannibals"), 29439, "Bone", "Island", "HillBilly", "cm_birdy")
  for i = 1, 5 do
    cannibals[i] = AddHog(cannibalNames[i], 0, 100, cannibalHats[i])
  end

  if m8Scene == denseScene or m8Scene == waterScene then
    AddTeam(loc("Traitors"), 29439, "Bone", "Island", "HillBilly", "cm_birdy")
    if m8Scene == denseScene then
      DeleteGear(natives[2])
      natives[2] = AddHog(nativeNames[2], 0, 100, nativeHats[2])
    else
      DeleteGear(natives[3])
      natives[3] = AddHog(nativeNames[3], 0, 100, nativeHats[3])
    end
  end

  SetGearPositions()
end

function SetGearPositions()
  if m8Scene == cyborgScene then
    for i = 1, 10 do
      AnimSetGearPosition(natives[i], unpack(nativePosCyborg[i]))
      AnimTurn(natives[i], nativeDirCyborg[i])
    end
  elseif m8Scene == waterScene then
    for i = 1, 10 do
      AnimSetGearPosition(natives[i], unpack(nativePosWater[i]))
      AnimTurn(natives[i], nativeDirWater[i])
    end
  elseif m8Scene == denseScene then
    for i = 1, 10 do
      AnimSetGearPosition(natives[i], unpack(nativePosDense[i]))
      AnimTurn(natives[i], nativeDirDense[i])
    end
  else
    for i = 1, 10 do
      AnimSetGearPosition(natives[i], unpack(nativePosPrincess[i]))
      AnimTurn(natives[i], nativeDirPrincess[i])
    end
  end

  for i = 1, 5 do
    AnimSetGearPosition(cannibals[i], unpack(cannibalPos[i]))
    AnimTurn(cannibals[i], cannibalDir[i])
  end
end

function SetupPlace()
  if m8Scene == denseScene or m8Scene == waterScene then
    PlaceGirder(2296, 798, 4)
    PlaceGirder(2296, 700, 4)
    PlaceGirder(2225, 750, 2)
    PlaceGirder(2245, 750, 2)
    PlaceGirder(2265, 750, 2)
    PlaceGirder(2305, 750, 2)
    PlaceGirder(2345, 750, 2)
    PlaceGirder(2365, 750, 2)
  end
  if m8Scene == denseScene then
    traitor = natives[denseNum]
  elseif m8Scene == waterScene then
    traitor = natives[waterNum]
  end
end
-----------------------------Main Functions----------------------------
function onGameInit()
	Seed = 1
	GameFlags = gfOneClanMode
	TurnTime = 60000 
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 3000
	Explosives = 0
	Delay = 10 
  Map = "Hogville"
	Theme = "Nature"
  SuddenDeathTurns = 3000

  GetVariables()
  AddHogs()
  AnimInit()
end

function onGameStart()
  SetupPlace()
  AnimationSetup()
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
  gearDead[gear] = true
end

function onAmmoStoreInit()
  SetAmmo(amAirAttack, 9, 0, 0, 0)
  SetAmmo(amBaseballBat, 9, 0, 0, 0)
  SetAmmo(amBazooka, 9, 0, 0, 0)
  SetAmmo(amBlowTorch, 9, 0, 0, 0)
	SetAmmo(amClusterBomb,9, 0, 0, 0)
  SetAmmo(amDEagle, 9, 0, 0, 0)
  SetAmmo(amDrill, 9, 0, 0, 4)
  SetAmmo(amDynamite, 9, 0, 0, 3)
  SetAmmo(amFirePunch, 9, 0, 0, 0)
  SetAmmo(amFlamethrower, 9, 0, 0, 3)
  SetAmmo(amGirder, 9, 0, 0, 0)
  SetAmmo(amGrenade, 9, 0, 0, 0)
  SetAmmo(amHammer, 9, 0, 0, 0)
  SetAmmo(amJetpack, 9, 0, 0, 0)
  SetAmmo(amLandGun, 9, 0, 0, 0)
  SetAmmo(amLowGravity, 9, 0, 0, 2)
  SetAmmo(amMine, 9, 0, 0, 2)
  SetAmmo(amMolotov, 9, 0, 0, 3)
  SetAmmo(amMortar, 9, 0, 0, 4)
  SetAmmo(amNapalm, 9, 0, 0, 4)
  SetAmmo(amParachute, 9, 0, 0, 0)
  SetAmmo(amPickHammer, 9, 0, 0, 0)
  SetAmmo(amPortalGun, 9, 0, 0, 0)
  SetAmmo(amRope, 9, 0, 0, 0)
  SetAmmo(amRCPlane, 9, 0, 0, 0)
  SetAmmo(amSkip, 9, 0, 0, 0)
  SetAmmo(amShotgun, 9, 0, 0, 0)
  SetAmmo(amSMine, 9, 0, 0, 2)
  SetAmmo(amSniperRifle, 9, 0, 0, 0)
  SetAmmo(amSnowball, 9, 0, 0, 0)
  SetAmmo(amSwitch, 9, 0, 0, 0)
  SetAmmo(amTeleport, 9, 0, 0, 0)
	SetAmmo(amWatermelon, 9, 0, 0, 0)
  SetAmmo(amWhip, 9, 0, 0, 0)
end

function onNewTurn()
  if AnimInProgress() then
    TurnTimeLeft = -1
    return
  end
  if CurrentHedgehog == traitor then
    TurnTimeLeft = 0
  else
    TurnTimeLeft = -1
  end
end

function onPrecise()
  if GameTime > 2500 then
    SetAnimSkip(true)
  end
end
