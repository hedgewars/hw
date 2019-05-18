--[[
A Classic Fairytale: Long live the Queen

= SUMMARY =
Deathmatch against a leader of a pack of cyborgs with 4 different storylines (but mostly identical gameplay).

= GOALS =
Defeat Biomechanic Team.

= FLOW CHART =
- Show one of 4 possible storylines which affect the choice of the enemy leader (only minor effect on gameplay):
    | 1) If offer accepted in ACF2 and traitor not executed in ACF5: Dense Cloud
    | 2) Otherwise: If offer accepted in ACF2: Nancy Screw (cyborg)
    | 3) Otherwise: If traitor was executed in ACF5: Fell from Heaven
    | 4) Otherwise: Fiery Water
- Cut scene: startAnim
- TBS
- Biomechanic Team defeated.
- Cut scene: finalAnim
> Victory

== Non-linear events ==
| Leader dead
    - Cut scene: leaderDeadAnim
| Played more than 6 rounds and leader is still in game
    - Cut scene: fleeAnim
    - Leader flees
    - Instructions: Kill remaining enemies

]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")


-----------------------------Map--------------------------------------
local map =
{
	"\16\7\0\225\132\15\200\1\40\0\15\200\1\40\132\15\105\8\81\0\16\14\1\64\143\15\200\7\249\0\13\50\7\252\132\12\243\7\172\0",
	"\12\236\7\168\132\12\127\6\192\0\12\127\6\192\132\11\52\6\223\0\11\52\6\223\132\10\62\8\35\0\8\201\8\4\132\8\63\7\126\0",
	"\8\63\7\126\132\8\4\6\58\0\8\0\6\65\132\7\147\6\241\0\7\133\6\195\132\7\20\4\151\0\7\143\6\195\132\7\140\6\234\0",
	"\7\17\4\151\132\5\191\4\222\0\5\191\4\222\132\3\136\3\252\0\3\136\3\252\132\2\12\4\151\0\2\12\4\151\132\1\138\5\15\0",
	"\1\138\5\15\132\1\54\5\156\0\1\54\5\156\132\0\130\5\64\0\0\130\5\64\132\255\214\5\135\0\8\141\1\85\179\8\141\1\85\0",
	"\10\30\2\220\139\10\30\2\220\0\11\77\1\142\131\11\77\1\142\0\10\188\0\113\129\10\188\0\113\0\255\235\0\162\132\0\130\0\225\0",
	"\0\130\0\229\0\0\127\0\236\132\255\231\0\250\0\0\28\0\215\136\0\4\0\211\0\0\95\5\212\154\0\95\7\238\0\0\246\6\2\154",
	"\1\71\8\0\0\1\205\5\145\154\2\132\4\239\0\3\98\4\141\154\1\135\5\216\0\3\179\4\151\154\6\213\5\247\0\6\223\5\124\151",
	"\6\185\5\22\0\6\181\5\29\151\6\37\5\64\0\0\179\5\198\148\0\179\5\198\0\6\216\4\253\148\6\216\4\253\0\1\230\7\147\153",
	"\8\32\8\18\0\1\187\6\174\153\7\179\7\108\0\2\199\5\177\179\6\128\6\167\0\7\231\7\10\143\7\231\6\202\0\12\148\8\4\156",
	"\10\241\8\11\0\11\112\7\101\156\12\56\7\91\0\1\89\5\223\199\4\11\5\208\0\4\67\5\212\200\4\172\6\58\0\4\172\6\58\200",
	"\5\36\5\212\0\5\40\5\194\200\4\169\5\57\0\4\169\5\57\200\4\42\5\205\0\4\130\5\142\200\4\218\5\205\0\4\137\5\194\200",
	"\4\179\5\251\0\255\245\1\198\133\0\77\1\198\0\0\77\1\198\133\0\102\1\226\0\0\102\1\230\133\255\221\1\244\0\255\245\0\148\195",
	"\255\231\1\11\0\0\32\0\162\195\255\231\0\169\0\0\60\0\158\195\0\32\0\172\0\0\21\0\176\195\255\242\0\222\0\255\245\0\215\195",
	"\0\7\0\246\0\255\245\0\243\195\0\11\1\33\0\0\4\1\4\195\0\56\1\36\0\255\245\1\173\195\0\35\1\110\0\255\242\1\180\195",
	"\255\224\2\9\0\255\238\1\240\195\0\28\2\30\0\0\21\2\19\195\0\102\2\23\0\16\18\1\1\195\16\35\0\222\0\16\14\1\11\195",
	"\16\7\2\9\0\16\0\2\16\195\16\35\3\34\0\16\11\2\252\195\16\11\4\208\0\16\11\4\208\195\16\0\6\55\0\16\0\6\55\195",
	"\16\14\8\25\0",
}

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

