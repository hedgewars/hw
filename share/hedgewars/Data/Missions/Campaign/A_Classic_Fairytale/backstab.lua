--[[
A Classic Fairytale: Backstab

= SUMMARY =
It is revealed that there's a traitor among the natives.
Player decides whether to kill him or not.
After this, the natives must defeat 3 waves of cannibals.

= FLOW CHART =

== Linear events ==

- Cut scene: startScene (traitor is revealed)
- Player is instructed to decide what to do with the traitor
| Player kills traitor
    - Cut scene: afterChoiceAnim
| Player spares traitor (skips turn or moves too far away)
    - Cut scene: afterChoiceAnim (different)
| Player kills any other hog or own hog
    > Game over
- First turn of cannibals
- TBS
- First wave of cannibals dead
- Cut scene: wave2Anim
- Spawn 2nd cannibal wave
- TBS
- 2nd wave dead
- Cut scene: wave2DeadAnim
- All natives but one are encaged
- 7 turns till arrival of 3rd wave
- Arrival points are marked with circles
- One hero is deployed near the circles
- Player now only controls the hero, switch hog is removed
- TBS
- 3rd wave appears
- TBS
- 3rd wave dead
- Final cut scene
> Victory

=== The traitor ===
The traitor is chosen based on the past player decisions in the campaign.

== Non-linear events ==

| Any native hog dies after traitor decision:
    - Another hog (if alive) mourns the loss

]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")

-----------------------------Constants---------------------------------
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

spyKillStage = 1
platformStage = 2
wave3Stage = 3

tmpVar = 0

nativeNames = {loc("Leaks A Lot"), loc("Dense Cloud"), loc("Fiery Water"), 
               loc("Raging Buffalo"), loc("Righteous Beard"), loc("Fell From Grace"),
               loc("Wise Oak"), loc("Eagle Eye"), loc("Flaming Worm")}

nativeHats = {"Rambo", "RobinHood", "pirate_jack", "zoo_Bunny", "IndianChief",
              "tiara", "AkuAku", "None", "None"}

nativePos = {{887, 329}, {1050, 288}, {1731, 707},
             {830, 342}, {1001, 290}, {773, 340},
             {953, 305}, {347, 648}, {314, 647}}

nativeDir = {"Right", "Left", "Left", 
             "Right", "Left", "Right", 
             "Left", "Right", "Right"}

cannibalNames = {loc("Brain Teaser"), loc("Bone Jackson"), loc("Gimme Bones"), 
                 loc("Hedgibal Lecter"), loc("Bloodpie"), loc("Scalp Muncher"),
                 loc("Back Breaker"), loc("Dahmer"), loc("Meiwes"),
                 loc("Ear Sniffer"), loc("Regurgitator"), loc("Muriel")}

cannibalPos = {{3607, 1472}, {3612, 1487}, {3646, 1502}, 
               {3507, 195},  {3612, 1487}, {840, 1757}, 
               {3056, 1231}, {2981, 1222}, {2785, 1258}}

cannibalDir = {"Left", "Left", "Left",
               "Left", "Right", "Right",
               "Left", "Left", "Left"}

cyborgPos = {1369, 574}
cyborgPos2 = {1308, 148}

deployedPos = {2522, 1365}
-----------------------------Variables---------------------------------
natives = {}
nativeDead = {}
nativeHidden = {}
nativeRevived = {}
nativesNum = 0

cannibals = {}
cannibalDead = {}
cannibalHidden = {}

speakerHog = nil
spyHog = nil
deployedHog = nil
deployedDead = false
nativesTeleported = false
nativesIsolated = false
hogDeployed = false

cyborgHidden = false
needToAct = 0

m2Choice = 0
m4DenseDead = 0
m4BuffaloDead = 0
m4WaterDead = 0
m4ChiefDead = 0
m4LeaksDead = 0

needRevival = false
gearr = nil
startElimination = 0
stage = 0
choice = 0
highJumped = false
TurnsLeft = 0
startNativesNum = 0
nativesTeamName = nil
tribeTeamName = nil
cyborgTeamName = nil
cannibalsTeamName1 = nil
cannibalsTeamName2 = nil
runawayX, runawayY = 1932, 829

startAnim = {}
afterChoiceAnim = {}
wave2Anim = {}
wave2DeadAnim = {}
wave3DeadAnim = {}

vCircs = {}

trackedMines = {}
-----------------------------Animations--------------------------------
function Wave2Reaction()
  local i = 1
  local gearr = nil
  while nativeDead[i] == true do
    i = i + 1
  end
  gearr = natives[i]
  if nativeDead[denseNum] ~= true and band(GetState(natives[denseNum]), gstDrowning) == 0 then
    AnimInsertStepNext({func = AnimCustomFunction, args = {dense, EmitDenseClouds, {"Left"}}})
    AnimInsertStepNext({func = AnimTurn, args = {dense, "Left"}})
  end
  if nativeDead[buffaloNum] ~= true and band(GetState(natives[buffaloNum]), gstDrowning) == 0 then
    AnimInsertStepNext({func = AnimSay, args = {natives[buffaloNum], loc("Let them have a taste of my fury!"), SAY_SHOUT, 6000}}) 
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
  AnimInsertStepNext({func = AnimVisualGear, args = {natives[denseNum], GetX(natives[denseNum]) + dif, GetY(natives[denseNum]) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimVisualGear, args = {natives[denseNum], GetX(natives[denseNum]) + dif, GetY(natives[denseNum]) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimVisualGear, args = {natives[denseNum], GetX(natives[denseNum]) + dif, GetY(natives[denseNum]) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimWait, args = {natives[denseNum], 800}})
  AnimInsertStepNext({func = AnimVisualGear, args = {natives[denseNum], GetX(natives[denseNum]) + dif, GetY(natives[denseNum]) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimVisualGear, args = {natives[denseNum], GetX(natives[denseNum]) + dif, GetY(natives[denseNum]) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimWait, args = {natives[denseNum], 800}})
  AnimInsertStepNext({func = AnimVisualGear, args = {natives[denseNum], GetX(natives[denseNum]) + dif, GetY(natives[denseNum]) + dif, vgtSteam, 0, true}, swh = false})
end

function SaySafe()
  local i = 1
  while gearr == nil do
    if nativeDead[i] ~= true and nativeHidden[i] ~= true then
      gearr = natives[i]
    end
    i = i + 1
  end
  AnimInsertStepNext({func = AnimSay, args = {natives[wiseNum], loc("We are indeed."), SAY_SAY, 2500}})
  AnimInsertStepNext({func = AnimSay, args = {gearr, loc("I think we are safe here."), SAY_SAY, 4000}})
end

function ReviveNatives()
  for i = 1, 7 do
    if nativeHidden[i] == true and nativeDead[i] ~= true then
      RestoreHog(natives[i])
      nativeHidden[i] = false
      nativeRevived[i] = true
      AnimInsertStepNext({func = AnimOutOfNowhere, args = {natives[i], unpack(nativePos[i])}})
    end
  end
end

function WonderAlive()
  if nativeRevived[waterNum] == true then
    AnimInsertStepNext({func = AnimSay, args = {natives[waterNum], loc("I'm...alive? How? Why?"), SAY_THINK, 3500}})
    AnimInsertStepNext({func = AnimWait, args = {natives[waterNum], 800}})
    AnimInsertStepNext({func = AnimTurn, args = {natives[waterNum], "Left"}})
    AnimInsertStepNext({func = AnimWait, args = {natives[waterNum], 800}})
    AnimInsertStepNext({func = AnimTurn, args = {natives[waterNum], "Right"}})
  end
  if nativeRevived[leaksNum] == true and nativeRevived[denseNum] == true then
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("But why would they help us?"), SAY_SAY, 4000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("It must be the aliens!"), SAY_SAY, 3500}})
    AnimInsertStepNext({func = AnimSay, args = {natives[girlNum], loc("You just appeared out of thin air!"), SAY_SAY, 5000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("But...we died!"), SAY_SAY, 2500}})
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("This must be the caves!"), SAY_SAY, 3500}})
    AnimInsertStepNext({func = AnimSay, args = {natives[denseNum], loc("Dude, where are we?"), SAY_SAY, 3000}})
    AnimInsertStepNext({func = AnimWait, args = {natives[leaksNum], 800}})
    AnimInsertStepNext({func = AnimTurn, args = {natives[leaksNum], "Right"}})
    AnimInsertStepNext({func = AnimTurn, args = {natives[denseNum], "Left"}})
    AnimInsertStepNext({func = AnimWait, args = {natives[leaksNum], 800}})
    AnimInsertStepNext({func = AnimTurn, args = {natives[leaksNum], "Left"}})
    AnimInsertStepNext({func = AnimTurn, args = {natives[denseNum], "Right"}})
    AnimInsertStepNext({func = AnimWait, args = {natives[leaksNum], 800}})
    AnimInsertStepNext({func = AnimTurn, args = {natives[leaksNum], "Right"}})
    AnimInsertStepNext({func = AnimTurn, args = {natives[denseNum], "Left"}})
    AnimInsertStepNext({func = AnimWait, args = {natives[leaksNum], 800}})
    AnimInsertStepNext({func = AnimTurn, args = {natives[leaksNum], "Left"}})
    AnimInsertStepNext({func = AnimTurn, args = {natives[denseNum], "Right"}})
    AnimInsertStepNext({func = AnimCustomFunction, swh = false, args = {natives[leaksNum], CondNeedToTurn, {natives[leaksNum], natives[girlNum]}}})
    if nativeDead[chiefNum] ~= true then
      AnimInsertStepNext({func = AnimTurn, args = {natives[chiefNum], "Right"}})
    end
  elseif nativeRevived[leaksNum] == true then
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("Why would they do this?"), SAY_SAY, 6000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[wiseNum], loc("It must be the aliens' deed."), SAY_SAY, 5000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[wiseNum], loc("Do not laugh, inexperienced one, for he speaks the truth!"), SAY_SAY, 10000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("Yeah, sure! I died. Hilarious!"), SAY_SAY, 6000}})
    AnimInsertStepNext({func = AnimSay, args = {gearr, loc("You're...alive!? But we saw you die!"), SAY_SAY, 6000}})
    AnimInsertStepNext({func = AnimSay, args = {gearr, loc("Huh?"), SAY_SAY, 2000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("Wow, what a dream!"), SAY_SAY, 3000}})
    if nativeDead[chiefNum] ~= true then
      AnimInsertStepNext({func = AnimTurn, args = {natives[chiefNum], "Right"}})
    end
    AnimInsertStepNext({func = AnimCustomFunction, swh = false, args = {natives[leaksNum], CondNeedToTurn, {natives[leaksNum], natives[wiseNum]}}})
    AnimInsertStepNext({func = AnimCustomFunction, swh = false, args = {natives[leaksNum], CondNeedToTurn, {natives[leaksNum], gearr}}})
  elseif nativeRevived[denseNum] == true then
    AnimInsertStepNext({func = AnimSay, args = {natives[denseNum], loc("Dude, that's so cool!"), SAY_SAY, 3000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[wiseNum], loc("It must be the aliens' deed."), SAY_SAY, 5000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[denseNum], loc("But that's impossible!"), SAY_SAY, 3000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[wiseNum], loc("It was not a dream, unwise one!"), SAY_SAY, 5000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[denseNum], loc("Exactly, man! That was my dream."), SAY_SAY, 5000}})
    AnimInsertStepNext({func = AnimSay, args = {gearr, loc("You're...alive!? But we saw you die!"), SAY_SAY,  6000}})
    AnimInsertStepNext({func = AnimSay, args = {gearr, loc("Huh?"), SAY_SAY, 2000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[denseNum], loc("Dude, wow! I just had the weirdest high!"), SAY_SAY, 6000}})
    if nativeDead[chiefNum] ~= true then
      AnimInsertStepNext({func = AnimTurn, args = {natives[chiefNum], "Right"}})
    end
    AnimInsertStepNext({func = AnimCustomFunction, swh = false, args = {natives[denseNum], CondNeedToTurn, {natives[denseNum], natives[wiseNum]}}})
    AnimInsertStepNext({func = AnimCustomFunction, swh = false, args = {natives[denseNum], CondNeedToTurn, {natives[denseNum], gearr}}})
  end
