local skynet = require "skynet"
local cjson = require "cjson"
local serverconfig = require "serverconfig"
servicename = servicename or "noname"

local funclist ={}

function GetServerNum( )
	return serverconfig.serverid
end
-------------------------------------------字符串分割函数---------------------------
-------------------------------------------------------
-- 参数:待分割的字符串,分割字符
-- 返回:子串表.(含有空串)
function lua_string_split(str, split_char)
    local sub_str_tab = {};
    while (true) do
        local pos = string.find(str, split_char);
        if (not pos) then
            sub_str_tab[#sub_str_tab + 1] = str;
            break;
        end
        local sub_str = string.sub(str, 1, pos - 1);
        sub_str_tab[#sub_str_tab + 1] = sub_str;
        str = string.sub(str, pos + 1, #str);
    end

    return sub_str_tab;
end

function MakeTime( iYear,iMonth,iDay,iHour,iMin,iSec )
	local t = {
		year = iYear,
		month = iMonth,
		day = iDay,
		hour = iHour or 0,
		min =iMin or 0,
		sec = iSec or 0,
	}
	return os.time(t)
end


local TestTime = nil
function funclist.SetServiceTime(iYear,iMonth,iDay,iHour,iMin,iSec )
	TestTime = MakeTime(iYear,iMonth,iDay,iHour,iMin,iSec )
end
function funclist.GetServiceTime( )
	if TestTime then
		return TestTime
	else
		return GetSecond()
	end
end
function funclist.RealServiceTime( )
	TestTime = nil
end
NewRoleID = 200000

function funclist.InitNewRoleID(id )
	NewRoleID = id  
end
function funclist.GetNewRoleID()
	NewRoleID=NewRoleID+1
	print("NewRoleID",NewRoleID)
	return NewRoleID
end
function funclist.Seri(obj)
	return skynet.packstring(obj)
end
function funclist.UnSeri( str )
	if type(str)~= "string" or #str == 0 then
		return nil
	end
	return skynet.unpack(str)
end
function funclist.SeriJosn (obj)-- body
	return cjson.encode(obj)
end
function funclist.UnSeriJosn (str)-- body
	if type(str)=="string" and #str>0 then
		return cjson.decode(str)
	end
end
function skynetregister(sService)
	print("======333",sService)
	servicename = sService
	sService = string.format(".%s",sService)
	skynet.register(sService)
	if sService ~= ".GM" then
		skynetsend("GM","RegisterService",servicename)
	end
end

function skynetcall(sService,sCmd,...)
	return skynet.call(string.format(".%s",sService),"lua",sCmd,...)
end

function skynetsend(sService,sCmd,...)
	skynet.send(string.format(".%s",sService),"lua",sCmd,...)
end

function agentsend( pid,sCmd,... )
	if pid ==0 or not pid then
		return
	end
	if pid<=200000 then
			skynetsend("ROBOT","OnExpand",pid,sCmd,...)
		return
	else
		if skynetcall("ONLINE","GetID",pid)==0 then
			 skynet.error(pid.." agentsend ONLINE nil ")
			return
		end
	end
	skynetsend(string.format("AGENT%d",pid),"OnExpand",sCmd,...)
end

function agentcall( pid,sCmd,... )
	if pid ==0 or not pid then
		return
	end
	if pid<=200000 then
		return skynetcall("ROBOT","Expand",pid,sCmd,...)
	else
		if skynetcall("ONLINE","GetID",pid)==0 then
			 skynet.error(pid.." agentcall ONLINE nil ")
			return
		end
	end
	return skynetcall(string.format("AGENT%d",pid),"Expand",sCmd,...)
end

function skynetmyname()
return servicename
end
function GetSecond(  )
	return os.time()
end
function ChinaDate(iTime)
	iTime = iTime or GetSecond()
	 local tab = os.date("*t",iTime)
	 local iDay = (tab.wday-1)%7
	 if iDay == 0 then
	 	iDay = 7
	 end
	 return iDay,tab.hour,tab.min
end

function GetChinaDate(iTime)
	iTime = iTime or GetSecond()
	 local tab = os.date("*t",iTime)
	 return tab.year,tab.month ,tab.day ,math.ceil(tab.yday/7)
end

local standardTime = 1420387200

function funclist.GetDayNo( iTime )
	local iTime = iTime or GetSecond()
	local iDayNo = (iTime-standardTime)/3600/24
	return math.floor(iDayNo)
end

function funclist.GetHourNo( iTime )
	local iTime = iTime or GetSecond()
	local iHourNo = (iTime-standardTime)/3600
	return math.floor(iHourNo)
end

function funclist.GetTimeStr(iTime )
	local iTime = iTime or GetSecond()
	local t = os.date("*t", iTime)
	return t["year"].."."..t["month"].."."..t["day"].."-"..t["hour"]..":"..t["min"]
end
function funclist.GetTimeStr2(iTime )
	local iTime = iTime or GetSecond()
	local t = os.date("*t", iTime)
	local str = t["year"]
	if t["month"]<10 then
		str =str.."0"
	end
	str =str..t["month"]
	if t["day"]<10 then
		str =str.."0"
	end
	str =str..t["day"]
	if t["hour"]<10 then
		str =str.."0"
	end
	str =str..t["hour"]
	return str
end
function funclist.GetTimeToDay(iTime )
	local iTime = iTime or GetSecond()
	local t = os.date("*t", iTime)
	local str = t["year"]
	if t["month"]<10 then
		str =str.."0"
	end
	str =str..t["month"]
	if t["day"]<10 then
		str =str.."0"
	end
	str =str..t["day"]
	return str
end
function funclist.GetTimeStrSec(iTime )
	local iTime = iTime or GetSecond()
	local t = os.date("*t", iTime)
	local str = t["year"]
	if t["month"]<10 then
		str =str.."0"
	end
	str =str..t["month"]
	if t["day"]<10 then
		str =str.."0"
	end
	str =str..t["day"]
	if t["hour"]<10 then
		str =str.."0"
	end
	str =str..t["hour"]
	if t["min"]<10 then
		str =str.."0"
	end
	str =str..t["min"]
	if t["sec"]<10 then
		str =str.."0"
	end
	str =str..t["sec"]
	return str
end

function InList(val,tbl )
	for k,v in pairs(tbl) do
		if val == v then
			return true
		end
	end
	return false
end

local TimerMaxNo = 0
local TimerList = {}

function Call_Out(func,iSec,sFlag)
	TimerMaxNo = TimerMaxNo + 1
	local iTimerNo = TimerMaxNo
	TimerList[sFlag] =iTimerNo
	local tmpfunc = function() CallTimer(func,sFlag,iTimerNo) end
	iSec = math.max(iSec,1)
	skynet.timeout(iSec*100,tmpfunc)
end

function Remove_Call_Out(sFlag )
	TimerList[sFlag] = nil
end
function CallTimer(func,sFlag,iTimerNo )
	if not TimerList[sFlag] then
		return
	end
	if TimerList[sFlag]~=iTimerNo then
		return
	end
	TimerList[sFlag] =nil
	func()
end



function print_lua_table (lua_table, indent)
	indent = indent or 0

	for k, v in pairs(lua_table) do
		if type(k) == "string" then
			k = string.format("%q", k)
		end
		local szSuffix = ""
		if type(v) == "table" then
			szSuffix = "{"
		end
		local szPrefix = string.rep("    ", indent)
		formatting = szPrefix.."["..k.."]".." = "..szSuffix
		if type(v) == "table" then
			print(formatting)
			print_lua_table(v, indent + 1)
			print(szPrefix.."},")
		else
			local szValue = ""
			if type(v) == "string" then
				szValue = string.format("%q", v)
			else
				szValue = tostring(v)
			end
			print(formatting..szValue..",")
		end
	end
end
--打印所有的内容.
function print_obj(t)
  if type(t) == "table" then
    print_lua_table(t)
  else
    print("['".. t .."']")
  end
end


return funclist