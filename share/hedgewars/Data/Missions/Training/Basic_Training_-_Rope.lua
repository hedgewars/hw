--Created by Patrick Nielsen
--It's been so fun to create this, your welcome to contact me at Trivkz@gmail.com
--
--I've tried to keep the code as clear as possible and with comments.
--But as English is not my first language there may be spelling / grammar mistakes.
--
--I know there need to be more "tutorial" specefic messages, but I had a hard timer figuring out what to type / what would be the best technical description.


HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua") -- For the gearIsInBox function, wrote my own, but decided it was a waste to include it

local Player = nil -- Pointer to hog created in: onGameInit
local Target = nil -- Pointer to target hog
local GameLost = false -- You lost the game
local Objective = false -- Get to the target
local RopeMaster = false -- Achievement
local StatsSent = false -- Remember whether the stats have been sent already

local WaitTime = 1000 -- Wait 1sec before quit
local FollowTime = 1500 -- For use with FollowGear
local FollowingGear = false
local BaseballIntro = false -- Fail safe for ticker
local TargetNumber = 0 -- The current target number

local TargetPos = {} -- Tabel of targets
local Timers = {}
local GetTime = 0

TargetPos[ 1 ] = { X = 1100, Y = 1100, Message = loc("Now find the next target! |Tip: Normally you lose health by falling down, so be careful!") }
TargetPos[ 2 ] = { X = 1500, Y = 1490, Message = loc("You're getting pretty good! |Tip: When you shorten you rope, you move faster!|And when you lengthen it, you move slower.") }
TargetPos[ 3 ] = { X = 2200, Y = 800, Message = loc("The next one is pretty hard! |Tip: You have to do multiple swings!") }
TargetPos[ 4 ] = { X = 2870, Y = 400, Message = loc("I don't know how you did that. But good work!|The next one should be easy as cake for you!") }
TargetPos[ 5 ] = { X = 4000, Y = 1750, Message = "" }
TargetPos[ 6 ] = { Modifier = true, Func = function() -- Last target is ALWAYS the "winning" target!
	Info( loc("Congratulations"), loc("Congratulations! You've completed the Basic Rope Training!"), 0 ) -- Congrats
	PlaySound( sndVictory, Player )

	AddCaption( loc( "Victory!" ), 0xFFFFFFFF, capgrpGameState)
	if TurnTimeLeft >= 250000 then -- If you very fast, unlock the ahievement "Rope Master!"
		RopeMaster = true
		AddCaption( string.format(loc("Achievement gotten: %s"), loc("Rope Master") ), 0xffba00ff, capgrpMessage2)
		PlaySound( sndHomerun )
	end
	Objective = true
end }

function Info( Title, Text, Icon ) -- I made a small wrapper to ease the process
	ShowMission( loc("Rope Training"), Title, Text, Icon, 0 )
end

function NewFollowGear( Gear )
	FollowingGear = true
	FollowGear( Gear )
end

function SpawnTarget( PosX, PosY )
	Target = AddGear( 0, 0, gtTarget, 0, 0, 0, 0 ) -- Create a new target
	SetGearPosition( Target, PosX, PosY ) -- Set the position of the target
	NewFollowGear( Target )
end

function AutoSpawn() -- Auto spawn the next target after you've killed the current target!
	TargetNumber = TargetNumber + 1

	if TargetPos[ TargetNumber ].Modifier then -- If there is a modifier, run the function, only used in the winning target!
		TargetPos[ TargetNumber ].Func()
		return true
	end

	if TargetNumber > 1 then
		Info(loc("Training"), TargetPos[ TargetNumber - 1 ].Message, -amRope )
	end

	SpawnTarget( TargetPos[ TargetNumber ].X, TargetPos[ TargetNumber ].Y ) -- Spawn target on the next position
end

function InRange( Gear, PosX, PosY, Distance ) -- Fix as the default function didn't do quite what I needed
	GearX, GearY = GetGearPosition( Gear )

    return GearX >= PosX - Distance and GearX <= PosX + Distance and GearY >= PosY and GearY - Distance <= PosY + Distance
end

function CheckPosition( Hog, Distance ) -- Show a message when you get close to the current target!
	if (not BaseballIntro and not Objective) and (CurrentHedgehog ~= nil) then --Fail safe check
		if InRange( Hog, 1100, 1100, Distance ) then -- Check if the player is within predefined position of the first target
			BaseballIntro = true
			Info(loc("Training"), loc("Great work! Now hit it with your Baseball Bat! |Tip: You can change weapon with 'Right Click'!"), -amRope ) -- Guide them
			Timer( 10000, loc("Remember: The rope only bend around objects, |if it doesn't hit anything it's always stright!"))
		end
	end
