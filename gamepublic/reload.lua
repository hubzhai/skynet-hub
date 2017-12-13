local skynet = require "skynet"

local Modules = {}

local maindir = skynet.getenv("maindir")

function import(modname,dir )
	-- body
	dir =dir or maindir
	modname = dir .."/"..modname
	local pathname = modname..".lua"
	local oldmodule = Modules[modname]
	if oldmodule then
		return oldmodule
	end
	local newmodule =  {}
	Modules[modname] = newmodule
	setmetatable(newmodule,{__index = _G})
	local func,err = loadfile(pathname,"bt",newmodule)
	if not func then
		print("import error:"..err)
		print(debug.traceback())
		return nil,err
		-- body
	end
	func()
	return newmodule
end


function Reimport(modname,dir )
	-- body
	dir =dir or maindir
	modname = dir .."/"..modname
	local pathname = modname..".lua"
	local newmodule =  {}
	Modules[modname] = newmodule
	setmetatable(newmodule,{__index = _G})
	local f = io.open(pathname, "rb")
	if not f then
		return "Can't open " .. filename
	end
	local source = f:read "*a"
	f:close()
	--print("source",source)
		--dofile("script/tables/phonefare.lua")
		--collectgarbage "collect"
	newmodule =  load(source)() 
	return newmodule
end



function importall( evn,modname,dir )
	local  mod = import(modname,dir)
	for k,v in pairs(mod) do
		evn[k] = mod[k]
	end
	return mod
end

function reload( modname,dir )
	dir =dir or maindir
	modname = dir .."/"..modname
	local pathname = modname..".lua"
	local oldmodule = Modules[modname]
	if oldmodule then
		return oldmodule
	end
	local oldCache = {}
	for k,v in pairs(oldmodule) do
		if type(v)== "table" then
			oldCache[k]=v
		end
	end
	local newmodule = oldmodule
	local func,err = loadfile(pathname,"bt",newmodule)
	if not func then
		print("reload error:"..err)
		return nil,err
	end
	func()
	for k,v in pairs(oldCache) do
		if type(v)== "table" and v~=newmodule[k] then
			local  mt = getmetatable(newmodule[k])
			if mt then setmetatable(v,mt) end
			for newkey,newval in pairs(newmodule[k]) do
				v[newkey] =newval
			end
			newmodule[k]=v
		end
	end
	return newmodule
end