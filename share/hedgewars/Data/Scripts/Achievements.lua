HedgewarsScriptLoad("/Scripts/Locale.lua")

function awardAchievement(name, statMessage, capgrp)
	local achievementString = string.format(loc("Achievement gotten: %s"), name)
	if capgrp == nil then
		capgrp = capgrpMessage2
	end
	if capgrp ~= false then
		AddCaption(achievementString, 0xFFBA00FF, capgrp)
	end
	if not statMessage then
		statMessage = achievementString
	end
	SendStat(siCustomAchievement, statMessage)
end
