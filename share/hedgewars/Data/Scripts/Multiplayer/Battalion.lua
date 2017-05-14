--[[
  ########################################################################
  Name:      Battalion
  Made by:   Anachron 
  ########################################################################
]]--

--[[
  
  Readme:
  https://github.com/Anachron/hw-battalion

  ########################################################################
]]--

--[[
  ########################################################################
  Todo/Idea-List
  ########################################################################

  - Make Hogs sorted by rareness for teams with less hogs (more fair)
  - Keep first picked up unused crate utitlity until next round
  - Ship default scheme but let user overwrite it
  - Make SuddenDeathWaterRise dynamic
  - Make SuddenDeathTurns dynamic
  - Add Hog Variants like Crazy Scientist or Astronaut

  ########################################################################
]]--

--[[
  ##############################################################################
  ### GENERAL SCRIPT LOADING AND VARIABLE INITIALISATION                     ###
  ##############################################################################
]]--

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

-- List of all hog variants with belonging weapons,
--  hitpoints, chances and more
local variants = {}
local varName = ""
local newLine = ""--string.char(0x0A)
local gmAny = 0xFFFFFFFF
local version = "0.33"

--[[
  ##############################################################################
  ### VARIANT SETUP                                                          ###
  ##############################################################################
]]--

varName = "Pyromancer"
variants[varName] = {}
variants[varName]["chance"] = 7
variants[varName]["hat"] = "Gasmask"
variants[varName]["hp"] = 70
variants[varName]["hogLimit"] = 2
variants[varName]["weaponLimit"] = 1
variants[varName]["weapons"] = {amFlamethrower, amMolotov, amWhip}
variants[varName]["helperLimit"] = 1
variants[varName]["helpers"] = {amRope, amParachute}
variants[varName]["special"] = false

varName = "Builder"
variants[varName] = {}
variants[varName]["chance"] = 10
variants[varName]["hat"] = "constructor"
variants[varName]["hp"] = 100
variants[varName]["hogLimit"] = 1
variants[varName]["weaponLimit"] = 1
variants[varName]["weapons"] = {amDynamite, amWhip, amHammer}
variants[varName]["helperLimit"] = 1
variants[varName]["helpers"] = {amGirder, amBlowTorch}
variants[varName]["special"] = false

varName = "Rifleman"
variants[varName] = {}
variants[varName]["chance"] = 7
variants[varName]["hat"] = "Sniper"
variants[varName]["hp"] = 70
variants[varName]["hogLimit"] = 2
variants[varName]["weaponLimit"] = 1
variants[varName]["weapons"] = {amRCPlane, amShotgun, amSniperRifle}
variants[varName]["helperLimit"] = 1
variants[varName]["helpers"] = {amLowGravity, amParachute}
variants[varName]["special"] = false

varName = "Warrior"
variants[varName] = {}
variants[varName]["chance"] = 12
variants[varName]["hat"] = "spartan"
variants[varName]["hp"] = 120
variants[varName]["hogLimit"] = 2
variants[varName]["weaponLimit"] = 1
variants[varName]["weapons"] = {amClusterBomb, amGrenade, amBazooka}
variants[varName]["helperLimit"] = 1
variants[varName]["helpers"] = {amParachute, amRope}
variants[varName]["special"] = false

varName = "Chef"
variants[varName] = {}
variants[varName]["chance"] = 7
variants[varName]["hat"] = "chef"
variants[varName]["hp"] = 70
variants[varName]["hogLimit"] = 1
variants[varName]["weaponLimit"] = 1
variants[varName]["weapons"] = {amCake, amKnife, amWhip}
variants[varName]["helperLimit"] = 1
variants[varName]["helpers"] = {amRubber, amParachute}
variants[varName]["special"] = false

varName = "Medic"
variants[varName] = {}
variants[varName]["chance"] = 12
variants[varName]["hat"] = "war_desertmedic"
variants[varName]["hp"] = 120
variants[varName]["hogLimit"] = 1
variants[varName]["weaponLimit"] = 1
variants[varName]["weapons"] = {amResurrector, amMine, amGasBomb}
variants[varName]["helperLimit"] = 1
variants[varName]["helpers"] = {amTeleport, amParachute}
variants[varName]["special"] = false

varName = "Ninja"
variants[varName] = {}
variants[varName]["chance"] = 8
variants[varName]["hat"] = "NinjaTriangle"
variants[varName]["hp"] = 80
variants[varName]["hogLimit"] = 2
variants[varName]["weaponLimit"] = 1
variants[varName]["weapons"] = {amSMine, amMine, amFirePunch}
variants[varName]["helperLimit"] = 1
variants[varName]["helpers"] = {amRope, amParachute}
variants[varName]["special"] = false

varName = "Athlete"
variants[varName] = {}
variants[varName]["chance"] = 8
variants[varName]["hat"] = "footballhelmet"
variants[varName]["hp"] = 80
variants[varName]["hogLimit"] = 1
variants[varName]["weaponLimit"] = 1
variants[varName]["weapons"] = {amBaseballBat, amFirePunch, amSeduction}
variants[varName]["helperLimit"] = 1
variants[varName]["helpers"] = {amRope, amPickHammer}
variants[varName]["special"] = false

varName = "Scientist"
variants[varName] = {}
variants[varName]["chance"] = 7
variants[varName]["hat"] = "doctor"
variants[varName]["hp"] = 80
variants[varName]["hogLimit"] = 1
variants[varName]["weaponLimit"] = 1
variants[varName]["weapons"] = {amPortalGun, amSineGun, amIceGun}
variants[varName]["helperLimit"] = 1
variants[varName]["helpers"] = {amTeleport, amJetpack}  
variants[varName]["special"] = false

varName = "Air-General"
variants[varName] = {}
variants[varName]["chance"] = 5
variants[varName]["hat"] = "war_desertofficer"
variants[varName]["hp"] = 50
variants[varName]["hogLimit"] = 1
variants[varName]["weaponLimit"] = 1
variants[varName]["weapons"] = {amMineStrike, amNapalm, amAirAttack}
variants[varName]["helperLimit"] = 1
variants[varName]["helpers"] = {amRope, amParachute}
variants[varName]["special"] = true

varName = "Hunter"
variants[varName] = {}
variants[varName]["chance"] = 10
variants[varName]["hat"] = "Skull"
variants[varName]["hp"] = 100
variants[varName]["hogLimit"] = 1
variants[varName]["weaponLimit"] = 1
variants[varName]["weapons"] = {amBee, amMortar, amDrill}
variants[varName]["helperLimit"] = 1
variants[varName]["helpers"] = {amRope, amParachute}
variants[varName]["special"] = false

varName = "King"
variants[varName] = {}
variants[varName]["chance"] = 3
variants[varName]["hat"] = "crown"
variants[varName]["hp"] = 60
variants[varName]["hogLimit"] = 1
variants[varName]["weaponLimit"] = 1
variants[varName]["weapons"] = {amWatermelon, amHellishBomb, amBallgun}
variants[varName]["helperLimit"] = 1
variants[varName]["helpers"] = {amRope, amParachute}
variants[varName]["special"] = true

varName = "Knight"
variants[varName] = {}
variants[varName]["chance"] = 0
variants[varName]["hat"] = "knight"
variants[varName]["hp"] = 80
variants[varName]["hogLimit"] = 1
variants[varName]["weaponLimit"] = 1
variants[varName]["weapons"] = {amShotgun, amBazooka, amMine}
variants[varName]["helperLimit"] = 1
variants[varName]["helpers"] = {amParachute, amRope}
variants[varName]["special"] = true

