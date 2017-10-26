HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

-----------------------------Constants---------------------------------
startStage = 0
spyStage = 1
wave1Stage = 2
wave2Stage = 3
cyborgStage = 4
ramonStage = 5
aloneStage = 6
duoStage = 7
interSpyStage = 8
interWeakStage = 9
acceptedReturnStage = 10
refusedReturnStage = 11
attackedReturnStage = 12
loseStage = 13

ourTeam = 0
weakTeam = 1
strongTeam = 2
cyborgTeam = 3

leaksNr = 0
denseNr = 1

choiceAccept = 1
choiceRefuse = 2
choiceAttack = 3

HogNames = {loc("Brainiac"), loc("Corpsemonger"), loc("Femur Lover"), loc("Glark"), loc("Bonely"), loc("Rot Molester"), loc("Bloodrocutor"), loc("Muscle Dissolver"), loc("Bloodsucker")}

---POSITIONS---

cannibalPos = {{3108, 1127}, 
               {2559, 1080}, {3598, 1270}, {3293, 1177}, {2623, 1336}, 
               {3418, 1336}, {3447, 1335}, {3481, 1340}, {3507, 1324}} 
densePos = {2776, 1177}
leaksPos = {2941, 1172}
cyborgPos = {1113, 1818}

---Animations

startDialogue = {}
weaklingsAnim = {}
stronglingsAnim = {}
acceptedAnim = {}
acceptedSurvivedFinalAnim = {}
acceptedDiedFinalAnim = {}
refusedAnim = {}
refusedFinalAnim = {}
attackedAnim = {}
attackedFinalAnim = {}

-----------------------------Variables---------------------------------
lastHogTeam = ourTeam
lastOurHog = leaksNr
lastEnemyHog = 0
stage = 0
choice = 0

brainiacDead = false
cyborgHidden = false
leaksHidden = false
denseHidden = false
cyborgAttacked = false
shotgunTaken = false
grenadeTaken = false
spikyDead = false
ramonDead = false
denseDead = false
leaksDead = false
ramonHidden = false
spikyHidden = false
grenadeUsed = false
shotgunUsed = false


hogNr = {}
cannibalDead = {}
isHidden = {}


--------------------------Anim skip functions--------------------------
function AfterRefusedAnim()
  if stage == loseStage then
    return
  end
  SpawnUtilityCrate(2045, 1575, amSwitch)
  SpawnAmmoCrate(2365, 1495, amShotgun)
  SpawnAmmoCrate(2495, 1519, amGrenade)
  SpawnUtilityCrate(2620, 1524, amRope)
  ShowMission(loc("The Shadow Falls"), loc("The Showdown"), loc("Save Leaks A Lot!|Hint: The switch hedgehog utility might be of help to you."), 1, 6000)
  RemoveEventFunc(CheckDenseDead)
  AddEvent(CheckStronglingsDead, {}, DoStronglingsDeadRefused, {}, 0)
  AddAmmo(cannibals[6], amGrenade, 1)
  AddAmmo(cannibals[7], amGrenade, 1)
  AddAmmo(cannibals[8], amGrenade, 1)
  AddAmmo(cannibals[9], amGrenade, 1)
  stage = ramonStage
  SwitchHog(cannibals[9])
  FollowGear(ramon)
  EndTurn(true)
  SetGearMessage(ramon, 0)
  SetGearMessage(leaks, 0)
  AnimWait(ramon, 1)
  AddFunction({func = HideHog, args = {cyborg}})
end

function SkipRefusedAnim()
  if stage == loseStage then
    return
  end
  RefusedStart()
  AnimSetGearPosition(dense, 2645, 1146)
  AnimSetGearPosition(ramon, 2218, 1675)
  AnimSetGearPosition(spiky, 2400, 1675)
end

function AfterStartDialogue()
  if stage == loseStage then
    return
  end
  stage = spyStage
  ShowMission(loc("The Shadow Falls"), loc("Play with me!"), loc("Kill the cannibal!").."|"..loc("Both your hedgehogs must survive."), 1, 6000)
  TurnTimeLeft = TurnTime
end


function StartSkipFunc()
  if stage == loseStage then
    return
  end
  SetState(cannibals[1], 0)
  AnimTurn(leaks, "Right")
  AnimSwitchHog(leaks)
  SetInputMask(0xFFFFFFFF)
end

function AfterWeaklingsAnim()
  if stage == loseStage then
    return
  end
  AddAmmo(cannibals[2], amShotgun, 1)
  AddAmmo(cannibals[2], amGrenade, 1)
  AddAmmo(cannibals[3], amShotgun, 1)
  AddAmmo(cannibals[3], amGrenade, 1)
  AddAmmo(cannibals[4], amShotgun, 1)
  AddAmmo(cannibals[4], amGrenade, 1)
  AddAmmo(cannibals[5], amShotgun, 1)
  AddAmmo(cannibals[5], amGrenade, 1)
  AddAmmo(leaks, amSkip, 100)
  AddAmmo(dense, amSkip, 100)
  AddEvent(CheckWeaklingsKilled, {}, DoWeaklingsKilled, {}, 0)
  SetHealth(SpawnHealthCrate(2757, 1030), 50)
  SetHealth(SpawnHealthCrate(2899, 1009), 50)
  stage = wave1Stage
  SwitchHog(dense)
  SetGearMessage(dense, 0)
  SetGearMessage(leaks, 0)
  TurnTimeLeft = TurnTime
  ShowMission(loc("The Shadow Falls"), loc("Why do you not like me?"), loc("Obliterate them!|Hint: You might want to take cover...").."|"..loc("Both your hedgehogs must survive."), 1, 6000)
end

function SkipWeaklingsAnim()
  if stage == loseStage then
    return
  end
  for i = 2, 5 do
    if isHidden[cannibals[i]] == true then
      RestoreHog(cannibals[i])
      isHidden[cannibals[i]] = false
    end
    AnimSetGearPosition(cannibals[i], unpack(cannibalPos[i]))
    SetState(cannibals[i], 0)
  end
  SetInputMask(0xFFFFFFFF)