end

function ExplainAlive()
  if needRevival == true and m4WaterDead == 1 then
    RestoreCyborg()
    AnimSetGearPosition(cyborg, unpack(cyborgPos))
    AnimInsertStepNext({func = AnimCustomFunction, args = {water, HideCyborg, {}}})
    AnimInsertStepNext({func = AnimSwitchHog, args = {water}})
    AnimInsertStepNext({func = AnimSay, args = {cyborg, loc("The answer is ... entertainment. You'll see what I mean."), SAY_SAY, 8000}})
    AnimInsertStepNext({func = AnimSay, args = {cyborg, loc("You're probably wondering why I brought you back ..."), SAY_SAY, 8000}})
  end
end

function SpyDebate()
  if m2Choice == choiceAccepted then
    spyHog = natives[denseNum]
    AnimInsertStepNext({func = AnimSay, args = {natives[wiseNum], loc("What shall we do with the traitor?"), SAY_SAY, 6000}})
    AnimInsertStepNext({func = SetHealth, swh = false, args = {natives[denseNum], 26}})
    AnimInsertStepNext({func = AnimVisualGear, args = {natives[wiseNum], GetGearPosition(natives[denseNum]), vgtExplosion, 0, true}})
    AnimInsertStepNext({func = AnimSay, args = {natives[wiseNum], loc("Here, let me help you!"), SAY_SAY, 3000}})
    if nativeDead[chiefNum] == true then
      AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("I forgot that she's the daughter of the chief, too..."), SAY_THINK, 7000}})
      AnimInsertStepNext({func = AnimSay, args = {natives[girlNum], loc("You killed my father, you monster!"), SAY_SAY, 5000}})
    end
    AnimInsertStepNext({func = AnimSay, args = {natives[denseNum], loc("Look, I had no choice!"), SAY_SAY, 3000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("You have been giving us out to the enemy, haven't you!"), SAY_SAY, 7000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("You're a pathetic liar!"), SAY_SAY, 3000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("Interesting! Last time you said you killed a cannibal!"), SAY_SAY, 7000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[denseNum], loc("I told you, I just found them."), SAY_SAY, 4500}})
    AnimInsertStepNext({func = AnimCustomFunction, args = {natives[denseNum], EmitDenseClouds, {"Left"}}})
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("Where did you get the weapons in the forest, Dense Cloud?"), SAY_SAY, 8000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("Not now, Fiery Water!"), SAY_SAY, 3000}})
  else
    spyHog = natives[waterNum]
    AnimInsertStepNext({func = AnimSay, args = {natives[wiseNum], loc("What shall we do with the traitor?"), SAY_SAY, 5000}})
    AnimInsertStepNext({func = SetHealth, swh = false, args = {natives[waterNum], 26}})
    AnimInsertStepNext({func = AnimVisualGear, args = {natives[wiseNum], nativePos[denseNum][1] + 50, nativePos[denseNum][2], vgtExplosion, 0, true}})
    AnimInsertStepNext({func = AnimSay, args = {natives[girlNum], loc("I can't believe what I'm hearing!"), SAY_SAY, 5500}})
    AnimInsertStepNext({func = AnimSay, args = {natives[waterNum], loc("You know what? I don't even regret anything!"), SAY_SAY, 7000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[girlNum], loc("In fact, you are the only one that's been acting strangely."), SAY_SAY, 8000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[waterNum], loc("Are you accusing me of something?"), SAY_SAY, 3500}})
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("Seems like every time you take a \"walk\", the enemy finds us!"), SAY_SAY, 8000}})
    AnimInsertStepNext({func = AnimSay, args = {natives[waterNum], loc("You know...taking a stroll."), SAY_SAY, 3500}})
    AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("Where have you been?!"), SAY_SAY, 3000}})
  end
  if nativeRevived[waterNum] == true then
    AnimInsertStepNext({func = AnimSay, args = {natives[waterNum], loc("You won't believe what happened to me!"), SAY_SAY, 5500}})
  end
  AnimInsertStepNext({func = AnimSay, args = {natives[waterNum], loc("Hey, guys!"), SAY_SAY, 2000}})
  AnimInsertStepNext({func = AnimMove, args = {natives[waterNum], "Left", nativePos[denseNum][1] + 50, nativePos[denseNum][2]}})
  AnimInsertStepNext({func = AnimJump, args = {natives[waterNum], "back"}})
  AnimInsertStepNext({func = AnimTurn, args = {natives[waterNum], "Right"}})
  AnimInsertStepNext({func = AnimMove, args = {natives[waterNum], "Left", 1228, 412}})
  AnimInsertStepNext({func = AnimJump, args = {natives[waterNum], "long"}})
  AnimInsertStepNext({func = AnimJump, args = {natives[waterNum], "long"}})
  AnimInsertStepNext({func = AnimJump, args = {natives[waterNum], "long"}})
  AnimInsertStepNext({func = AnimTurn, args = {natives[waterNum], "Left"}})
  AnimInsertStepNext({func = AnimSay, args = {natives[wiseNum], loc("There must be a spy among us!"), SAY_SAY, 4000}})
  AnimInsertStepNext({func = AnimSay, args = {natives[girlNum], loc("We made sure noone followed us!"), SAY_SAY, 4000}})
  AnimInsertStepNext({func = AnimSay, args = {natives[leaksNum], loc("What? Here? How did they find us?!"), SAY_SAY, 5000}})