--[[
  ##############################################################################
  ### GENERAL VARIABLES USED FOR GAMEPLAY                                    ###
  ##############################################################################
]]--

local unused = {amSnowball, amDrillStrike, amTardis}
local lowWeaps = {amKamikaze}
local lowTresh = 25

local counter = {} -- Saves how many hogs of a variant a team has
local group = {} -- Saves randomized variants for all teams
local teamIndex = {} -- Temporary counter for amount of mutated hogs in team
local teamHogs = {} -- Saves a list of all hogs belonging to a team
local hogCount = {} -- Saves how many hogs a team has
local teamNames = {} -- Saves all teams and names
local hogInfo = {} -- Saves all hogs with their original values

local LastHog = nil -- Last Hedgehog
local CurHog = nil -- Current Hedgehog
local LastTeam = nil -- Last Team
local CurTeam = nil -- Current Team
local TurnEnded = true -- Boolean whether current turn ended or not

local mode = 'default' -- Which game type to play
local luck = 100 -- Multiplier for bonuses like crates
local strength = 1 -- Multiplier for more weapons
local mutate = false -- Whether or not to mutate the hogs

local highHasBonusWeps = false -- whether or not a hog got bonus weapons on current turn
local highHasBonusHelp = false -- whether or not a hog got bonus helpers on current turn
local highPickupCount = 1
local highPickupSDCount = 2
local highHelperCount = 1
local highHelperSDCount = 1
local highEnemyKillHPBonus = 10
local highFriendlyKillHPBonus = 15
local highWeapons = {} -- Saves the weapons from kills
local highHelpers = {} -- Saves the helpers from kills
local highSpecialBonus = {amTeleport, amJetpack}
local highSpecialPool = {amExtraDamage, amVampiric}

local kingLinkPerc = 50 -- Percentage of life to share from the team

local pointsWepBase = 5 -- Game start points weapons
local pointsHlpBase = 2 -- Game start points helpers
local pointsKeepPerc = 80 -- Percentage of points to take to next round
local pointsWepTurn = 5 -- Round bonus points weapons
local pointsHlpTurn = 2 -- Round bonus points helpers
local pointsWepMax = 25 -- Maximum points for weapons
local pointsHlpMax = 10 -- Maximum points for helpers
local pointsKeepSDPerc = 60 -- Percentage of points to take to next round on SD
local pointsWepSDTurn = 7 -- Round bonus points weapons on SD
local pointsHlpSDTurn = 3 -- Round bonus points helpers on SD
local pointsWepSDMax = 35 -- Maximum points for weapons on SD
local pointsHlpSDMax = 15 -- Maximum points for helpers on SD

local pointsWeaponVal = {}
pointsWeaponVal[amBazooka] = 5
pointsWeaponVal[amShotgun] = 4
pointsWeaponVal[amFirePunch] = 3
pointsWeaponVal[amMine] = 5
--pointsWeaponVal[amAirAttack] = 10
pointsWeaponVal[amBee] = 6
pointsWeaponVal[amClusterBomb] = 7
pointsWeaponVal[amGrenade] = 5
pointsWeaponVal[amDEagle] = 3
pointsWeaponVal[amWhip] = 3
pointsWeaponVal[amDynamite] = 7
--pointsWeaponVal[amMineStrike] = 14
pointsWeaponVal[amMortar] = 4
pointsWeaponVal[amWatermelon] = 30
pointsWeaponVal[amSniperRifle] = 3
pointsWeaponVal[amBaseballBat] = 3
pointsWeaponVal[amCake] = 7
--pointsWeaponVal[amNapalm] = 11
pointsWeaponVal[amDrill] = 6
pointsWeaponVal[amHellishBomb] = 20
pointsWeaponVal[amSineGun] = 4
--pointsWeaponVal[amKamikaze] = 3
--pointsWeaponVal[amBallgun] = 12
--pointsWeaponVal[amPianoStrike] = 15
pointsWeaponVal[amSnowball] = 2
pointsWeaponVal[amMolotov] = 3
pointsWeaponVal[amFlamethrower] = 4
pointsWeaponVal[amRCPlane] = 7
--pointsWeaponVal[amDrillStrike] = 12
pointsWeaponVal[amGasBomb] = 2
pointsWeaponVal[amHammer] = 3
pointsWeaponVal[amSMine] = 4
pointsWeaponVal[amAirMine] = 3
pointsWeaponVal[amKnife] = 3
pointsWeaponVal[amPortalGun] = 5
--pointsWeaponVal[amIceGun] = 6
pointsWeaponVal[amSeduction] = 2

local pointsHelperVal = {}
pointsHelperVal[amRope] = 5
pointsHelperVal[amParachute] = 2
--pointsHelperVal[amGirder] = 3
pointsHelperVal[amBlowTorch] = 2
pointsHelperVal[amLowGravity] = 3
--pointsHelperVal[amRubber] = 4
pointsHelperVal[amPickHammer] = 2
pointsHelperVal[amTeleport] = 10
pointsHelperVal[amJetpack] = 8

local pointsPerTeam = {}
local pointsToWep = {} -- List of [points] = {ammo1, ammo2}
local pointsToHlp = {} -- List of [points] = {ammo1, ammo2}
local wepPoints = {}
local hlpPoints = {}

local suddenDeath = false

local healthCrateChance = 7
local utilCrateChance = 9
local weaponCrateChance = 12

local healthCrateChanceSD = 12
local utilCrateChanceSD = 16
local weaponCrateChanceSD = 21

local emptyCrateChance = 7
local bonusCrateChance = 5
local cratePickupGap = 35

local utilities = {amInvulnerable, amVampiric, amExtraTime, amExtraDamage, amRope, amLandGun}
local autoSelectHelpers = {amRope, amParachute}

local LastWaterLine = 0 -- Saves WaterLine to make sure a water rise wont trigger highland kill

local helpers = {}
helpers[amSkip] = true
helpers[amRope] = true
helpers[amParachute] = true
helpers[amBlowTorch] = true
helpers[amGirder] = true
helpers[amTeleport] = true
helpers[amSwitch] = true
helpers[amJetpack] = true
helpers[amBirdy] = true
helpers[amPortalGun] = true
helpers[amResurrector] = true
helpers[amTardis] = true
helpers[amLandGun] = true
helpers[amRubber] = true
--helpers[amKamikaze] = true

local posCaseAmmo    = 1
local posCaseHealth  = 2
local posCaseUtility = 4
local posCaseDummy   = 8

--[[
  ##############################################################################
  ### GENERAL BONUS LUA FUNCTIONS                                            ###
  ##############################################################################
]]--

function swap(array, index1, index2)
    array[index1], array[index2] = array[index2], array[index1]
end

function shuffle(array)
    local cnt = #array
    while cnt > 1 do
        local index = GetRandom(cnt) +1
        swap(array, index, cnt)
        cnt = cnt - 1
    end
end

function table.clone(org)
  local copy = {}
  for orig_key, orig_value in pairs(org) do
      copy[orig_key] = orig_value
  end
  return copy
end

--[[
  ##############################################################################
  ### WEAPON, UTILITY AND AMMO FUNCTIONS                                     ###
  ##############################################################################
]]--

function clearHogAmmo(hog)
  local lastNum = amRubber

  if amAirMine ~= nil then
    lastNum = amAirMine
  end

  for val=0,lastNum do
    AddAmmo(hog, val, 0)
  end