denseScene = 1
princessScene = 2
waterScene = 3
cyborgScene = 4

nativeNames = {loc("Leaks A Lot"), loc("Dense Cloud"), loc("Fiery Water"), 
               loc("Raging Buffalo"), loc("Righteous Beard"), loc("Fell From Grace"),
               loc("Wise Oak"), loc("Ramon"), loc("Spiky Cheese")
              }
nativeSaveNames = {"M8DeployedDead", "M8RamonDead", "M8SpikyDead", "M8PrincessDead"}

nativeUnNames = {loc("Zork"), loc("Steve"), loc("Jack"),
                 loc("Lee"), loc("Elmo"), loc("Rachel"),
                 loc("Muriel")}

nativeHats = {"Rambo", "RobinHood", "pirate_jack", "zoo_Bunny", "IndianChief",
              "tiara", "AkuAku", "rasta", "hair_yellow"}

nativePos = {{1474, 1209}, {923, 990}, {564, 1120}, {128, 1315}}
nativesNum = 4
nativesLeft = 4

cyborgNames = {loc("Artur Detour"), loc("Led Heart"), loc("Orlando Boom!"), loc("Nilarian"), 
               loc("Steel Eye"), loc("Rusty Joe"), loc("Hatless Jerry"), loc("Gas Gargler")}

cyborgsDif = {2, 2, 2, 2, 2, 2, 2, 2}
cyborgsHealth = {100, 100, 100, 100, 100, 100, 100, 100}
cyborgHidePos = {1665, 1800}
cyborgsTeamNum = {4, 3}
cyborgsNum = 7
cyborgsPos = {{2893, 1723}, {2958, 1717}, {3027, 1710}, {3096, 1704},
              {2584, 665},  {2047, 1562}, {115, 179}, {2162, 1916}}
cyborgsDir = {"Left", "Left", "Left", "Left", "Left", "Left", "Right", "Left"}

crateConsts = {}
reactions = {}

enemyPos = {4078, 195}

-----------------------------Variables---------------------------------
natives = {}
origNatives = {}

cyborgs = {}
cyborg = nil

gearDead = {}
hedgeHidden = {}

scene = 0
enemyFled = "0"

deployedLeader = "0"
princessLeader = "0"

startAnim = {}
fleeAnim = {}
finalAnim = {}
leaderDeadAnim = {}

nativeAwaitingDeletion = nil
-----------------------------Animations--------------------------------
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

function AnimationSetup()
  table.insert(startAnim, {func = AnimWait, args = {enemy, 3000}})
  table.insert(startAnim, {func = AnimCaption, swh = false, args = {natives[1], loc("The team continued their quest of finding the rest of the tribe."), 4000}})
  table.insert(startAnim, {func = AnimCaption, swh = false, args = {natives[1], loc("They stumbled upon a pile of weapons, they seemed to be getting closer."), 4500}})
  if scene == denseScene then
    if m5DeployedNum == denseNum then
      deployedLeader = "1"
      SetupDenseAnimDeployed()
    else
      SetupDenseAnim()
    end
  elseif scene == waterScene then
    if m5DeployedNum == waterNum then
      deployedLeader = "1"
      SetupWaterAnimDeployed()
    else
      SetupWaterAnim()
    end
  elseif scene == princessScene then
    princessLeader = "1"
    SetupPrincessAnim()
  else
    SetupCyborgAnim()
  end

  AddSkipFunction(startAnim, SkipAnim, {startAnim})
  AddSkipFunction(fleeAnim, SkipAnim, {fleeAnim})
  AddSkipFunction(leaderDeadAnim, SkipAnim, {leaderDeadAnim})
end

function SetupLeaderDeadAnim()
  local gear = nil
  if CheckCyborgsDead() then
    return
  end
  for i = nativesLeft, 1, -1 do
    if band(GetState(natives[i]), gstDrowning) == 0 then
      gear = natives[i]
    end
  end
  if gear == nil then
    return
  end
  table.insert(leaderDeadAnim, {func = AnimFollowGear, args = {gear}})
  table.insert(leaderDeadAnim, {func = AnimSay, args = {gear, loc("That traitor won't be killing us anymore!"), SAY_THINK, 6000}})
end