end

function AnimationSetup()
  table.insert(startAnim, {func = AnimWait, swh = false, args = {natives[leaksNum], 3000}})
  table.insert(startAnim, {func = AnimCustomFunction, swh = false, args = {natives[leaksNum], SaySafe, {}}})
  if needRevival == true then
    table.insert(startAnim, {func = AnimCustomFunction, swh = false, args = {cyborg, ReviveNatives, {}}})
    table.insert(startAnim, {func = AnimCustomFunction, swh = false, args = {natives[leaksNum], WonderAlive, {}}})
    table.insert(startAnim, {func = AnimCustomFunction, swh = false, args = {cyborg, ExplainAlive, {}}})
  end
  table.insert(startAnim, {func = AnimCustomFunction, swh = false, args = {natives[leaksNum], RestoreWave, {1}}})
  table.insert(startAnim, {func = AnimOutOfNowhere, args = {cannibals[1], unpack(cannibalPos[1])}})
  table.insert(startAnim, {func = AnimOutOfNowhere, args = {cannibals[2], unpack(cannibalPos[2])}})
  table.insert(startAnim, {func = AnimOutOfNowhere, args = {cannibals[3], unpack(cannibalPos[3])}})
  table.insert(startAnim, {func = AnimWait, args = {natives[leaksNum], 1000}})
  table.insert(startAnim, {func = AnimCustomFunction, swh = false, args = {natives[leaksNum], SpyDebate, {}}})
  AddSkipFunction(startAnim, SkipStartAnim, {})
end

function SetupWave2Anim()
  for i = 7, 1, -1 do
    if nativeDead[i] ~= true then
      speakerHog = natives[i]
    end
  end
  table.insert(wave2Anim, {func = AnimOutOfNowhere, args = {cannibals[4], unpack(cannibalPos[4])}})
  table.insert(wave2Anim, {func = AnimOutOfNowhere, args = {cannibals[5], unpack(cannibalPos[5])}})
  table.insert(wave2Anim, {func = AnimOutOfNowhere, args = {cannibals[6], unpack(cannibalPos[6])}})
  table.insert(wave2Anim, {func = AnimSay, args = {speakerHog, loc("Look out! There's more of them!"), SAY_SHOUT, 5000}})
  AddSkipFunction(wave2Anim, SkipWave2Anim, {})
end

function PutCircles()
  if circlesPut then
    return
  end
  vCircs[1] = AddVisualGear(0,0,vgtCircle,0,true)
  vCircs[2] = AddVisualGear(0,0,vgtCircle,0,true)
  vCircs[3] = AddVisualGear(0,0,vgtCircle,0,true)
  SetVisualGearValues(vCircs[1], cannibalPos[7][1], cannibalPos[7][2], 100, 255, 1, 10, 0, 120, 3, 0xff00ffff)
  SetVisualGearValues(vCircs[2], cannibalPos[8][1], cannibalPos[8][2], 100, 255, 1, 10, 0, 120, 3, 0xff00ffff)
  SetVisualGearValues(vCircs[3], cannibalPos[9][1], cannibalPos[9][2], 100, 255, 1, 10, 0, 120, 3, 0xff00ffff)
  circlesPut = true
