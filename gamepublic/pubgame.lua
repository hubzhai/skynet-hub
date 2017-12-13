local skynet = require "skynet"
local pubdefines = require "pubdefines"

function ServiceExit(  )
	skynet.exit()
end
function MyName( )
	return skynetmyname()
end
function GetMemory(  )
	return collectgarbage("count")
end
function UpdateCode( sFile,sDir )
	if string.find(sFile,"protocol") then
		local net = import "net"
		local sPb = string.sub(sfile,10)
		net.UpdatePb(sPb)
	else
		local mod = reload(sFile,sDir)
		if mod and mod["UpdateCodeInit"] then
			mod.UpdateCodeInit()
			mod["UpdateCodeInit"] = nil
		end
	end
end
function RegisterCmd( cmd )
	cmd["ServiceExit"] = ServiceExit
	cmd["MyName"] = MyName
	cmd["GetMemory"] = GetMemory
	cmd["UpdateCode"] = function(...) return UpdateCode(...) end
	cmd["SetServiceTime"] = pubdefines.SetServiceTime
	cmd["GetServiceTime"] = pubdefines.GetServiceTime
	cmd["RealServiceTime"] = pubdefines.RealServiceTime
end
