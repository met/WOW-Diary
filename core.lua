--[[
MIT License

Copyright (c) 2019 Martin Hassman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

SLASH_WOWDIARY1 = "/dia";
SLASH_WOWDIARY2 = "/wowdiary";
-- usage /altitem NECK # display neck item for all known alts
SlashCmdList["WOWDIARY"] = function(msg)

	--TODO make nice display from diary data here, maybe filltered by level 

	if msg == "silent" then
		WowDiarySettings["silent"] = true;
		print("WoWDiary silent on.");
	elseif msg == "nosilent" then
		WowDiarySettings["silent"] = false;
		print("WoWDiary silent off.");
	else
		-- 
	end
end

local frame = CreateFrame("FRAME");

function frame:OnEvent(event, arg1, ...)

	if event == "ADDON_LOADED" and arg1 == "WoWDiary" then
		if WowDiarySettings == nill then
			WowDiarySettings = {};
			DefaultSettings(WowDiarySettings);
		end

		if WowDiaryData == nill and arg1 == "WoWDiary" then
			WowDiaryData = {};
		end

	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		OnCombatEvent();

	elseif event == "CHAT_MSG_MONEY" then
		--print("PENIZE");
		--print(event, arg1, ...);

	elseif event == "PLAYER_MONEY" then
		--print(event, arg1, ...);
		--print("Money=", GetMoney());

	elseif event == "QUEST_ACCEPTED" then
		-- here we can same quest title (because later is difficult to find it)
		-- print("QUEST_ACCEPTED", arg1, ...);
		-- print(GetQuestLogTitle(arg1));

		local questName, questLevel, _, _, _, _, _, questID = GetQuestLogTitle(arg1);
		WriteQuestDBItem(WowDiaryData, questID, questName, questLevel);

	elseif event == "QUEST_TURNED_IN" then
		WriteFinishedQuest(WowDiaryData, UnitLevel("player"), arg1);

	elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
		-- ZONE_CHANGED_INDOORS sometimes happen when I entered into some building, but sometimes only ZONE_CHANGED happens
		-- ZONE_CHANGED_NEW_AREA I did not debug yet

		-- TODO should I write zones if I am flying? Probably not, it is not real visiting

		onMapEvent(event, arg1, ...);
	end

end

function onMapEvent(event, arg1, ...)
	print("Map event", event, arg1, ...);
	print(GetZoneText(), "-", GetSubZoneText());

	if GetRealZoneText() ~= GetZoneText() then
		print("REAL zone name differs");
		print(GetRealZoneText());
	end

	if event == "ZONE_CHANGED" then
		WriteVisitedZone(WowDiaryData, UnitLevel("player"), GetZoneText(), GetSubZoneText());
	end
end

function OnCombatEvent()
	local timestamp, combatEvent, hideCaster, srcGUID, srcName, srcFlags, sourceRaidFlags, dstGUID, dstName, dstFlags, destRaidFlags, arg12, arg13, arg14 = CombatLogGetCurrentEventInfo();
	-- Those arguments appear for all combat event variants.
	-- print(CombatLogGetCurrentEventInfo());
	if srcGUID == UnitGUID("player") then	
		print("My", combatEvent);
	else
		if WowDiarySettings["silent"] == false then
			print("??", combatEvent);
		end
	end

	if combatEvent == "PARTY_KILL" and srcGUID == UnitGUID("player") then
		-- player made another kill
		WriteNewKill(WowDiaryData, UnitLevel("player"), dstName);

	elseif combatEvent == "SPELL_CAST_SUCCESS" and srcGUID == UnitGUID("player") and arg13 == "Pick Pocket" then
		-- player cast pick pocketing, but we do not know how much money he earned
		--print("Kradu");
		--print(CombatLogGetCurrentEventInfo());
		-- TODO if I want record what player pickpocketed, then I need to listen more events with money
		-- TODO and check that they follow this pickpocketing event
		-- TODO all 3 step process is neccesary to distinguish pickpocketing from corpse or chest looting
	elseif combatEvent == "SPELL_DAMAGE" and srcGUID == UnitGUID("player") then
		print(CombatLogGetCurrentEventInfo());
	end	
end


-- record another kill made by player at current level
function WriteNewKill(setts, level, name)

	if setts[level] == nill then
		setts[level] = {};
	end

	if setts[level]["kills"] == nill then
		setts[level]["kills"] = {};
	end

	if setts[level]["kills"][name] == nill then
		setts[level]["kills"][name] = 0;
	end

	setts[level]["kills"][name] = setts[level]["kills"][name] + 1;

end

function WriteFinishedQuest(diary, level, questID)
	if diary[level] == nill then
		diary[level] = {};
	end

	if diary[level]["quests"] == nill then
		diary[level]["quests"] = {};
	end

	table.insert(diary[level]["quests"], questID);
end

function WriteVisitedZone(diary, level, zoneName, subzoneName)

	if diary[level] == nill then
		diary[level] = {};
	end

	if diary[level]["zones"] == nill then
		diary[level]["zones"] = {};
	end

	-- write visited zone
	if diary[level]["zones"][zoneName] == nill then
		diary[level]["zones"][zoneName] = {};
	end

	-- if there is subzone name, write visites subzone
	if subzoneName ~= nill and subzoneName ~= "" and diary[level]["zones"][zoneName][subzoneName] == nill then
		diary[level]["zones"][zoneName][subzoneName] = 1;
	end
end

-- record Quest item do the Quest Database
function WriteQuestDBItem(diary, questID, questName, questLevel)

	if diary["DB"] == nill then
		diary["DB"] = {};
	end

	if diary["DB"]["quests"] == nill then
		diary["DB"]["quests"] = {};
	end

	-- if this questID is in DB already, do not need to write again
	if diary["DB"]["quests"][questID] == nill then
		diary["DB"]["quests"][questID] = {};
		diary["DB"]["quests"][questID]["name"] = questName;
		diary["DB"]["quests"][questID]["level"] = questLevel;
	end
end

-- initial settings, set after instalation or reset
function DefaultSettings(setts)
	setts["silent"] = false;	-- in silent mode we write less info to console
end

frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");

frame:RegisterEvent("CHAT_MSG_MONEY");
frame:RegisterEvent("PLAYER_MONEY");

frame:RegisterEvent("QUEST_ACCEPTED");
frame:RegisterEvent("QUEST_TURNED_IN");

frame:RegisterEvent("ZONE_CHANGED");
frame:RegisterEvent("ZONE_CHANGED_INDOORS");
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA");


frame:SetScript("OnEvent", frame.OnEvent);