end

function DeleteCircles()
  for i=1, #vCircs do
    DeleteVisualGear(vCircs[i])
  end
end

function SetupWave2DeadAnim()
  for i = 7, 1, -1 do
    if nativeDead[i] ~= true then
      deployedHog = natives[i]
    end
  end
  if nativeDead[wiseNum] ~= true and band(GetState(natives[wiseNum]), gstDrowning) == 0 then
    if nativesNum > 1 then
      table.insert(wave2DeadAnim, {func = AnimWait, args = {natives[wiseNum], 1500}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("What a strange feeling!"), SAY_THINK, 3000}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("I need to warn the others."), SAY_THINK, 3000}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("If only I had a way..."), SAY_THINK, 3000}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("Oh, silly me! I forgot that I'm the shaman."), SAY_THINK, 6000}})
      table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {natives[wiseNum], TeleportNatives, {}}})
      table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {natives[wiseNum], TurnNatives, {natives[wiseNum]}}})
      table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {natives[wiseNum], CondNeedToTurn, {natives[wiseNum], deployedHog}}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("I sense another wave of cannibals heading our way!"), SAY_SAY, 6500}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("I feel something...a place! They will arrive near the circles!"), SAY_SAY, 7500}})
      table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {natives[wiseNum], PutCircles, {}}})
      table.insert(wave2DeadAnim, {func = AnimWait, args = {natives[wiseNum], 1500}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("We need to prevent their arrival!"), SAY_SAY, 4500}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("Go, quick!"), SAY_SAY, 2500}})
      table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {natives[wiseNum], DeployHog, {}}})
      table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {natives[wiseNum], RestoreCyborg, {}}})
      table.insert(wave2DeadAnim, {func = AnimOutOfNowhere, swh = false, args = {cyborg, cyborgPos2[1], cyborgPos2[2]}})
      table.insert(wave2DeadAnim, {func = AnimTurn, args = {cyborg, "Left"}})
      if nativesNum > 1 then
        table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {cyborg, IsolateNatives, {}}})
        table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {cyborg, PutCGI, {}}})
        table.insert(wave2DeadAnim, {func = AnimSay, args = {cyborg, loc("I want to see how it handles this!"), SAY_SAY, 6000}})
      end
      table.insert(wave2DeadAnim, {func = AnimSwitchHog, args = {deployedHog}})
      table.insert(wave2DeadAnim, {func = AnimDisappear, args = {cyborg, 0, 0}})
--      table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {cyborg, DeployHog, {}}})
      table.insert(wave2DeadAnim, {func = AnimCustomFunction, swh = false, args = {cyborg, HideCyborg, {}}})
    else
      table.insert(wave2DeadAnim, {func = AnimWait, args = {natives[wiseNum], 1500}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("What a strange feeling!"), SAY_THINK, 3000}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("I sense another wave of cannibals heading my way!"), SAY_THINK, 6500}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("I feel something...a place! They will arrive near the circles!"), SAY_SAY, 7500}})
      table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {natives[wiseNum], PutCircles, {}}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("I need to prevent their arrival!"), SAY_THINK, 4500}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("If only I had a way..."), SAY_THINK, 3000}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {natives[wiseNum], loc("Oh, silly me! I forgot that I'm the shaman."), SAY_THINK, 6000}})
    end
  else
    table.insert(wave2DeadAnim, {func = AnimWait, args = {cyborg, 1500}})
    table.insert(wave2DeadAnim, {func = AnimCustomFunction, swh = false, args = {cyborg, RestoreCyborg, {}}})
    table.insert(wave2DeadAnim, {func = AnimOutOfNowhere, args = {cyborg, cyborgPos2[1], cyborgPos2[2]}})
    table.insert(wave2DeadAnim, {func = AnimTurn, args = {cyborg, "Left"}})
    table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {cyborg, TeleportNatives, {}}})
    table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {cyborg, TurnNatives, {cyborg}}})
    table.insert(wave2DeadAnim, {func = AnimSay, args = {cyborg, loc("Oh, my! This is even more entertaining than I've expected!"), SAY_SAY, 7500}})
    table.insert(wave2DeadAnim, {func = AnimSay, args = {cyborg, loc("You might want to find a way to instantly kill arriving cannibals!"), SAY_SAY, 8000}})
    table.insert(wave2DeadAnim, {func = AnimSay, args = {cyborg, loc("I believe there's more of them."), SAY_SAY, 4000}})
    table.insert(wave2DeadAnim, {func = AnimSay, args = {cyborg, loc("I marked the place of their arrival. You're welcome!"), SAY_SAY, 6000}})
    table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {natives[wiseNum], PutCircles, {}}})
    table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {deployedHog, DeployHog, {}}})
    if nativesNum > 1 then
--      table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {natives[wiseNum], RestoreCyborg, {}}})
--      table.insert(wave2DeadAnim, {func = AnimOutOfNowhere, swh = false, args = {cyborg, cyborgPos2[1], cyborgPos2[2]}})
--      table.insert(wave2DeadAnim, {func = AnimTurn, args = {cyborg, "Left"}})
      table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {cyborg, IsolateNatives, {}}})
      table.insert(wave2DeadAnim, {func = AnimCustomFunction, args = {cyborg, PutCGI, {}}})
      table.insert(wave2DeadAnim, {func = AnimSay, args = {cyborg, loc("I want to see how it handles this!"), SAY_SAY, 6000}})
    end
    table.insert(wave2DeadAnim, {func = AnimSwitchHog, args = {deployedHog}})
    table.insert(wave2DeadAnim, {func = AnimDisappear, swh = false, args = {cyborg, 0, 0}})
    table.insert(wave2DeadAnim, {func = AnimCustomFunction, swh = false, args = {cyborg, HideCyborg, {}}})
  end
  AddSkipFunction(wave2DeadAnim, SkipWave2DeadAnim, {})
end

function IsolateNatives()
  if not nativesIsolated then
    PlaceGirder(710, 299, 6)
    PlaceGirder(690, 299, 6)
    PlaceGirder(761, 209, 4)
    PlaceGirder(921, 209, 4)
    PlaceGirder(1081, 209, 4)
    PlaceGirder(761, 189, 4)
    PlaceGirder(921, 189, 4)
    PlaceGirder(1081, 189, 4)
    PlaceGirder(761, 169, 4)
    PlaceGirder(921, 169, 4)
    PlaceGirder(1081, 169, 4)
    PlaceGirder(761, 149, 4)
    PlaceGirder(921, 149, 4)
    PlaceGirder(1081, 149, 4)
    PlaceGirder(761, 129, 4)
    PlaceGirder(921, 129, 4)
    PlaceGirder(1081, 129, 4)
    PlaceGirder(1120, 261, 2)
    PlaceGirder(1140, 261, 2)
    PlaceGirder(1160, 261, 2)
    AddAmmo(deployedHog, amDEagle, 0)
    AddAmmo(deployedHog, amFirePunch, 0)
    nativesIsolated = true
  end
