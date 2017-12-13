local skynet = require "skynet"
--local sql = require "sql"
local pubdefines= require "pubdefines"
local CToolblk ={}
CToolblk.__index = CToolblk
function CToolblk:New(o)
	-- body
	local obj = o or {}
	obj.__index = obj
    setmetatable(obj,self)
    return obj
end
-----------------------------------------------------------------------------------初始化
function CToolblk:Init()
	print("========== CToolblk:Init() ============")

end

-----------------------------------------------------------------------------------------------------
function New()
	local c = CToolblk:New()
	c:Init()
	return c
end

function CToolblk:NewDay(iDay)
	self:updataDatas()
	--print("========CToolblk==NewDay=========")
	self:Init()
end

function CToolblk:NewHour(iDay,iHour)
	--self:updataDatas()
	--print("========CToolblk==NewHour=========")
	--self:Init()
end

GMObj =GMObj or nil

function GetObj( )
	if not GMObj then
		GMObj = New()
	end
	return GMObj
end