local animPos, lastx, lasty, jumpTypes, jumpTimes, moveDirs, jumpStarted
local moveTime = 0
local backJumped, jTimer, awTime, globalWait, stageEvents, seNum, curEvent
local needtoDecrease
local AnimList, AnimListNum
local FunctionList, FunctionListNum
local skipFuncList
local skipping
local baseInputMask = 0xFFFFFFFF
local extraInputMask = baseInputMask
--------------------------------Animation---------------------------------
--------------------------(In-game cinematics)----------------------------

function AddSkipFunction(anim, func, args)
  skipFuncList[anim] = {sfunc = func, sargs = args}
end

function RemoveSkipFunction(anim)
  skipFuncList[anim] = nil
end

function SetAnimSkip(bool)
  skipping = bool
end

function AnimInProgress()
  return AnimListNum ~= 0
end

function SkipAnimation(anim)
  if skipFuncList[anim] == nil then
    return
  else 
    skipFuncList[anim].sfunc(unpack(skipFuncList[anim].sargs))
  end
end

function AddFunction(element)
  table.insert(FunctionList, element)
  FunctionListNum = FunctionListNum + 1
end

function RemoveFunction()
  table.remove(FunctionList, 1)
  FunctionListNum = FunctionListNum - 1
end

function ExecuteAfterAnimations()
  if FunctionListNum == 0 then
    return
  end
  FunctionList[1].func(unpack(FunctionList[1].args))
  RemoveFunction()
end

local function updateInputMask()
     SetInputMask(band(baseInputMask, extraInputMask))
end

local function startCinemaLock()
     SetCinematicMode(true)
     baseInputMask = bnot(gmAnimate+gmAttack+gmDown+gmHJump+gmLeft+gmLJump+gmRight+gmSlot+gmSwitch+gmTimer+gmUp+gmWeapon)
     updateInputMask()
end

local function stopCinemaLock()
     baseInputMask = 0xFFFFFFFF
     updateInputMask()
     SetCinematicMode(false)
end

function AnimSetInputMask(newExtraInputMask)
     extraInputMask = newExtraInputMask
     updateInputMask()
end

function AnimInit(startAnimating)
  lastx = 0
  lasty = 0
  jumpTypes = {long = gmLJump, high = gmHJump, back = gmHJump}
  jumpTimes = {long = 500, high = 500, back = 300, backback = 500} 
  moveDirs = {Right = gmRight, Left = gmLeft}
  jumpStarted = false
  backJumped = false
  jTimer = 0
  awTime = 0
  globalWait = 0
  stageEvents = {}
  seNum = 0
  curEvent = 0
  needToDecrease = 0
  AnimList = {}
  AnimListNum = 0
  FunctionList = {}
  FunctionListNum = 0
  skipping = false
  skipFuncList = {}
  animPos = 1
  if startAnimating then
     startCinemaLock()
  end
end

function AnimSwitchHog(gear)
  --SetGearMessage(gear, 0)
  --SetState(gear, 0)
  SwitchHog(gear)
  FollowGear(gear)
  return true
end

function AnimGiveState(gear, state)
  SetState(gear, state)
  return true
end

function AnimRemoveState(gear, state)
  SetState(gear, band(GetState(gear), bnot(state)))
  return true
end

function AnimGearWait(gear, time)
  AnimWait(gear, time)
  return true
end

function AnimUnWait()
  if globalWait > 0 then
    globalWait = globalWait - 1
  end
end

function AnimWait(gear, time)   -- gear is for compatibility with Animate
  globalWait = globalWait + time
  return true
end

function AnimWaitLeft()
  return globalWait
end

function AnimSay(gear, text, manner, time)
  HogSay(gear, text, manner, 2)
  if time ~= nil then
    AnimWait(gear, time)
  end
  return true
end

function AnimSound(gear, sound, time)
  PlaySound(sound, gear)
  AnimWait(gear, time)
  return true
end