end

function PutCGI()
  AddVisualGear(710, 299, vgtExplosion, 0, false)
  AddVisualGear(690, 299, vgtExplosion, 0, false)
  AddVisualGear(761, 209, vgtExplosion, 0, false)
  AddVisualGear(921, 209, vgtExplosion, 0, false)
  AddVisualGear(1081, 209, vgtExplosion, 0, false)
  AddVisualGear(761, 189, vgtExplosion, 0, false)
  AddVisualGear(921, 189, vgtExplosion, 0, false)
  AddVisualGear(1081, 189, vgtExplosion, 0, false)
  AddVisualGear(761, 169, vgtExplosion, 0, false)
  AddVisualGear(921, 169, vgtExplosion, 0, false)
  AddVisualGear(1081, 169, vgtExplosion, 0, false)
  AddVisualGear(761, 149, vgtExplosion, 0, false)
  AddVisualGear(921, 149, vgtExplosion, 0, false)
  AddVisualGear(1081, 149, vgtExplosion, 0, false)
  AddVisualGear(761, 129, vgtExplosion, 0, false)
  AddVisualGear(921, 129, vgtExplosion, 0, false)
  AddVisualGear(1081, 129, vgtExplosion, 0, false)
  AddVisualGear(1120, 261, vgtExplosion, 0, false)
  AddVisualGear(1140, 261, vgtExplosion, 0, false)
  AddVisualGear(1160, 261, vgtExplosion, 0, false)
end

function TeleportNatives()
  if not nativesTeleported then
     nativePos[waterNum] = {1100, 288}
     for i = 1, 7 do
       if nativeDead[i] ~= true then 
         AnimTeleportGear(natives[i], unpack(nativePos[i]))
       end
     end
     nativesTeleported = true
  end
end

function TurnNatives(hog)
  for i = 1, 7 do
    if nativeDead[i] == false then
      if GetX(natives[i]) < GetX(hog) then
        AnimTurn(natives[i], "Right")
      else
        AnimTurn(natives[i], "Left")
      end
    end
  end
end

function DeployHog()
  if not hogDeployed then
     -- Steal switch to force the deployed hog to be on its own
     AddAmmo(deployedHog, amSwitch, 0)
     AnimSwitchHog(deployedHog)
     AnimTeleportGear(deployedHog, unpack(deployedPos))
     if deployedHog ~= natives[wiseNum] then
        AnimSay(deployedHog, loc("Why me?!"), SAY_THINK, 2000)
     end
     hogDeployed = true
  end
end

function SetupAfterChoiceAnim()
  for i = 7, 1, -1 do
    if nativeDead[i] ~= true then
      if natives[i] ~= spyHog then
        speakerHog = natives[i]
      end
    end
  end
  if choice == choiceEliminate then
    table.insert(afterChoiceAnim, {func = AnimWait, args = {speakerHog, 1500}})
    table.insert(afterChoiceAnim, {func = AnimSay, args = {speakerHog, loc("He won't be selling us out anymore!"), SAY_SAY, 6000}})
    if nativeDead[girlNum] ~= true and m4ChiefDead == 1 then
      table.insert(afterChoiceAnim, {func = AnimSay, args = {natives[girlNum], loc("That's for my father!"), SAY_SAY, 3500}})
    end
    table.insert(afterChoiceAnim, {func = AnimSay, args = {speakerHog, loc("Let's show those cannibals what we're made of!"), SAY_SAY, 7000}})
  else
    table.insert(afterChoiceAnim, {func = AnimCustomFunction, swh = false, args = {natives[leaksNum], CondNeedToTurn, {speakerHog, spyHog}}})
    table.insert(afterChoiceAnim, {func = AnimSay, args = {speakerHog, loc("We'll spare your life for now!"), SAY_SAY, 4500}})
    table.insert(afterChoiceAnim, {func = AnimSay, args = {spyHog, loc("May the spirits aid you in all your quests!"), SAY_SAY, 7000}})
    table.insert(afterChoiceAnim, {func = AnimSay, args = {speakerHog, loc("I just don't want to sink to your level."), SAY_SAY, 6000}})
    table.insert(afterChoiceAnim, {func = AnimSay, args = {speakerHog, loc("Let's show those cannibals what we're made of!"), SAY_SAY, 7000}})
  end
  table.insert(afterChoiceAnim, {func = AnimSay, args = {natives[8], loc("Let us help, too!"), SAY_SAY, 3000}})
  table.insert(afterChoiceAnim, {func = AnimTurn, args = {speakerHog, "Left", SAY_SAY, 7000}})
  table.insert(afterChoiceAnim, {func = AnimSay, args = {speakerHog, loc("No. You and the rest of the tribe are safer there!"), SAY_SAY, 7000}})
  AddSkipFunction(afterChoiceAnim, SkipAfterChoiceAnim, {})
end

function SetupHogDeadAnim(gear)
  hogDeadAnim = {}
  if nativesNum == 0 then
    return
  end
  local hogDeadStrings = {string.format(loc("They killed %s! You bastards!"), gear),
                          string.format(loc("%s! Why?!"), gear), 
                          loc("That was just mean!"), 
                          string.format(loc("Oh no, not %s!"), gear),
                          string.format(loc("Why %s? Why?"), gear),
                          string.format(loc("What has %s ever done to you?"), gear)}
  table.insert(hogDeadAnim, {func = AnimSay, args = {CurrentHedgehog, hogDeadStrings[7 - nativesNum], SAY_SHOUT, 4000}})
end

function AfterHogDeadAnim()
  freshDead = nil
  SetTurnTimeLeft(TurnTime)
end

--------------------------Anim skip functions--------------------------

function AfterAfterChoiceAnim()
  stage = 0
  AddEvent(CheckWaveDead, {1}, DoWaveDead, {1}, 0)
  AddAmmo(speakerHog, amSwitch, 100)
  SetGearMessage(speakerHog, 0)
  SetState(speakerHog, 0)
  SetTurnTimeLeft(MAX_TURN_TIME)
  ShowMission(loc("Backstab"), loc("The food bites back"), loc("Defeat the cannibals!"), 1, 4000)
  SetAmmoDelay(amBlowTorch, 0)
  SetAmmoDelay(amGirder, 0)
  SetAmmoDelay(amLandGun, 0)
  SetAmmoDelay(amRope, 0)
  SetAmmoDelay(amParachute, 0)
  SpawnCrates()
end

function SkipAfterChoiceAnim()
  SetGearMessage(CurrentHedgehog, 0)
  AnimSwitchHog(speakerHog)