function SetupDenseAnim()
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Yo, dude! Get away from our weapons!"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Dense Cloud?! What are you doing?!"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("What does it look like?"), SAY_SHOUT, 3500}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Are you helping the aliens?"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Haha, I love the look on your face!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Did you really think that I've changed?"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("But why did you betray us?!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Yo, the aliens gave me plants. Medicinal plants. Lots of it."), SAY_SHOUT, 6500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("You never give me plants!"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Besides, why would I choose certain death?"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Do you have any idea how bad an exploding arrow hurts?"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Dude, it's unbearable!"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("You're a coward!"), SAY_SHOUT, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("You endangered your whole tribe, you bastard!"), SAY_SHOUT, 7000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Yeah, well, for some dude to be happy, some other dude has to suffer."), SAY_SHOUT, 11000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("That's just the way it works, you know."), SAY_SHOUT, 6500}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("You're some piece of hypocrite junkie!"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Why do you always have to call me names?"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, EmitDenseClouds, {}}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Make fun of me when I fart …"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("IT'S A SERIOUS MEDICAL CONDITION!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("You don't deserve my sacrifice!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("I won't let you kill the tribe!"), SAY_SHOUT, 5000}})

  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("Dude, this is boring!"), SAY_SAY, 3000}})
  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("I ain't gonna sit around no more!"), SAY_SAY, 5000}})

  table.insert(fleeAnim, {func = AnimTurn, args = {enemy, "Right"}})
  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("Yo, escort my buttocks!"), SAY_SHOUT, 3500}})
  table.insert(fleeAnim, {func = AnimSwitchHog, args = {natives[1]}})
  table.insert(fleeAnim, {func = AnimWait, args = {natives[1], 1}})
  table.insert(fleeAnim, {func = AnimDisappear, swh = false, args = {enemy, 0, 0}})
end

function SetupDenseAnimDeployed()
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, EmitDenseClouds, {}}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[3], enemy}}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[2], enemy}}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[1], enemy}}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("I'm afraid I can't let you proceed!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Huh?"), SAY_THINK, 0}})
  table.insert(startAnim, {func = AnimSay, args = {natives[2], loc("What the?"), SAY_THINK, 0}})
  table.insert(startAnim, {func = AnimSay, args = {natives[3], loc("Why?"), SAY_SAY, 1000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Dude, wow, you're so cute!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Did you really think I've changed?"), SAY_SHOUT, 4500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("I'm still with the aliens."), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimTeleportGear, args = {enemy, unpack(enemyPos)}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[1], enemy}}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("What?!"), SAY_THINK, 1000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[3], loc("But you saved me!"), SAY_SAY, 2500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Haha, that was just a coincidence!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("I was heading home, you see!"), SAY_SHOUT, 3500}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("We were your home! Your family!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("How could you betray us?"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Yo, the aliens gave me plants. Medicinal plants. Lots of it."), SAY_SHOUT, 6500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("You never give me plants!"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Besides, why would I choose certain death?"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Do you have any idea how bad an exploding arrow hurts?"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Dude, it's unbearable!"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("You're a coward!"), SAY_SHOUT, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("You endangered your whole tribe, you bastard!"), SAY_SHOUT, 7000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Yeah, well, for some dude to be happy, some other dude has to suffer."), SAY_SHOUT, 11000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("That's just the way it works, you know."), SAY_SHOUT, 6500}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("You're some piece of hypocrite junkie!"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Why do you always have to call me names?"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, EmitDenseClouds, {}}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Make fun of me when I fart …"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("IT'S A SERIOUS MEDICAL CONDITION!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("You don't deserve my sacrifice!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("I won't let you kill the tribe!"), SAY_SHOUT, 5000}})

  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("Dude, this is boring!"), SAY_SAY, 3000}})
  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("I ain't gonna sit around no more!"), SAY_SAY, 5000}})
  table.insert(fleeAnim, {func = AnimTurn, args = {enemy, "Right"}})
  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("Yo, escort my buttocks!"), SAY_SHOUT, 3500}})
  table.insert(fleeAnim, {func = AnimSwitchHog, args = {natives[1]}})
  table.insert(fleeAnim, {func = AnimWait, args = {natives[1], 1}})
  table.insert(fleeAnim, {func = AnimDisappear, swh = false, args = {enemy, 0, 0}})
end

