--[[
A Classic Fairytale: Family Reunion

= GOALS =
Kill all visible cyborgs (not the princess).
Then move hero to princess and Ramon and Spike Cheese to the surface.

= FLOW CHART =
== Linear events ==

- Cut scene: Intro
- First goal: Kill all visible cyborgs (princess is not a cyborg)
- First goal completed
- Cut scene: Cyborg reveals second goal
- A ton of 5s mines spawn on the surface
- Second goal: Hero must reach princess; Ramon and Spiky Cheese must reach the surface
- Second goal completed
> Victory

== Non-linear events ==
| Princess dead:
    > Game over
| Ramon, Spiky Cheese or hero dead:
    > Game over

]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

-----------------------------Map--------------------------------------
local map = 
{
	"\255\242\4\218\132\0\53\4\253\0\0\53\4\253\132\0\102\5\92\0\0\102\5\92\132\0\106\5\205\0\0\106\5\205\132\1\1\6\37\0",
	"\1\1\6\37\132\1\124\6\160\0\1\113\6\160\132\2\157\6\111\0\2\164\6\107\132\2\252\6\178\0\2\252\6\178\132\3\224\4\179\0",
	"\3\224\4\179\132\3\38\2\209\0\3\38\2\209\132\4\109\3\179\0\4\109\3\179\132\5\124\3\172\0\5\128\3\172\132\6\69\4\239\0",
	"\6\69\4\239\132\7\175\4\32\0\7\172\4\46\132\8\116\5\18\0\3\38\2\213\132\3\41\1\244\0\3\41\1\244\132\3\94\2\245\0",
	"\8\127\5\8\132\8\127\0\14\0\8\127\0\14\132\8\194\5\29\0\8\194\5\29\132\9\36\5\82\0\9\29\5\75\132\9\180\5\103\0",
	"\9\194\5\92\132\10\51\6\5\0\10\51\6\5\132\10\216\5\152\0\10\227\5\145\132\11\189\5\212\0\11\189\5\212\132\12\91\5\131\0",
	"\12\91\5\131\132\12\253\5\191\0\12\253\5\191\132\13\149\5\106\0\13\149\5\106\132\16\11\5\106\0\14\19\5\110\132\14\16\4\236\0",
	"\14\16\4\236\132\15\66\4\236\0\15\66\4\236\132\15\66\5\110\0\14\79\4\194\132\15\6\4\194\0\14\255\4\176\132\14\255\4\49\0",
	"\14\255\4\49\132\14\76\4\53\0\14\76\4\53\132\14\76\4\201\0\14\125\4\74\128\14\128\4\187\0\14\188\4\77\128\14\185\4\179\0",
	"\14\111\4\39\129\14\76\3\252\0\14\72\3\249\129\14\72\3\147\0\14\72\3\147\129\14\97\3\235\0\14\97\3\235\129\14\146\4\28\0",
	"\14\202\4\28\129\14\248\3\238\0\14\248\3\238\129\15\17\3\133\0\15\17\3\133\129\15\27\3\235\0\15\27\3\235\129\14\230\4\49\0",
	"\1\124\6\220\130\1\244\7\13\0\1\244\7\13\130\2\104\6\206\0\2\100\6\206\130\2\30\6\178\0\2\12\6\181\130\1\135\6\213\0",
	"\3\172\7\136\130\15\41\7\136\0\15\41\7\136\130\15\41\7\62\0\15\41\7\62\130\3\175\7\52\0\3\175\7\52\130\3\126\6\206\0",
	"\3\126\6\206\130\3\122\7\133\0\3\122\7\133\130\3\186\7\136\0\8\123\7\94\136\9\173\7\101\0\8\88\7\66\130\8\88\7\119\0",
	"\9\212\7\69\130\9\212\7\126\0\8\155\0\14\133\8\151\5\11\0\8\190\2\160\131\8\194\5\1\0\14\83\3\235\131\14\114\4\21\0",
	"\15\10\3\196\131\15\10\3\235\0\15\10\3\235\131\14\220\4\32\0\14\65\5\47\137\15\20\5\36\0\15\41\5\82\132\15\41\5\82\0",
	"\3\94\3\17\138\4\137\5\124\0\3\221\3\119\138\5\57\4\250\0\4\102\4\67\160\5\26\4\74\0\4\113\5\36\161\5\142\4\222\0",
	"\4\42\5\216\169\9\89\6\26\0\6\100\5\22\145\8\134\5\64\0\6\255\4\197\140\7\161\4\120\0\7\214\4\204\146\7\214\4\204\0",
	"\10\55\6\97\147\11\13\5\247\0\11\59\6\26\146\11\224\6\30\0\12\95\6\16\153\14\55\6\90\0\13\173\5\226\153\15\196\5\212\0",
	"\15\172\7\91\152\15\165\5\230\0\15\235\7\221\142\255\238\7\207\0\14\248\6\188\152\3\217\6\178\0\3\112\6\83\143\3\31\7\101\0",
	"\3\73\7\143\140\3\73\7\143\0\15\62\7\13\140\15\62\7\13\0\15\101\7\157\140\15\101\7\157\0\2\181\6\220\141\1\205\7\108\0",
	"\2\86\6\160\137\2\150\6\128\0\2\26\6\153\134\1\96\6\195\0\1\82\6\241\136\1\226\7\59\0\2\157\7\98\155\2\157\7\98\0",
	"\1\64\7\80\149\255\249\7\27\0\1\4\6\174\148\0\25\6\86\0\0\211\6\58\139\0\7\5\219\0\0\35\5\159\142\0\4\5\47\0",
	"\8\123\0\14\199\8\187\0\11\0\16\14\5\99\199\16\14\7\245\0\255\235\4\218\199\255\238\8\25\0\8\67\2\72\202\8\208\2\72\0",
	"\8\141\1\251\202\8\141\0\74\0\8\201\2\143\195\8\204\4\49\0\8\84\2\185\205\8\204\2\188\0\8\99\2\230\205\8\187\2\230\0",
	"\8\165\3\41\131\8\144\3\3\0\8\144\3\3\131\8\60\2\248\0\8\60\2\248\131\7\252\3\59\0\7\252\3\59\131\8\137\3\31\0",
	"\8\56\3\20\131\8\102\3\20\0\8\60\3\13\194\8\60\3\13\0\8\60\3\3\128\8\60\3\31\0\7\238\3\66\128\7\214\3\84\0",
	"\7\217\3\87\128\7\217\3\98\0\7\217\3\87\128\7\200\3\91\0\6\209\4\70\208\8\18\4\95\0\0\11\4\225\131\0\0\8\21\0",
	"\15\224\5\99\131\15\245\7\252\0\15\242\5\191\192\15\196\6\33\0\15\196\6\33\192\15\245\6\209\0\15\245\6\209\192\15\193\7\115\0",
	"\15\193\7\115\192\15\235\8\18\0\15\249\5\223\196\15\217\6\40\0\15\217\6\40\196\16\4\6\188\0\15\245\6\16\196\16\21\7\77\0",
	"\16\0\6\245\196\15\214\7\112\0\15\207\7\129\196\16\0\8\4\0\15\245\7\80\196\16\4\7\207\0\15\221\5\85\196\16\11\5\184\0",
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

nativeNames = {loc("Leaks A Lot"), loc("Dense Cloud"), loc("Fiery Water"), 
               loc("Raging Buffalo"), loc("Righteous Beard"), loc("Fell From Grace"),
               loc("Wise Oak"), loc("Ramon"), loc("Spiky Cheese")
              }

nativeUnNames = {loc("Zork"), loc("Steve"), loc("Jack"),
                 loc("Lee"), loc("Elmo"), loc("Rachel"),
                 loc("Muriel")}

nativeHats = {"Rambo", "RobinHood", "pirate_jack", "zoo_Bunny", "IndianChief",
              "tiara", "AkuAku", "rasta", "hair_yellow"}

nativePos = {{110, 1310}, {984, 1907}, {1040, 1907}}
nativePos2 = {196, 1499}

cyborgNames = {loc("Unit 0x0007"), loc("Hogminator"), loc("Carol"), 
               loc("Blender"), loc("Elderbot"), loc("Fiery Water")}
cyborgsDif = {2, 2, 2, 2, 2, 1}
cyborgsHealth = {45, 45, 45, 40, 40, 20}
cyborgPos = {945, 1216}
cyborgsNum = 6
cyborgsPos = {{2243, 1043}, {3588, 1227}, {2781, 1388},
              {3749, 1040}, {2475, 1338}, {3853, 881}}
cyborgsDir = {"Left", "Left", "Left", "Left", "Left", "Right"}

princessTeamName = nil
nativesTeamName = nil
biomechanicTeamName = nil
cyborgTeamName = nil

princessPos = {3737, 1181}
crateConsts = {}
reactions = {}

nativeMidPos = {1991, 841}
cyborgMidPos = {2109, 726}
nativeMidPos2 = {2250, 1071}
-----------------------------Variables---------------------------------
natives = {}
native = nil

cyborgs = {}
cyborg = nil

gearDead = {}
hedgeHidden = {}

startAnim = {}
midAnim = {}
princessFreedAnim = {}

freshDead = nil
crates = {}
cratesNum = 0

princessFreed = false
closeToPrincess = false
friendsEscaped = false
-----------------------------Animations--------------------------------
function EmitDenseClouds(dir)
  local dif
  if dir == "Left" then
    dif = 10
  else
    dif = -10
  end
  AnimInsertStepNext({func = AnimVisualGear, args = {natives[1], GetX(natives[1]) + dif, GetY(natives[1]) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimVisualGear, args = {natives[1], GetX(natives[1]) + dif, GetY(natives[1]) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimVisualGear, args = {natives[1], GetX(natives[1]) + dif, GetY(natives[1]) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimWait, args = {natives[1], 800}})
  AnimInsertStepNext({func = AnimVisualGear, args = {natives[1], GetX(natives[1]) + dif, GetY(natives[1]) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimVisualGear, args = {natives[1], GetX(natives[1]) + dif, GetY(natives[1]) + dif, vgtSteam, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimWait, args = {natives[1], 800}})
  AnimInsertStepNext({func = AnimVisualGear, args = {natives[1], GetX(natives[1]) + dif, GetY(natives[1]) + dif, vgtSteam, 0, true}, swh = false})
end

function AnimationSetup()
  table.insert(startAnim, {func = AnimWait, args = {natives[1], 4000}})
  table.insert(startAnim, {func = AnimMove, args = {natives[1], "Right", unpack(nativePos2)}})
  if m5DeployedNum == leaksNum then
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Those aliens are destroying the island!"), SAY_THINK, 5000}})
  elseif m5DeployedNum == denseNum then
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Dude, all the plants are gone!"), SAY_THINK, 3500}})
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("What am I gonna...eat, yo?"), SAY_THINK, 3500}})
  elseif m5DeployedNum == girlNum then
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Fell From Heaven is the best! Fell From Heaven is the greatest!"), SAY_THINK, 7000}})
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Yuck! I bet they'll keep worshipping her even after I save the village!"), SAY_THINK, 7500}})
  elseif m5DeployedNum == chiefNum then
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("I'm getting old for this!"), SAY_THINK, 4000}})
  elseif m5DeployedNum == waterNum then
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("I'm getting thirsty..."), SAY_THINK, 3000}})
  elseif m5DeployedNum == buffaloNum then
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("I wonder why I'm so angry all the time..."), SAY_THINK, 6000}})
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("It must be a childhood trauma..."), SAY_THINK, 4000}})
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Just wait till I get my hands on that trauma! ARGH!"), SAY_THINK, 6500}})
  elseif m5DeployedNum == wiseNum then
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("I could just teleport myself there..."), SAY_THINK, 4500}})
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("It's a shame, I forgot how to do that!"), SAY_THINK, 4500}})
  end
  table.insert(startAnim, {func = AnimCustomFunction, args = {natives[1], RestoreHedge, {cyborg}}})
  table.insert(startAnim, {func = AnimOutOfNowhere, args = {cyborg, unpack(cyborgPos)}})
  table.insert(startAnim, {func = AnimTurn, args = {cyborg, "Left"}})
  table.insert(startAnim, {func = AnimTurn, args = {natives[2], "Left"}})
  table.insert(startAnim, {func = AnimTurn, args = {natives[3], "Left"}})
  table.insert(startAnim, {func = AnimSay, args = {cyborg, string.format(loc("Hello again, %s!"), nativeUnNames[m5DeployedNum]), SAY_SAY, 2500}})
  table.insert(startAnim, {func = AnimSay, args = {cyborg, loc("I just found out that they have captured your princess!"), SAY_SAY, 7000}})
  if m5DeployedNum == girlNum then
    table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Of course I have to save her. What did I expect?!"), SAY_SAY, 7000}})
  elseif m5DeployedNum == denseNum then
    table.insert(startAnim, {func = AnimCustomFunction, args = {natives[1], EmitDenseClouds, {"Right"}}})
  end
  table.insert(startAnim, {func = AnimSay, args = {cyborg, loc("She's behind that tall thingy."), SAY_SAY, 5000}})
  table.insert(startAnim, {func = FollowGear, swh = false, args = {princess}})
  table.insert(startAnim, {func = AnimWait, swh = false, args = {princess, 1000}})
  table.insert(startAnim, {func = FollowGear, swh = false, args = {cyborg}})
  table.insert(startAnim, {func = AnimSay, args = {cyborg, loc("I'm here to help you rescue her."), SAY_SAY, 5000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[2], loc("Yo, dude, we're here, too!"), SAY_SHOUT, 4000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[3], loc("We were trying to save her and we got lost."), SAY_SHOUT, 6000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("That's typical of you!"), SAY_SAY, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {natives[1], loc("Why are you helping us, uhm...?"), SAY_SAY, 3000}})
  table.insert(startAnim, {func = AnimSay, args = {cyborg, loc("Call me Beep! Well, 'cause I'm such a nice...person!"), SAY_SAY, 2500}})
  table.insert(startAnim, {func = AnimDisappear, args = {cyborg, unpack(cyborgPos)}})
  table.insert(startAnim, {func = AnimSwitchHog, args = {natives[1]}})
  table.insert(startAnim, {func = AnimWait, args = {natives[1], 1}})
  AddSkipFunction(startAnim, SkipStartAnim, {})

  table.insert(midAnim, {func = AnimCustomFunction, args = {natives[1], RestoreHedge, {cyborg}}})
  table.insert(midAnim, {func = AnimOutOfNowhere, args = {cyborg, unpack(cyborgMidPos)}}) 
  table.insert(midAnim, {func = AnimTurn, args = {cyborg, "Left"}})
  table.insert(midAnim, {func = AnimTeleportGear, args = {natives[1], unpack(nativeMidPos)}})
  table.insert(midAnim, {func = AnimSay, args = {cyborg, loc("Here, let me help you save her!"), SAY_SAY, 5000}})
  table.insert(midAnim, {func = AnimSay, args = {natives[1], loc("Thanks!"), SAY_SAY, 2000}})
  table.insert(midAnim, {func = AnimTeleportGear, args = {natives[1], unpack(nativeMidPos2)}})
  table.insert(midAnim, {func = AnimSay, args = {natives[1], loc("Why can't he just let her go?!"), SAY_THINK, 5000}})
  AddSkipFunction(midAnim, SkipMidAnim, {})

  table.insert(princessFreedAnim, {func = AnimSay, args = {princess, loc("Thank you, my hero!"), SAY_SAY, 4000}})
  table.insert(princessFreedAnim, {func = Victory, args = {}})
  AddSkipFunction(princessFreedAnim, SkipPrincessFreedAnim, {})
end

--------------------------Anim skip functions--------------------------
function AfterMidAnim()
  HideHedge(cyborg)
  SetupPlace3()
  SetGearMessage(natives[1], 0)
  AddNewEvent(CheckPrincessFreed, {}, DoPrincessFreed, {}, 0)
  AddNewEvent(CheckCloseToPrincess, {}, DoCloseToPrincess, {}, 0)
  AddNewEvent(CheckFriendsEscaped, {}, DoFriendsEscaped, {}, 0)
  EndTurn(true)
  ShowMission(loc("Family Reunion"), loc("Salvation"),
     loc("Get your teammates out of their natural prison and save the princess!") .."|"..
     loc("All your hedgehogs must be above the marked height!") .."|"..
     loc("Hint: Drilling holes should solve everything.").."|"..
     loc("Hint: It might be a good idea to place a girder before starting to drill. Just saying.").."|"..
     string.format(loc("Hint: %s needs to get really close to the princess!"), nativeNames[m5DeployedNum]).."|"..
     loc("Mines time: 5 seconds"), 1, 7000)
  local vCirc = AddVisualGear(0,0,vgtCircle,0,true)
  SetVisualGearValues(vCirc, 2625, 1500, 100, 255, 1, 10, 0, 120, 3, 0xff00ffff)
end

function SkipPrincessFreedAnim()
  Victory()
end

function SkipMidAnim()
  AnimTeleportGear(natives[1], unpack(nativeMidPos2))
  AnimSwitchHog(natives[1])
  AnimWait(natives[1], 1)
end

function SetupPlace3()
  SpawnSupplyCrate(2086, 1887, amRope, 1)
  SpawnSupplyCrate(2147, 728, amBlowTorch, 2)
  SpawnSupplyCrate(2778, 1372, amPickHammer, 4)
  SpawnSupplyCrate(2579, 1886, amPickHammer, 3)
  SpawnSupplyCrate(2622, 1893, amGirder, 1)
  SpawnSupplyCrate(2671, 1883, amPortalGun, 3)
  SpawnSupplyCrate(2831, 1384, amGirder, 3)

  SetTimer(AddGear(2725, 1387, gtMine, 0, 0, 0, 0), 5000)
  SetTimer(AddGear(2760, 1351, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2805, 1287, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2831, 1376, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2684, 1409, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2637, 1428, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2278, 1280, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2311, 1160, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2339, 1162, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2362, 1184, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2407, 1117, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2437, 1143, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2472, 1309, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2495, 1331, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2536, 1340, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2569, 1360, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2619, 1379, gtMine, 0, 0, 0, 0), 5000)
	SetTimer(AddGear(2596, 1246, gtMine, 0, 0, 0, 0), 5000)
end

function SkipStartAnim()
  AnimSetGearPosition(natives[1], unpack(nativePos2))
  AnimSwitchHog(natives[1])
  AnimWait(natives[1], 1)
end

function AfterStartAnim()
  HideHedge(cyborg)
  SetupPlace2()
  SetGearMessage(natives[1], 0)
  AddNewEvent(CheckGearDead, {natives[1]}, EndMission, {}, 0)
  AddNewEvent(CheckGearDead, {natives[2]}, EndMission, {}, 0)
  AddNewEvent(CheckGearDead, {natives[3]}, EndMission, {}, 0)
  AddNewEvent(CheckGearDead, {princess}, EndMission, {}, 0)
  AddNewEvent(CheckCyborgsDead, {}, DoCyborgsDead, {}, 0)
  for i = 1, cyborgsNum do
    AddNewEvent(CheckGearDead, {cyborgs[i]}, DoCyborgDead, {i}, 0)
  end
  AddNewEvent(CheckOutOfCluster, {}, DoOutOfCluster, {}, 1)
  AddNewEvent(CheckOutOfGrenade, {}, DoOutOfGrenade, {}, 1)
--  AddNewEvent(CheckNeedToHide, {}, DoNeedToHide, {}, 1)
  SetTurnTimeLeft(TurnTime)
  ShowMission(loc("Family Reunion"), loc("Hostage Situation"), loc("Save the princess! All your hogs must survive!|Hint: Kill the cyborgs first! Use the ammo very carefully!|Hint: You might want to spare a girder for cover!"), 1, 7000)
end

function SetupPlace2()
	PlaceGirder(709, 564, 7)
	PlaceGirder(591, 677, 7)
	PlaceGirder(473, 794, 7)
	PlaceGirder(433, 933, 5)
	PlaceGirder(553, 1052, 5)
	PlaceGirder(674, 1170, 5)
	PlaceGirder(710, 1310, 7)
	PlaceGirder(648, 1427, 5)
  PlaceGirder(2110, 980, 0)

	SpawnSupplyCrate(814, 407, amBazooka, 4)
	clusterCrate = SpawnSupplyCrate(862, 494, amClusterBomb, 4)
	SpawnSupplyCrate(855, 486, amBee, 3)
	grenadeCrate1 = SpawnSupplyCrate(849, 459, amGrenade, 4)
	SpawnSupplyCrate(2077, 847, amWatermelon, 3)
	grenadeCrate2 = SpawnSupplyCrate(2122, 847, amGrenade, 3)

	SpawnSupplyCrate(747, 1577, amPickHammer, 1)
	SpawnSupplyCrate(496, 1757, amGirder, 2)
	SpawnSupplyCrate(1809, 1880, amGirder, 1)
	SpawnSupplyCrate(530, 1747, amPortalGun, 1)
end

-----------------------------Events------------------------------------
function CheckCloseToPrincess()
  if GetX(natives[1]) == nil or GetX(princess) == nil then
    return false
  end
  return math.abs(GetX(natives[1]) - GetX(princess)) <= 20 and math.abs(GetY(natives[1]) - GetY(princess)) <= 17 and StoppedGear(natives[1])
end

function CheckFriendsEscaped()
  if GetX(natives[2]) == nil or GetX(natives[3]) == nil then
    return false
  end
  return GetY(natives[2]) < 1500 and GetY(natives[3]) < 1500 and StoppedGear(natives[2]) and StoppedGear(natives[3])
end

function CheckPrincessFreed()
  return CheckCloseToPrincess() and CheckFriendsEscaped()
end

function DoPrincessFreed()
  AddAnim(princessFreedAnim)
end

function DoFriendsEscaped()
  if friendsEscaped then
    return
  end
  if not CheckCloseToPrincess() then
    if GetX(natives[2]) == nil and GetX(natives[1]) == nil then
      return
    end
    HogSay(natives[2], string.format(loc("Finally! We're out of this hellhole. Now go save the princess, %s!"), nativeNames[m5DeployedNum]), SAY_SAY)
  end
  friendsEscaped = true
end

function DoCloseToPrincess()
  if closeToPrincess then
    return
  end
  if not CheckFriendsEscaped() then
    if GetX(natives[2]) == nil then
      return
    end
    HogSay(natives[2], loc("Hey, don't forget us! We still need to climb up!"), SAY_SHOUT)
    FollowGear(natives[2])
  end
  closeToPrincess = true
end

function Victory()
  if not princessFreed then
    if progress and progress<7 then
      SaveCampaignVar("Progress", "7")
    end
    princessFreed = true
    DismissTeam(cyborgTeamName)
    EndTurn(true)
  end
end

function CheckCyborgsDead()
  return cyborgsLeft == 0
end

function DoCyborgsDead()
  SetGearMessage(CurrentHedgehog, 0)
  RestoreHedge(princess)
--  RemoveEventFunc(CheckNeedToHide)
  AddAnim(midAnim)
  AddFunction({func = AfterMidAnim, args = {}})
end

function DoCyborgDead(index)
  if cyborgsLeft == 0 then
    return
  end
  if index == 1 then
    SpawnSupplyCrate(1700, 407, amBazooka, 3)
  elseif index == 2 then
    SpawnSupplyCrate(1862, 494, amClusterBomb, 3)
  elseif index == 3 then
    SpawnSupplyCrate(1855, 486, amBee, 1)
  elseif index == 4 then
    SpawnSupplyCrate(1849, 459, amGrenade, 3)
  elseif index == 5 then
    SpawnSupplyCrate(2122, 847, amGrenade, 3)
  elseif index == 6 then
    SpawnSupplyCrate(2077, 847, amWatermelon, 1)
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

function EndMission()
  if not princessFreed then
    RemoveEventFunc(CheckFriendsEscaped)
    RemoveEventFunc(CheckCloseToPrincess)
    RemoveEventFunc(CheckPrincessFreed)
    AddCaption(loc("So the princess was never heard of again ..."))
    DismissTeam(nativesTeamName)
    DismissTeam(princessTeamName)
    EndTurn(true)
  end
end

function CheckOutOfCluster()
  return CheckGearDead(clusterCrate) and GetAmmoCount(natives[1], amClusterBomb) == 0
end

function CheckOutOfGrenade()
  return CheckGearDead(grenadeCrate1) and CheckGearDead(grenadeCrate2) and GetAmmoCount(natives[1], amGrenade) == 0
end

function DoOutOfCluster()
  if (GetX(natives[1]) == nil) then
    return
  end
  clusterCrate = SpawnSupplyCrate(GetX(natives[1]) - 50, GetY(natives[1]) - 50, amClusterBomb, 3)
end

function DoOutOfGrenade()
  if (GetX(natives[1]) == nil) then
    return
  end
  grenadeCrate2 = SpawnSupplyCrate(GetX(natives[1]) - 50, GetY(natives[1]) - 50, amGrenade, 3)
end

function CheckNeedToHide()
  if gearDead[princess] == true then
    return false
  end
  return TurnTimeLeft == 0
end

function DoNeedToHide()
  HideHedge(princess)
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
end

function SetupPlace()
  SetHogHat(natives[1], nativeHats[m5DeployedNum])
  SetHogName(natives[1], nativeNames[m5DeployedNum])
  if m2Choice ~= choiceAccepted or m5Choice ~= choiceEliminate then
    DeleteGear(cyborgs[cyborgsNum])
    cyborgsNum = cyborgsNum - 1
  end
  HideHedge(cyborg)
end

function SetupAmmo()
  AddAmmo(cyborgs[1], amBazooka, 100)
  AddAmmo(cyborgs[1], amGrenade, 100)
  AddAmmo(cyborgs[1], amClusterBomb, 100)
  AddAmmo(cyborgs[1], amSniperRifle, 1)
  AddAmmo(cyborgs[1], amDynamite, 100)
  AddAmmo(cyborgs[1], amBaseballBat, 100)
  AddAmmo(cyborgs[1], amMolotov, 100)
  AddAmmo(cyborgs[1], amWatermelon, 1)
  AddAmmo(cyborgs[1], amAirAttack, 2)
  AddAmmo(cyborgs[1], amDrillStrike, 1)
end

function AddHogs()
  princessTeamName = AddTeam(loc("Princess"), -2, "Bone", "Island", "HillBilly_qau", "cm_female")
  SetTeamPassive(princessTeamName, true)
  princess = AddHog(loc("Fell From Heaven"), 0, 333, "tiara")
  SetGearAIHints(princess, aihDoesntMatter)
  gearDead[princess] = false

  nativesTeamName = AddMissionTeam(-2)
  for i = 7, 9 do
    natives[i-6] = AddHog(nativeNames[i], 0, 100, nativeHats[i])
    gearDead[natives[i-6]] = false
  end

  cyborgTeamName = AddTeam(loc("011101001"), -1, "ring", "UFO", "Robot_qau", "cm_binary")
  cyborg = AddHog(loc("Unit 334a$7%;.*"), 0, 200, "cyborg1")
  gearDead[cyborg] = false

  biomechanicTeamName = AddTeam(loc("Biomechanic Team"), -1, "ring", "UFO", "Robot_qau", "cm_cyborg")
  for i = 1, cyborgsNum do
    cyborgs[i] = AddHog(cyborgNames[i], cyborgsDif[i], cyborgsHealth[i], "cyborg2")
    gearDead[cyborgs[i]] = false
  end
  cyborgsLeft = cyborgsNum

  for i = 1, 3 do
    AnimSetGearPosition(natives[i], unpack(nativePos[i]))
  end

  AnimSetGearPosition(cyborg, unpack(cyborgPos))
  AnimSetGearPosition(princess, unpack(princessPos))
  AnimTurn(princess, "Left")

  for i = 1, cyborgsNum do
    AnimSetGearPosition(cyborgs[i], unpack(cyborgsPos[i]))
    AnimTurn(cyborgs[i], cyborgsDir[i])
  end
end

function CondNeedToTurn(hog1, hog2)
  xl, xd = GetX(hog1), GetX(hog2)
  if xl == nil or xd == nil then
    return
  end
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
	GameFlags = gfSolidLand + gfDisableLandObjects + gfDisableGirders
	TurnTime = 60000 
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 3000
	Explosives = 0
  MapGen = mgDrawn
	Theme = "Hell"
  WaterRise = 0
  HealthDecrease = 0

	for i = 1, #map do
		ParseCommand('draw ' .. map[i])
	end

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
  if GetGearType(gear) == gtHedgehog then
    if GetHogTeamName(gear) == biomechanicTeamName then
      cyborgsLeft = cyborgsLeft - 1
    end
  end
end

function onAmmoStoreInit()
  SetAmmo(amSkip, 9, 0, 0, 0)
  SetAmmo(amSwitch, 9, 0, 0, 0)
	SetAmmo(amBazooka, 0, 0, 0, 8)
	SetAmmo(amClusterBomb,0, 0, 0, 8)
	SetAmmo(amBee, 0, 0, 0, 3)
	SetAmmo(amGrenade, 0, 0, 0, 8)
	SetAmmo(amWatermelon, 0, 0, 0, 2)
	SetAmmo(amSniperRifle, 0, 0, 0, 3)
	SetAmmo(amPickHammer, 0, 0, 0, 1)
	SetAmmo(amGirder, 0, 0, 0, 3)
	SetAmmo(amPortalGun, 0, 0, 0, 1)
end

function onNewTurn()
  if AnimInProgress() then
    SetTurnTimeLeft(MAX_TURN_TIME)
    return
  end
  if CurrentHedgehog == cyborg then
    if CheckCyborgsDead() ~= true then
      for i = 1, 3 do
        if gearDead[natives[i]] ~= true then
          HideHedge(natives[i])
        end
      end
    end
    EndTurn(true)
  else
    for i = 1, 3 do
      if gearDead[natives[i]] ~= true then
        RestoreHedge(natives[i])
      end
    end
  end
end

function onPrecise()
  if GameTime > 2500 and AnimInProgress() then
    SetAnimSkip(true)
    return
  end
--  HideHedge(princess)
--  for i = 1, 5 do
--    DeleteGear(cyborgs[i])
--  end
--  AddAmmo(natives[1], amTeleport, 100)
end