end

function AfterWave2Anim()
  AddEvent(CheckWaveDead, {2}, DoWaveDead, {2}, 0)
  SetGearMessage(CurrentHedgehog, 0)
  SetState(CurrentHedgehog, 0)
  SpawnCrates()
  SetTurnTimeLeft(TurnTime)
end

function SkipWave2DeadAnim()
  TeleportNatives()
  TurnNatives()
  PutCircles()
  DeployHog()
  if nativesNum > 1 then
    IsolateNatives()
  end
end

function SpawnPlatformCrates()
  SpawnSupplyCrate(2494, 1262, amMine)
  SpawnSupplyCrate(2574, 1279, amSMine)
  SpawnSupplyCrate(2575, 1267, amMine)
  SpawnSupplyCrate(2617, 1259, amSMine)
  SpawnSupplyCrate(2579, 1254, amMine)
  SpawnSupplyCrate(2478, 1243, amMine)
end

function AfterWave2DeadAnim()
  TurnsLeft = 7
  stage = platformStage
  SpawnPlatformCrates()
  SetGearMessage(CurrentHedgehog, 0)
  AddEvent(CheckTurnsOver, {}, DoTurnsOver, {3}, 0)
  AddEvent(CheckWaveDead, {3}, DoWaveDead, {3}, 0)
  AddEvent(CheckDeployedDead, {}, DoDeployedDead, {}, 0)
  HideCyborg()
  EndTurn(true)
  ShowMission(loc("Backstab"), loc("Drills"), loc("You have 7 turns until the next wave arrives.|Make sure the arriving cannibals are greeted appropriately!|If the hog dies, the cause is lost.|Hint: You might want to use some mines ..."), 1, 12000)
end

function DoTurnsOver()
  stage = wave3Stage
  RestoreWave(3)
  DeleteCircles()
end

function SkipWave2Anim()
  AnimSwitchHog(speakerHog)
end

function SkipStartAnim()
  ReviveNatives()
  AnimSetGearPosition(natives[waterNum], nativePos[denseNum][1] + 50, nativePos[denseNum][2])
  RestoreWave(1)
  SetGearMessage(CurrentHedgehog, 0)
  SetState(CurrentHedgehog, 0)
  if m2Choice == choiceAccepted then
    spyHog = natives[denseNum]
  else
    spyHog = natives[waterNum]
  end
  SetHealth(spyHog, 26)
end

function AfterStartAnim()
  AnimSwitchHog(natives[leaksNum])
  stage = spyKillStage
  AddEvent(CheckChoice, {}, DoChoice, {}, 0)
  AddEvent(CheckKilledOther, {}, DoKilledOther, {}, 0)
  AddEvent(CheckChoiceRefuse, {}, DoChoiceRefuse, {}, 0)
  AddEvent(CheckChoiceRunaway, {}, DoChoiceRefuse, {}, 0)
  ShowMission(loc("Backstab"), loc("Judas"),
    string.format(loc("Kill the traitor, %s, or spare his life!"), GetHogName(spyHog)) .. "|" ..
    loc("Kill him or skip your turn."),
    1, 8000)
end

-----------------------------Events------------------------------------
function CheckTurnsOver()
  return TurnsLeft == 0
end

function CheckDeployedDead()
  return deployedDead
end

function DoDeployedDead()
  ShowMission(loc("Backstab"), loc("Brutus"), loc("You have failed to save the tribe!"), 0, 6000)
  DismissTeam(nativesTeamName)
  DismissTeam(tribeTeamName)
  DismissTeam(cyborgTeamName)
  EndTurn(true)
end

function CheckChoice()
  return choice ~= 0 and tmpVar == 0
end

function CheckDeaths()
  for i = 1, 7 do
    if natives[i] ~= spyHog and band(GetState(natives[i]), gstAttacked) ~= 0 then
      return true
    end
  end
  return false
end

function DoChoice()
  RemoveEventFunc(CheckChoiceRefuse)
  RemoveEventFunc(CheckChoiceRunaway)
  SetGearMessage(CurrentHedgehog, 0)
  SetupAfterChoiceAnim()
  AddAnim(afterChoiceAnim)
  AddFunction({func = AfterAfterChoiceAnim, args = {}})
end

function CheckChoiceRefuse()
  return highJumped == true and StoppedGear(CurrentHedgehog)
end

function CheckChoiceRunaway()
  return CurrentHedgehog and band(GetState(CurrentHedgehog), gstHHDriven) ~= 0 and GetHogTeamName(CurrentHedgehog) == nativesTeamName and GetX(CurrentHedgehog) >= runawayX and GetY(CurrentHedgehog) >= runawayY and StoppedGear(CurrentHedgehog)
end

function CheckChoiceRunawayAll()
  for i= 1, 7 do
    local hog = natives[i]
    if hog ~= nil and GetHealth(hog) and hog ~= spyHog and GetX(hog) >= runawayX and GetY(hog) >= runawayY and StoppedGear(hog) then
      return true
    end
  end
  return false
end

function DoChoiceRefuse()
  choice = choiceSpare
end

function CheckKilledOther()
  if stage ~= spyKillStage then
    return false
  end
  return (nativesNum < startNativesNum and choice ~= choiceEliminate) or
          (nativesNum < startNativesNum - 1 and choice == choiceEliminate)
end

function DoKilledOther()
  ShowMission(loc("Backstab"), loc("Brutus"), loc("You have killed an innocent hedgehog!"), 0, 6000)
  DismissTeam(nativesTeamName)
  DismissTeam(tribeTeamName)
  EndTurn(true)
end

function CheckWaveDead(index)
  for i = (index - 1) * 3 + 1, index * 3 do
    if cannibalDead[i] ~= true or CurrentHedgehog == cannibals[i] then
      return false
    end
  end
  return true
end

function DoWaveDead(index)
  EndTurn(true)
  needToAct = index
end

function AddWave3DeadAnim()
  AnimSwitchHog(deployedHog)
  AnimWait(deployedHog, 1)
  AddFunction({func = HideNatives, args = {}})
  AddFunction({func = SetupWave3DeadAnim, args = {}})
  AddFunction({func = AddAnim, args = {wave3DeadAnim}})
  AddFunction({func = AddFunction, args = {{func = AfterWave3DeadAnim, args = {}}}})
end

function HideNatives()
  for i = 1, 9 do
    if nativeDead[i] ~= true and natives[i] ~= deployedHog then
      if nativeHidden[i] ~= true then
        HideHog(natives[i])
        nativeHidden[i] = true
      end
    end
  end
end

