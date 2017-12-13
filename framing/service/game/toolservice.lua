
local skynet = require "skynet"
local timectrl = require "timectrl"
local handle = require "cmd/toolcmd"
require "pubdefines"
skynet.start(function()
	print("===23==4=34==4======")
	skynet.dispatch("lua", function(_,_, cmd, ...)
		local f = handle.command[cmd]
		local r = f(...)
		if r ~="NULL"  then
			skynet.ret(skynet.pack(r))
		end
	end)
	skynetregister("TOOL")
	print("===23==4=34==4======")
	timectrl.Init(function (...) handle.NewHour(...) end,function(...) handle.NewDay( ... ) end )
end)
