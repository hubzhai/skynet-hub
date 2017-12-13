local skynet = require "skynet"
local statement ={}

local CStatement = {}
CStatement.__index = CStatement

function CStatement:New( o )
	local obj = o or {}
	obj.__index = obj
    setmetatable(obj,self)
    return obj
end

function CStatement:Init(sSql,skey)
	self.m_sql = sSql
	self.m_key = skey
end
function CStatement:Clean()
	self.parm ={}
	self.cur = 1
end
function CStatement:Add(val)
	--table.insert(self.parm,"'"..val.."'")
	self.parm[tostring(self.cur)] =val
	self.cur = self.cur +1
end
function CStatement:MakeSql( )
	return string.gsub(self.m_sql,"%$(%d+)",self.parm)
end
function CStatement:Run( )
	local sprm = ""
	local sql = self:MakeSql()
	--print(sql)
	if #sql>838860 then
		print("sql err  #sql>838860",sql)
		return
	end
	return skynet.call(".DB","lua","Query",sql)
	--return skynet.call(16777226,"lua","Query",sql)
end

function statement.New(sSql,skey)
	-- body
	local obj = CStatement:New()
	obj:Init(sSql,skey)
	return obj
end


return statement