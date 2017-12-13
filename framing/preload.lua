-- This file will execute before every lua service start
-- See config
package.path =package.path ..";framing/?.lua"
package.path =package.path ..";gamepublic/?.lua"

require "pubdefines"
require "reload"

local function LogBug(sLog )
	-- body
	local f =io.open("gslog.txt","a+")
	local sHead = os.date("%Y-%m-%d %X")
	sLog =string.format("[%s]%s\n%s\n",sHead,skynetmyname(),sLog)
	f:write(sLog)
	f:close()
end 
local errorback = error
function error( ... )
	-- -- body
	-- LogBug(tostring(select(1,...)))
	-- errorback(...)
end