end

function AfterStronglingsAnim()
  if stage == loseStage then
    return
  end
  stage = cyborgStage
  ShowMission(loc("The Shadow Falls"), loc("The Dilemma"), loc("Choose your side! If you want to join the strange man, walk up to him.|Otherwise, walk away from him. If you decide to att...nevermind..."), 1, 8000)
  AddEvent(CheckChoice, {}, DoChoice, {}, 0)
  AddEvent(CheckRefuse, {}, DoRefuse, {}, 0)
  AddEvent(CheckAccept, {}, DoAccept, {}, 0)
  AddEvent(CheckConfront, {}, DoConfront, {}, 0)
  AddAmmo(dense, amSwitch, 0)
  AddAmmo(dense, amSkip, 0)
  AddAmmo(leaks, amSwitch, 0)
  AddAmmo(leaks, amSkip, 0)
  SetHealth(SpawnHealthCrate(2557, 1030), 50)
  SetHealth(SpawnHealthCrate(3599, 1009), 50)
  EndTurn(true)
end

function SkipStronglingsAnim()
  if stage == loseStage then
    return
  end
  for i = 6, 9 do
    if isHidden[cannibals[i]] == true then
      RestoreHog(cannibals[i])
      isHidden[cannibals[i]] = false
    end
    AnimSetGearPosition(cannibals[i], unpack(cannibalPos[i]))
    SetState(cannibals[i], 0)
  end
  if cyborgHidden == true then
    RestoreHog(cyborg)
    cyborgHidden = false
  end
  SetState(cyborg, 0)
  SetState(dense, 0)
  AnimSetGearPosition(dense, 1350, 1315)
  FollowGear(dense)
  HogTurnLeft(dense, true)
  AnimSetGearPosition(cyborg, 1250, 1315)
  SwitchHog(dense)
  SetInputMask(0xFFFFFFFF)
end

function AfterAcceptedAnim()
  if stage == loseStage then
    return
  end
  stage = acceptedReturnStage
  SpawnUtilityCrate(1370, 810, amGirder)
  SpawnUtilityCrate(1300, 810, amParachute)
  ShowMission(loc("The Shadow Falls"), loc("The walk of Fame"), loc("Return to Leaks A Lot!"), 1, 6000)
  AddEvent(CheckReadyForStronglings, {}, DoReadyForStronglings, {}, 0)
  AddEvent(CheckNeedGirder, {}, DoNeedGirder, {}, 0)
  AddEvent(CheckNeedWeapons, {}, DoNeedWeapons, {}, 0)
  RemoveEventFunc(CheckDenseDead)
  SwitchHog(dense)
  AnimWait(dense, 1)
  AddFunction({func = HideHog, args = {cyborg}})
end

function SkipAcceptedAnim()
  if stage == loseStage then
    return
  end
  AnimSetGearPosition(cyborg, unpack(cyborgPos))
  SetState(cyborg, gstInvisible)
  AnimSwitchHog(dense)
  SetInputMask(0xFFFFFFFF)
end

function AfterAttackedAnim()
  if stage == loseStage then
    return
  end
  stage = aloneStage
  ShowMission(loc("The Shadow Falls"), loc("The Individualist"), loc("Defeat the cannibals!|Grenade hint: set the timer with [1-5], aim with [Up]/[Down] and hold [Space] to set power"), 1, 8000)
  AddAmmo(cannibals[6], amGrenade, 1)
  AddAmmo(cannibals[6], amFirePunch, 0)
  AddAmmo(cannibals[6], amBaseballBat, 0)
  AddAmmo(cannibals[7], amGrenade, 1)
  AddAmmo(cannibals[7], amFirePunch, 0)
  AddAmmo(cannibals[7], amBaseballBat, 0)
  AddAmmo(cannibals[8], amGrenade, 1)
  AddAmmo(cannibals[8], amFirePunch, 0)
  AddAmmo(cannibals[8], amBaseballBat, 0)
  AddAmmo(cannibals[9], amGrenade, 1)
  AddAmmo(cannibals[9], amFirePunch, 0)
  AddAmmo(cannibals[9], amBaseballBat, 0)
  SetGearMessage(leaks, 0)
  TurnTimeLeft = TurnTime
  AddEvent(CheckStronglingsDead, {}, DoStronglingsDeadAttacked, {}, 0)
  SwitchHog(leaks)
  AnimWait(dense, 1)
  AddFunction({func = HideHog, args = {cyborg}})
end

function SkipAttackedAnim()
  if stage == loseStage then
    return
  end
  if denseDead == false then
    DeleteGear(dense)
  end
  SpawnAmmoCrate(2551, 994, amGrenade)
  SpawnAmmoCrate(3551, 994, amGrenade)
  SpawnAmmoCrate(3392, 1101, amShotgun)
  SpawnAmmoCrate(3192, 1101, amShotgun)
  AnimSetGearPosition(cyborg, unpack(cyborgPos))
  SetState(cyborg, gstInvisible)
  AnimSwitchHog(leaks)
  SetInputMask(0xFFFFFFFF)
end

  
-----------------------------Animations--------------------------------

function SpawnCrates()
  SpawnAmmoCrate(2551, 994, amGrenade)
  SpawnAmmoCrate(3551, 994, amGrenade)
  SpawnAmmoCrate(3392, 1101, amShotgun)
  SpawnAmmoCrate(3192, 1101, amShotgun)
  return true
end

function EmitDenseClouds(anim, dir)
  if stage == loseStage then
    return
  end
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