function SetupWaterAnim()
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Stay there, comrades!"), SAY_SHOUT, 2500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Come closer and die! … burp …"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Fiery Water?! Are you drunk again?"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Drunk with power, perhaps!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("The power of love! No, wait, the power of the aliens!"), SAY_SHOUT, 7500}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("We trusted you, you fool!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Why do you keep betraying us?"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Why, why, why, why!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("I grew sick of the oppression! I broke free!"), SAY_SHOUT, 6500}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("What oppression? You were the most unoppressed member of the tribe!"), SAY_SHOUT, 10000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("The oppression of the elders, of course!"), SAY_SHOUT, 6500}})
  if m5DeployedNum == leaksNum then
    table.insert(startAnim, {func = AnimSay, args = {enemy, loc("You should know this more than anyone, Leaks!"), SAY_SHOUT, 7000}})
  elseif m5LeaksDead == 1 then
    table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Just look at Leaks, may he rest in peace!"), SAY_SHOUT, 6500}})
  end
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("We, the youth, have to constantly prove our value."), SAY_SHOUT, 7000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("We work and work until we sweat blood."), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("We risk our lives going through challenges."), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("All this to please our beloved “elders” … hick …"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("And what do they do in the meantime? Nothing!"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("All they do is sit around and judge us!"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("You have never worked a bit in your life!"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("All you do is take long walks when everyone else works."), SAY_SHOUT, 9000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Anyway, the aliens accept me for who I am."), SAY_SHOUT, 7000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("We won't accept you destroying our village!"), SAY_SHOUT, 7000}})

  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("Argh, the boredom!"), SAY_SAY, 3000}})
  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("I have more important things to do!"), SAY_SAY, 5000}})
  table.insert(fleeAnim, {func = AnimTurn, args = {enemy, "Right"}})
  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("Comrades! Sail me away!"), SAY_SHOUT, 3500}})
  table.insert(fleeAnim, {func = AnimSwitchHog, args = {natives[1]}})
  table.insert(fleeAnim, {func = AnimWait, args = {natives[1], 1}})
  table.insert(fleeAnim, {func = AnimDisappear, swh = false, args = {enemy, 0, 0}})
end

function SetupWaterAnimDeployed()
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[3], enemy}}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[2], enemy}}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[1], enemy}}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Stop, comrades!"), SAY_SHOUT, 2500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("I cannot let you go any further! … burp …"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Fiery Water?! Are you drunk again?"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Drunk with power, perhaps!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("The power of love! No, wait, the power of the aliens!"), SAY_SHOUT, 7500}})
  table.insert(startAnim, {func = AnimTeleportGear, args = {enemy, unpack(enemyPos)}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[3], enemy}}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[2], enemy}}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[1], enemy}}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("We trusted you, you fool!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Why do you keep betraying us?"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Why, why, why, why!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("I grew sick of the oppression! I broke free!"), SAY_SHOUT, 6500}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("What oppression? You were the most unoppressed member of the tribe!"), SAY_SHOUT, 10000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("The oppression of the elders, of course!"), SAY_SHOUT, 6500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Just look at Leaks, may he rest in peace!"), SAY_SHOUT, 6500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("We, the youth, have to constantly prove our value."), SAY_SHOUT, 7000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("We work and work until we sweat blood."), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("We risk our lives going through challenges."), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("All this to please our beloved “elders” … hick …"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("And what do they do in the meantime? Nothing!"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("All they do is sit around and judge us!"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("You have never worked a bit in your life!"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("All you do is take long walks when everyone else works."), SAY_SHOUT, 9000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Anyway, the aliens accept me for who I am."), SAY_SHOUT, 7000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("We won't accept you destroying our village!"), SAY_SHOUT, 7000}})

  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("Argh, the boredom!"), SAY_SAY, 3000}})
  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("I have more important things to do!"), SAY_SAY, 5000}})
  table.insert(fleeAnim, {func = AnimTurn, args = {enemy, "Right"}})
  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("Comrades! Sail me away!"), SAY_SHOUT, 3500}})
  table.insert(fleeAnim, {func = AnimSwitchHog, args = {natives[1]}})
  table.insert(fleeAnim, {func = AnimWait, args = {natives[1], 1}})
  table.insert(fleeAnim, {func = AnimDisappear, swh = false, args = {enemy, 0, 0}})
end