end

function autoSelectAmmo(hog, var)
  -- Check if hog has any "useful" helper, select helper, if yes
  for key, val in pairs(autoSelectHelpers) do
    if GetAmmoCount(hog, val) > 0 then
      SetWeapon(val)
      return
    end
  end
end

function AddHogAmmo(hog, ammo)
  -- Add weapons of variant
  --for key, val in pairs(variants[var]["weapons"]) do
  for key, val in pairs(ammo) do
    --AddAmmo(hog, val, 1)
    AddAmmo(hog, val, GetAmmoCount(hog, val) +1)
  end
end

function GetRandomAmmo(hog, sourceType)
  local var = getHogInfo(hog, 'variant')
  ammo = {}
  local source = ''

  if variants[var] == nil then
    return ammo
  end

  if sourceType == "weapons" then
    source = variants[var][sourceType]
    sourceLimit = variants[var]["weaponLimit"]
  elseif sourceType == "helpers" then
    source = variants[var][sourceType]
    sourceLimit = variants[var]["helperLimit"]
  elseif sourceType == 'poolWeapons' then
    if highWeapons[hog] == nil then
      highWeapons[hog] = {}
    end
    source = highWeapons[hog]
    if suddenDeath == false then
      sourceLimit = highPickupCount
    else
      sourceLimit = highPickupSDCount
    end
  elseif sourceType == 'poolHelpers' then
    if highHelpers[hog] == nil then
      highHelpers[hog] = {}
    end
    source = highHelpers[hog]
    if suddenDeath == false then
      sourceLimit = highHelperCount
    else
      sourceLimit = highHelperSDCount
    end
  else
    return ammo
  end
  
  local varAmmo = {}
  for key, val in pairs(source) do
      varAmmo[key] = val
  end
  
  -- If the amount of random weapons is equally to the amount of weapons possible
  -- We don't need to randomize
  if sourceLimit >= table.getn(source) then
    return varAmmo
  end

  local randIndex = 0
  local i = 0
  while i < sourceLimit and #varAmmo > 0 do
    randIndex = GetRandom(#varAmmo) +1
    ammo[i] = varAmmo[randIndex]

    -- Shift last value to the current index
    varAmmo[randIndex] = varAmmo[#varAmmo]
    -- And remove the last index from the array
    varAmmo[#varAmmo] = nil
    i = i +1
  end

  return ammo
end

function addTurnAmmo(hog)
  -- Check if hog is valid
  if hog == nil then
    return
  end

  -- Check if hog is alive
  local hp = GetHealth(hog)
  if hp == nil or hp <= 0 then
    return
  end

  -- Unless its points mode, get weapons normally by variant
  if mode ~= "points" then
    local maxHp = getHogInfo(hog, 'maxHp')
    local hpPer = div(hp * 100, maxHp)

    local wep = getHogInfo(hog, 'weapons')
    local hlp = getHogInfo(hog, 'helpers')

    if wep == nil or table.getn(wep) == 0 then
      hogInfo[hog]['weapons'] = GetRandomAmmo(hog, "weapons")
      wep = getHogInfo(hog, 'weapons')
    end

    if hlp == nil or table.getn(hlp) == 0 then
      hogInfo[hog]['helpers'] = GetRandomAmmo(hog, "helpers")
      hlp = getHogInfo(hog, 'helpers')
    end

    AddHogAmmo(hog, wep)
    AddHogAmmo(hog, hlp)

    if mode == 'highland' then
      local poolWeapons = GetRandomAmmo(hog, 'poolWeapons')
      local poolHelpers = GetRandomAmmo(hog, 'poolHelpers')

      AddHogAmmo(hog, poolWeapons)
      AddHogAmmo(hog, poolHelpers)
    end

    if hpPer < lowTresh or suddenDeath == true then
      AddHogAmmo(hog, lowWeaps)
    end
  -- We are on points mode, so we need to generate weapons based on points
  else
    setupPointsAmmo(hog)
  end

  AddAmmo(hog, amSkip, -1)
end

function setupPointsAmmo(hog)
  local teamName = getHogInfo(hog, 'team')
  local turnWepPoints = pointsPerTeam[teamName]['weapons']
  local turnHlpPoints = pointsPerTeam[teamName]['helpers']
  local weps = {}
  local help = {}

  local wepPointsTmp = table.clone(wepPoints)
  local wepMinPnt = wepPointsTmp[1]
  local wepMaxPnt = wepPointsTmp[#wepPointsTmp]

  --AddCaption("Hog: " .. hog .. " Wep: " .. turnWepPoints .. " - Hlp: " .. turnHlpPoints, GetClanColor(GetHogClan(CurHog)),  capgrpGameState)
  --WriteLnToConsole("BEFORE ## Team: " .. teamName .. " Wep: " .. pointsPerTeam[teamName]['weapons'] .. " - Hlp: " .. pointsPerTeam[teamName]['helpers'])

  while true do
    if turnWepPoints < wepMinPnt then
      break
    end

    if wepPointsTmp[#wepPointsTmp] > turnWepPoints then
      while wepPointsTmp[#wepPointsTmp] > turnWepPoints do
        table.remove(wepPointsTmp)
      end
      wepMaxPnt = turnWepPoints
    end

    local randPoint = wepPointsTmp[GetRandom(#wepPointsTmp) +1]
    local randWepList = pointsToWep[randPoint]
    local randWep = randWepList[GetRandom(#randWepList) +1]

    table.insert(weps, randWep)
    turnWepPoints = turnWepPoints -randPoint
  end

  local hlpPointsTmp = table.clone(hlpPoints)
  local hlpMinPnt = hlpPointsTmp[1]
  local hlpMaxPnt = hlpPointsTmp[#hlpPointsTmp]

  while true do
    if turnHlpPoints < hlpMinPnt then
      break
    end

    if hlpPointsTmp[#hlpPointsTmp] > turnHlpPoints then
      while hlpPointsTmp[#hlpPointsTmp] > turnHlpPoints do
        table.remove(hlpPointsTmp)
      end
      hlpMaxPnt = turnHlpPoints
    end

    local randPoint = hlpPointsTmp[GetRandom(#hlpPointsTmp) +1]
    local randHlpList = pointsToHlp[randPoint]
    local randHlp = randHlpList[GetRandom(#randHlpList) +1]

    table.insert(help, randHlp)
    turnHlpPoints = turnHlpPoints -randPoint
  end

  AddHogAmmo(hog, weps)
  AddHogAmmo(hog, help)

  -- Save remaining points
  pointsPerTeam[teamName]['weaponsRem'] = turnWepPoints
  pointsPerTeam[teamName]['helpersRem'] = turnHlpPoints

  -- Save already collected points so that they wont be "taxed"
  pointsPerTeam[teamName]['weaponsFix'] = pointsPerTeam[teamName]['weapons']
  pointsPerTeam[teamName]['helpersFix'] = pointsPerTeam[teamName]['helpers']

  --WriteLnToConsole("AFTER ## Team: " .. teamName .. " Wep: " .. pointsPerTeam[teamName]['weapons'] .. " - Hlp: " .. pointsPerTeam[teamName]['helpers'])
end

--[[
  ##############################################################################
  ### HOG SETUP  FUNCTIONS                                                   ###
  ##############################################################################
]]--

function MutateHog(hog)
  local var = getHogInfo(hog, 'variant')

  SetHogName(hog, var)
  SetHogHat(hog, variants[var]["hat"])
end

function GetRandomVariant()
  local maxNum = 0

  for key, val in pairs(variants) do
    maxNum = maxNum + variants[key]["chance"]
  end

  local rand = GetRandom(maxNum)
  local lowBound = 0
  local highBound = 0
  local var = nil

  for key, val in pairs(variants) do
    highBound = lowBound + variants[key]["chance"]
    if rand <= highBound then
      var = key
      break
    end
    lowBound = highBound
  end

  return var
end

function addRandomVariantToTeam(team)
  if counter[team] == nil then
    counter[team] = {}
  end

  while true do
    local var = GetRandomVariant()
    if counter[team][var] == nil and variants[var]["hogLimit"] > 0 then
      counter[team][var] = 1
      break
    elseif counter[team][var] ~= nil and counter[team][var] < variants[var]["hogLimit"] then
      counter[team][var] = counter[team][var] +1
      break
    end
  end

  return var
end

function setTeamHogs(team)
  local maxHog = hogCount[team]

  group[team] = {}
  counter[team] = {}

  if mode == 'king' then
    maxHog = maxHog -1
  end

  for i=1,maxHog do
    table.insert(group[team], group['all'][i])
  end

  if mode == 'king' then
    counter[team]['King'] = 1
    table.insert(group[team], 'King')
  end
end

function countTeamHogs(hog)
  local team = GetHogTeamName(hog)

  if hogCount[team] == nil then
    hogCount[team] = 1
    teamHogs[team] = {}
  else
    hogCount[team] = hogCount[team] +1
  end

  teamHogs[team][hogCount[team]] = hog

  teamNames[team] = 1
end

function setHogVariant(hog)
  local team = getHogInfo(hog, 'team')

  if teamIndex[team] == nil then
    teamIndex[team] = 1
  else
    teamIndex[team] = teamIndex[team] +1
  end

  local hogNum = teamIndex[team]
  local hogVar = group[team][hogNum]

  hogInfo[hog]['variant'] = hogVar
  SetHealth(hog, variants[hogVar]["hp"])
end

function getHogInfo(hog, info)
  if hog == nil then
    AddCaption(loc("ERROR [getHogInfo]: Hog is nil!"), 0xFFFFFFFF, capgrpMessage)
    WriteLnToConsole(loc("ERROR [getHogInfo]: Hog is nil!"), 0xFFFFFFFF, capgrpMessage)
    return
  end

  if hogInfo[hog] == nil then
    return nil
  end

  return hogInfo[hog][info]
end

function setHogInfo(hog)
  if hog == nil then
    AddCaption(loc("ERROR [getHogInfo]: Hog is nil!"), 0xFFFFFFFF, capgrpMessage)
    WriteLnToConsole(loc("ERROR [getHogInfo]: Hog is nil!"), 0xFFFFFFFF, capgrpMessage)
    return
  end

  hogInfo[hog] = {}
  hogInfo[hog]['maxHp'] = GetHealth(hog)
  hogInfo[hog]['name'] = GetHogName(hog)
  hogInfo[hog]['hat'] = GetHogHat(hog)
  hogInfo[hog]['team'] = GetHogTeamName(hog)
  hogInfo[hog]['clan'] = GetHogClan(hog)
  hogInfo[hog]['clanColor'] = GetClanColor(hogInfo[hog]['clan'])
end

--[[
  ##############################################################################
  ### CRATE SPAWN AND PICKUP FUNCTIONS                                       ###
  ##############################################################################
]]--

--[[
 : Heals either 10 (95% chance) or 15 (5% chance) hitpoints
 : Plus 10% of the hogs base hitpoints. 
 :
 : Has a 7% chance to be empty.
]]--
function onHealthCratePickup()
  local factor = 2
  local msgColor = getHogInfo(CurHog, 'clanColor')
  local healHp = 0
  PlaySound(sndShotgunReload)

  if GetRandom(100) < emptyCrateChance then
    AddCaption(loc("It's empty!"), msgColor, capgrpMessage)
    return
  elseif GetRandom(100) < bonusCrateChance then
    factor = 3
  end

  local var = getHogInfo(CurHog, 'variant')
  local hogHealth = GetHealth(CurHog)
  healHp = 5 * factor

  -- Add extra 10% of hogs base hp to heal
  healHp = healHp + div(getHogInfo(CurHog, 'maxHp'), 10)

  AddCaption(string.format(loc("+%d"), healHp), msgColor, capgrpMessage)

  SetEffect(CurHog, hePoisoned, 0)
  SetHealth(CurHog, hogHealth + healHp)
  local effect = AddVisualGear(GetX(CurHog), GetY(CurHog) +cratePickupGap, vgtHealthTag, healHp, false)
  -- (vgUid, X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint)
  SetVisualGearValues(effect, nil, nil, nil, nil, nil, nil, nil, nil, nil, msgColor)
end

--[[
 : Adds either 1 (95% chance) or 2 (5% chance) random weapon(s) based on the hog variant.
 :
 : Has a 7% chance to be empty.
]]--
function onWeaponCratePickup()
  local factor = 1 * strength
  local msgColor = GetClanColor(GetHogClan(CurHog))
  PlaySound(sndShotgunReload)

  if GetRandom(100) < emptyCrateChance then
    AddCaption(loc("It's empty!"), msgColor, capgrpMessage)
    return
  elseif GetRandom(100) < bonusCrateChance then
    factor = 2 * strength
  end

  local randIndex
  local randAmmo

  if mode ~= 'points' then
    local var = getHogInfo(CurHog, 'variant')
    randIndex = GetRandom(table.getn(variants[var]["weapons"])) +1
    randAmmo = variants[var]["weapons"][randIndex]
  else
    local possibleWeapons = {}

    for key, val in pairs(pointsWeaponVal) do
      if val > 2 and val < 8 then
        table.insert(possibleWeapons, key)
      end
    end

    randIndex = GetRandom(table.getn(possibleWeapons)) +1
    randAmmo = possibleWeapons[randIndex]
  end

  AddCaption(string.format(loc("+%d ammo"), factor), msgColor, capgrpMessage)

  AddAmmo(CurHog, randAmmo, GetAmmoCount(CurHog, randAmmo) +factor)
  local effect = AddVisualGear(GetX(CurHog), GetY(CurHog) +cratePickupGap, vgtAmmo, 0, true)
  -- (vgUid, X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint)
  SetVisualGearValues(effect, nil, nil, nil, nil, nil, randAmmo, nil, nil, nil, msgColor)
end
--[[
 : Adds either 1 (95% chance) or 2 (5% chance) random helper(s) based on the hog variant.
 :
 : Has a 7% chance to be empty.
]]--
function onUtilityCratePickup()
  local factor = 1 * strength
  local msgColor = GetClanColor(GetHogClan(CurHog))
  PlaySound(sndShotgunReload)

  if GetRandom(100) < emptyCrateChance then
    AddCaption(loc("It's empty!"), msgColor, capgrpMessage)
    return
  elseif GetRandom(100) < bonusCrateChance then
    factor = 2 * strength
  end

  local randIndex
  local randUtility

  if mode ~= 'points' then
    randIndex = GetRandom(table.getn(utilities)) +1
    randUtility = utilities[randIndex]
  else
    local possibleHelpers = {}

    for key, val in pairs(pointsHelperVal) do
      table.insert(possibleHelpers, key)
    end

    randIndex = GetRandom(table.getn(possibleHelpers)) +1
    randUtility = possibleHelpers[randIndex]
  end
  
  AddCaption(string.format(loc("+%d ammo"), factor), msgColor, capgrpMessage)

  AddAmmo(CurHog, randUtility, GetAmmoCount(CurHog, randUtility) +factor)
  local effect = AddVisualGear(GetX(CurHog), GetY(CurHog) +cratePickupGap, vgtAmmo, 0, true)
  -- (vgUid, X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint)
  SetVisualGearValues(effect, nil, nil, nil, nil, nil, randUtility, nil, nil, nil, msgColor)
end

function onPickupCrate(crate)
  local pos = GetGearPos(crate)

  -- Check if the crate is fake
  if pos % posCaseDummy >= 1 then
    if pos % posCaseDummy == posCaseAmmo then
      onWeaponCratePickup()
    elseif pos % posCaseDummy == posCaseHealth then
      onHealthCratePickup()
    elseif pos % posCaseDummy == posCaseUtility then
      onUtilityCratePickup()
    end
  end
end

function RandomTurnEvents()
  if GetRandom(100) < weaponCrateChance then
    SpawnFakeAmmoCrate(0, 0, false, false)
    return 5000
  elseif GetRandom(100) < utilCrateChance then
    SpawnFakeUtilityCrate(0, 0, false, false)
    return 5000
  elseif GetRandom(100) < healthCrateChance then
    SpawnFakeHealthCrate(0, 0, false, false)
    return 5000
  end
  return 0
end

--[[
  ##############################################################################
  ### SUDDEN DEATH FUNCTIONS                                                 ###
  ##############################################################################
]]--

function onSuddenDeathDamage(hog)
  local hp = GetHealth(hog)
  local maxHp = getHogInfo(hog, 'maxHp')
  local newHp = 0
  local hpDec = 0
  local hpPer = div(hp * 100, maxHp)

  if hp > 1 then
    local msgColor = GetClanColor(GetHogClan(hog))
    if hpPer <= 25 then
      newHp = hp -2
    elseif hpPer <= 50 then
      newHp = hp -3
    elseif hpPer <= 75 then
      newHp = hp -4
    elseif hpPer <= 100 then
      newHp = hp -5
    elseif hpPer <= 125 then
      newHp = hp -6
    elseif hpPer <= 150 then
      newHp = hp -7
    else
      newHp = div(hp * 93, 100)
    end

    if newHp <= 0 then
      newHp = 1
    end

    hpDec = hp - newHp

    SetHealth(hog, newHp)
    local effect = AddVisualGear(GetX(hog), GetY(hog) +cratePickupGap, vgtHealthTag, hpDec, false)
    SetVisualGearValues(effect, nil, nil, nil, nil, nil, nil, nil, nil, nil, msgColor)
  end
end

function onSuddenDeathTurn()
  runOnGears(onSuddenDeathDamage)
end

function onSuddenDeath()
  suddenDeath = true

  healthCrateChance = healthCrateChanceSD
  utilCrateChance = utilCrateChanceSD
  weaponCrateChance = weaponCrateChanceSD

  if mode == 'highland' then
    highEnemyKillHPBonus = highEnemyKillHPBonus +5
    highFriendlyKillHPBonus = highFriendlyKillHPBonus +10
  end

  if mode ~= 'points' then
    for key, val in pairs(variants) do
      if not variants[key]["special"] then
        variants[key]["weaponLimit"] = variants[key]["weaponLimit"] +1
      end
    end
  end

  if mode ~= 'points' then
    for hog, val in pairs(hogInfo) do
      hogInfo[hog]['weapons'] = {}
      hogInfo[hog]['helpers'] = {}
    end
    
    runOnGears(setupHogTurn)
  end
end

--[[
  ##############################################################################
  ### GEAR TRACKING FUNCTIONS                                                ###
  ##############################################################################
]]--

function onGearAdd(gear)
  local gearType = GetGearType(gear)
  
  if gearType == gtHedgehog then
    trackGear(gear)
  elseif gearType == gtRCPlane then
    -- Limit bombs to 1 until 0.9.23 is released
    SetHealth(gear, 1)
  elseif gearType == gtAirBomb then
    -- gearUid, Angle, Power, WDTimer, Radius, Density, Karma, DirAngle, AdvBounce, ImpactSound, ImpactSounds, Tint, Damage, Boom
    SetGearValues(gear, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 15)
  elseif gearType == gtCake then
    -- gearUid, Angle, Power, WDTimer, Radius, Density, Karma, DirAngle, AdvBounce, ImpactSound, ImpactSounds, Tint, Damage, Boom
    SetGearValues(gear, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 50)
  elseif gearType == gtDEagleShot then
    -- gearUid, Angle, Power, WDTimer, Radius, Density, Karma, DirAngle, AdvBounce, ImpactSound, ImpactSounds, Tint, Damage, Boom
    SetGearValues(gear, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 12)
  end
end

function onHighlandKill(gear)
  local deathVar = getHogInfo(gear, 'variant')
  local killVar = getHogInfo(CurHog, 'variant')
  local bonAmmo = {}
  local deathMaxHP = getHogInfo(gear, 'maxHp')
  local curHP = GetHealth(CurHog)
  local newHP = 0
  local hpDiff = 0
  local addAmmo = false

  -- Killer hog is dead! Don't do anything
  if curHP == nil or curHP <= 0 then
    return
  end

  -- Killer and victim is equal! Don't do anything
  if CurHog == gear then
    return
  end

  -- Hog drowned because of water, not enemy
  if LastWaterLine ~= WaterLine then
    return
  end

  -- Enemy kill! Add weapons to pool and to hog
  if getHogInfo(gear, 'clan') ~= getHogInfo(CurHog, 'clan') then

    -- Initialize weapons if required
    if highWeapons[CurHog] == nil then
      highWeapons[CurHog] = {}
    end

    if highHelpers[CurHog] == nil then
      highHelpers[CurHog] = {}
    end

    -- If not a special hog, use the victims weapons
    if variants[deathVar]['special'] == false then
      bonAmmo = variants[deathVar]['weapons']

      if suddenDeath == true then
        ammoCount = highPickupSDCount
      else
        ammoCount = highPickupCount
      end

      -- Check if hog already got bonus weapons
      if table.getn(highWeapons[CurHog]) == 0 and highHasBonusWeps == false then
        highHasBonusWeps = true
        addAmmo = true
      end

      -- Pass turn bonus weapons to hog pool
      for key, val in pairs(bonAmmo) do
        local idx = table.getn(highWeapons[CurHog]) +1
        highWeapons[CurHog][idx] = val
      end
    -- It's a special hog, use special pool
    else
      bonAmmo = highSpecialBonus

      ammoCount = 1

      -- Check if hog already got bonus helpers
      if table.getn(highWeapons[CurHog]) == 0 and highHasBonusHelp == false then
        highHasBonusHelp = true
        addAmmo = true
      end

      -- Pass turn bonus weapons to hog pool
      for key, val in pairs(highSpecialPool) do
        local idx = table.getn(highHelpers[CurHog]) +1
        highHelpers[CurHog][idx] = val
      end
    end

    if addAmmo then
      local i = 1
      while i <= ammoCount and #bonAmmo > 0 do
        local randAmmo = GetRandom(#bonAmmo) +1
        local randAmmoType = bonAmmo[randAmmo]

        -- Remove the randomized weapon so it cannot be picked up twice
        table.remove(bonAmmo, randAmmo)

        AddAmmo(CurHog, randAmmoType, GetAmmoCount(CurHog, randAmmoType) +1)

        local effect = AddVisualGear(GetX(CurHog), GetY(CurHog) + (cratePickupGap * i), vgtAmmo, 0, true)
        -- (vgUid, X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint)
        SetVisualGearValues(effect, nil, nil, nil, nil, nil, randAmmoType, nil, nil, nil, nil)

        i = i +1
      end
    end

    hpDiff = div(deathMaxHP * highEnemyKillHPBonus, 100)
    newHP = curHP + hpDiff
    SetHealth(CurHog, newHP)

    local effect = AddVisualGear(GetX(CurHog), GetY(CurHog) - cratePickupGap, vgtHealthTag, hpDiff, false)
    -- (vgUid, X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint)
    SetVisualGearValues(effect, nil, nil, nil, nil, nil, nil, nil, nil, nil, GetClanColor(GetHogClan(CurHog)))
  -- Friendly fire! Remove all weapons and helpers from pool
  else
    highWeapons[CurHog] = {}
    highHelpers[CurHog] = {}

    hpDiff = div(deathMaxHP * highFriendlyKillHPBonus, 100)
    newHP = curHP - hpDiff
    if newHP > 0 then
      SetHealth(CurHog, newHP)
    else
      SetHealth(CurHog, 0)
    end

    local effect = AddVisualGear(GetX(CurHog), GetY(CurHog) - cratePickupGap, vgtHealthTag, hpDiff, false)
    -- (vgUid, X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint)
    SetVisualGearValues(effect, nil, nil, nil, nil, nil, nil, nil, nil, nil, GetClanColor(GetHogClan(CurHog)))
  end
end

function onKingDeath(KingHog)
  local team = getHogInfo(KingHog, 'team')
  local msgColor = getHogInfo(KingHog, 'clanColor')

  AddCaption(string.format(loc("The king of %s has died!"), team), 0xFFFFFFFF, capgrpGameState)
  PlaySound(sndByeBye)
  DismissTeam(team)

  -- for hog, val in pairs(hogInfo) do
  --   if getHogInfo(hog, 'team') == team then
  --     hp = GetHealth(hog)
  --     if hp ~= nil and hp > 0 then
  --       SetState(KingHog, gstHHDeath)
  --       SetHealth(hog, 0)
  --       SetGearValues(hog, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0)
  --     end
  --   end
  -- end
end

function onPointsKill(gear)
  local deathVar = getHogInfo(gear, 'variant')
  local killVar = getHogInfo(CurHog, 'variant')
  local deathClan = getHogInfo(gear, 'clan')
  local killClan = getHogInfo(CurHog, 'clan')
  local team = getHogInfo(CurHog, 'team')

  local curHP = GetHealth(CurHog)

  -- Killer hog is dead! Don't do anything
  if curHP == nil or curHP <= 0 then
    return
  end

  -- Hog drowned because of water, not enemy
  if LastWaterLine ~= WaterLine then
    return
  end

  -- Same clan, friendly kill, skip
  if killClan == deathClan then
    return
  end

  pointsPerTeam[team]['weapons'] = pointsPerTeam[team]['weapons'] + 2
  pointsPerTeam[team]['helpers'] = pointsPerTeam[team]['helpers'] + 1

  local effect = AddVisualGear(GetX(CurHog) - (cratePickupGap / 2), GetY(CurHog), vgtHealthTag, 2, false)
  -- (vgUid, X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint)
  SetVisualGearValues(effect, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0xFFFFFFFF)

  local effect = AddVisualGear(GetX(CurHog) + (cratePickupGap / 2), GetY(CurHog), vgtHealthTag, 1, false)
  -- (vgUid, X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint)
  SetVisualGearValues(effect, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0x444444FF)
end

function onGearDelete(gear)
  trackDeletion(gear)

  if GetGearType(gear) == gtCase and band(GetGearMessage(gear), gmDestroy) ~= 0 then
    onPickupCrate(gear)
  end

  if GetGearType(gear) == gtHedgehog then
    if mode ~= 'points' then
      hogInfo[gear]['weapons'] = {}
      hogInfo[gear]['helpers'] = {}
    end

    -- If dying gear is a hog and mode is highland, check for kills
    if mode == 'highland' then
      onHighlandKill(gear)
    -- If current hog is dying and we are on points mode, we need to save the unused weapons/helpers
    elseif mode == 'points' and CurHog == gear then
      savePoints(gear)
    elseif mode == 'points' and CurHog ~= gear then
      onPointsKill(gear)
    end

    if mode == 'king' and getHogInfo(gear, 'variant') == 'King' then
      onKingDeath(gear)
    end
  end
end

--[[
  ##############################################################################
  ### TURN BASED FUNCTIONS                                                   ###
  ##############################################################################
]]--

function calcKingHP()
  local teamKings = {}
  local teamHealth = {}

  for hog, val in pairs(hogInfo) do
    local hp = GetHealth(hog)

    if hp ~= nil and hp > 0 then
      local team = getHogInfo(hog, 'team')

      if teamHealth[team] == nil then
        teamHealth[team] = 0
      end

      if getHogInfo(hog, 'variant') == 'King' then
        teamKings[team] = hog
      else
        teamHealth[team] = teamHealth[team] + hp
      end
    end
  end

  for team, hog in pairs(teamKings) do
    local hp = GetHealth(hog)
    local newHP = div(teamHealth[team] * kingLinkPerc, 100)
    local diff = newHP - hp

    -- Set hitpoints to 1 if no other hog is alive or only has 1 hitpoint
    if newHP <= 0 then
      newHP = 1
      diff = 0
    end

    if diff < 0 then
      diff = -diff
    end

    if hp ~= newHP then
      SetHealth(hog, newHP)
      local effect = AddVisualGear(GetX(hog), GetY(hog) - cratePickupGap, vgtHealthTag, diff, false)
      -- (vgUid, X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint)
      SetVisualGearValues(effect, nil, nil, nil, nil, nil, nil, nil, nil, nil, GetClanColor(GetHogClan(hog)))
    end
  end
end

function setupHogTurn(hog)
  clearHogAmmo(hog)
  addTurnAmmo(hog)
end

function onTurnEnd()
  local anyHog = nil
  for team, val in pairs(teamNames) do
    -- Count amount of alive hogs in team
    local c = 0
    for idx, hog in pairs(teamHogs[team]) do
      if GetHealth(hog) ~= nil then
        anyHog = hog
        c = c + 1
      end
    end

    -- Only one hog left, unfreeze the hog
    if c == 1 then
      if GetHealth(anyHog) ~= nil then
        SetEffect(anyHog, heFrozen, 0)
      end
    end
  end

  -- When we are on points mode count remaining weapon/helper points
  if mode == 'points' and GetHealth(CurHog) ~= nil then
    savePoints(CurHog)
  end

  -- Run random turn events
  RandomTurnEvents()
end

function savePoints(hog)
  local team = getHogInfo(hog, 'team')
  local hogWepPoints = 0
  local hogHlpPoints = 0

  for ammoType=0,amAirMine do
    local ammoCount = GetAmmoCount(hog, ammoType)

    if pointsWeaponVal[ammoType] ~= nil then
      hogWepPoints = hogWepPoints + (pointsWeaponVal[ammoType] * ammoCount)
    elseif pointsHelperVal[ammoType] ~= nil then
      hogHlpPoints = hogHlpPoints + (pointsHelperVal[ammoType] * ammoCount)
    end
  end

  local wepWoTax = pointsPerTeam[team]['weaponsFix']
  local hlpWoTax = pointsPerTeam[team]['helpersFix']
  local wepToTax = 0
  local hlpToTax = 0

  if hogWepPoints <= wepWoTax then
    wepWoTax = hogWepPoints
  else
    wepToTax = hogWepPoints - wepWoTax
  end

  if hogHlpPoints <= hlpWoTax then
    hlpWoTax = hogHlpPoints
  else
    hlpToTax = hogHlpPoints - hlpWoTax
  end

  if suddenDeath == false then
    pointsPerTeam[team]['weapons'] = pointsPerTeam[team]['weaponsRem'] + wepWoTax + div(wepToTax * pointsKeepPerc, 100)
    pointsPerTeam[team]['helpers'] = pointsPerTeam[team]['helpersRem'] + hlpWoTax + div(hlpToTax * pointsKeepPerc, 100)
  else
    pointsPerTeam[team]['weapons'] = pointsPerTeam[team]['weaponsRem'] + wepWoTax + div(wepToTax * pointsKeepSDPerc, 100)
    pointsPerTeam[team]['helpers'] = pointsPerTeam[team]['helpersRem'] + hlpWoTax + div(hlpToTax * pointsKeepSDPerc, 100)
  end

  local effect = AddVisualGear(GetX(hog) - (cratePickupGap / 2), GetY(hog), vgtHealthTag, pointsPerTeam[team]['weapons'], false)
  -- (vgUid, X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint)
  SetVisualGearValues(effect, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0xFFFFFFFF)

  local effect = AddVisualGear(GetX(hog) + (cratePickupGap / 2), GetY(hog), vgtHealthTag, pointsPerTeam[team]['helpers'], false)
  -- (vgUid, X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint)
  SetVisualGearValues(effect, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0x444444FF)
end

function onPointsTurn()
  local hogWepPoints = 0
  local hogHlpPoints = 0

  if suddenDeath == false then
    pointsPerTeam[LastTeam]['weapons'] = pointsPerTeam[LastTeam]['weapons'] + pointsWepTurn
    pointsPerTeam[LastTeam]['helpers'] = pointsPerTeam[LastTeam]['helpers'] + pointsHlpTurn

    if pointsPerTeam[LastTeam]['weapons'] > pointsWepMax then
      pointsPerTeam[LastTeam]['weapons'] = pointsWepMax
    end

    if pointsPerTeam[LastTeam]['helpers'] > pointsHlpMax then
      pointsPerTeam[LastTeam]['helpers'] = pointsHlpMax
    end
  else
    pointsPerTeam[LastTeam]['weapons'] = pointsPerTeam[LastTeam]['weapons'] + pointsWepSDTurn
    pointsPerTeam[LastTeam]['helpers'] = pointsPerTeam[LastTeam]['helpers'] + pointsHlpSDTurn

    if pointsPerTeam[LastTeam]['weapons'] > pointsWepSDMax then
      pointsPerTeam[LastTeam]['weapons'] = pointsWepSDMax
    end

    if pointsPerTeam[LastTeam]['helpers'] > pointsHlpSDMax then
      pointsPerTeam[LastTeam]['helpers'] = pointsHlpSDMax
    end
  end

  -- Take the first alive hog from LastTeam and setup new weapons and helpers
  -- Since the weapons and helpers are shared the whole team, this is sufficent
  for idx, teamHog in pairs(teamHogs[LastTeam]) do
    if GetHealth(teamHog) ~= nil then
      clearHogAmmo(teamHog)
      addTurnAmmo(teamHog)
      break
    end
  end
end

function onNewTurn()
  LastHog = CurHog
  LastTeam = CurTeam
  CurHog = CurrentHedgehog
  CurTeam = getHogInfo(CurHog, 'team')
  TurnEnded = false

  if suddenDeath == true then
    onSuddenDeathTurn()
  else
    AddCaption(string.format(loc("Round %d (Sudden Death in round %d)"), (TotalRounds +1), (SuddenDeathTurns +2)), getHogInfo(CurHog, 'clanColor'),  capgrpGameState)
  end

  -- Generate new weapons for last hog if it's still alive
  if LastHog ~= nil and LastHog ~= CurHog then
    if mode == 'points' then
      onPointsTurn()
    else
      hogInfo[LastHog]['weapons'] = {}
      hogInfo[LastHog]['helpers'] = {}
      setupHogTurn(LastHog)
    end
  end

  -- Recalculate the kings hp if required
  if mode == 'king' then
    calcKingHP()
  end

  if mode == 'highland' then
    highHasBonusWeps = false
    highHasBonusHelp = false
  end

  -- Set LastWaterLine to the current water line
  LastWaterLine = WaterLine
end

function onGameTick20()
  if TurnEnded == false and TurnTimeLeft <= 0 then
    TurnEnded = true
    onTurnEnd()
  end
end

--[[
  ##############################################################################
  ### GAME START FUNCTIONS                                                   ###
  ##############################################################################
]]--

function onAmmoStoreInit()
  local lastNum = amAirMine

  for val=0,lastNum do
    SetAmmo(val, 0, 0, 0, 0)
  end
end

function onParameters()
  parseParams()

  if params['mode'] ~= nil then
    mode = params['mode']
  end

  if params['mutate'] ~= nil then
    mutate = params['mutate']
  end

  if params['strength'] ~= nil and tonumber(params['strength']) > 0 then
    strength = tonumber(params['strength'])
    -- Highland
    if mode == 'highland' then
      highPickupCount = highPickupCount * strength
      highPickupSDCount = highPickupSDCount * strength
      highHelperCount = highHelperCount * strength
      highHelperSDCount = highHelperSDCount * strength
    -- Points
    elseif mode == 'points' then
      pointsWepBase = pointsWepBase * strength
      pointsHlpBase = pointsHlpBase * strength
      pointsWepTurn = pointsWepTurn * strength
      pointsHlpTurn = pointsHlpTurn * strength
      pointsWepMax = pointsWepMax * strength
      pointsHlpMax = pointsHlpMax * strength
      pointsWepSDTurn = pointsWepSDTurn * strength
      pointsHlpSDTurn = pointsHlpSDTurn * strength
      pointsWepSDMax = pointsWepSDMax * strength
      pointsHlpSDMax = pointsHlpSDMax * strength
    -- Either king or normal mode, change variants
    else
      for name, data in pairs(variants) do
        variants[name]["weaponLimit"] = variants[name]["weaponLimit"] * strength
        variants[name]["helperLimit"] = variants[name]["helperLimit"] * strength
      end
    end
  end

  if params['luck'] ~= nil and tonumber(params['luck']) > 0 then
    luck = tonumber(params['luck'])

    healthCrateChance = div(healthCrateChance * luck, 100)
    utilCrateChance = div(utilCrateChance * luck, 100)
    weaponCrateChance = div(weaponCrateChance * luck, 100)

    healthCrateChanceSD = div(healthCrateChanceSD * luck, 100)
    utilCrateChanceSD = div(utilCrateChanceSD * luck, 100)
    weaponCrateChanceSD = div(weaponCrateChanceSD * luck, 100)

    emptyCrateChance = div(emptyCrateChance * 100, luck)
    bonusCrateChance = div(bonusCrateChance * luck, 100)
  end
end

function onGameStart()
  -- If we are not on points mode, we start randomizing everything
  if mode ~= 'points' then
    if GetGameFlag(gfBorder) or MapHasBorder() then
      variants["Air-General"] = nil
      variants['Athlete'] = nil
    end

    if mode == 'king' then
      variants['King']['chance'] = 0
    end

    for i=1,8 do
      addRandomVariantToTeam("all")
    end

    -- Translate randomized team to a flat group
    group['all'] = {}
    for key, val in pairs(counter["all"]) do
      for i=1, counter["all"][key] do
        table.insert(group['all'], key)
      end
    end

    -- Shuffle group for more randomness
    shuffle(group['all'])
  -- We are in points mode, setup other weapons
  elseif mode == 'points' then
    --variants['King']['chance'] = 0
    --if variants['Air-General'] ~= nil then
    --  variants['Air-General']['chance'] = 0
    --end

    -- Translate [ammo] -> points to [points] -> {ammo1, ammo2}
    for ammoType, ammoPoints in pairs(pointsWeaponVal) do
      if pointsToWep[ammoPoints] == nil then
        pointsToWep[ammoPoints] = {}
      end

      table.insert(pointsToWep[ammoPoints], ammoType)
    end

    for ammoType, ammoPoints in pairs(pointsHelperVal) do
      if pointsToHlp[ammoPoints] == nil then
        pointsToHlp[ammoPoints] = {}
      end

      table.insert(pointsToHlp[ammoPoints], ammoType)
    end

    for points, ammoList in pairs(pointsToWep) do
      table.insert(wepPoints, points)
    end

    for points, ammoList in pairs(pointsToHlp) do
      table.insert(hlpPoints, points)
    end

    table.sort(wepPoints)
    table.sort(hlpPoints)

    -- All done, sort the table
    --table.sort(pointsToWep)
    --table.sort(pointsToHlp)
  end

  -- Initial Hog Setup
  runOnGears(countTeamHogs)

  for key, val in pairs(teamNames) do
    if mode == 'points' then
      pointsPerTeam[key] = {}
      pointsPerTeam[key]['weapons'] = pointsWepBase
      pointsPerTeam[key]['helpers'] = pointsHlpBase
    else
      setTeamHogs(key)
    end
  end

  runOnGears(setHogInfo)
  
  if mode ~= 'points' then
    runOnGears(setHogVariant)
    runOnGears(setupHogTurn)
    if mutate ~= false and mutate ~= 'false' then
      runOnGears(MutateHog)
    end
  end

  if mode == 'points' then
    for key, val in pairs(teamNames) do
      clearHogAmmo(teamHogs[key][1])
      addTurnAmmo(teamHogs[key][1])
    end
  end

  if mode == 'king' then
    calcKingHP()
  end

  local txt = ''
  local icon = 0

  if mode ~= 'points' then
    txt = txt .. loc("Variants: Hogs will be randomized from 12 different variants") .. "|"
    txt = txt .. loc("Weapons: Hogs will get 1 out of 3 weapons randomly each turn") .. "|"
    txt = txt .. loc("Helpers: Hogs will get 1 out of 2 helpers randomly each turn") .. "|"
    txt = txt .. loc("Crates: Crates drop randomly with chance of being empty") .. "|"
    txt = txt .. loc("Last Resort: Having less than 25% base health gives kamikaze") .. "|"
    txt = txt .. loc("Modifiers: Unlimited ammo, per-hog ammo") .. "|"
  else
    txt = txt .. loc("Crates: Crates drop randomly and may be empty") .. "|"
    txt = txt .. loc("Modifiers: Unlimited ammo, shared clan ammo") .. "|"
  end

  if luck ~= 100 then
    txt = txt .. string.format(loc("Luck: %d%% (modifier for crates)"), luck) .. "|"
  end

  if strength > 1 then
    txt = txt .. string.format(loc("Strength: %d (multiplier for ammo)"), strength) .. "|"
  end

  if mode == 'highland' then
    txt = txt .. " |"
    txt = txt .. loc("--- Highland ---").."|"
    txt = txt .. string.format(loc("Enemy kills: Collect victim's weapons and +%d%% of its base health"), highEnemyKillHPBonus).."|"
    txt = txt .. string.format(loc("Friendly kills: Clear killer's pool and -%d%% of its base health"), highFriendlyKillHPBonus).."|"
    txt = txt .. string.format(loc("Turns: Hogs get %d random weapon(s) from their pool"), highPickupCount).."|"
    txt = txt .. loc("Hint: Kills won't transfer a hog's pool to the killer's pool").."|"
    txt = txt .. loc("Specials: Kings and air generals drop helpers, not weapons").."|"
    icon = 1 -- Target
  elseif mode == 'king' then
    txt = txt .. " |"
    txt = txt .. loc("--- King ---").."|"
    txt = txt .. loc("Variants: The last hog of each team will be a king").."|"
    txt = txt .. string.format(loc("Turns: King's health is set to %d%% of the team health"), kingLinkPerc).."|"
    icon = 0 -- Golen Crown
  elseif mode == 'points' then
    txt = txt .. " |"
    txt = txt .. loc("--- Points ---").."|"
    txt = txt .. loc("Variants: King and air general are disabled").."|"
    txt = txt .. string.format(loc("Weapons: Each team starts with %d weapon points"), pointsWepBase).."|"
    txt = txt .. string.format(loc("Helpers: Each team starts with %d helper points"), pointsHlpBase).."|"
    txt = txt .. string.format(loc("Turns: Refill %d weapon and %d helper points|and randomize weapons and helpers based on team points"), pointsWepTurn, pointsHlpTurn).."|"
    icon = 4 -- Golden Star
  else
    icon = -amGrenade -- Grenade
  end

  --txt = txt .. "Switch: Max. 3 times a game per team, cooldown of 5 turns|"
  txt = txt .. " |"
  txt = txt .. loc("--- Sudden Death ---").."|"
  txt = txt .. loc("Weapons: Nearly every hog variant gets 1 kamikaze").."|"
  txt = txt .. loc("Crates: Crates drop more often with a higher chance of bonus ammo").."|"
  txt = txt .. loc("Water: Rises by 37 per turn").."|"
  txt = txt .. loc("Health: Hogs lose up to 7% base health per turn").."|"

  if mode == 'default' then
    txt = txt .. " |"
    txt = txt .. loc("--- Hint ---").."|"
    txt = txt .. loc("Modes: Activate “highland”, “king” or “points” mode by putting mode=<name>|into the script parameter").."|"
  end

  if mode == 'highland' then
    txt = txt .. string.format(loc("Highland: Hogs get %d random weapons from their pool"), highPickupSDCount) .. "|"
  end

  ShowMission(loc("Battalion"), loc("Less tools, more fun"), txt, icon, 1000)

  -- Tell the user about the amount of rounds until sudden death
  AddCaption(string.format(loc("Rounds until Sudden Death: %d"), SuddenDeathTurns +2), 0xFFFFFFFF, capgrpGameState)
end

function onGameInit()
  --[[ CONFIGURATEABLE FOR PLAYERS ]]--
  --[[ ONCE IT HAS BEEN ADDED TO HW ]]--

  --[[ REQUIRED CONFIGURATIONS ]]--

  WaterRise = 37 -- Water rises by 37
  HealthDecrease = 0 -- No health decrease by game, script with 7%
  CaseFreq = 0 -- don't spawn crates

  -- Removed gfResetWeps to see weapons next turn
  EnableGameFlags(gfInfAttack)
  DisableGameFlags(gfResetWeps)

  if mode ~= 'points' then
    EnableGameFlags(gfPerHogAmmo)
  else
    DisableGameFlags(gfPerHogAmmo)
  end
end
