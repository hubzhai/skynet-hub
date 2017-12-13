local config = {}

config.log_level = 1 -- 1:debug 2:info 3:notice 4:warning 5:error

config.debug_port = 9333
config.version = 110
config.gamed = { 
	name = "gameserver", 
	port = 8888, 
	maxclient = 5000, 
	pool = 32,
}
config.accountdb ={
	ip = "192.168.1.248",
	port=3306,
	database="account",
	user="root",
	password="123456",
	
}


--config.playerredis ={
--	host = "127.0.0.1",
--	port=6379,
--	db=1,
--	--auth="foobared",
	
--}


return config
