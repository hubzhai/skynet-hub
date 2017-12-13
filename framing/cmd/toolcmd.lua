local skynet = require "skynet"
--local sql = require "sql"
local pubdefines = require "pubdefines"
local toolblk = require "blk/toolblk"
 command = {}
function command.start()
	toolblk.GetObj()
end


------------------------------------------------------------------------


function NewHour(iDay,iHour)
	local obj = toolblk.GetObj()
	if not obj then
		return 
	end
	obj:NewHour(iDay,iHour)
end
function NewDay(iDay )
	local obj = toolblk.GetObj()
	if not obj then
		return 
	end
	obj:NewDay(iDay)
end

function command.ServiceExit( )
	local obj = gmblk.GetObj()
	if not obj then
		return 
	end
	 obj:SaveData()
	return true
 end 