function SetupPrincessAnim()
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[3], enemy}}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[2], enemy}}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[1], enemy}}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Oh, my! I forgot something!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("We need to go back!"), SAY_SHOUT, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("What could you possibly forget in that cage?"), SAY_SHOUT, 7000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("I don't like your tone! You're hurting me!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("I'm terribly sorry!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("What is it that you forgot?"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Uhmm, it's … uhm … my ring!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("It's precious to me!"), SAY_SHOUT, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("We don't have time for that now!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("We have to find our folk!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("But I want my sandals!"), SAY_SHOUT, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Sandals?! I thought you left your ring!"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("All right, you got me!"), SAY_SHOUT, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Got you? You're acting weird."), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("You just can't let it go, can you!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("All right, I'll admit it!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Admit what?"), SAY_SHOUT, 2000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("You give me no choice!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("I can't let you go further because …"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("I'm the spy! I've been giving you out!"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimTeleportGear, args = {enemy, unpack(enemyPos)}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[3], enemy}}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[2], enemy}}})
  table.insert(startAnim, {func = AnimCustomFunction, args = {enemy, CondNeedToTurn, {natives[1], enemy}}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("But … they kidnapped you!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Oh, that. We were just having fun!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("It's an ancient ritual of theirs."), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Why did you do this?"), SAY_SHOUT, 4000}})
  if m5ChiefDead == 1 then
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Why did you kill your father?"), SAY_SHOUT, 5000}})
  end
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Do you have any idea what it's like in the village for a woman?"), SAY_SHOUT, 10000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("How would you like being discriminated against?"), SAY_SHOUT, 7000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Not being able to fight or hunt."), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Gathering fruits all day long."), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Doing stuff a monkey could do."), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Always being considered weak and fragile."), SAY_SHOUT, 6000}})
  if m5DeployedNum == girlNum then
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("In case you haven't noticed, I'm a woman, too!"), SAY_SHOUT, 8000}})
    table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Yes, but you're … different!"), SAY_SHOUT, 6000}})
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Of course I am!"), SAY_SHOUT, 3000}})
  end
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("The aliens respect me, even worship me!"), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("I'm living a dream!"), SAY_SHOUT, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Well, you're about to wake up!"), SAY_SHOUT, 5000}})

  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("Hmm … it's going slower than expected."), SAY_SAY, 5000}})
  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("I am going to leave the kids play by themselves."), SAY_SAY, 6000}})
  table.insert(fleeAnim, {func = AnimTurn, args = {enemy, "Right"}})
  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("Alien! I wish to be moved!"), SAY_SHOUT, 4000}})
  table.insert(fleeAnim, {func = AnimSwitchHog, args = {natives[1]}})
  table.insert(fleeAnim, {func = AnimWait, args = {natives[1], 1}})
  table.insert(fleeAnim, {func = AnimDisappear, swh = false, args = {enemy, 0, 0}})
end

function SetupCyborgAnim()
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Stop right there, puny worms!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Stay away from our weapons!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("We come in peace! Just let our friends go!"), SAY_SHOUT, 5500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("I'm afraid we cannot afford that."), SAY_SHOUT, 4500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("You see, hedgehog spikes are very, very valuable."), SAY_SHOUT, 6500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Very valuable, haha!"), SAY_SHOUT, 3500}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Don't you dare harming our tribe!"), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("It's a shame, really!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("I regret to end your little odyssey."), SAY_SHOUT, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("It was fun to watch."), SAY_SHOUT, 3500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("The way you handled your little internal conflicts …"), SAY_SHOUT, 6500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Did you really think that we needed the help of one of you?"), SAY_SHOUT, 7500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("You should have known that we don't rely on meatbags!"), SAY_SHOUT, 7500}})
  table.insert(startAnim, {func = AnimSay, args = {enemy, loc("It was fun to watch, though."), SAY_SHOUT, 3500}})
  if m5Choice == choiceEliminate then
    table.insert(startAnim, {func = AnimSay, args = {enemy, loc("Heck, you even executed one of your own!"), SAY_SHOUT, 6000}})
  end
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("It was all a trick?!"), SAY_SHOUT, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Some sick game of yours?!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("We won't let you hurt any more of us!"), SAY_SHOUT, 6000}})

  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("Entered boredom phase! Discrepancies detected …"), SAY_SAY, 5000}})
  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("Initiate escape wish!"), SAY_SAY, 6000}})
  table.insert(fleeAnim, {func = AnimTurn, args = {enemy, "Right"}})
  table.insert(fleeAnim, {func = AnimSay, args = {enemy, loc("Running displacement algorithm …"), SAY_SHOUT, 4000}})
  table.insert(fleeAnim, {func = AnimSwitchHog, args = {natives[1]}})
  table.insert(fleeAnim, {func = AnimWait, args = {natives[1], 1}})
  table.insert(fleeAnim, {func = AnimDisappear, swh = false, args = {enemy, 0, 0}})
end

