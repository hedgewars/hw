function saveCompletedStatus(planetNum)
	--        1       2        3        4      5         6
	-- order: moon01, fruit01, fruit02, ice01, desert01, death01
	local status = "000000"
	if tonumber(GetCampaignVar("MainMissionsStatus")) then
		status = GetCampaignVar("MainMissionsStatus")
	end
	if i == 1 then
		status = "1"..status:sub(planetNum+1)
	elseif i == status:len() then
		status = status:sub(1,planetNum-1).."1"
	else
		status = status:sub(1,planetNum-1).."1"..status:sub(planetNum+1)
	end
	SaveCampaignVar("MainMissionsStatus",status)
end

function getCompletedStatus()
	local allStatus = ""
	if tonumber(GetCampaignVar("MainMissionsStatus")) then
		allStatus = GetCampaignVar("MainMissionsStatus")
	end
	local status = {
		moon01 = false,
		fruit01 = false,
		fruit02 = false,
		ice01 = false,
		desert01 = false,
		death01 = false
	}
	if allStatus ~= "" then
		if allStatus:sub(1,1) == "1" then
			status.moon01 = true
		end
		if allStatus:sub(2,2) == "1" then
			status.fuit01 = true
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
	end
	return status
end