function AnimTurn(gear, dir)
  if dir == "Right" then
    HogTurnLeft(gear, false)
  else
    HogTurnLeft(gear, true)
  end
  return true
end

function AnimFollowGear(gear)
  FollowGear(gear)
  return true
end

function AnimMove(gear, dir, posx, posy, maxMoveTime)
  dirr = moveDirs[dir]
  SetGearMessage(gear, dirr)
  moveTime = moveTime + 1
  if (maxMoveTime and moveTime > maxMoveTime) then
    SetGearMessage(gear, 0)
    SetGearPosition(gear, posx, posy)
    lastx = GetX(gear)
    lasty = GetY(gear)
    moveTime = 0
    return true
  elseif GetX(gear) == posx or GetY(gear) == posy then
    SetGearMessage(gear, 0)
    lastx = GetX(gear)
    lasty = GetY(gear)
    moveTime = 0
    return true
  end
  return false
end

function AnimJump(gear, jumpType)
  if jumpStarted == false then
    lastx = GetX(gear)
    lasty = GetY(gear)
    backJumped = false
    jumpStarted = true
    SetGearMessage(gear, jumpTypes[jumpType])
    AnimGearWait(gear, jumpTimes[jumpType])
  elseif jumpType == "back" and backJumped == false then
    backJumped = true
    SetGearMessage(gear, jumpTypes[jumpType])
    AnimGearWait(gear, jumpTimes["backback"])
  else
    curx = GetX(gear)
    cury = GetY(gear)
    if curx == lastx and cury == lasty then
      jumpStarted = false
      backJumped = false
      AnimGearWait(gear, 100)
      return true
    else
      lastx = curx
      lasty = cury
      AnimGearWait(gear, 100)
    end
  end
  return false
end

function AnimSetGearPosition(gear, destX, destY, fall)
  SetGearPosition(gear, destX, destY)
  if fall ~= false then
    SetGearVelocity(gear, 0, 10)
  end
  return true
end

function AnimDisappear(gear, destX, destY)
	AddVisualGear(GetX(gear)-5, GetY(gear)-5, vgtSmoke, 0, false)
	AddVisualGear(GetX(gear)+5, GetY(gear)+5, vgtSmoke, 0, false)
	AddVisualGear(GetX(gear)-5, GetY(gear)+5, vgtSmoke, 0, false)
	AddVisualGear(GetX(gear)+5, GetY(gear)-5, vgtSmoke, 0, false)
  PlaySound(sndExplosion)
	AnimSetGearPosition(gear, destX, destY)
  return true
end

function AnimOutOfNowhere(gear, destX, destY)
  AnimSetGearPosition(gear, destX, destY)
  AddVisualGear(destX, destY, vgtBigExplosion, 0, false)
  PlaySound(sndExplosion)
  AnimGearWait(gear, 50)
  return true
end

function AnimTeleportGear(gear, destX, destY)
	AddVisualGear(GetX(gear)-5, GetY(gear)-5, vgtSmoke, 0, false)
	AddVisualGear(GetX(gear)+5, GetY(gear)+5, vgtSmoke, 0, false)
	AddVisualGear(GetX(gear)-5, GetY(gear)+5, vgtSmoke, 0, false)
	AddVisualGear(GetX(gear)+5, GetY(gear)-5, vgtSmoke, 0, false)
	AnimSetGearPosition(gear, destX, destY)
	AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)
  PlaySound(sndExplosion)
  FollowGear(gear)
  AnimGearWait(gear, 50)
  return true
end

function AnimVisualGear(gear, x, y, vgType, state, critical)
  AddVisualGear(x, y, vgType, state, critical)
  return true
end

function AnimCaption(gear, text, time)
  AddCaption(text)
  if time == nil then
    return true
  end
  AnimWait(gear, time)
  return true
end

function AnimCustomFunction(gear, func, args)
  if args == nil then
    args = {}
  end
  retval = func(unpack(args))
  if retval == false then
    return false
  else
    return true
  end
end