function BlowDenseCloud()
  if stage == loseStage then
    return
  end
  AnimInsertStepNext({func = DeleteGear, args = {dense}, swh = false}) 
  AnimInsertStepNext({func = AnimVisualGear, args = {dense, GetX(dense), GetY(dense), vgtBigExplosion, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimWait, args = {dense, 1200}})
  AnimInsertStepNext({func = AnimVisualGear, args = {dense, GetX(dense) + 20, GetY(dense), vgtExplosion, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimWait, args = {dense, 100}})
  AnimInsertStepNext({func = AnimVisualGear, args = {dense, GetX(dense) + 10, GetY(dense), vgtExplosion, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimWait, args = {dense, 100}})
  AnimInsertStepNext({func = AnimVisualGear, args = {dense, GetX(dense) - 10, GetY(dense), vgtExplosion, 0, true}, swh = false})
  AnimInsertStepNext({func = AnimWait, args = {dense, 100}})
  AnimInsertStepNext({func = AnimVisualGear, args = {dense, GetX(dense) - 20, GetY(dense), vgtExplosion, 0, true}, swh = false})
end

function SetupAcceptedSurvivedFinalAnim()
  table.insert(acceptedSurvivedFinalAnim, {func = AnimCustomFunction, args = {dense, CondNeedToTurn, {leaks, dense}}})
  table.insert(acceptedSurvivedFinalAnim, {func = AnimSay, args = {leaks, loc("Pfew! That was close!"), SAY_SAY, 3000}})
  if grenadeUsed and shotgunUsed then
    table.insert(acceptedSurvivedFinalAnim, {func = AnimSay, args = {leaks, loc("Where did you get the exploding apples and the magic bow that shoots many arrows?"), SAY_SAY, 9000}})
  elseif grenadeUsed then
    table.insert(acceptedSurvivedFinalAnim, {func = AnimSay, args = {leaks, loc("Where did you get the exploding apples?"), SAY_SAY, 6000}})
  elseif shotgunUsed then
    table.insert(acceptedSurvivedFinalAnim, {func = AnimSay, args = {leaks, loc("Where did you get the magic bow that shoots many arrows?"), SAY_SAY, 8000}})
  else
    table.insert(acceptedSurvivedFinalAnim, {func = AnimSay, args = {leaks, loc("Did you warn the village?"), SAY_SAY, 4000}})
    table.insert(acceptedSurvivedFinalAnim, {func = AnimSay, args = {dense, loc("No, I came back to help you out..."), SAY_SAY, 5000}})
  end
  if grenadeUsed or shotgunUsed then
    table.insert(acceptedSurvivedFinalAnim, {func = AnimSay, args = {dense, loc("Uhm...I met one of them and took his weapons."), SAY_SAY, 5000}})
  end
  table.insert(acceptedSurvivedFinalAnim, {func = AnimSay, args = {dense, loc("We should head back to the village now."), SAY_SAY, 5000}})
end

function AnimationSetup()
  table.insert(startDialogue, {func = AnimWait, args = {dense, 4000}})
  table.insert(startDialogue, {func = AnimCaption, args = {leaks, loc("After the shock caused by the enemy spy, Leaks A Lot and Dense Cloud went hunting to relax."), 6000}})
  table.insert(startDialogue, {func = AnimCaption, args = {leaks, loc("Little did they know that this hunt will mark them forever..."), 4000}})
  table.insert(startDialogue, {func = AnimSay, args = {leaks, loc("I have no idea where that mole disappeared...Can you see it?"), SAY_SAY, 9000}})
  table.insert(startDialogue, {func = AnimSay, args = {dense, loc("Nope. It was one fast mole, that's for sure."), SAY_SAY, 5000}}) 
  table.insert(startDialogue, {func = AnimCustomFunction, args = {dense, EmitDenseClouds, {startDialogue, "Right"}}})
  table.insert(startDialogue, {func = AnimWait, args = {dense, 2000}})
  table.insert(startDialogue, {func = AnimSay, args = {leaks, loc("Please, stop releasing your \"smoke signals\"!"), SAY_SAY, 5000}})
  table.insert(startDialogue, {func = AnimSay, args = {leaks, loc("You're terrorizing the forest...We won't catch anything like this!"), SAY_SAY, 6000}})
  table.insert(startDialogue, {func = AnimSay, args = {leaks, loc("..."), SAY_THINK, 1000}})
  table.insert(startDialogue, {func = AnimGiveState, args = {cannibals[1], 0}, swh = false})
  table.insert(startDialogue, {func = AnimOutOfNowhere, args = {cannibals[1], unpack(cannibalPos[1])}, swh = false})
  table.insert(startDialogue, {func = AnimTurn, args = {leaks, "Right"}})
  table.insert(startDialogue, {func = AnimTurn, args = {cannibals[1], "Right"}})
  table.insert(startDialogue, {func = AnimWait, args = {cannibals[1], 1000}})
  table.insert(startDialogue, {func = AnimTurn, args = {cannibals[1], "Left"}})
  table.insert(startDialogue, {func = AnimWait, args = {cannibals[1], 1000}})
  table.insert(startDialogue, {func = AnimTurn, args = {cannibals[1], "Right"}})
  table.insert(startDialogue, {func = AnimSay, args = {cannibals[1], loc("I can't believe it worked!"), SAY_THINK, 3500}})
  table.insert(startDialogue, {func = AnimSay, args = {cannibals[1], loc("That shaman sure knows what he's doing!"), SAY_THINK, 6000}})
  table.insert(startDialogue, {func = AnimSay, args = {cannibals[1], loc("Yeah...I think it's a 'he', lol."), SAY_THINK, 5000}})
  table.insert(startDialogue, {func = AnimSay, args = {leaks, loc("It wants our brains!"), SAY_SHOUT, 3000}})
  table.insert(startDialogue, {func = AnimTurn, args = {cannibals[1], "Left"}})
  table.insert(startDialogue, {func = AnimSay, args = {cannibals[1], loc("Not you again! My head still hurts from last time!"), SAY_SHOUT, 6000}})
  table.insert(startDialogue, {func = AnimSwitchHog, args = {leaks}})
  AddSkipFunction(startDialogue, StartSkipFunc, {})

  table.insert(weaklingsAnim, {func = AnimGearWait, args = {leaks, 1000}})
  table.insert(weaklingsAnim, {func = AnimCustomFunction, args = {leaks, CondNeedToTurn, {leaks, dense}}})
  table.insert(weaklingsAnim, {func = AnimSay, args = {leaks, loc("Did you see him coming?"), SAY_SAY, 3500}})
  table.insert(weaklingsAnim, {func = AnimSay, args = {dense, loc("No. Where did he come from?"), SAY_SAY, 3500}})
  table.insert(weaklingsAnim, {func = AnimCustomFunction, args = {leaks, UnHideWeaklings, {}}})
  table.insert(weaklingsAnim, {func = AnimOutOfNowhere, args = {cannibals[2], unpack(cannibalPos[2])}})
  table.insert(weaklingsAnim, {func = AnimGiveState, args = {cannibals[2], 0}})
  table.insert(weaklingsAnim, {func = AnimWait, args = {leaks, 400}})
  table.insert(weaklingsAnim, {func = AnimGiveState, args = {cannibals[3], 0}})
  table.insert(weaklingsAnim, {func = AnimOutOfNowhere, args = {cannibals[3], unpack(cannibalPos[3])}})
  table.insert(weaklingsAnim, {func = AnimWait, args = {leaks, 400}})
  table.insert(weaklingsAnim, {func = AnimGiveState, args = {cannibals[4], 0}})
  table.insert(weaklingsAnim, {func = AnimOutOfNowhere, args = {cannibals[4], unpack(cannibalPos[4])}})
  table.insert(weaklingsAnim, {func = AnimWait, args = {leaks, 400}})
  table.insert(weaklingsAnim, {func = AnimGiveState, args = {cannibals[5], 0}})
  table.insert(weaklingsAnim, {func = AnimOutOfNowhere, args = {cannibals[5], unpack(cannibalPos[5])}})
  table.insert(weaklingsAnim, {func = AnimWait, args = {leaks, 400}})
  table.insert(weaklingsAnim, {func = AnimSay, args = {cannibals[3], loc("Are we there yet?"), SAY_SAY, 4000}}) 
  table.insert(weaklingsAnim, {func = AnimSay, args = {dense, loc("This must be some kind of sorcery!"), SAY_SHOUT, 3500}})
  table.insert(weaklingsAnim, {func = AnimSwitchHog, args = {leaks}})
  AddSkipFunction(weaklingsAnim, SkipWeaklingsAnim, {})

  table.insert(stronglingsAnim, {func = AnimGearWait, args = {leaks, 1000}})
  table.insert(stronglingsAnim, {func = AnimCustomFunction, args = {leaks, UnHideStronglings, {}}})
  table.insert(stronglingsAnim, {func = AnimCustomFunction, args = {leaks, CondNeedToTurn, {leaks, dense}}})
  table.insert(stronglingsAnim, {func = AnimGiveState, args = {leaks, 0}})
  table.insert(stronglingsAnim, {func = AnimGiveState, args = {dense, 0}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {leaks, loc("I thought their shaman died when he tried our medicine!"), SAY_SAY, 7000}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {dense, loc("I saw it with my own eyes!"), SAY_SAY, 4000}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {leaks, loc("Then how do they keep appearing?"), SAY_SAY, 4000}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {leaks, loc("It's impossible to communicate with the spirits without a shaman."), SAY_SAY, 7000}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {dense, loc("We need to warn the village."), SAY_SAY, 3500}})
  table.insert(stronglingsAnim, {func = AnimGiveState, args = {cannibals[6], 0}})
  table.insert(stronglingsAnim, {func = AnimOutOfNowhere, args = {cannibals[6], unpack(cannibalPos[6])}})
  table.insert(stronglingsAnim, {func = AnimWait, args = {leaks, 400}})
  table.insert(stronglingsAnim, {func = AnimGiveState, args = {cannibals[7], 0}})
  table.insert(stronglingsAnim, {func = AnimOutOfNowhere, args = {cannibals[7], unpack(cannibalPos[7])}})
  table.insert(stronglingsAnim, {func = AnimWait, args = {leaks, 400}})
  table.insert(stronglingsAnim, {func = AnimGiveState, args = {cannibals[8], 0}})
  table.insert(stronglingsAnim, {func = AnimOutOfNowhere, args = {cannibals[8], unpack(cannibalPos[8])}})
  table.insert(stronglingsAnim, {func = AnimWait, args = {leaks, 400}})
  table.insert(stronglingsAnim, {func = AnimGiveState, args = {cannibals[9], 0}})
  table.insert(stronglingsAnim, {func = AnimOutOfNowhere, args = {cannibals[9], unpack(cannibalPos[9])}})
  table.insert(stronglingsAnim, {func = AnimWait, args = {leaks, 400}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {cannibals[7], loc("What a ride!"), SAY_SHOUT, 2000}})
  table.insert(stronglingsAnim, {func = AnimTurn, args = {leaks, "Right"}})
  table.insert(stronglingsAnim, {func = AnimWait, args = {leaks, 700}})
  table.insert(stronglingsAnim, {func = AnimTurn, args = {leaks, "Left"}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {leaks, loc("We can't defeat them!"), SAY_THINK, 3000}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {leaks, loc("I'll hold them off while you return to the village!"), SAY_SAY, 6000}})
  table.insert(stronglingsAnim, {func = AnimFollowGear, args = {cyborg}, swh = false})
  table.insert(stronglingsAnim, {func = AnimCaption, args = {cyborg, loc("30 minutes later...")}, swh = false})
  table.insert(stronglingsAnim, {func = AnimWait, args = {cyborg, 2000}})
  table.insert(stronglingsAnim, {func = AnimSetGearPosition, args = {dense, 1420, 1315}})
  table.insert(stronglingsAnim, {func = AnimMove, args = {dense, "Left", 1400, 0}})
  table.insert(stronglingsAnim, {func = AnimCustomFunction, args = {dense, EmitDenseClouds, {stronglingsAnim, "Left"}}})
  table.insert(stronglingsAnim, {func = AnimMove, args = {dense, "Left", 1350, 0}})
  table.insert(stronglingsAnim, {func = AnimOutOfNowhere, args = {cyborg, 1250, 1320}})
  table.insert(stronglingsAnim, {func = AnimRemoveState, args = {cyborg, gstInvisible}})
  table.insert(stronglingsAnim, {func = AnimGearWait, args = {cyborg, 2000}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {cyborg, loc("Greetings, cloudy one!"), SAY_SAY, 3000}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {cyborg, loc("I have come to make you an offering..."), SAY_SAY, 6000}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {cyborg, loc("You are given the chance to turn your life around..."), SAY_SAY, 6000}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {cyborg, loc("If you agree to provide the information we need, you will be spared!"), SAY_SAY, 7000}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {cyborg, loc("Have no illusions, your tribe is dead, indifferent of your choice."), SAY_SAY, 7000}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {cyborg, loc("If you decide to help us, though, we will no longer need to find a new governor for the island."), SAY_SAY, 8000}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {cyborg, loc("If you know what I mean..."), SAY_SAY, 3000}})
  table.insert(stronglingsAnim, {func = AnimSay, args = {cyborg, loc("So? What will it be?"), SAY_SAY, 3000}})
  table.insert(stronglingsAnim, {func = AnimSwitchHog, args = {dense}})
  AddSkipFunction(stronglingsAnim, SkipStronglingsAnim, {})

  table.insert(acceptedAnim, {func = AnimSay, args = {cyborg, loc("Great choice, Steve! Mind if I call you that?"), SAY_SAY, 7000}})
  table.insert(acceptedAnim, {func = AnimSay, args = {dense, loc("Whatever floats your boat..."), SAY_SAY, 4500}})
  table.insert(acceptedAnim, {func = AnimSay, args = {cyborg, loc("Great! You will be contacted soon for assistance."), SAY_SAY, 6000}})
  table.insert(acceptedAnim, {func = AnimSay, args = {cyborg, loc("In the meantime, take these and return to your \"friend\"!"), SAY_SAY, 6000}})
  table.insert(acceptedAnim, {func = AnimGiveState, args = {cyborg, gstInvisible}})
  table.insert(acceptedAnim, {func = AnimDisappear, args = {cyborg, unpack(cyborgPos)}})
  table.insert(acceptedAnim, {func = AnimSwitchHog, args = {dense}})
  AddSkipFunction(acceptedAnim, SkipAcceptedAnim, {}) 

  table.insert(acceptedDiedFinalAnim, {func = AnimSay, args = {leaks, loc("Pfew! That was close!"), SAY_THINK, 3000}})
  table.insert(acceptedDiedFinalAnim, {func = AnimSay, args = {leaks, loc("Your death will not be in vain, Dense Cloud!"), SAY_THINK, 5000}})
  table.insert(acceptedDiedFinalAnim, {func = AnimSay, args = {dense, loc("You will be avenged!"), SAY_SAY, 3000}})

  table.insert(refusedAnim, {func = AnimSay, args = {cyborg, loc("I see..."), SAY_SAY, 2000}})
  table.insert(refusedAnim, {func = AnimSay, args = {cyborg, loc("Remember this, pathetic animal: when the day comes, you will regret your blind loyalty!"), SAY_SAY, 8000}})
  table.insert(refusedAnim, {func = AnimSay, args = {cyborg, loc("You just committed suicide..."), SAY_SAY, 5000}})
  table.insert(refusedAnim, {func = AnimDisappear, args = {cyborg, unpack(cyborgPos)}})
  table.insert(refusedAnim, {func = AnimGiveState, args = {cyborg, gstInvisible}})
  table.insert(refusedAnim, {func = AnimSay, args = {dense, loc("If you say so..."), SAY_THINK, 3000}})
  table.insert(refusedAnim, {func = AnimFollowGear, args = {cyborg}, swh = false})
  table.insert(refusedAnim, {func = AnimWait, args = {cyborg, 700}})
  table.insert(refusedAnim, {func = AnimCustomFunction, args = {dense, RefusedStart, {}}})
  table.insert(refusedAnim, {func = AnimOutOfNowhere, args = {dense, 2645, 1146}})
  table.insert(refusedAnim, {func = AnimOutOfNowhere, args = {ramon, 2218, 1675}})
  table.insert(refusedAnim, {func = AnimOutOfNowhere, args = {spiky, 2400, 1675}})
  table.insert(refusedAnim, {func = AnimTurn, args = {spiky, "Left"}})
  table.insert(refusedAnim, {func = AnimWait, args = {cyborg, 1700}})
  table.insert(refusedAnim, {func = AnimTurn, args = {spiky, "Right"}})
  table.insert(refusedAnim, {func = AnimWait, args = {cyborg, 1700}})
  table.insert(refusedAnim, {func = AnimTurn, args = {spiky, "Left"}})
  table.insert(refusedAnim, {func = AnimSay, args = {spiky, loc("Dude, we really need a new shaman..."), SAY_SAY, 4000}})
  AddSkipFunction(refusedAnim, SkipRefusedAnim, {})

  table.insert(refusedFinalAnim, {func = AnimSay, args = {leaks, loc("It's over..."), SAY_SAY, 2000}})
  table.insert(refusedFinalAnim, {func = AnimSay, args = {leaks, loc("Let's head back to the village!"), SAY_SAY, 4000}})

  table.insert(attackedAnim, {func = AnimCustomFunction, args = {dense, CondNeedToTurn, {cyborg, dense}}})
  table.insert(attackedAnim, {func = AnimCustomFunction, args = {cyborg, SetHealth, {cyborg, 200}}})
  table.insert(attackedAnim, {func = AnimWait, args = {cyborg, 2000}})
  table.insert(attackedAnim, {func = AnimSay, args = {cyborg, loc("Really?! You thought you could harm me with your little toys?"), SAY_SAY, 7000}})
  table.insert(attackedAnim, {func = AnimSay, args = {cyborg, loc("You're pathetic! You are not worthy of my attention..."), SAY_SAY, 6000}})
  table.insert(attackedAnim, {func = AnimSay, args = {cyborg, loc("Actually, you aren't worthy of life! Take this..."), SAY_SAY, 5000}})
  table.insert(attackedAnim, {func = AnimCustomFunction, args = {dense, BlowDenseCloud, {}}, swh = false})
  table.insert(attackedAnim, {func = AnimWait, args = {cyborg, 2000}})
  table.insert(attackedAnim, {func = AnimSay, args = {cyborg, loc("Incredible..."), SAY_SAY, 3000}})
  table.insert(attackedAnim, {func = AnimDisappear, args = {cyborg, unpack(cyborgPos)}})
  table.insert(attackedAnim, {func = AnimGiveState, args = {cyborg, gstInvisible}})
  table.insert(attackedAnim, {func = AnimSwitchHog, args = {leaks}})
  table.insert(attackedAnim, {func = AnimSay, args = {leaks, loc("I wonder where Dense Cloud is..."), SAY_THINK, 4000}})
  table.insert(attackedAnim, {func = AnimSay, args = {leaks, loc("I can't wait any more, I have to save myself!"), SAY_THINK, 5000}})
  table.insert(attackedAnim, {func = AnimCustomFunction, args = {leaks, SpawnCrates, {}}})
  table.insert(attackedAnim, {func = AnimWait, args = {leaks, 1500}})
  table.insert(attackedAnim, {func = AnimSay, args = {leaks, loc("Where are all these crates coming from?!"), SAY_THINK, 5500}})
  AddSkipFunction(attackedAnim, SkipAttackedAnim, {})
  
  table.insert(attackedFinalAnim, {func = AnimWait, args = {leaks, 2000}})
  table.insert(attackedFinalAnim, {func = AnimSay, args = {leaks, loc("I have to get back to the village!"), SAY_THINK, 5000}})
  table.insert(attackedFinalAnim, {func = AnimSay, args = {leaks, loc("Dense Cloud must have already told them everything..."), SAY_THINK, 7000}})

end


-----------------------------Misc--------------------------------------


function RefusedStart()
  if stage == loseStage then
    return
  end
  if ramonHidden == true then
    RestoreHog(ramon)
    ramonHidden = false
  end
  if spikyHidden == true then
    RestoreHog(spiky)
    spikyHidden = false
  end
  SetState(ramon, 0)
  SetState(spiky, 0)
  SetGearMessage(dense, 0)
  SetGearMessage(ramon, 0)
  SetGearMessage(spiky, 0)
end

function AddHogs()
	AddTeam(loc("Natives"), 29439, "Bone", "Island", "HillBilly", "cm_birdy")
  ramon = AddHog(loc("Ramon"), 0, 100, "rasta")
	leaks = AddHog(loc("Leaks A Lot"), 0, 100, "Rambo")
  dense = AddHog(loc("Dense Cloud"), 0, 100, "RobinHood")
  spiky = AddHog(loc("Spiky Cheese"), 0, 100, "hair_yellow")

  AddTeam(loc("Weaklings"), 14483456, "skull", "Island", "Pirate","cm_vampire")
  cannibals = {}
  cannibals[1] = AddHog(loc("Brainiac"), 5, 20, "Zombi")

  for i = 2, 5 do
    cannibals[i] = AddHog(HogNames[i], 1, 20, "Zombi")
    hogNr[cannibals[i]] = i - 2
  end

  AddTeam(loc("Stronglings"), 14483456, "skull", "Island", "Pirate","cm_vampire")

  for i = 6, 9 do
    cannibals[i] = AddHog(HogNames[i], 2, 30, "vampirichog")
    hogNr[cannibals[i]] = i - 2
  end

  AddTeam(loc("011101001"), 14483456, "ring", "UFO", "Robot", "cm_binary")
  cyborg = AddHog(loc("Y3K1337"), 0, 200, "cyborg1")
end

function PlaceHogs()
  HogTurnLeft(leaks, true)

  for i = 2, 9 do
    AnimSetGearPosition(cannibals[i], unpack(cyborgPos))
    AnimTurn(cannibals[i], "Left")
    cannibalDead[i] = false
  end

  AnimSetGearPosition(cannibals[1], cannibalPos[1][1], cannibalPos[1][2])
  AnimTurn(cannibals[1], "Left")

  AnimSetGearPosition(cyborg, cyborgPos[1], cyborgPos[2])
  AnimSetGearPosition(ramon, 2218, 1675)
  AnimSetGearPosition(skiky, 2400, 1675)
  AnimSetGearPosition(dense, densePos[1], densePos[2])
  AnimSetGearPosition(leaks, leaksPos[1], leaksPos[2]) 
end

function VisiblizeHogs()
  for i = 1, 9 do
    SetState(cannibals[i], gstInvisible)
  end
  SetState(cyborg, gstInvisible)
  SetState(ramon, gstInvisible)
  SetState(spiky, gstInvisible)
end

function CondNeedToTurn(hog1, hog2)
  if stage == loseStage then
    return
  end
  xl, xd = GetX(hog1), GetX(hog2)
  if xl and xd then
    if xl > xd then
      AnimInsertStepNext({func = AnimTurn, args = {hog1, "Left"}})
      AnimInsertStepNext({func = AnimTurn, args = {hog2, "Right"}})
    elseif xl < xd then
      AnimInsertStepNext({func = AnimTurn, args = {hog2, "Left"}})
      AnimInsertStepNext({func = AnimTurn, args = {hog1, "Right"}})
    end
  end
end

function HideHogs()
  for i = 2, 9 do
    HideHog(cannibals[i])
    isHidden[cannibals[i]] = true
  end
  HideHog(cyborg)
  cyborgHidden = true
  HideHog(ramon)
  HideHog(spiky)
  ramonHidden = true
  spikyHidden = true
end

function HideStronglings()
  if stage == loseStage then
    return
  end
  for i = 6, 9 do
    HideHog(cannibals[i])
    isHidden[cannibals[i]] = true
  end
end

function UnHideWeaklings()
  if stage == loseStage then
    return
  end
  for i = 2, 5 do
    RestoreHog(cannibals[i])
    isHidden[cannibals[i]] = false
    SetState(cannibals[i], gstInvisible)
  end
end

function UnHideStronglings()
  if stage == loseStage then
    return
  end
  for i = 6, 9 do
    RestoreHog(cannibals[i])
    isHidden[cannibals[i]] = false
    SetState(cannibals[i], gstInvisible)
  end
  RestoreHog(cyborg)
  cyborgHidden = false
  SetState(cyborg, gstInvisible)
end

function ChoiceTaken()
  if stage == loseStage then
    return
  end
  SetGearMessage(CurrentHedgehog, 0)
  if choice == choiceAccept then
    AddAnim(acceptedAnim)
    AddFunction({func = AfterAcceptedAnim, args = {}})
  elseif choice == choiceRefuse then
    AddAnim(refusedAnim)
    AddFunction({func = AfterRefusedAnim, args = {}})
  else
    AddAnim(attackedAnim)
    AddFunction({func = AfterAttackedAnim, args = {}})
  end
end

function KillCyborg()
  if stage == loseStage then
    return
  end
  RestoreHog(cyborg)
  DeleteGear(cyborg)
  EndTurn(true)
end
-----------------------------Events------------------------------------

function CheckBrainiacDead()
  return brainiacDead
end

function DoBrainiacDead()
  if stage == loseStage then
    return
  end
  EndTurn(true)
  SetGearMessage(CurrentHedgehog, 0)
  AddAnim(weaklingsAnim)
  AddFunction({func = AfterWeaklingsAnim, args = {}})
  stage = interSpyStage
end
  
function CheckWeaklingsKilled()
  for i = 2, 5 do
    if cannibalDead[i] == false then
      return false
    end
  end
  return true
end

function DoWeaklingsKilled()
  if stage == loseStage then
    return
  end
  SetGearMessage(CurrentHedgehog, 0)
  AddAnim(stronglingsAnim)
  AddFunction({func = AfterStronglingsAnim, args = {}})
  stage = interWeakStage
  DismissTeam(loc("Weaklings"))
end

function CheckRefuse()
  return GetX(dense) > 1400 and StoppedGear(dense)
end

function DoRefuse()
  if stage == loseStage then
    return
  end
  choice = choiceRefuse
end

function CheckAccept()
  return GetX(dense) < 1300 and StoppedGear(dense)
end

function DoAccept()
  if stage == loseStage then
    return
  end
  choice = choiceAccept
end

function CheckConfront()
  return cyborgAttacked and StoppedGear(dense)
end

function DoConfront()
  if stage == loseStage then
    return
  end
  choice = choiceAttack
end

function CheckChoice()
  return choice ~= 0
end

function DoChoice()
  if stage == loseStage then
    return
  end
  RemoveEventFunc(CheckConfront)
  RemoveEventFunc(CheckAccept)
  RemoveEventFunc(CheckRefuse)
  ChoiceTaken()
end

function CheckNeedGirder()
  if stage == loseStage then
    return false
  end
  return GetX(dense) > 1640 and StoppedGear(dense)
end

function DoNeedGirder()
  if stage == loseStage then
    return
  end
  ShowMission(loc("The Shadow Falls"), loc("Under Construction"), loc("Return to Leaks A Lot!") .. "|" .. loc("To place a girder, select it, use [Left] and [Right] to select angle and length, place with [Left Click]"), 1, 6000)
end

function CheckNeedWeapons()
  if stage == loseStage then
    return false
  end
  return GetX(dense) > 2522 and StoppedGear(dense)
end

function DoNeedWeapons()
  if stage == loseStage then
    return
  end
  grenadeCrate = SpawnAmmoCrate(2550, 800, amGrenade)
  shotgunCrate = SpawnAmmoCrate(2610, 850, amShotgun)
  AddCaption(loc("A little gift from the cyborgs"))
end

function CheckReadyForStronglings()
  if stage == loseStage then
    return false
  end
  return (shotgunTaken and grenadeTaken) or GetX(dense) > 2700
end

function DoReadyForStronglings()
  if stage == loseStage then
    return
  end
  ShowMission(loc("The Shadow Falls"), loc("The guardian"), loc("Protect yourselves!|Grenade hint: set the timer with [1-5], aim with [Up]/[Down] and hold [Space] to set power").."|"..loc("Both your hedgehogs must survive."), 1, 8000)
  AddAmmo(dense, amSkip, 100)
  AddAmmo(dense, amSwitch, 100)
  AddAmmo(leaks, amSkip, 100)
  AddAmmo(leaks, amSwitch, 100)
  stage = duoStage
  RemoveEventFunc(CheckNeedGirder)
  RemoveEventFunc(CheckNeedWeapons)
  AddEvent(CheckStronglingsDead, {}, DoStronglingsDead, {}, 0)
  AddAmmo(cannibals[6], amGrenade, 2)
  AddAmmo(cannibals[6], amShotgun, 2)
  AddAmmo(cannibals[7], amGrenade, 2)
  AddAmmo(cannibals[7], amShotgun, 2)
  AddAmmo(cannibals[8], amGrenade, 2)
  AddAmmo(cannibals[8], amShotgun, 2)
  AddAmmo(cannibals[9], amGrenade, 2)
  AddAmmo(cannibals[9], amShotgun, 2)
  SetGearMessage(leaks, 0)
  SetGearMessage(dense, 0)
  TurnTimeLeft = TurnTime
end

function DoStronglingsDead()
  if stage == loseStage then
    return
  end
  SetGearMessage(CurrentHedgehog, 0)
  if denseDead == true then
    AddAnim(acceptedDiedFinalAnim)
    SaveCampaignVar("M2DenseDead", "1")
  else
    SetupAcceptedSurvivedFinalAnim()
    AddAnim(acceptedSurvivedFinalAnim)
    SaveCampaignVar("M2DenseDead", "0")
  end
  SaveCampaignVar("M2RamonDead", "0")
  SaveCampaignVar("M2SpikyDead", "0")
  AddFunction({func = KillCyborg, args = {}})
  if progress and progress<2 then
    SaveCampaignVar("Progress", "2")
  end
  SaveCampaignVar("M2Choice", "" .. choice)
end

function DoStronglingsDeadRefused()
  if stage == loseStage then
    return
  end
  if denseDead == true then
    SaveCampaignVar("M2DenseDead", "1")
  else
    SaveCampaignVar("M2DenseDead", "0")
  end
  if ramonDead == true then
    SaveCampaignVar("M2RamonDead", "1")
  else
    SaveCampaignVar("M2RamonDead", "0")
  end
  if spikyDead == true then
    SaveCampaignVar("M2SpikyDead", "1")
  else
    SaveCampaignVar("M2SpikyDead", "0")
  end
  AddAnim(refusedFinalAnim)
  AddFunction({func = KillCyborg, args = {}})
  if progress and progress<2 then
    SaveCampaignVar("Progress", "2")
  end
  SaveCampaignVar("M2Choice", "" .. choice)
end

function DoStronglingsDeadAttacked()
  if stage == loseStage then
    return
  end
  SaveCampaignVar("M2DenseDead", "1")
  SaveCampaignVar("M2RamonDead", "0")
  SaveCampaignVar("M2SpikyDead", "0")
  if progress and progress<2 then
    SaveCampaignVar("Progress", "2")
  end
  SaveCampaignVar("M2Choice", "" .. choice)
  AddAnim(attackedFinalAnim)
  AddFunction({func = KillCyborg, args = {}})
end

function CheckStronglingsDead()
  if leaksDead == true then
    return false
  end
  for i = 6, 9 do
    if cannibalDead[i] == false then
      return false
    end
  end
  return true
end

function CheckLeaksDead()
  return leaksDead
end

function DoDead()
  if stage == loseStage then
    return
  end
  AddCaption(loc("...and so the cyborgs took over the world..."))
  stage = loseStage
  DismissTeam(loc("Natives"))
end

function CheckDenseDead()
  return denseDead and choice ~= choiceAttack 
end

-----------------------------Main Functions----------------------------

function onGameInit()
	Seed = 334 
	GameFlags = gfSolidLand + gfDisableWind + gfPerHogAmmo
	TurnTime = 50000 
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 3000
	Explosives = 0
	Delay = 10 
	Map = "A_Classic_Fairytale_shadow"
	Theme = "Nature"
	-- Disable Sudden Death
	HealthDecrease = 0
	WaterRise = 0

  AddHogs()
  PlaceHogs()
  VisiblizeHogs()
  
  AnimInit()
  AnimationSetup()
end

function onGameStart()
  progress = tonumber(GetCampaignVar("Progress"))
  HideHogs()
  AddAmmo(leaks, amSwitch, 100)
  AddAmmo(dense, amSwitch, 100)
  AddEvent(CheckLeaksDead, {}, DoDead, {}, 0)
  AddEvent(CheckDenseDead, {}, DoDead, {}, 0)
  AddAnim(startDialogue)
  AddFunction({func = AfterStartDialogue, args = {}})
  AddEvent(CheckBrainiacDead, {}, DoBrainiacDead, {}, 0)
  ShowMission(loc("The Shadow Falls"), loc("The First Encounter"), loc("Survive!|Hint: Cinematics can be skipped with the [Precise] key."), 1, 0)
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
  if gear == cannibals[1] then
    brainiacDead = true
  elseif gear == grenadeCrate then
    grenadeTaken = true
  elseif gear == shotgunCrate then
    shotgunTaken = true
  elseif gear == dense then
    denseDead = true
  elseif gear == leaks then
    leaksDead = true
  elseif gear == ramon then
    ramonDead = true
  elseif gear == spiky then
    spikyDead = true
  else
    for i = 2, 9 do
      if gear == cannibals[i] then
        cannibalDead[i] = true
      end
    end
  end
end

function onGearAdd(gear)
  if GetGearType(gear) == gtGrenade and GetHogTeamName(CurrentHedgehog) == loc("Natives") then
    grenadeUsed = true
  elseif GetGearType(gear) == gtShotgunShot and GetHogTeamName(CurrentHedgehog) == loc("Natives") then
    shotgunUsed = true
  end
end

function onAmmoStoreInit()
  SetAmmo(amDEagle, 9, 0, 0, 0)
  SetAmmo(amSniperRifle, 6, 0, 0, 0)
  SetAmmo(amFirePunch, 3, 0, 0, 0)
  SetAmmo(amWhip, 4, 0, 0, 0)
  SetAmmo(amBaseballBat, 4, 0, 0, 0)
  SetAmmo(amHammer, 2, 0, 0, 0)
  SetAmmo(amLandGun, 1, 0, 0, 0)
  SetAmmo(amSnowball, 7, 0, 0, 0)
  SetAmmo(amGirder, 0, 0, 0, 2)
  SetAmmo(amParachute, 0, 0, 0, 2)
  SetAmmo(amGrenade, 0, 0, 0, 3)
  SetAmmo(amShotgun, 0, 0, 0, 3)
  SetAmmo(amSwitch, 0, 0, 0, 8)
  SetAmmo(amRope, 0, 0, 0, 6)
  SetAmmo(amSkip, 9, 0, 0, 0)
end

function onNewTurn()
  if AnimInProgress() then
    TurnTimeLeft = -1
  elseif stage == cyborgStage then
    if CurrentHedgehog ~= dense then
      EndTurn(true)
    else
      TurnTimeLeft = -1
    end
  elseif stage == acceptedReturnStage then
    SwitchHog(dense)
    FollowGear(dense)
    TurnTimeLeft = -1
  end
end

function onGearDamage(gear, damage)
  if gear == cyborg and stage == cyborgStage then
    cyborgAttacked = true
  end
end

function onPrecise()
  if GameTime > 2500 and AnimInProgress() then
    SetAnimSkip(true)
    return
  end
end

