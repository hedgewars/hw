HedgewarsScriptLoad("/Scripts/Locale.lua")

function awardAchievement(name, statMessage, capgrp)
	local achievementString = string.format(loc("Achievement gotten: %s"), name)
	if capgrp == nil then
		captionType = capgrpMessage2
	end
	if capgrp ~= false then
		AddCaption(achievementString, 0xFFBA00FF, capgrpMessage2)
	end
	if not statMessage then
		statMessage = achievementString
	end
	SendStat(siCustomAchievement, statMessage)
end