function SetupWave3DeadAnim()
  table.insert(wave3DeadAnim, {func = AnimTurn, args = {deployedHog, "Left"}})
  table.insert(wave3DeadAnim, {func = AnimSay, args = {deployedHog, loc("That ought to show them!"), SAY_SAY, 4000}})
  table.insert(wave3DeadAnim, {func = AnimSay, args = {deployedHog, loc("Guys, do you think there's more of them?"), SAY_SHOUT, 7000}})
  table.insert(wave3DeadAnim, {func = AnimVisualGear, args = {deployedHog, unpack(nativePos[wiseNum]), vgtFeather, 0, true, true}})
  table.insert(wave3DeadAnim, {func = AnimWait, args = {deployedHog, 1000}})
  table.insert(wave3DeadAnim, {func = AnimSay, args = {deployedHog, loc("Where are they?!"), SAY_THINK, 3000}})
  table.insert(wave3DeadAnim, {func = AnimCustomFunction, args = {deployedHog, RestoreCyborg, {}}})
  table.insert(wave3DeadAnim, {func = AnimOutOfNowhere, args = {cyborg, 4040, 782}})
  table.insert(wave3DeadAnim, {func = AnimSay, args = {cyborg, loc("These primitive people are so funny!"), SAY_THINK, 6500}})
  table.insert(wave3DeadAnim, {func = AnimMove, args = {cyborg, "Right", 4060, 0, 7000}})
  table.insert(wave3DeadAnim, {func = AnimSwitchHog, args = {deployedHog}})
  table.insert(wave3DeadAnim, {func = AnimWait, args = {deployedHog, 1}})
  table.insert(wave3DeadAnim, {func = AnimCustomFunction, args = {deployedHog, HideCyborg, {}}})
  table.insert(wave3DeadAnim, {func = AnimSay, args = {deployedHog, loc("I need to find the others!"), SAY_THINK, 4500}})
  table.insert(wave3DeadAnim, {func = AnimSay, args = {deployedHog, loc("I have to follow that alien."), SAY_THINK, 4500}})
end

function SkipWave3DeadAnim()
  AnimSwitchHog(deployedHog)
end

function AfterWave3DeadAnim()
  if nativeDead[leaksNum] == true then
    SaveCampaignVar("M5LeaksDead", "1")
  else
    SaveCampaignVar("M5LeaksDead", "0")
  end
  if nativeDead[denseNum] == true then
    SaveCampaignVar("M5DenseDead", "1")
  else
    SaveCampaignVar("M5DenseDead", "0")
  end
  if nativeDead[waterNum] == true then
    SaveCampaignVar("M5WaterDead", "1")
  else
    SaveCampaignVar("M5WaterDead", "0")
  end
  if nativeDead[buffaloNum] == true then
    SaveCampaignVar("M5BuffaloDead", "1")
  else
    SaveCampaignVar("M5BuffaloDead", "0")
  end
  if nativeDead[girlNum] == true then
    SaveCampaignVar("M5GirlDead", "1")
  else
    SaveCampaignVar("M5GirlDead", "0")
  end
  if nativeDead[wiseNum] == true then
    SaveCampaignVar("M5WiseDead", "1")
  else
    SaveCampaignVar("M5WiseDead", "0")
  end
  if nativeDead[chiefNum] == true then
    SaveCampaignVar("M5ChiefDead", "1")
  else
    SaveCampaignVar("M5ChiefDead", "0")
  end
  SaveCampaignVar("M5Choice", "" .. choice)
  if progress and progress<5 then
    SaveCampaignVar("Progress", "5")
  end

  for i = 1, 7 do 
    if natives[i] == deployedHog then
      SaveCampaignVar("M5DeployedNum", "" .. i)
    end
  end

  DismissTeam(tribeTeamName)
  DismissTeam(cannibalsTeamName1)
  DismissTeam(cannibalsTeamName2)
  DismissTeam(cyborgTeamName)
  EndTurn(true)
end

-----------------------------Misc--------------------------------------

function SpawnCrates()
  SpawnSupplyCrate(0, 0, amDrill)
  SpawnSupplyCrate(0, 0, amGrenade)
  SpawnSupplyCrate(0, 0, amBazooka)
  SpawnSupplyCrate(0, 0, amDynamite)
  SpawnSupplyCrate(0, 0, amGrenade)
  SpawnSupplyCrate(0, 0, amMine)
  SpawnSupplyCrate(0, 0, amShotgun)
  SpawnSupplyCrate(0, 0, amFlamethrower)
  SpawnSupplyCrate(0, 0, amMolotov)
  SpawnSupplyCrate(0, 0, amSMine)
  SpawnSupplyCrate(0, 0, amMortar)
  SpawnSupplyCrate(0, 0, amRope)
  SpawnSupplyCrate(0, 0, amRope)
  SpawnSupplyCrate(0, 0, amParachute)
  SpawnSupplyCrate(0, 0, amParachute)
  SetHealth(SpawnHealthCrate(0, 0), 25)
  SetHealth(SpawnHealthCrate(0, 0), 25)
  SetHealth(SpawnHealthCrate(0, 0), 25)
  SetHealth(SpawnHealthCrate(0, 0), 25)
  SetHealth(SpawnHealthCrate(0, 0), 25)
  SetHealth(SpawnHealthCrate(0, 0), 25)
end


function RestoreWave(index)
  for i = (index - 1) * 3 + 1, index * 3 do
    if cannibalHidden[i] == true then
      RestoreHog(cannibals[i])
      AnimSetGearPosition(cannibals[i], unpack(cannibalPos[i]))
      FollowGear(cannibals[i])
      cannibalHidden[i] = false
    end
  end
end

function GetVariables()
  progress = tonumber(GetCampaignVar("Progress"))
  m2Choice = tonumber(GetCampaignVar("M2Choice")) or choiceRefused
  m4DenseDead = tonumber(GetCampaignVar("M4DenseDead")) or 0
  m4LeaksDead = tonumber(GetCampaignVar("M4LeaksDead")) or 0
  m4ChiefDead = tonumber(GetCampaignVar("M4ChiefDead")) or 0
  m4WaterDead = tonumber(GetCampaignVar("M4WaterDead")) or 0
  m4BuffaloDead = tonumber(GetCampaignVar("M4BuffaloDead")) or 0
end

function HideCyborg()
  if cyborgHidden == false then
    HideHog(cyborg)
    cyborgHidden = true
  end
end

function RestoreCyborg()
  if cyborgHidden == true then
    RestoreHog(cyborg)
    cyborgHidden = false
    -- Clear mines around cyborg
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

