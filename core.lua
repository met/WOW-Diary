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

local cYellow = "\124cFFFFFF00";
local cRed = "\124cFFFF0000";
local cWhite = "\124cFFFFFFFF";
local cBlue =  "\124cFF0000FF";

local cBlue1 = "\124cFF6896FF";

local msgPrefix = cYellow.."[WoWDiary] "..cWhite;

SLASH_WOWDIARY1 = "/dia";
SLASH_WOWDIARY2 = "/wowdiary";
SlashCmdList["WOWDIARY"] = function(msg)
	-- /dia silent   --> switch on silent mode, write less msgs
	-- /dia nosilent --> switch off silent mode
	-- /dia cur --> show progress on current level
	-- /dia NUMBER --> show progress on level NUMBER

	-- for multiword 
	local msg1, msg2 = strsplit(" ", msg);

	if msg == "" then
		print(cYellow.."WoWDiary addon");
		print(cYellow.."Usage:");
		print("/dia cur");
		print("/dia silent");
		print("/dia nosilent");
		print("/dia LEVELNUMBER");
		print("/dia LEVELNUMBER kills");

	elseif msg == "silent" then
		WowDiarySettings["silent"] = true;
		print("WoWDiary silent on.");
	elseif msg == "nosilent" then
		WowDiarySettings["silent"] = false;
		print("WoWDiary silent off.");

	elseif msg == "current" or msg == "cur" then
		ShowLevelProgress(WowDiaryData, UnitLevel("player"));

	elseif tonumber(msg) ~=nil then
		ShowLevelProgress(WowDiaryData, tonumber(msg));

	elseif msg1 ~= nil and tonumber(msg1) ~= nil and msg2 ~= nil and msg2 ~= "" then
	 	--Filter by level and keyword, e.g "1 kills", "2 deaths"

	 	ShowFilterProgress(WowDiaryData, tonumber(msg1), msg2);
	end
end

local frame = CreateFrame("FRAME");

function frame:OnEvent(event, arg1, ...)

	if event == "ADDON_LOADED" and arg1 == "WoWDiary" then
		print(msgPrefix.."version "..GetAddOnMetadata("WowDiary", "version"));
		print(msgPrefix.."Use /dia for help");

		if WowDiarySettings == nil then
			WowDiarySettings = {};
			DefaultSettings(WowDiarySettings);
			print(msgPrefix.."Loaded for the first time. Setting defaults.");
		end

		if WowDiaryData == nil then
			WowDiaryData = {};
		end

		if WowDiarySharedDB == nill then
			WowDiarySharedDB = {};
		end

		if WowDiarySharedData == nill then
			WowDiarySharedData = {};
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
		local skill, skilllevel = string.match(arg1, "^Your skill in (.+) has increased to (%d+).");
		-- we must check it match succeded, there or other messages for this event as well
		-- e.g. You have gained the First Aid skill.
		if skill ~= nil and skilllevel ~= nil then
			WriteUpdatedSkills(WowDiaryData, UnitLevel("player"), skill, skilllevel);
		end

	elseif event == "CHAT_MSG_SYSTEM" then
		-- there is huge amount of different messages for this event, see https://www.townlong-yak.com/framexml/live/GlobalStrings.lua
		-- we look for ERR_LEARN_RECIPE_S = "You have learned how to create a new item: %s."
		local itemName = string.match(arg1, "^You have learned how to create a new item: (.+).");

		if itemName ~= nil then
			--print("Matched recipe item:", itemName);
			WriteLearnedRecipe(WowDiaryData, UnitLevel("player"), itemName);
		end

	elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then
		local mobName, gainedXP = string.match(arg1, "^(.+) dies, you gain (%d+) experience(.*)");
		local restedBonusXP = string.match(arg1, "%+(%d+) exp Rested bonus");

		--print("CHAT_MSG_COMBAT_XP_GAIN", arg1, ...);
		--print(mobName, gainedXP);
		--print("Rested bonus:", restedBonusXP);

		-- Check for succesfull match. Some other chat messages raises this event too.
		if mobName ~= nill and gainedXP ~= nill and tonumber(gainedXP) ~= nil then

			gainedXP = tonumber(gainedXP);
			local percentLevelXP = round(gainedXP / UnitXPMax("player") * 100);

			if restedBonusXP == nil or tonumber(restedBonusXP) == nil then
				restedBonusXP = 0;
			else
				restedBonusXP = tonumber(restedBonusXP);
			end

			if percentLevelXP > 2 then 
				print("Killed "..mobName..", gained "..gainedXP.." = "..cYellow..percentLevelXP.."% of current level.");
			else
				print("Killed "..mobName..", gained "..gainedXP.." = "..percentLevelXP.."% of current level.");
			end
			WriteKillsXP(WowDiaryData, UnitLevel("player"), mobName, gainedXP, restedBonusXP);
		end

	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		if UnitCanAttack("player", "mouseover") then
			local mobName, realmName = UnitName("mouseover");
			if mobName ~= nil then
				UpdateTooltip(WowDiaryData, GameTooltip, UnitLevel("player"), UnitXPMax("player"), mobName);
			end
		end
	end