function AnimInsertStepNext(step)
  table.insert(AnimList[1], animPos + 1, step)
  return true
end

function AnimShowMission(gear, caption, subcaption, text, icon, time)
  ShowMission(caption, subcaption, text, icon, time)
  return true
end

function RemoveAnim()
  table.remove(AnimList, 1)
  AnimListNum = AnimListNum - 1
end

function AddAnim(animation)
  table.insert(AnimList, animation)
  AnimListNum = AnimListNum + 1
  if AnimListNum == 1 then
    skipping = false
  end
end

function ShowAnimation()
  if AnimListNum == 0 then
    skipping = false
    return true
  else
    SetTurnTimeLeft(cMaxTurnTime)
    if Animate(AnimList[1]) == true then
      RemoveAnim()
    end
  end
  return false
end

function Animate(steps)
  if skipping == true then
    animPos = 1
    stopCinemaLock()
    SkipAnimation(steps)
    return true
  end
    
  if globalWait ~= 0 then
    return false
  end

  if steps[animPos] == nil then
      animPos = 1
      stopCinemaLock()
      return true
  end
  
  if steps[animPos].args[1] ~= CurrentHedgehog and steps[animPos].func ~= AnimWait 
    and (steps[animPos].swh == nil or steps[animPos].swh == true) then
      AnimSwitchHog(steps[animPos].args[1])
  end

  startCinemaLock()
  retVal = steps[animPos].func(unpack(steps[animPos].args))
  if (retVal ~= false) then
    animPos = animPos + 1
  end

  return false
end

------------------------------Event Handling------------------------------

function AddEvent(condFunc, condArgs, doFunc, doArgs, evType)
  seNum = seNum + 1
  stageEvents[seNum] = {}
  stageEvents[seNum].cFunc = condFunc
  stageEvents[seNum].cArgs = condArgs
  stageEvents[seNum].dFunc = doFunc
  stageEvents[seNum].dArgs = doArgs
  stageEvents[seNum].evType = evType
end

function AddNewEvent(condFunc, condArgs, doFunc, doArgs, evType)
  local i
  for i = 1, seNum do
    if stageEvents[i].cFunc == condFunc and stageEvents[i].cArgs == condArgs and
       stageEvents[i].dFunc == doFunc and stageEvents[i].dArgs == doArgs and 
       stageEvents[seNum].evType == evType then
       return
    end
  end
  AddEvent(condFunc, condArgs, doFunc, doArgs, evType)
end

function RemoveEvent(evNum)
  if stageEvents[evNum] ~= nil then
    seNum = seNum - 1
    table.remove(stageEvents, evNum)
    if evNum < curEvent then
      return true
    end
  end
  if evNum < curEvent then
    needToDecrease = needToDecrease + 1
  end
end

function RemoveEventFunc(cFunc, cArgs)
  local i = 1
  while i <= seNum do
    if stageEvents[i].cFunc == cFunc and (cArgs == nil or cArgs == stageEvents[i].cArgs) then
      RemoveEvent(i)
      i = i - 1
    end
    i = i + 1
  end
end


function CheckEvents()
  local i = 1
  while i <= seNum do
    curEvent = i
    if stageEvents[i].cFunc(unpack(stageEvents[i].cArgs)) then
      stageEvents[i].dFunc(unpack(stageEvents[i].dArgs))
      if needToDecrease > 0 then
        i = i - needToDecrease
        needToDecrease = 0
      end
      if stageEvents[i].evType ~= 1 then 
        RemoveEvent(i)
        i = i - 1
      end
    end
    i = i + 1
  end
  curEvent = 0
end

-------------------------------------Misc---------------------------------

function StoppedGear(gear)
  -- GetHealth returns nil if gear does not exist
  if not GetHealth(gear) then
     -- We consider the gear to be “stopped” if it has been destroyed
     return true
  end
  dx,dy = GetGearVelocity(gear)
  return math.abs(dx) <= 1 and math.abs(dy) <= 1
end
