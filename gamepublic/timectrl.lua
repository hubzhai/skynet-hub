local skynet = require "skynet"
local pubdefines = require "pubdefines"

local funclist = {}

local  DayNo = pubdefines.GetDayNo()
local function GetNextRefrshSec( )
	local tab = os.date("*t",GetSecond())
	local iSec = tab.sec
	local iMin = tab.min
	local iNextSec = 60*60-(iMin*60+iSec)
	iNextSec = math.max(0,iNextSec)
	iNextSec = math.min(3600,iNextSec)
	return iNextSec
end
local function NewHour(NewHourCB,NewDayCB )
	local iNextSec = GetNextRefrshSec()
	local func = function() NewHour(NewHourCB,NewDayCB ) end
	Call_Out(func,iNextSec,"TimeCtrl")
	local iDay,iHour = ChinaDate()
	if NewHourCB then
		NewHourCB(iDay,iHour)
	end
	if NewDayCB and DayNo ~= pubdefines.GetDayNo() then
		DayNo = pubdefines.GetDayNo()
		NewDayCB(iDay)
	end
end
function funclist.Init(NewHourCB,NewDayCB )
	local iNextSec = GetNextRefrshSec()
	local func = function() NewHour(NewHourCB,NewDayCB ) end
	Call_Out(func,iNextSec,"TimeCtrl" )
end

return funclist