end


local tasks = {}; -- our tasks queue

-- OnUpdate event is triggered cca every 25ms
-- we use this event for scheduling our tasks
function frame:OnUpdate()

	if tasks and tasks[1] then
		local curTask = tasks[1];

		-- Is it time to process our task now?
		if GetTime() >= curTask.time then
			table.remove(tasks, 1);

			--print(cRed.."=====================================");
			--print("frame:OnUpdate - making our task");
			--print(curTask.time, curTask.taskname);

			if curTask.taskname == "NEW_ZONE" then
				--print(GetZoneText(), "-", GetSubZoneText());
				-- and now finally we can write new visited zone
				WriteVisitedZone(WowDiaryData, UnitLevel("player"), GetZoneText(), GetSubZoneText());
			end

		end

		-- if there are not another tasks in queue, unregister handler
		if #tasks == 0 then
			frame:SetScript("OnUpdate", nil);
			--print(cRed.."UPDATE HANDLER UNREGISTERED");
		end
	end
end

function onMapEvent(event, arg1, ...)

	if GetRealZoneText() ~= GetZoneText() then
		print(cRed.."REAL zone name differs");
		print(GetZoneText(), "-", GetSubZoneText());
		print(GetRealZoneText());
	end

	-- do not track zones visited by player in taxi
	if UnitOnTaxi("player") then
		return;
	end

	if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
		WriteVisitedZone(WowDiaryData, UnitLevel("player"), GetZoneText(), GetSubZoneText());
	
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		-- this is more complicated. UI may not have correct GetZoneText, GetSubZoneText yet
		-- we register task that check for GetZoneText, GetSubZoneText very soon

		--print(cRed.."=====================================");
		--print(cYellow.."Map event", event, arg1, ...);
		--print(GetZoneText(), "-", GetSubZoneText());

		local delayInSeconds = 2;
		table.insert(tasks, {["time"] = (GetTime() + delayInSeconds), ["taskname"] = "NEW_ZONE"});
		frame:SetScript("OnUpdate", frame.OnUpdate);
		--print(cRed.."TASK REGISTERED");
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

	if diary[level] == nil then
		diary[level] = {};
	end

	if diary[level]["kills"] == nil then
		diary[level]["kills"] = {};
	end

	if diary[level]["kills"][name] == nil then
		diary[level]["kills"][name] = 0;
	end

	diary[level]["kills"][name] = diary[level]["kills"][name] + 1;

end

-- record gained XP for new Kill
function WriteKillsXP(diary, level, mobName, xp, restXP)

	if diary == nil or level == nil or type(level) ~= "number" or mobName == nil or xp == nil or type(xp) ~= "number" or restXP == nil or type(restXP) ~= "number" then
		print(msgPrefix.."ERROR: WriteKillsXP called with nil or wrong parameters.");
		return;
	end

	if diary[level] == nil then
		diary[level] = {};
	end

	if diary[level].killsXP == nill then
		diary[level].killsXP = {};
	end

	if diary[level].killsXP[mobName] == nill then
		diary[level].killsXP[mobName] = 0;
	end

	diary[level].killsXP[mobName] = diary[level].killsXP[mobName] + xp;

	--TODO we could handle rest XP too

end

function WriteFinishedQuest(diary, level, questID)
	if diary[level] == nil then
		diary[level] = {};
	end

	if diary[level]["quests"] == nil then
		diary[level]["quests"] = {};
	end

	table.insert(diary[level]["quests"], questID);
end

function WriteVisitedZone(diary, level, zoneName, subzoneName)

	if diary[level] == nil then
		diary[level] = {};
	end

	if diary[level]["zones"] == nil then
		diary[level]["zones"] = {};
	end

	-- write visited zone
	if diary[level]["zones"][zoneName] == nil then
		diary[level]["zones"][zoneName] = {};
	end

	-- if there is subzone name, write visites subzone
	if subzoneName ~= nil and subzoneName ~= "" and diary[level]["zones"][zoneName][subzoneName] == nil then
		diary[level]["zones"][zoneName][subzoneName] = 1;
	end
end

-- record reached skill level
function WriteUpdatedSkills(diary, level, skill, skilllevel)

	if diary[level] == nil then
		diary[level] = {};
	end

	if diary[level]["skills"] == nil then
		diary[level]["skills"] = {};
	end

	diary[level]["skills"][skill] = skilllevel;
end

-- record new learned recipe
function WriteLearnedRecipe(diary, level, itemName)
	assert(diary, "WriteLearnedRecipe - diary is nil");
	assert(level, "WriteLearnedRecipe - level is nil");
	assert(itemName, "WriteLearnedRecipe - itemName is nil");

	if diary[level] == nil then
		diary[level] = {};
	end

	if diary[level].recipes == nil then
		diary[level].recipes = {};
	end

	if diary[level].recipes[itemName] == nil then
		table.insert(diary[level].recipes, itemName);
	end
end