function SetupPlace()
  startNativesNum = nativesNum
  HideCyborg()
  for i = 1, 9 do
    HideHog(cannibals[i])
    cannibalHidden[i] = true
  end
  if m4LeaksDead == 1 then
    HideHog(natives[leaksNum])
    nativeHidden[leaksNum] = true
    needRevival = true
  end
  if m4DenseDead == 1 then
    if m2Choice ~= choiceAccepted then
      DeleteGear(natives[denseNum])
      startNativesNum = startNativesNum - 1
      nativeDead[denseNum] = true
    else
      HideHog(natives[denseNum])
      nativeHidden[denseNum] = true
      needRevival = true
    end
  end
  if m4WaterDead == 1 then
    HideHog(natives[waterNum])
    nativeHidden[waterNum] = true
    needRevival = true
  end
  if m4ChiefDead == 1 then
    DeleteGear(natives[chiefNum])
    startNativesNum = startNativesNum - 1
    nativeDead[chiefNum] = true
    AnimSetGearPosition(natives[girlNum], unpack(nativePos[buffaloNum]))
    nativePos[girlNum] = nativePos[buffaloNum]
  end
  if m4BuffaloDead == 1 then
    startNativesNum = startNativesNum - 1
    nativeDead[buffaloNum] = true
    DeleteGear(natives[buffaloNum])
  end
  PlaceGirder(3568, 1461, 1)
  PlaceGirder(440, 523, 5)
  PlaceGirder(350, 441, 1)
  PlaceGirder(405, 553, 5)
  PlaceGirder(316, 468, 1)
  PlaceGirder(1319, 168, 0)
end

function SetupAmmo()
  AddAmmo(natives[girlNum], amSwitch, 0)
end

function AddHogs()
  tribeTeamName = AddTeam(loc("Tribe"), -2, "Bone", "Island", "HillBilly", "cm_birdy")
  SetTeamPassive(tribeTeamName, true)
  for i = 8, 9 do
    natives[i] = AddHog(nativeNames[i], 0, 100, nativeHats[i])
  end

  nativesTeamName = AddMissionTeam(-2)
  for i = 1, 7 do
    natives[i] = AddHog(nativeNames[i], 0, 100, nativeHats[i])
  end
  nativesNum = 7

  cannibalsTeamName1 = AddTeam(loc("Assault Team"), -1, "skull", "Island", "Pirate", "cm_vampire")
  for i = 1, 6 do
    cannibals[i] = AddHog(cannibalNames[i], 3, 50, "vampirichog")
  end

  cannibalsTeamName2 = AddTeam(loc("Reinforcements"), -1, "skull", "Island", "Pirate", "cm_vampire")
  for i = 7, 9 do
    cannibals[i] = AddHog(cannibalNames[i], 2, 50, "vampirichog")
  end

  cyborgTeamName = AddTeam(loc("011101001"), -1, "ring", "UFO", "Robot", "cm_binary")
  cyborg = AddHog(loc("Unit 334a$7%;.*"), 0, 200, "cyborg1")

  for i = 1, 9 do
    AnimSetGearPosition(natives[i], unpack(nativePos[i]))
    AnimTurn(natives[i], nativeDir[i])
  end

  AnimSetGearPosition(cyborg, 0, 0)

  for i = 1, 9 do
    AnimSetGearPosition(cannibals[i], cannibalPos[i][1], cannibalPos[i][2] + 40)
    AnimTurn(cannibals[i], cannibalDir[i])
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

-----------------------------Main Functions----------------------------

function onGameInit()
	Seed = 2
	GameFlags = gfSolidLand
	TurnTime = 60000 
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 3000
	Explosives = 0
	Map = "Cave"
	Theme = "Nature"
	WaterRise = 0
	HealthDecrease = 0
	AddHogs()
	AnimInit()
end

function onGameStart()
  GetVariables()
  SetupAmmo()
  SetupPlace()
  AnimationSetup()
  AddAnim(startAnim)
  AddFunction({func = AfterStartAnim, args = {}})
  SetAmmoDelay(amBlowTorch, 9999)
  SetAmmoDelay(amGirder, 9999)
  SetAmmoDelay(amLandGun, 9999)
  SetAmmoDelay(amRope, 9999)
  SetAmmoDelay(amParachute, 9999)
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

  for i = 1, 7 do
    if gear == natives[i] then
      if nativeDead[i] ~= true then
        freshDead = nativeNames[i]
      end
      nativeDead[i] = true
      nativesNum = nativesNum - 1
    end
  end

  for i = 1, 9 do
    if gear == cannibals[i] then
      cannibalDead[i] = true
    end
  end

  if gear == spyHog and stage == spyKillStage then
    freshDead = nil
    choice = choiceEliminate
    tmpVar = 1
  end

  if gear == deployedHog then
    deployedDead = true
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
  SetAmmo(amBazooka, 4, 0, 0, 4)
  SetAmmo(amGrenade, 4, 0, 0, 4)
  SetAmmo(amMine, 2, 0, 0, 2)
  SetAmmo(amSMine, 2, 0, 0, 2)
  SetAmmo(amMolotov, 2, 0, 0, 3)
  SetAmmo(amFlamethrower, 2, 0, 0, 3)
  SetAmmo(amShotgun, 4, 0, 0, 4)
  SetAmmo(amTeleport, 0, 0, 0, 2)
  SetAmmo(amDrill, 0, 0, 0, 4)
  SetAmmo(amMortar, 0, 0, 0, 4)
end

j = 0

function onNewTurn()
  tmpVar = 0
  if AnimInProgress() then
    SetTurnTimeLeft(MAX_TURN_TIME)
    return
  end

  TurnsLeft = TurnsLeft - 1
  
  if stage == platformStage then
    AddCaption(string.format(loc("Turns until arrival: %d"), TurnsLeft))
  end
  if deployedHog then
    if GetHogTeamName(CurrentHedgehog) == nativesTeamName then
      AnimSwitchHog(deployedHog)
    end
  end

  if stage == spyKillStage then
    if GetHogTeamName(CurrentHedgehog) ~= nativesTeamName then
      EndTurn(true)
    else
      if CurrentHedgehog == spyHog then
        AnimSwitchHog(natives[leaksNum])
      end
      SetGearMessage(CurrentHedgehog, 0)
      SetTurnTimeLeft(MAX_TURN_TIME)
      if CheckChoiceRunawayAll() then
        highJumped = true
      end
    end
  else
    if freshDead ~= nil and GetHogTeamName(CurrentHedgehog) == nativesTeamName then
      SetupHogDeadAnim(freshDead)
      AddAnim(hogDeadAnim)
      AddFunction({func = AfterHogDeadAnim, args = {}})
    end
  end
  if needToAct > 0 then
    if needToAct == 1 then
      RestoreWave(2)
      SetupWave2Anim()
      AddAnim(wave2Anim)
      AddFunction({func = AfterWave2Anim, args = {}})
    elseif needToAct == 2 then
      SetupWave2DeadAnim()
      AddAnim(wave2DeadAnim)
      AddFunction({func = AfterWave2DeadAnim, args = {}})
    elseif needToAct == 3 then
      AnimSwitchHog(deployedHog)
      AddFunction({func = AddWave3DeadAnim, args = {}})
    end
    needToAct = 0
  end
end

function onPreciseLocal()
  if GameTime > 2500 and AnimInProgress() then
    SetAnimSkip(true)
    return
  end
end

function onSkipTurn()
  if stage == spyKillStage then
    highJumped = true
  end
end
