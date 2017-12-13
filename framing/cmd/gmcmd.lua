local skynet = require "skynet"
local sql = require "sql"
local pubdefines = require "pubdefines"
local gmblk = import "blk/gmblk"
 command = {}
function command.start( )
	print("gm start")
	gmblk.GetObj()
end

function command.AddPhoneTrade(tab)
	local obj = gmblk.GetObj()
	if not obj then
		return "NULL"
	end
	obj:AddPhoneTrade(tab)
	return "NULL"
end

function command.GetGMPhoneTrade( index,itype )
	local obj = gmblk.GetObj()
	if not obj then
		return 
	end
	return obj:GetGMPhoneTrade( index,itype)
end

function command.ModfiyPTState( id,state )
	local obj = gmblk.GetObj()
	if not obj then
		return "NULL"
	end
	obj:ModfiyPTState(id,state)
	return "NULL"
end
function command.AddNotify(...)
	local obj = gmblk.GetObj()
	if not obj then
		return "NULL"
	end
	obj:AddNotify(...)
	return "NULL"
end
function command.GMAddMail( tab)
	local obj = gmblk.GetObj()
	if not obj then
		return "NULL"
	end
	 obj:GMAddMail( tab)
	return "NULL"
end
function command.AddGmCount( ...)
	local obj = gmblk.GetObj()
	if not obj then
		return "NULL"
	end
	 obj:AddGmCount( ...)
	return "NULL"
end
function command.AddYear( ...)
	local obj = gmblk.GetObj()
	if not obj then
		return "NULL"
	end
	 obj:AddYear( ...)
	return "NULL"
end
function command.AddMonth( ...)
	local obj = gmblk.GetObj()
	if not obj then
		return "NULL"
	end
	 obj:AddMonth( ...)
	return "NULL"
end
function command.AddWork( ...)
	local obj = gmblk.GetObj()
	if not obj then
		return "NULL"
	end
	 obj:AddWork( ...)
	return "NULL"
end
function command.GetGMCount( ... )
	local obj = gmblk.GetObj()
	if not obj then
		return 
	end
	
	return obj:GetGMCount()
end

function command.GetGMCoutByIndex( ... )
	local obj = gmblk.GetObj()
	if not obj then
		return 
	end
	
	return obj:GetGMCoutByIndex(...)
end

function command.RemoveMail( ...)
	local obj = gmblk.GetObj()
	if not obj then
		return "NULL"
	end
	 obj:RemoveMail( ...)
	return "NULL"
end

function command.RemoveNotify( ...)
	local obj = gmblk.GetObj()
	if not obj then
		return "NULL"
	end
	 obj:RemoveNotify( ...)
	return "NULL"
end
function command.LookMail( ... )
	local obj = gmblk.GetObj()
	if not obj then
		return 
	end
	return obj:LookMail( ...)
end

function command.GetMailByIndex( ... )
	local obj = gmblk.GetObj()
	if not obj then
		return 
	end
	return obj:GetMailByIndex( ...)
end

servicelist = {}
function command.RegisterService(sSer )
	servicelist[sSer] = 1
	return "NULL"
end

function command.ServiceExit( )
	local obj = gmblk.GetObj()
	if not obj then
		return 
	end
	 obj:SaveData()
	return true
 end 

function command.Reboot(index )
	for k,v in pairs(servicelist) do
		if string.find(k,"AGENT") then
			print(k,v)
			skynetcall(k,"ServiceExit")
			servicelist[k]=nil
		end
	end
	skynet.sleep(3000)
	for k,v in pairs(servicelist) do
		print(k,v)
		skynetcall(k,"ServiceExit")
	end
	print("Reboot")
	
	local obj = gmblk.GetObj()
	if  obj then
		obj:SaveData()
	end
	skynet.sleep(3000)
	if index==1 then
	--	os.execute("sh run1.sh")
	elseif index==2 then
		--os.execute("sh run2.sh")
	end
	print("exit")

	--os.exit()
	skynet.abort()
end

function command.SetRebootTime(index )
	local time = 1
	if index==2 then
		--time = 5
	end
	 command.Reboot(1)
	--skynetsend("ONLINE","SendSysNotify","服务器将在"..time.."分钟后维护")
	--Call_Out(function() command.Reboot(index) end,time*60,"Reboot")
	return 0
end

function command.GetDataByIndex( ... )
	local obj = gmblk.GetObj()
	if not obj then
		return 
	end
	return obj:GetDataByIndex( ...)
end
function NewHour(iDay,iHour)
	local obj = gmblk.GetObj()
	if not obj then
		return 
	end
	obj:NewHour(iDay,iHour)
end
function NewDay(iDay )
	local obj = gmblk.GetObj()
	if not obj then
		return 
	end
	obj:NewDay(iDay)
end