end

function Timer( Delay, Message )
	local Timer = {}
	Timer.End = GetTime + Delay
	Timer.Message = Message

	table.insert( Timers, Timer )
end

function onGameInit() -- Called when the game loads
	Seed = 1 -- The base number for the random number generator
	GameFlags = gfInfAttack + gfOneClanMode + gfSolidLand + gfInvulnerable + gfBorder -- Game settings and rules, going with a border to make it easier
	TurnTime = 300000 -- Player can move for 5min each round
	CaseFreq = 0 -- No random crate drops
	MinesNum = 0 -- Never place any mines on the map
	Explosives = 0 -- Never place any explosives
	Delay = 1 -- We don't wont to wait between each round ( as the only is one )
	Map = "Ropes" -- Map name
	Theme = "Nature" -- Map theme
	-- Disable Sudden Death
	SuddenDeathTurns = 50
	WaterRise = 0
	HealthDecrease = 0

	AddTeam( loc( "Rope Team" ), 14483456, "Simple", "Island", "Default", "cm_shoppa" ) -- Lets make the team
	Player = AddHog( loc( "Hunter" ), 0, 1, "StrawHat" ) -- Add a hog for it, and name it "Hunter"
	SetGearPosition( Player, 420, 1750 ) -- Set player position

	SetEffect( Player, heResurrectable, 1 ) -- By Suggestion :)
end

function onGameStart() -- Called when the game starts
	SendHealthStatsOff()
	AutoSpawn() -- Spawn our 1st target using the wrapper function

	SetHealth( Player, 100 ) -- Give the player 100 Health points

	PlaceGirder(46,1783, 0) -- Place a girder to prevent the player falling into the water

	local message = loc("Get to the target using your rope!") .. "|" .. loc("Controls: Hold the Attack key (space by default) to|fire the rope, then, once attached use:|Left and Right to swing the rope;|Up and Down to contract and expand.")
	Info(loc("Training"), message, -amRope ) -- Short intro to tell the player what to do
	Timer( 10000, message .. "|" .. loc("Tip: The rope physics are different than in the real world, |use it to your advantage!") ) -- After 15 sec, give them more help
end

function onNewTurn()
	SetWeapon(amRope) -- Set the default weapon to Rope
end

function onGameTick20()
	if TurnTimeLeft < 40 and TurnTimeLeft > 0 then -- Round starts at 0, so we check if the round is finished by using 1
		GameLost = true -- You lost the game
		Info(loc("Training"), loc("You did not make it in time, try again!"), -amSkip )
		if not StatsSent then
			SendStat(siGameResult, loc("You failed!"))
			SendStat(siCustomAchievement, loc("You did not make it in time, try again!"))
			StatsSent = true
		end
		SetHealth( Player, 0 ) -- Kill the player so he can't keep moving!

		SetEffect( Player, heResurrectable, 0 )

	end

	-- If the player gets to the last target, they win OR
	-- If round is finished and your not at the target you lose
	-- in either case, end the game
	if (Objective == true) or (GameLost == true) then
		if (WaitTime == 0 and not StatsSent) then
			SendStat(siGameResult, loc("You have finished the Basic Rope Training!"))
			SendStat(siCustomAchievement, loc("Good job!"))
			SendStat(siPlayerKills, "0", loc("Rope Team"))
			if RopeMaster then
				SendStat(siCustomAchievement, loc("You earned the \"Rope Master\" achievement for finishing in under 50 seconds."))
			end
			StatsSent = true
			EndGame()
		else
			WaitTime = WaitTime - 20
		end
	end

	if FollowingGear == true then
		if FollowTime == 0 then
			FollowingGear = false
			FollowTime = 1500
			FollowGear( Player )
		else
			FollowTime = FollowTime - 20
		end
	end

	for k, v in pairs( Timers ) do
		if v.End <= GetTime then
			Info(loc("Training"), v.Message, -amRope )
			Timers[ k ] = nil
		end
	end

	GetTime = GetTime + 20

	CheckPosition( Player, 70 ) -- Run the CheckPosition function to check if the player is close to a target
end

function onAmmoStoreInit()
	SetAmmo( amRope, 9, 2, 0, 0 ) -- Player ammo, Rope
	SetAmmo( amBaseballBat, 9, 2, 0, 0 ) --Baseball bat
end

function onGearDelete( Gear )
	if GetGearType( Gear ) == gtTarget then
		AutoSpawn() -- When a target is deleted / destroyed, spawn a new one!
	end
end
