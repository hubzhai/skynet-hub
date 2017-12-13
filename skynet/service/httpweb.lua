local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string
local cjson = require "cjson"
local mode = ...
local httpc = require "http.httpc"
local MD5 = require "md5"

if mode == "agent" then
local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end
--发送Post请求
function Send_Post()
	-- set dns server
    httpc.dns()
    -- set timeout 1 second
    httpc.timeout = 3000
    
	local http_info = {
		money = 10,
		bank = 20
	}
	local respheader = nil
    local states,body = httpc.post("192.168.2.169", "/index.php/api/pay/submitOrderInfo", http_info, respheader)
	if states == 200 then
		local data = cjson.decode(body)
        return data.data
    end
    return false
end

skynet.start(function()
	skynet.dispatch("lua", function (_,_,id)
		socket.start(id)  -- 开始接收一个 socket
		-- limit request body size to 8192 (you can pass nil to unlimit)
		-- 一般的业务不需要处理大量上行数据，为了防止攻击，做了一个 8K 限制。这个限制可以去掉。
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
		--print("========23=4=2=34=234=23=4",code, url, method, header, body)
		if code then
			if code ~= 200 then  -- 如果协议解析有问题，就回应一个错误码 code 。
				response(id, code)
			else
				-- 这是一个示范的回应过程，你可以根据你的实际需要，解析 url, method 和 header 做出回应。
				local accountdb = skynet.uniqueservice("accountdb")
				local tmp = {}
				local result = "false"
				if header.host then
					table.insert(tmp, string.format("host: %s", header.host))
				end
				if url ~= "/favicon.ico" then
					local path, query = urllib.parse(url)
					if query and method == "POST" then
						--local data = cjson.decode(body)
						print(id,code,body)
						if header["content-type"] == "withdraw" then
							local data = cjson.decode(body)
							if skynet.call(accountdb,"lua","Auditing_Msg",data.withdraw_id) then
								result = "true"
							end							
						end						
					elseif query and method == "GET" then
						local q = urllib.parse_query(query)
						--local data = cjson.decode(q)
						print(q)
						for k,v in pairs(q) do
							print(k,v)
						end
						result = "true"
					end
				end
				response(id, code, result)
			end
		else
			-- 如果抛出的异常是 sockethelper.socket_error 表示是客户端网络断开了。
			if url == sockethelper.socket_error then
				skynet.error("socket closed")
			else
				skynet.error(url)
			end
		end
		socket.close(id)
	end)
end)

else

skynet.start(function()
	
	local agent = {}
	for i= 1, 10 do
		-- 启动 20 个代理服务用于处理 http 请求
		agent[i] = skynet.newservice(SERVICE_NAME, "agent")  
	end
	local balance = 1
	-- 监听一个 web 端口
	local id = socket.listen("127.0.0.1", 8002)  
	socket.start(id , function(id, addr)
		-- 当一个 http 请求到达的时候, 把 socket id 分发到事先准备好的代理中去处理。
		skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
		skynet.send(agent[balance], "lua", id)
		balance = balance + 1
		if balance > #agent then
			balance = 1
		end
	end)
end)

end
