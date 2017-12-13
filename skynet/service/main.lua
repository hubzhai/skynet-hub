local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
local config = require "config.system"

local max_client = 64

skynet.start(function()
	skynet.error("Server start")
	print("Server start")
	os.execute("'' > gslog.txt")


	local servicelist = {
		"protoloader",
		"httpweb",
		--  "loginservice",
		--  "toolservice",
	}



	for k,v in pairs(servicelist) do
		local service = skynet.newservice(v)
		skynet.send(service,"lua","start")
	end
	print("OK")





	--skynet.uniqueservice("protoloader")
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)
	skynet.newservice("simpledb")

    -- local db = skynet.uniqueservice("accountdb")
    -- skynet.call(db,'lua','start',config.accountdb);

	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = 8888,
		maxclient = max_client,
		nodelay = true,
	})
	skynet.error("Watchdog listen on", 8888)
	skynet.exit()
end)
