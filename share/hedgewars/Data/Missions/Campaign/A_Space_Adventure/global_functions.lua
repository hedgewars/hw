local missionsNum = 14

function saveCompletedStatus(planetNum)
	--        1       2        3        4      5         6        7
	-- order: moon01, fruit01, fruit02, ice01, desert01, death01, final
	local status = "0000000"
	if tonumber(GetCampaignVar("MainMissionsStatus")) then
		status = GetCampaignVar("MainMissionsStatus")
	end

	local planetToLevelMapping = {
		[1] = 2,
		[2] = 3,
		[3] = 8,
		[4] = 5,
		[5] = 4,
		[6] = 9,
		[7] = 14
	}

	local level = planetToLevelMapping[planetNum]
	if level ~= nil then
		SaveCampaignVar("Mission"..level.."Won", "true")
	end

	if planetNum == 1 then
		status = "1"..status:sub(2)
	elseif planetNum == status:len() then
		status = status:sub(1,planetNum-1).."1"
	else
		status = status:sub(1,planetNum-1).."1"..status:sub(planetNum+1)
	end
	SaveCampaignVar("MainMissionsStatus",status)

	checkAllMissionsCompleted()
end

function checkAllMissionsCompleted()
	local allMissions = true
	for i=2, missionsNum do
		if GetCampaignVar("Mission"..i.."Won") ~= "true" then
			allMissions = false
			break
		end
	end
	if allMissions then
		SaveCampaignVar("Mission1Won", "true")
	end
end

function getCompletedStatus()
	local allStatus = ""
	if tonumber(GetCampaignVar("MainMissionsStatus")) then
		allStatus = GetCampaignVar("MainMissionsStatus")
	end
	local status = {
		moon01 = false,
		moon02 = false,
		fruit01 = false,
		fruit02 = false,
		fruit03 = false,
		ice01 = false,
		ice02 = false,
		desert01 = false,
		desert02 = false,
		desert03 = false,
		death01 = false,
		death02 = false,
		final = false
	}
	if allStatus ~= "" then
		if allStatus:sub(1,1) == "1" then
			status.moon01 = true
		end
		if allStatus:sub(2,2) == "1" then
			status.fruit01 = true
		end
		if allStatus:sub(3,3) == "1" then
			status.fruit02 = true
		end
		if allStatus:sub(4,4) == "1" then
			status.ice01 = true
		end
		if allStatus:sub(5,5) == "1" then
			status.desert01 = true
		end
		if allStatus:sub(6,6) == "1" then
			status.death01 = true
		end
		if allStatus:sub(7,7) == "1" then
			status.final = true
		end
	end
	-- Bonus missions
	if GetCampaignVar("Mission13Won") == "true" then
		status.moon02 = true
	end
	if GetCampaignVar("Mission6Won") == "true" then
		status.ice02 = true
	end
	if GetCampaignVar("Mission7Won") == "true" then
		status.desert02 = true
	end
	if GetCampaignVar("Mission10Won") == "true" then
		status.fruit03 = true
	end
	if GetCampaignVar("Mission11Won") == "true" then
		status.death02 = true
	end
	if GetCampaignVar("Mission12Won") == "true" then
		status.desert03 = true
	end
	return status
end

function initCheckpoint(mission)
	local checkPoint = 1
	if GetCampaignVar("CurrentMission") ~= mission then
		SaveCampaignVar("CurrentMission", mission)
		SaveCampaignVar("CurrentMissionCheckpoint", 1)
	else
		checkPoint = tonumber(GetCampaignVar("CurrentMissionCheckpoint"))
	end
	return checkPoint
end

-- Reset mission checkpoint to 1
-- Returns true if the player reached a checkpoint before, false otherwise.
function resetCheckpoint(mission)
	local cp = tonumber(GetCampaignVar("CurrentMissionCheckpoint"))
	SaveCampaignVar("CurrentMissionCheckpoint", 1)

	return (type(cp) == "number" and cp > 1)
end

function saveCheckpoint(cp)
	SaveCampaignVar("CurrentMissionCheckpoint", cp)
end

-- saves what bonuses are available
-- times is how many times the bonus will be available, this will be mission specific
function saveBonus(index, times)
	--        1         2        3
	-- order: desert03, fruit03, death02
	local bonus = "000"
	if tonumber(GetCampaignVar("SideMissionsBonuses")) then
		bonus = GetCampaignVar("SideMissionsBonuses")
	end
	if index == 1 then
		bonus = times..bonus:sub(2)
	elseif index == bonus:len() then
		bonus = bonus:sub(1,index-1)..times
	else
		bonus = bonus:sub(1,index-1)..times..bonus:sub(index+1)
	end
	SaveCampaignVar("SideMissionsBonuses",bonus)
end

function getBonus(index)
	local bonus = 0
	if tonumber(GetCampaignVar("SideMissionsBonuses")) then
		bonusString = GetCampaignVar("SideMissionsBonuses")
		bonus = bonusString:sub(index,index)
	end
	return bonus
end

-- splits number by delimiter
function split(s, delimiter)
	local res = {}
	local first = ""
	for i=1,s:len() do
		if s:sub(1,1) == delimiter then
			table.insert(res, tonumber(first))
			first = ""
		else
			first = first..s:sub(1,1)
		end
		s = s:sub(2)
	end
	if first:len() > 0 then
		table.insert(res, tonumber(first))
	end
	return res
end