-- record new player death on current level
function WritePlayerDeath(diary, level)

	-- TODO if we look at last combat event that made damage to player we can find who killed him
	if diary[level] == nil then
		diary[level] = {};
	end

	if diary[level]["deaths"] == nil then
		diary[level]["deaths"] = {};
	end

	if diary[level]["deaths"]["count"] == nil then
		diary[level]["deaths"]["count"] = 0;
	end

	diary[level]["deaths"]["count"] = diary[level]["deaths"]["count"] + 1;
end

-- record Quest item do the Quest Database
function WriteQuestDBItem(diary, questID, questName, questLevel)

	if diary["DB"] == nil then
		diary["DB"] = {};
	end

	if diary["DB"]["quests"] == nil then
		diary["DB"]["quests"] = {};
	end

	-- if this questID is in DB already, do not need to write again
	if diary["DB"]["quests"][questID] == nil then
		diary["DB"]["quests"][questID] = {};
		diary["DB"]["quests"][questID]["name"] = questName;
		diary["DB"]["quests"][questID]["level"] = questLevel;
	end
end

-- Show in tooltip how many mobs killed on this level and how much XP gained
function UpdateTooltip(diary, tooltip, level, xpLevelMax, mobName)
	assert(diary, "UpdateTooltip - diary is nil");
	assert(tooltip, "UpdateTooltip - tooltip is nil");
	assert(level, "UpdateTooltip - level is nil");
	assert(xpLevelMax, "UpdateTooltip - xpLevelMax is nil");
	assert(mobName, "UpdateTooltip - mobName is nil");

	if diary[level] == nil or diary[level].kills == nil or diary[level].killsXP == nil then
		return;
	end

	-- TODO make custom settings to hide/show tooltip info

	if tonumber(diary[level].kills[mobName]) ~= nil then
		tooltip:AddLine(cYellow.."Killed on this level "..tostring(diary[level].kills[mobName]).." times.");
	end

	if tonumber(diary[level].killsXP[mobName]) ~= nil then
		local killsXP = tonumber(diary[level].killsXP[mobName]);
		local percentLevelXP = round(killsXP / xpLevelMax * 100);

--		tooltip:AddLine(cBlue1.."Gained XP on this level "..tostring(diary[level].killsXP[mobName]).." ("..percentLevelXP.."%).");
		tooltip:AddLine(cBlue1.."Gained XP on this level "..percentLevelXP.."%.");
	end

	tooltip:Show();
end

function ShowLevelProgress(diary, level)
	if diary == nil or level == nil then
		print(msgPrefix.."ERROR: Call ShowLevelProgress with nil parameters.");
		return;
	end

	if diary[level] == nil then
		print("No progress on level", level .. ".");
		return;
	end

	print(cYellow.."Player progress on level "..level..":");

	local numberKills = 0;

	if diary[level]["kills"] ~= nil then
		for k,v in pairs(diary[level]["kills"]) do
			numberKills = numberKills + v;
		end
	end
	print("Killed", numberKills, "creatures on level", level .. ".");

	local numberQuests = 0;

	if diary[level]["quests"] ~= nil then
		numberQuests = #diary[level]["quests"];
	end

	print("Finished", numberQuests, "quests on level", level .. ".");

	local numberDeaths = 0;

	if diary[level]["deaths"] ~= nil and diary[level]["deaths"]["count"] ~= nil then
		numberDeaths = diary[level]["deaths"]["count"];
	end

	print("Played died", numberDeaths, "times on level", level .. ".");

	if diary[level]["skills"] ~= nil then
		for k,v in pairs(diary[level]["skills"]) do
			print("Player reached level", v, "in", k, "on level", level .. ".");
		end

	end
end


function ShowFilterProgress(diary, level, filter)

	if diary == nil or level == nil or filter == nil or filter == "" then
		print(msgPrefix.."ERROR: Call ShowFilterProgress with nil parameters.");
		return;
	end

	if diary[level] == nil then
		print("No progress on level", level .. ".");
		return;
	end

	if filter == "kills" then

		if diary[level].kills == nil then
			print(cYellow.."Player killed nothing on level "..level..".");
		else
			print(cYellow.."Player killed these creatures on level "..level..":");

			for k,v in pairs(diary[level].kills) do
				print(k,v);
			end
		end

	elseif filter == "deaths" then

		if diary[level].deaths == nil or diary[level].deaths.count == nil then
			print(cYellow.."Player did not die on level "..level..".");
		else
			print(cYellow.."Player died "..diary[level].deaths.count.." times on level "..level..".");
		end

	elseif filter == "zones" then

		if diary[level].zones == nill then 
			print(cYellow.."Player visited no zones on level "..level..".");
		else
			print(cYellow.."Player visited these zones on level "..level..":");

			for k,v in pairs(diary[level].zones) do
				print(k);

				for k1,v1 in pairs(diary[level].zones[k]) do
					print("  - "..k1);
				end
			end
		end

	end

end

-- Round numbers, Usage:
-- round(5.6) => 6
-- round(5.678, 2) => 5.68
function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
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
frame:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN");
frame:RegisterEvent("PLAYER_XP_UPDATE");
frame:RegisterEvent("CHAT_MSG_SYSTEM");


frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT");

frame:SetScript("OnEvent", frame.OnEvent);
