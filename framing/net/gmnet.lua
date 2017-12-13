local skynet = require "skynet"
local agent = import "agentnet"
local sql = require "sql"
local pubdefines = require "pubdefines"
local state = import "state"
local net = import "net"
local player = import "player"

 handle = {}
local gm={}
gm["test10010"] = {"100861",6666,99} 
gm["test10011"] = {"100861",6667,98} 
function handle.C2GQuestUser(  role,pkg  )
	local user = pkg["pid"]
	print("C2GQuestUser",user)
	local info  = skynetcall("PRIV","GetData",user)
	print("user",user,info,#info)
	info = info or {}
 	local tab  ={}
 	tab["user"]= info["user"] or ""
 	tab["name"] =info["name"] or ""
 	tab["dim"] =info["dim"]  or 0
 	tab["gold"] =info["gold"] or 0
 	local pid = info["id"]
 	tab["id"] = pid
 	if pid then
 		local pinfo  = skynetcall("PRIV","GetPlayerinfo",pid)
 		local lo = pinfo["local"]
 		local attr = pinfo["Attr"]
 		tab["QuitTime"] = pubdefines.GetTimeStr(lo["QuitTime"] or 0 )
 		tab["LoginTime"] = pubdefines.GetTimeStr(lo["LoginTime"] or 0 )
 		tab["TotalTime"] =lo["TotalTime"] or 0
 		tab["LoginDay"] =lo["LoginDay"] or 0
 		tab["register"] =pubdefines.GetTimeStr(lo["LoginTime"] or 0 )
 		tab["state"] =attr["state"] or 0
 		tab["winnum"] =attr["winnum"] or 0
		tab["losenum"] =attr["losenum"] or 0
 	end
 	return tab
end
function handle.C2GQuestAllUser( role,pkg )
	local index = pkg["index"]
	local tab  = skynetcall("PRIV","QuestAllUser",index)
 	return tab
end

function handle.C2GGMSysNotify( role,pkg )
	local str = pkg["str"]
	local time = pkg["time"]
	skynetsend("GM","AddNotify",str,time)
	--skynetsend("ONLINE","SendSysNotify",str)
	return {result = 0}
end
function handle.C2GGMGetNotify( role,pkg )
	local index = pkg["index"]
	local itype = pkg["type"]
	local tab  = skynetcall("GM","GetDataByIndex",index,itype)
 	return tab
end
function  handle.C2GGMLogin( role,args,fd )
	local user,pwd = args["user"],args["pwd"]
	print("C2GGMLogin",user,pwd)
	local r = 1 
	if gm[user] and gm[user][1]==pwd  then
		r = gm[user][3]
		local id = gm[user][2]
		skynetcall("GATE","KickByPid",id)
 		skynetsend("GATE","GMLoginS",fd,user,id)
	end
	return {result = r}
end
function handle.C2GGMGetPayCount( role,args )
	print("C2GGMGetPayCount")
	local tab = skynetcall("GM","GetGMCount")
	for k,v in pairs(tab) do
		print(k,v)
	end
	return {money= tab.money or 0,time= tab.time or 0,count= tab.count or 0,paycount= tab.paycount or 0}
end
--没用
function handle.C2GModfiyPTState( role,args,fd )
	local id,state = args["id"],args["state"]
	print("C2GModfiyPTState",id,state)
	skynetsend("GM","ModfiyPTState",id,state)
	return {result = 0}
end
--没用
function handle.C2GGMGetPayYear( role,args,fd )
	local itype,index = args["itype"],args["index"]
	print("C2GGMGetPayYear", itype,index)
	if itype<=2 then
		local tab  = skynetcall("GAMELOG","Expand", {"GetGMCoutByIndex",itype,index})
 		return tab
	elseif itype<=4 then
		local info = skynetcall("GM","GetGMCoutByIndex", itype,index )
		return info
	end
end
--没用
function handle.C2GGMGetPayinfo( role,args,fd )
	local pid,index = args["pid"],args["index"]
	local info = skynetcall("PRIV","GetPayinfo",pid,index)
	return info
end

function handle.C2GGMAddMail(role,args,fd )
	local tab = {}
	tab["sTitle"] = args["sTitle"]
	tab["pid"] = args["pid"]
	tab["content"] = args["content"]
	tab["gold"] = args["gold"]
	tab["horn"] = args["horn"]
	tab["timer"] = args["time"]
	local pid = tab["pid"]
	--print("pid",pid)
	if pid then
		if pid~=0 then
			local info = skynetcall("PRIV","GetData",pid)
			if info then
				tab["name"] = info["name"]
				skynetsend("GM","GMAddMail",tab)
			else
				return {result = 1}
			end
		else
			tab["name"] = "全体"
			skynetsend("GM","GMAddMail",tab)
		end
		return {result = 0}
	end
	return {result = 1}
end
function handle.C2GGMGetMail( role,pkg )
	local index = pkg["index"]
	local itype = pkg["type"]
	print("C2GGMGetMail",index,itype )
	local tab  = skynetcall("GM","GetMailByIndex",index,itype)
 	return tab
end

function handle.C2GGMUserCount( role,pkg )
	local starttime = pkg["starttime"]
	local endtime = pkg["endtime"]
	print("C2GGMUserCount",starttime,endtime )
	local tab  = skynetcall("GAMELOG","Expand", {"GetUserCount",starttime,endtime})
 	return tab
end

function handle.C2GGMLookMail( role,pkg )
	local index = pkg["id"]
	local itype = pkg["type"]
	print("C2GGMLookMail",index,itype )
	local tab  = skynetcall("GM","LookMail",index,itype)
 	return tab
end

function handle.C2GGMPhoneFare(role,pkg)
	local phoneTab =  Reimport("tables/phonefare")
	local tab ={}
	tab["farelist"] = {}
	for i,v in pairs(phoneTab) do
		print(v["phone"],v["gold"])
		tab["farelist"][i] ={["id"]=i,["money"]=v["phone"],["gold"]=v["gold"]}
	end
	return tab
end

function handle.C2GGMModfiyPhoneFare(role,pkg)
	print("C2GGMModfiyPhoneFare")
	local list  = pkg["farelist"]
	if not list then
		return
	end
	local phoneTab =Reimport "tables/phonefare"
	for k,v in pairs(list) do
	--	print(k,v["id"],v["gold"])
		if v and phoneTab[v["id"]] then
			phoneTab[k]["gold"] = v["gold"]
		end
	end
	local file = io.open("sfw/tables/phonefare.lua","w+")
	print("file",file)
	file:write("phoneFareList = {}\n")
	for k,v in pairs(phoneTab) do
		local str = "phoneFareList["..k.."] = {['phone']="..v["phone"]..",['gold']="..v["gold"].."}\n"
		file:write(str)
	end
		file:write("return phoneFareList\n")
	file:close()

	
	skynetsend("ONLINE","UpdateTable")
	print("-----------------")
	return {result = 0}
end

function handle.C2GGmCommand(role,pkg)
	print("C2GGmCommand")
	local icom = pkg["command"]
	local data = pkg["data"]
	if #data<=2 then
		return {result = 1}
	end
	print(data)
	local t  = load("return {"..data.." }")()
	print(t,type(t))
	if type(t)~="table" then
		return {result = 1}
	end
	print(t[1],t[2],t[3])
	if icom ==1 then
		if role.m_Rom>0 then
			skynetcall("ROM"..role.m_RomLV,"ModifCards",role.m_ID,role.m_Rom,t)
			return {result = 0}
		end
	elseif icom ==2 then
		 local s = skynetcall("ONLINE","GetID",t[1])
		 if s==0 then
		 	 skynetsend("PRIV","SetState",t[1],t[2])
		 else
		 	local b  =agentcall(t[1],{"SetState",t[2]})
		 	if not b then
		 		return  {result = 1}
		 	end
		 end
		 return {result = 0}
	elseif icom ==3 then
		skynetsend("GM","RemoveMail",t[1],t[2])
	elseif icom ==4 then
		skynetsend("GM","RemoveNotify",t[1],t[2])
	elseif icom ==5 then
		skynetsend("GM","SetRebootTime",1)
		return {result = 0}
	end
	return {result = 2}
end






--[[{
      ["userGameRecordInfoEverydayCounterID"] =  "int", 
      ["playGamesCount10"] =  "int", 
      ["playGamesCount20"] =  "int", 
      ["playGamesCount50"] =  "int", 
      ["dayTime"] =  "int", 

}--]]

--[[{
      ["userLoginInfoEverydayCounterID"] =  "int", 
      ["loginTimeMoreThan6Day"] =  "int", 
      ["loginTimeMoreThan7Day"] =  "int", 
      ["wastageUserGoldCount"] =  "int", 
      ["dayTime"] =  "int", 
}--]]

--[[{
      ["userRegisterInfoEverydayID"] =  "int", 
      ["todayRegisterNum"] =  "int", 

}--]]

function handle.C2GGMGetGameData(role,pkg)
	local returTbl = {}
	
	local starttime = pkg["starttime"]
	local endtime = pkg["endtime"]
	print(starttime,endtime)

	local function GetStampDayCount(starttime, endtime)
		return math.floor((endtime - starttime)/24/3600)

	end



	local  function Format(registerInfoOne, loginInfoOne, gameRecordOne)
		local transTbl = 
		{
			["playGamesCount10"] =  gameRecordOne["playGamesCount10"] or 0, 
      		["playGamesCount20"] =  gameRecordOne["playGamesCount20"] or 0, 
      		["playGamesCount50"] =  gameRecordOne["playGamesCount50"] or 0, 
			["loginTimeMoreThan6Day"] =  loginInfoOne["loginTimeMoreThan6Day"] or 0, 
      		["loginTimeMoreThan7Day"] =  loginInfoOne["loginTimeMoreThan7Day"] or 0, 
      		["wastageUserGoldCount"] =  loginInfoOne["wastageUserGoldCount"] or 0, 
      		["todayRegisterNum"] = registerInfoOne["todayRegisterNum"] or 0,
      		["todayLowPlacePlayerCount"] = gameRecordOne["playGamesInLowPlacePlayerCount"] or 0,
      		["todayLowPlaceGamesCount"] = gameRecordOne["playGamesInLowPlaceGamesCount"] or 0,
      		["todayMiddlePlacePlayerCount"] = gameRecordOne["playGamesInMiddlePlacePlayerCount"] or 0,
      		["todayMiddlePlaceGamesCount"] = gameRecordOne["playGamesInMiddlePlaceGamesCount"] or 0,
      		["todayHighPlacePlayerCount"] = gameRecordOne["playGamesInHighPlacePlayerCount"] or 0,
      		["todayHighPlaceGamesCount"] = gameRecordOne["playGamesInHighPlaceGamesCount"] or 0,
      		["todayRelief1TimesCount"] =  gameRecordOne["relief1TimesCount"] or 0,
      		["todayRelief2TimesCount"] =  gameRecordOne["relief2TimesCount"] or 0,
      		["todayRelief3TimesCount"] =  gameRecordOne["relief3TimesCount"] or 0,
      		["dayTime"] = gameRecordOne["dayTime"] or -1
		}

		return transTbl
	end

	local bindex = 1
	local eindex = GetStampDayCount(starttime, endtime)
	local btime = starttime
	local etime = endtime

	local registerInfoAll = skynetcall("DATACENTER","GetUserRegisterInfoRecord", bindex, eindex, "dayTime", string.format("<%d,%d>", btime, etime))[2]
	local loginInfoAll = skynetcall("DATACENTER","GetUserLoginInfoEverydayCounterItem", bindex, eindex, "dayTime", string.format("<%d,%d>", btime, etime))[2]
	local gameRecordAll =  skynetcall("DATACENTER","GetUserGameRecordInfoEverydayCounterItem", bindex, eindex, "dayTime",  string.format("<%d,%d>", btime, etime))[2]

	local maxNum = math.max( #loginInfoAll, #gameRecordAll)

	local maxNum = math.max(#registerInfoAll,maxNum)

	-- print(#loginInfoAll,#gameRecordAll,#registerInfoAll)

	for i=1,maxNum do
		local registerInfoOne = registerInfoAll[i]
		local loginInfoOne = loginInfoAll[i]
		local gameRecordOne = gameRecordAll[i]

		table.insert(returTbl, Format(registerInfoOne or {}, loginInfoOne or {}, gameRecordOne or {}))
	end
	
	return { ["gameData"] = returTbl}
end


function handle.C2GGMGetChargeHourData(role,pkg)
	local returTbl = {}

	local starttime = math.min(pkg["starttime"], pkg["endtime"])
	local endtime = math.max(pkg["starttime"], pkg["endtime"])


	local function GetStampHourCount(starttime, endtime)
		return math.floor((endtime - starttime)/3600)

	end
	-- local function transTime(ttime)
	-- 	local hour = ttime % 100
	-- 	local day = math.floor(ttime/100)%100
	-- 	local month = math.floor(ttime/10000) % 100
	-- 	local year = math.floor(ttime/1000000) % 10000
	-- 	return os.time{year=year, month=month, day=day, hour = hour, min = 0, sec = 0}
	-- end

	-- local function trans2ClientTime(ctime)
	-- 	local ctimedate = os.date("*t", ctime)
	-- 	return ctimedate["year"] * 1000000 + ctimedate["month"] * 10000 + ctimedate["day"]*100 + ctimedate["hour"]
	-- end

	local  function Format(data)
		local transTbl = 
		{
			["chargeHourMoneyCount"] = data["chargeHourMoneyCount"] or 0,
			["chargeAllMoneyCount"] = data["chargeAllMoneyCount"]  or 0,
			["chargeHourFirstChargePlayerCount"] = data["chargeHourFirstChargePlayerCount"] or 0,
			["chargeHourPlayerCount"] = data["chargeHourPlayerCount"]  or 0,
			["allHourLoginPlayerCount"] = data["allHourLoginPlayerCount"]  or 0,
			["allPlayerCount"] = data["allPlayerCount"] or 0,
			["chargeHourTimes"] = data["chargeHourTimes"]  or 0,
			["chargePlayerGameTimeEveryhour"] = data["chargePlayerGameTimeEveryhour"]  or 0,
			["chargeFirstLogin2FirstChargeGameCount"] = data["chargeFirstLogin2FirstChargeGameCount"]  or 0,
			["hourTime"] = data["hourTime"] or 0
		}

		return transTbl
	end


	local bindex = 1
	local eindex = GetStampHourCount(starttime, endtime)
	local btime = starttime
	local etime = endtime
	local alldatas = skynetcall("DATACENTER","GetUserChargeInfoEveryhourDataAll", bindex, eindex, "hourTime", string.format("<%d,%d>", btime, etime))[2]

	local retdatas = {}
	for k,v in pairs(alldatas) do
		table.insert(retdatas, Format(v))
	end

	return {chargeData = retdatas}
end


function handle.C2GGMGetChargeDayData(role,pkg)
	local returTbl = {}

	local starttime = math.min(pkg["starttime"], pkg["endtime"])
	local endtime = math.max(pkg["starttime"], pkg["endtime"])

	local function GetStampDayCount(starttime, endtime)
		return math.floor((endtime - starttime)/24/3600)

	end
	-- local function transTime(ttime)
	-- 	-- local hour = ttime % 100
	-- 	local day = math.floor(ttime/100)%100
	-- 	local month = math.floor(ttime/10000) % 100
	-- 	local year = math.floor(ttime/1000000) % 10000
	-- 	return os.time{year=year, month=month, day=day, hour = 0, min = 0, sec = 0}
	-- end

	-- local function trans2ClientTime(ctime)
	-- 	local ctimedate = os.date("*t", ctime)
	-- 	-- 去掉小时
	-- 	return ctimedate["year"] * 1000000 + ctimedate["month"] * 10000 + ctimedate["day"]*100
	-- end

	local  function Format(data, DayAgo1Data, one7DayAgo7Data)
	
		local transTbl = 
		{
			["chargeDayMoneyCount"] = data["chargeDayMoneyCount"] or 0,
			["chargeAllMoneyCount"] = data["chargeAllMoneyCount"] or 0,
			["chargeDayFirstChargePlayerCount"] = data["chargeDayFirstChargePlayerCount"]  or 0,
			["chargeDayLoginPlayerCount"] = data["chargeDayLoginPlayerCount"] or 0,
			["chargeDayPlayerCount"] = data["chargeDayPlayerCount"] or 0,
			["allDayLoginPlayerCount"] = data["allDayLoginPlayerCount"] or 0,
			["allPlayerCount"] = data["allPlayerCount"] or 0,
			["chargeDayTimes"] = data["chargeDayTimes"] or 0,
			["chargePlayer1DayLoginCount"] = data["chargePlayer1DayLoginCount"] or 0,
			["chargePlayer7DayLoginCount"] = data["chargePlayer7DayLoginCount"] or 0,
			["chargePlayerGameTimeEveryday"] = data["chargePlayerGameTimeEveryday"] or 0,
			["chargeFirstLogin2FirstChargeGameCount"] = data["chargeFirstLogin2FirstChargeGameCount"] or 0,
			["chargeDay1DayAgoPlayerCount"] = DayAgo1Data["chargeDayPlayerCount"] or 0,
			["chargeDay7DayAgoPlayerCount"] = one7DayAgo7Data["chargeDayPlayerCount"] or 0,
			["dayTime"] = data["dayTime"] or 0
		}

		return transTbl
	end


	local bindex = 1
	local eindex = GetStampDayCount(starttime, endtime)
	local btime = starttime
	local etime = endtime
	local alldatas = skynetcall("DATACENTER","GetUserChargeInfoEverydayDataAll", bindex, eindex, "dayTime", string.format("<%d,%d>", btime, etime))[2]
	local retdatas = {}
	for k, dayData in pairs(alldatas) do
		local dayData1DayAgo = skynetcall("DATACENTER","GetUserChargeInfoEverydayDataAll", 1, 1, "dayTime", string.format("<%d,%d>", tonumber(dayData["dayTime"]) - 24 * 3600, dayData["dayTime"]))[2]
		local dayData7DayAgo = skynetcall("DATACENTER","GetUserChargeInfoEverydayDataAll", 1, 1, "dayTime", string.format("<%d,%d>", tonumber(dayData["dayTime"]) - 7 * 24 * 3600, dayData["dayTime"]))[2]
		table.insert(retdatas, Format(dayData, dayData1DayAgo, dayData7DayAgo))
	end
	return {chargeData = retdatas}
end

function handle.C2GGMGetChargeMonthData(role,pkg)
	local returTbl = {}

	local starttime = math.min(pkg["starttime"], pkg["endtime"])
	local endtime = math.max(pkg["starttime"], pkg["endtime"])

	local function GetStampMonthCount(starttime, endtime)
		local startDate = os.date("*t", starttime)
		local endDate = os.date("*t", endtime)
		return (endDate["year"] - startDate["year"]) * 12 + endDate["month"] - startDate["month"]

	end

	-- local function transTime(ttime)
	-- 	-- local hour = ttime % 100
	-- 	-- local day = math.floor(ttime/100)%100
	-- 	local month = math.floor(ttime/10000) % 100
	-- 	local year = math.floor(ttime/1000000) % 10000
	-- 	return os.time{year=year, month=month, day=0, hour = 0, min = 0, sec = 0}
	-- end

	-- local function trans2ClientTime(ctime)
	-- 	local ctimedate = os.date("*t", ctime)
	-- 	-- 去掉小时
	-- 	return ctimedate["year"] * 1000000 + ctimedate["month"] * 10000
	-- end

	local  function Format(data)
		local transTbl = 
		{
			["chargeMonthMoneyCount"] = data["chargeMonthMoneyCount"] or 0,
			["chargeAllMoneyCount"] = data["chargeAllMoneyCount"] or 0,
			["chargeMonthFirstChargePlayerCount"] = data["chargeMonthFirstChargePlayerCount"] or 0,
			["chargeMonthPlayerCount"] = data["chargeMonthPlayerCount"] or 0,
			["allMonthLoginPlayerCount"] = data["allMonthLoginPlayerCount"] or 0,
			["allPlayerCount"] = data["allPlayerCount"] or 0,
			["chargeMonthTimes"] = data["chargeMonthTimes"] or 0,
			["chargePlayer1DayLoginCount"] = data["chargePlayer1DayLoginCount"] or 0,
			["chargePlayer7DayLoginCount"] = data["chargePlayer7DayLoginCount"] or 0,
			["chargePlayerGameTimeEverymonth"] = data["chargePlayerGameTimeEverymonth"] or 0,
			["chargeFirstLogin2FirstChargeGameCount"] = data["chargeFirstLogin2FirstChargeGameCount"] or 0,
			["monthTime"] = data["monthTime"] or 0
		}

		return transTbl
	end


	local bindex = 1
	local eindex = GetStampMonthCount(starttime, endtime)
	local btime = starttime
	local etime = endtime

	local alldatas = skynetcall("DATACENTER","GetUserChargeInfoEverymonthDataAll", bindex, eindex, "monthTime", string.format("<%d,%d>", btime, etime))[2]

	local retdatas = {}
	for k,v in pairs(alldatas) do
		table.insert(retdatas, Format(v))
	end

	return {chargeData = retdatas}
end


function handle.C2GGMGetSendSupport(role,pkg)
	local bindex = pkg["bindex"]
	local eindex = pkg["eindex"]
	local skey = pkg["skey"]
	local sval = pkg["sval"]
	local  function Format(data)
		
		local uInfo = skynetcall("PRIV","GetData", data["pid"])


		local transTbl = 
		{
			["id"] = data["supportInfoID"] or 0,
			["title"] = data["title"] or "",
			["content"] = data["content"] or "",
			["uID"] = data["pid"] or -1,
			["uName"] = uInfo and uInfo["name"] or "",
			["uRealName"] = uInfo and uInfo["user"] or "",
			["isHandle"] = data["isHandle"] or -1,
			["supportInfoTime"] = data["supportInfoTime"] or -1
		}

		return transTbl
	end

	local supportInfoData = skynetcall("SUPPORTINFO","GetSupportInfoItem", bindex, eindex, skey, sval)


	local retTbl = {}

	for k,v in pairs(supportInfoData[2]) do
		table.insert(retTbl, Format(v))
	end

	return { supportData = retTbl, allNum = supportInfoData[1]}
end


function handle.C2GGMUpdateSendSupport(role,pkg)
	local id = pkg["id"]
	local skey = pkg["skey"]
	local sval = pkg["sval"]

	skynetcall("SUPPORTINFO", "UpdateSupportInfoItemMoreByID", id, skey, sval)

	return {result = 0}
end


-- facebook总人数  游客注册总人数
function handle.C2GGMGetRegisterInstitutionNowCount(role,pkg)

	local facebookNum = skynetcall("DATACENTER", "GetUserRegisterInstitutionCount", "facebook") or 0

	local visitorNum = skynetcall("DATACENTER", "GetUserRegisterInstitutionCount", "visitor") or 0
	
	return { facebookNum = facebookNum, visitorNum = visitorNum}
end


--  总付费金额 总付费人数 付费玩家平均游戏时长 付费玩家平均充值次数
function handle.C2GGMChargePlayerInfoNowCount(role,pkg)

	local allChargeMoneyCount = 0
	local allChargePlayerCount = 0
	local allChargePlayerGameTimeCount = 0
	local allChargePlayerChargePayTimesCount = 0


	local allData = skynetcall("DATACENTER", "GetChargeInfoAllData")
	for k,v in pairs(allData) do
		local chargePid = v["chargePid"]
		local chargeMoneyCount = v["chargeMoneyCount"]
		local chargeMoneyTimesCount = v["chargeMoneyTimesCount"]
		local playGameTime = 0

		local gameRecord = skynetcall("DATACENTER", "GetGameRecord", chargePid)
		
		if gameRecord then
			playGameTime = gameRecord["playGameTime"]
		else
			skynet.error("can't find gameRecord in handle.C2GGMChargePlayerInfoNowCount")
		end

		allChargeMoneyCount = allChargeMoneyCount + chargeMoneyCount

		allChargePlayerCount = allChargePlayerCount + 1

		allChargePlayerGameTimeCount = allChargePlayerGameTimeCount + playGameTime

		allChargePlayerChargePayTimesCount = allChargePlayerChargePayTimesCount + chargeMoneyTimesCount
	end


	return { 
	allChargeMoneyCount = allChargeMoneyCount, 
	allChargePlayerCount = allChargePlayerCount,
	allChargePlayerGameTimeCount = allChargePlayerGameTimeCount,
	allChargePlayerChargePayTimesCount = allChargePlayerChargePayTimesCount}
end


function handle.C2SGetUserChargeInfo(role,pkg)
	local bindex = pkg["bindex"]
	local eindex = pkg["eindex"]
	local qstrKey = pkg["qkey"]
	local qstrVal = pkg["qval"]

	local data = skynetcall("DATACENTER", "GetOneChargeData", bindex, eindex, qstrKey,  qstrVal)
	local sum = data[1]
	local sumTbl = data[2]

	local  function Format(data)
		
		local uInfo = skynetcall("PRIV","GetData", data["oneChargePid"])

		local transTbl = 
		{
			["useOnerChargeRecordID"] = data["useOnerChargeRecordID"] or 0,
			["oneChargeMoneyCount"] = data["oneChargeMoneyCount"] or "",
			["oneChargeGameMoneyCount"] = data["oneChargeGameMoneyCount"] or "",
			["oneChargeTime"] = data["oneChargeTime"] or 0,
			["oneChargeOrderID"] = data["oneChargeOrderID"] or 0,
			["oneChargePid"] = data["oneChargePid"] or 0,
			["playerNickname"] = uInfo and uInfo["name"] or ""
		}

		return transTbl
	end

	retTbl = {}

	for k,v in pairs(sumTbl) do
		table.insert(retTbl, Format(v))
	end


	return {sum = sum, userChargeInfo = retTbl}
end




function handle.C2SGetRankUserChargeInfo(role,pkg)
	local bindex = pkg["bindex"]
	local eindex = pkg["eindex"]



	local data = skynetcall("DATACENTER", "GetRankUserChargeInfo", bindex, eindex)

	local sum = data[1]
	local sumTbl = data[2]

	local  function Format(index, data)
		
		local uInfo = skynetcall("PRIV","GetData", data["chargePid"])

		local transTbl = 
		{
			["rankChageRank"] = index + bindex - 1,
			["rankChargeMoneyCount"] = data["chargeMoneyCount"] or "",
			["rankChargeGameMoneyCount"] = data["chargeGameMoneyCount"] or "",
			["rankChargePid"] = data["chargePid"] or 0,
			["rankChargeMoneyTimesCount"] = data["chargeMoneyTimesCount"] or 0,
			["rankChargePlayerNickname"] = uInfo and uInfo["name"] or "",
		}

		return transTbl
	end

	retTbl = {}

	for k,v in pairs(sumTbl) do

		table.insert(retTbl, Format(k, v))
	
	end

	return {sum = sum, rankuserChargeInfo = retTbl}
end


  
-- 初、中、高三个场次实时在线人数、 在线总人数
-- C2GGetRoomPlayerNum 203 {
-- 有人已经写好
-- function handle.C2GGMWherePlayerNowCount(role,pkg)

-- 	local nowLowPlacePlayerCount = 0

-- 	local nowMidlePlacePlayerCount = 0

-- 	local nowHighPlacePlayerCount = 0


-- end

function handle.C2GGMOnlineNum( role,pkg )
	local tab = {}
	tab["num1"] = skynetcall("ROM1", "GetOnlineNum")
	tab["num2"] = skynetcall("ROM2", "GetOnlineNum")
	tab["num3"] = skynetcall("ROM3", "GetOnlineNum")
	tab["online"] = skynetcall("ONLINE", "getonline")
	return tab
end

-- 领取 1.2 .3 次救济金的人数
function handle.C2GGMChargeReliefGoldNowCount(role,pkg)
	local relief1TimesCount = 0

	local relief2TimesCount = 0

	local relief3TimesCount = 0

	local allData = skynetcall("DATACENTER", "GetGameRecordAll")

	for k,v in pairs(allData) do
			
		if v["reliefTimesCount"] == 1 then

			relief1TimesCount = relief1TimesCount + 1
			
		elseif v["reliefTimesCount"] == 2 then

			relief2TimesCount = relief2TimesCount + 1
			
		elseif v["reliefTimesCount"] == 3 then

			relief3TimesCount = relief3TimesCount + 1

		end

	end

	return {
		relief1TimesCount = relief1TimesCount,
		relief2TimesCount = relief2TimesCount,
		relief3TimesCount = relief3TimesCount
	}
end


function C2GCmd(role,cmd, args, response,fd)
	local isgm = player.GetType()
	print("isgm",isgm)
	if isgm~=1 and cmd ~="C2GGMLogin" then
	--	return
	end
	local f = assert(handle[cmd])
	local r = f(role,args,fd)
	if response then
		return response(r)
	end
end