function SetupFinalAnim()
  local found = 0
  local gears = {}
  for i = nativesLeft, 1, -1 do
    if band(GetState(natives[i]), gstDrowning) == 0 then
      found = found + 1
      gears[found] = natives[i]
    end
  end
  if found == 0 then
    return
  else
    for i = 1, found do
      table.insert(finalAnim, {func = AnimCustomFunction, args = {gears[1], CondNeedToTurn, {cyborg, gears[i]}}})
    end
    table.insert(finalAnim, {func = AnimSay, args = {cyborg, loc("Nice work, meatbags!"), SAY_SAY, 3000}})
    table.insert(finalAnim, {func = AnimSay, args = {cyborg, loc("You're on your way to freeing your tribe!"), SAY_SAY, 5500}})
    table.insert(finalAnim, {func = AnimSay, args = {gears[1], loc("Do you know where they are?"), SAY_SAY, 4000}})
    table.insert(finalAnim, {func = AnimSay, args = {gears[found], loc("We need to hurry!"), SAY_SAY, 3000}})
    table.insert(finalAnim, {func = AnimSay, args = {cyborg, loc("Haha! Come!"), SAY_SAY, 2000}})
    table.insert(finalAnim, {func = AnimJump, args = {cyborg, "high"}})
    table.insert(finalAnim, {func = AnimDisappear, args = {cyborg, GetGearPosition(cyborg)}})
    for i = 1, found do
      table.insert(finalAnim, {func = HideHedge, swh = false, args = {gears[i]}})
    end
    table.insert(finalAnim, {func = SetState, swh = false, args = {cyborg, gstInvisible}})
  end
end


--------------------------Anim skip functions--------------------------
function AfterStartAnim()
  SetGearMessage(natives[1], 0)
  ShowMission(loc("Long Live The Queen"), loc("Closing in"), loc("Defeat the enemy!").."|"..loc("The leader seems scared, he will probably flee."), 1, 0)
  SetHealth(SpawnHealthCrate(2207, 44), 25)
  SetHealth(SpawnHealthCrate(519, 1519), 25)
  SetHealth(SpawnHealthCrate(826, 895), 25)
  SpawnSupplyCrate(701, 1046, amGirder, 3)
  SetTurnTimeLeft(TurnTime)
end

function SkipAnim(anim)
  if anim == startAnim then
    SetGearPosition(enemy, unpack(enemyPos))
    HogTurnLeft(enemy, true)
  end
  if GetHogTeamName(CurrentHedgehog) ~= nativesTeamName then
    EndTurn(true)
  end
  AnimWait(enemy, 1)
end

function AfterFleeAnim()
  SetHealth(SpawnHealthCrate(130, 455), 25)
  SetHealth(SpawnHealthCrate(2087, 50), 25)
  SetHealth(SpawnHealthCrate(2143, 54), 25)
  SetHealth(SpawnHealthCrate(70, 1308), 25)
  SetGearMessage(CurrentHedgehog, 0)
  HideHedge(enemy)
  ShowMission(loc("Long Live The Queen"), loc("Coward"), loc("The leader escaped. Defeat the rest of the aliens!"), 1, 0)
  SetTurnTimeLeft(TurnTime)
end

function AfterLeaderDeadAnim()
  SetHealth(SpawnHealthCrate(130, 455), 25)
  SetHealth(SpawnHealthCrate(2087, 50), 25)
  SetHealth(SpawnHealthCrate(2143, 54), 25)
  SetHealth(SpawnHealthCrate(70, 1308), 25)
  ShowMission(loc("Long Live The Queen"), loc("Bullseye"), loc("Good job! Defeat the rest of the aliens!"), 1, 0)
  EndTurn(true)
end
-----------------------------Events------------------------------------
function CheckTurnsOver()
  return TotalRounds > 6
end

function DoTurnsOver()
  SetGearMessage(CurrentHedgehog, 0)
  enemyFled = "1"
  AddAnim(fleeAnim)
  AddFunction({func = AfterFleeAnim, args = {}})
  RemoveEventFunc(CheckGearDead, {enemy})
end

function CheckNativesDead()
  return nativesLeft == 0
end

function DoNativesDead()
  RemoveEventFunc(CheckTurnsOver)
  RemoveEventFunc(CheckGearDead)
  RemoveEventFunc(CheckCyborgsDead)
  AddCaption(loc("And so the cyborgs took over the island."))
  EndTurn(true)
end

function CheckCyborgsDead()
  return (cyborgsLeft == 0 and (gearDead[enemy] == true or enemyFled == "1"))
end

function KillEnemy()
  if enemyFled == "1" then
    DismissTeam(leaderbotTeamName)
  end
  DismissTeam(cyborgTeamName)
  EndTurn(true)
end

function DoCyborgsDead()
  SaveCampaignVariables()
  RestoreHedge(cyborg)
  PlaceGirder(3292, 922, 4)
  SetGearPosition(cyborg, 3290, 902)
  SetupFinalAnim()
  AddAnim(finalAnim)
  AddFunction({func = KillEnemy, args = {}})
