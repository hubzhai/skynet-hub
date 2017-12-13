
local skynet = require "skynet"
local timectrl = require "timectrl"
local handle = import "framing/cmd/gmcmd"
require "pubdefines"
skynet.start(function()
	print("========3==34==4=4=4=")
	skynet.dispatch("lua", function(_,_, cmd, ...)
		local f = handle.command[cmd]
		if not f then
			print("command not find",cmd)
			return 
		end
		local r = f(...)
		if r ~="NULL" then
			skynet.ret(skynet.pack(r))
		end
	end)
	skynetregister("GM")
	timectrl.Init(function (...) handle.NewHour(...) end,function(...) handle.NewDay( ... ) end )
end)
