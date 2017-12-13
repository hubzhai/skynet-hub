local skynet = require "skynet"
local agent = import "agentnet"
local sql = require "sql"
local pubdefines = require "pubdefines"
local net = import "net"
 handle = {}



function C2GCmd(role,cmd, args, response,fd)
	if not role then
		print("not role ....")
		return
	end
	local f = assert(handle[cmd])
	local r = f(role,args,fd)
	if response  then
		return response(r)
	end
end