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
	-- /dia silent   --> switch on silent mode, write less msgs
	-- /dia nosilent --> switch off silent mode
	-- /dia cur --> show progress on current level

	if msg == "silent" then
		WowDiarySettings["silent"] = true;
		print("WoWDiary silent on.");
	elseif msg == "nosilent" then
		WowDiarySettings["silent"] = false;
		print("WoWDiary silent off.");

	elseif msg == "current" or msg == "cur" then
		ShowLevelProgress(WowDiaryData, UnitLevel("player"));
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
		OnCombatEvent(event, arg1, ...);

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

	elseif event == "PLAYER_DEAD" then
		--print(event, arg1, ...);
		WritePlayerDeath(WowDiaryData, UnitLevel("player"));

	elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or event == "ZONE_CHANGED_NEW_AREA" then
		onMapEvent(event, arg1, ...);

	elseif event == "CHAT_MSG_SKILL" then
		-- Msg like:
		-- Your skill in Fishing has increased to 131.
		local skill, skilllevel = string.match(arg1, "Your skill in (.+) has increased to (%d+).");
		WriteUpdatedSkills(WowDiaryData, UnitLevel("player"), skill, skilllevel);
	end

end

function onMapEvent(event, arg1, ...)

	-- ZONE_CHANGED_INDOORS sometimes happen when I entered into some building, but sometimes only ZONE_CHANGED happens
	-- ZONE_CHANGED_NEW_AREA I did not debug yet, happens when player enter game or change main zone

	-- TODO should I write zones if I am flying? Probably not, it is not real visiting

	if event ~= "ZONE_CHANGED" then
		print("=====================================");
		print("=====================================");
		print("=====================================");
		print("=====================================");
		print("=====================================");
		print("=====================================");
		print("=====================================");
		print("Map event", event, arg1, ...);
		print(GetZoneText(), "-", GetSubZoneText());
	end

	if GetRealZoneText() ~= GetZoneText() then
		print("REAL zone name differs");
		print(GetZoneText(), "-", GetSubZoneText());
		print(GetRealZoneText());
	end

	if event == "ZONE_CHANGED" then
		WriteVisitedZone(WowDiaryData, UnitLevel("player"), GetZoneText(), GetSubZoneText());
	end
end

function OnCombatEvent()
	local timestamp, combatEvent, hideCaster, srcGUID, srcName, srcFlags, sourceRaidFlags, dstGUID, dstName, dstFlags, destRaidFlags, arg12, arg13 = CombatLogGetCurrentEventInfo();
	-- Those arguments appear for all combat event variants.
	-- print(CombatLogGetCurrentEventInfo());
	if WowDiarySettings["silent"] == false then
		if srcGUID == UnitGUID("player") then
			print("My", combatEvent);
		else
			print("??", combatEvent);
		end
	end

	if srcGUID == UnitGUID("player") then

		if combatEvent == "PARTY_KILL" then
			-- player made another kill
			WriteNewKill(WowDiaryData, UnitLevel("player"), dstName);

		elseif combatEvent == "SWING_DAMAGE" then
			local swingDamage, overkill = select(12, CombatLogGetCurrentEventInfo());
			print("Doing SWING_DAMAGE", swingDamage);
			--print(CombatLogGetCurrentEventInfo());

		elseif combatEvent == "RANGE_DAMAGE" then
			local rangeName, _, rangeDamage, overkill = select(13, CombatLogGetCurrentEventInfo());
			print("Doing RANGE_DAMAGE", rangeName, rangeDamage);
			--print(CombatLogGetCurrentEventInfo());

		elseif combatEvent == "SPELL_DAMAGE" then
			local spellName, _, spellDamage, overkill = select(13, CombatLogGetCurrentEventInfo());
			print("Doing SPELL_DAMAGE", spellName, spellDamage);
			--print(CombatLogGetCurrentEventInfo());

		elseif combatEvent == "SPELL_CAST_SUCCESS" and arg13 == "Pick Pocket" then
			-- player cast pick pocketing, but we do not know how much money he earned
			--print("Kradu");
			--print(CombatLogGetCurrentEventInfo());
			-- TODO if I want record what player pickpocketed, then I need to listen more events with money
			-- TODO and check that they follow this pickpocketing event
			-- TODO all 3 step process is neccesary to distinguish pickpocketing from corpse or chest looting

		end	

	end

	if dstGUID == UnitGUID("player") then
		if combatEvent == "SWING_DAMAGE" then

		elseif combatEvent == "RANGE_DAMAGE" then

		elseif combatEvent == "SPELL_DAMAGE" then

		end
	end


end


-- record another kill made by player at current level
function WriteNewKill(diary, level, name)

	if diary[level] == nill then
		diary[level] = {};
	end

	if diary[level]["kills"] == nill then
		diary[level]["kills"] = {};
	end

	if diary[level]["kills"][name] == nill then
		diary[level]["kills"][name] = 0;
	end

	diary[level]["kills"][name] = diary[level]["kills"][name] + 1;

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

-- record reached skill level
function WriteUpdatedSkills(diary, level, skill, skilllevel)

	if diary[level] == nill then
		diary[level] = {};
	end

	if diary[level]["skills"] == nill then
		diary[level]["skills"] = {};
	end

	diary[level]["skills"][skill] = skilllevel;
end

-- record new player death on current level
function WritePlayerDeath(diary, level)

	-- TODO if we look at last combat event that made damage to player we can find who killed him
	if diary[level] == nill then
		diary[level] = {};
	end

	if diary[level]["deaths"] == nill then
		diary[level]["deaths"] = {};
	end

	if diary[level]["deaths"]["count"] == nill then
		diary[level]["deaths"]["count"] = 0;
	end

	diary[level]["deaths"]["count"] = diary[level]["deaths"]["count"] + 1;
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

function ShowLevelProgress(diary, level)
	if diary[level] == nill then
		print("No progress on level", level);
		return;
	end

	local numberKills = 0;

	if diary[level]["kills"] ~= nill then
		for k,v in pairs(diary[level]["kills"]) do
			numberKills = numberKills + v;
		end
	end
	print("Killed", numberKills, "creatures on level", level);

	local numberQuests = 0;

	if diary[level]["quests"] ~= nill then
		numberQuests = #diary[level]["quests"];
	end

	print("Finished", numberQuests, "quests on level", level);

	local numberDeaths = 0;

	if diary[level]["deaths"] ~= nill and diary[level]["deaths"]["count"] ~= nill then
		numberDeaths = diary[level]["deaths"]["count"];
	end

	print("Played died", numberDeaths, "times on level", level);

	if diary[level]["skills"] ~= nill then
		for k,v in pairs(diary[level]["skills"]) do
			print("Player reached level", v, "in", k, "on level", level);
		end

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

frame:RegisterEvent("PLAYER_DEAD");

frame:RegisterEvent("CHAT_MSG_SKILL");

frame:SetScript("OnEvent", frame.OnEvent);