end

function DoLeaderDead()
  if enemyFled ~= "1" then
    leaderDead = true
    SetGearMessage(CurrentHedgehog, 0)
    SetupLeaderDeadAnim()
    AddAnim(leaderDeadAnim)
    AddFunction({func = AfterLeaderDeadAnim, args = {}})
    RemoveEventFunc(CheckTurnsOver)
  end
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

function GetVariables()
  progress = tonumber(GetCampaignVar("Progress"))
  m5DeployedNum = tonumber(GetCampaignVar("M5DeployedNum")) or leaksNum
  m2Choice = tonumber(GetCampaignVar("M2Choice")) or choiceRefused
  m5Choice = tonumber(GetCampaignVar("M5Choice")) or choiceEliminate
  m5LeaksDead = tonumber(GetCampaignVar("M5LeaksDead")) or 0
  m5ChiefDead = tonumber(GetCampaignVar("M5ChiefDead")) or 0
end

function SaveCampaignVariables()
  SaveCampaignVar("M8DeployedLeader", deployedLeader)
  SaveCampaignVar("M8PrincessLeader", princessLeader)
  SaveCampaignVar("M8EnemyFled", enemyFled)
  SaveCampaignVar("M8Scene", "" .. scene)
  if progress and progress<8 then
    SaveCampaignVar("Progress", "8")
  end
end

function SetupPlace()
  HideHedge(cyborg)
  SetHogHat(natives[1], nativeHats[m5DeployedNum])
  SetHogName(natives[1], nativeNames[m5DeployedNum])

  if m5DeployedNum == denseNum then
    dense = natives[1]
  else
    dense = enemy
  end

  if m2Choice == choiceAccepted and m5Choice ~= choiceEliminate then
    scene = denseScene
    SetHogHat(enemy, nativeHats[denseNum])
    SetHogName(enemy, nativeNames[denseNum])
    dense = enemy
  elseif m2Choice == choiceAccepted then
    scene = cyborgScene
    SetHogHat(enemy, "cyborg2")
    SetHogName(enemy, loc("Nancy Screw"))
  elseif m5Choice == choiceEliminate then
    scene = princessScene
    SetHogHat(enemy, "tiara")
    SetHogName(enemy, loc("Fell From Heaven"))
  else
    scene = waterScene
    SetHogHat(enemy, nativeHats[waterNum])
    SetHogName(enemy, nativeNames[waterNum])
  end
  for i = 1, 4 do 
    if GetHogName(natives[i]) == GetHogName(enemy) then
      AnimSetGearPosition(enemy, GetGearPosition(natives[i]))
      DeleteGear(natives[i])
      -- triggers AfterSetupPlace when the gear is *actually* deleted
      nativeAwaitingDeletion = natives[i]
      DeleteGear(cyborgs[cyborgsLeft])
      break
    end
  end

  SpawnSupplyCrate(34, 410, amBee, 2)
  SpawnSupplyCrate(33, 374, amRCPlane, 1)
  SpawnSupplyCrate(74, 410, amAirAttack, 3)
  SpawnSupplyCrate(1313, 1481, amBazooka, 8)
  SpawnSupplyCrate(80, 360, amSniperRifle, 4)
  SpawnSupplyCrate(1037, 1508, amShotgun, 7)
  SpawnSupplyCrate(1037, 1472, amMolotov, 3)
  SpawnSupplyCrate(1146, 1576, amMortar, 8)

  SpawnSupplyCrate(1147, 1431, amPortalGun, 2)
  SpawnSupplyCrate(1219, 1542, amRope, 5)
  SpawnSupplyCrate(1259, 1501, amJetpack, 2)

  if not nativeAwaitingDeletion then
    AfterSetupPlace()
  end
end

function SetupEvents()
  AddNewEvent(CheckNativesDead, {}, DoNativesDead, {}, 0)
  AddNewEvent(CheckGearDead, {enemy}, DoLeaderDead, {}, 0)
  AddNewEvent(CheckTurnsOver, {}, DoTurnsOver, {}, 0)
  AddNewEvent(CheckCyborgsDead, {}, DoCyborgsDead, {}, 0)
end

function SetupAmmo()
  AddAmmo(natives[1], amPickHammer, 2)
  AddAmmo(natives[1], amBazooka, 0)
  AddAmmo(natives[1], amGrenade, 0)
  AddAmmo(natives[1], amShotgun, 0)
  AddAmmo(natives[1], amAirAttack, 0)
  AddAmmo(natives[1], amMolotov, 0)
end

