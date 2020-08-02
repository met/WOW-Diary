--[[
Copyright (c) 2020 Martin Hassman

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

local addonName, NS = ...;

-- Call Errlogger addon if installed to log errors

local cYellow = "\124cFFFFFF00";
local cWhite = "\124cFFFFFFFF";
local cRed = "\124cFFFF0000";
local cLightBlue = "\124cFFadd8e6";
local cGreen1 = "\124cFF38FFBE";



function NS.logError(...)
	if logError ~= nil then 		-- detect Errlogger addon
		logError(addonName, ...); 	-- call Errlogger if present
	else							-- or just print message to the output
		print(cRed, addonName, "[ERROR]", ...);
	end
end

function NS.logWarning(...)
	if logWarning ~= nil then
		logWarning(addonName, ...);
	else
		print(cRed, addonName, "[WARNING]", ...);
	end	
end

function NS.logInfo(...)
	if NS.settings.debug then
		if logInfo ~= nil then
			logInfo(addonName, ...);
		else
			print(cLightBlue, addonName, "[INFO]", ...);
		end
	end		
end

function NS.logDebug(...)
	if NS.settings.debug then
		if logDebug ~= nil then
			logDebug(addonName, ...);
		else
			print(cLightBlue, addonName, "[DEBUG]", ...);
		end
	end		
end
