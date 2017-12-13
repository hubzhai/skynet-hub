local skynet = require "skynet"
local sql = require "sql"
local pubdefines= require "pubdefines"
local CGMblk ={}
CGMblk.__index = CGMblk
function CGMblk:New(o)
	-- body
	local obj = o or {}
	obj.__index = obj
    setmetatable(obj,self)
    return obj
end

function CGMblk:Init()
	print("======= CGMblk:Init ========")
end


function CGMblk:SaveData( )
	for k,v in pairs(self.m_temp) do
		self:Save(k)
	end
	self.m_temp ={}

	for k,v in pairs(self.m_mailtemp) do
		self:SaveOther(k)
	end
	self.m_mailtemp ={}
	--self:SaveData()
	Call_Out(function() self:SaveData() end,5*60,"CGMblk")
end


function CGMblk:NewDay( ... )


end
function CGMblk:NewHour( ... )


end

function CGMblk:RemoveTable( tab,id )
	for k,v in pairs(tab) do
		if v.id == id then
			table.remove( tab, k )
			return
		end
	end
end

function New()
	local c = CGMblk:New()
	c:Init()
	return c
end

GMObj =GMObj or nil

function GetObj( )
	if not GMObj then
		GMObj = New()
	end
	return GMObj
end