nativesTeamName = nil
beepTeamName = nil
corpTeamName = nil
leaderbotTeamName = nil
cyborgTeamName = nil

function AddHogs()
  nativesTeamName = AddMissionTeam(-2)
  for i = 7, 9 do
    natives[i-6] = AddHog(nativeNames[i], 0, 100, nativeHats[i])
    origNatives[i-6] = natives[i-6]
  end
  natives[4] = AddHog(loc("Fell From Heaven"), 0, 133, "tiara")
  origNatives[4] = natives[4]
  nativesLeft = nativesNum

  beepTeamName = AddTeam(loc("Beep Loopers"), -1, "ring", "UFO", "Robot_qau", "cm_cyborg")
  for i = 1, cyborgsTeamNum[1] do
    cyborgs[i] = AddHog(cyborgNames[i], cyborgsDif[i], cyborgsHealth[i], "cyborg2")
  end

  corpTeamName = AddTeam(loc("Corporationals"), -1, "ring", "UFO", "Robot_qau", "cm_cyborg")
  for i = cyborgsTeamNum[1] + 1, cyborgsNum do
    cyborgs[i] = AddHog(cyborgNames[i], cyborgsDif[i], cyborgsHealth[i], "cyborg2")
  end
  cyborgsLeft = cyborgsTeamNum[1] + cyborgsTeamNum[2]

  leaderbotTeamName = AddTeam(loc("Leaderbot"), -1, "ring", "UFO", "Robot_qau", "cm_cyborg")
  enemy = AddHog(loc("Name"), 2, 200, "cyborg1")

  cyborgTeamName = AddTeam(loc("011101001"), -1, "ring", "UFO", "Robot_qau", "cm_binary")
  cyborg = AddHog(loc("Unit 334a$7%;.*"), 0, 200, "cyborg1")
  SetGearPosition(cyborg, unpack(cyborgHidePos))

  for i = 1, nativesNum do
    AnimSetGearPosition(natives[i], unpack(nativePos[i]))
  end

  AnimSetGearPosition(enemy, unpack(enemyPos))
  AnimTurn(enemy, "Left")

  for i = 1, cyborgsNum do
    AnimSetGearPosition(cyborgs[i], unpack(cyborgsPos[i]))
    AnimTurn(cyborgs[i], cyborgsDir[i])
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
	Seed = 0
	GameFlags = gfDisableGirders + gfDisableLandObjects
	TurnTime = 60000 
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 3000
	Explosives = 0
  MapGen = mgDrawn
	Theme = "Hell"
  SuddenDeathTurns = 20

	for i = 1, #map do
		ParseCommand('draw ' .. map[i])
	end

  GetVariables()
  AnimInit()
  AddHogs()
end

function onGameStart()
  SetupAmmo()
  SetupPlace()
  -- Animation is setup in AfterSetupPlace
end

function AfterSetupPlace()
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
  local toRemove = nil
  gearDead[gear] = true
  if GetGearType(gear) == gtHedgehog then
    if GetHogTeamName(gear) == beepTeamName or GetHogTeamName(gear) == corpTeamName then
      cyborgsLeft = cyborgsLeft - 1
    elseif GetHogTeamName(gear) == nativesTeamName then
      for i = 1, nativesLeft do
        if natives[i] == gear then
          toRemove = i
        end
      end
      table.remove(natives, toRemove)
      nativesLeft = nativesLeft - 1
      if nativeAwaitingDeletion and gear == nativeAwaitingDeletion then
        AfterSetupPlace()
        nativeAwaitingDeletion = nil
      end
    end
  end
end

function onAmmoStoreInit()
  SetAmmo(amBaseballBat, 9, 0, 0, 0)
  SetAmmo(amFirePunch, 9, 0, 0, 0)
  SetAmmo(amDEagle, 9, 0, 0, 0)
  SetAmmo(amSkip, 9, 0, 0, 0)
  SetAmmo(amSwitch, 9, 0, 0, 0)
  SetAmmo(amBazooka, 9, 0, 0, 0)
  SetAmmo(amGrenade, 9, 0, 0, 0)
  SetAmmo(amAirAttack, 1, 0, 0, 0)
  SetAmmo(amMolotov, 5, 0, 0, 0)
  SetAmmo(amShotgun, 9, 0, 0, 0)
end

function onNewTurn()
  if AnimInProgress() then
    SetTurnTimeLeft(MAX_TURN_TIME)
    return
  end
  if GetHogTeamName(CurrentHedgehog) == cyborgTeamName then
    EndTurn(true)
  end
end

function onPrecise()
  if GameTime > 2500 and AnimInProgress() then
    SetAnimSkip(true)
  end
end
