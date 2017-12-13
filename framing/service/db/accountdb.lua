local skynet = require "skynet"
local mysql = require "skynet.db.mysql"
local cjson = require "cjson"

local CMD = {}
local marqueeDataList = nil
local db;
function CMD.create_guest_account(imei,ip,superior_guid)
	-- 电话 电话类型 版本 渠道 包名 imei ip
	local sql = string.format("Call create_guest_account ('%s','%s','%s','%s','%s','%s','%s','%s')","","","","","",imei,ip,superior_guid);

	local ret = db:query(sql);
	for k,_v in pairs(ret) do
		print("======",k,_v)
	end
	return ret;
end
function CMD.T_superior_guid(superior_guid)
		local sql = string.format("select * from channel_business where guid = '%d'",superior_guid);
		local ret = db:query(sql);		
		return ret;
end

function CMD.login_account(account,password)
	print(account,password)
	-- 帐号 密码
	local sql = string.format("Call verify_account ('%s','%s')",account,password);
	local ret = db:query(sql);
	return ret;
end
function CMD.select_convert_record(guid)
	local sql = string.format("select withdraw_id,withdraw_amount,status,updated_at from t_with_draw where guid = '%d' order by created_at DESC ",guid);
	local ret = db:query(sql);
	if ret.errno then
		print("...error...sql:",sql)
		return nil
	end
	return ret;
end
function CMD.Auditing_Msg(withdraw_id)
	local sql = string.format("select guid,status,status_msg,withdraw_amount from t_with_draw where withdraw_id = '%s'",withdraw_id)
	local ret_v = db:query(sql)
	if ret_v.errno then
		print("...error...sql:",sql)
	end
	local content ,money= "",0
	if ret_v[1].status == 1 then
		content = "亲爱的玩家您好，您提现的金额已经到账，请注意查收，祝您游戏愉快！"
	elseif ret_v[1].status == 2 then
		content = "亲爱的玩家您好，因爲"..ret_v[1].status_msg.."的原因，提现失败，金币已返还到你的账户，祝您游戏愉快！"
		money = ret_v[1].withdraw_amount
	end
	local msg_val = {
        guid = ret_v[1].guid,
        name = "系统邮件" ,
        content = content,
        type = 1
	}
	if CMD.insertMsg(msg_val) then
		--检测玩家是否在线
		local loginmgr = skynet.uniqueservice("loginmgr")
		local ret = skynet.call(loginmgr,"lua","get_agent_by_guid",ret_v[1].guid)
		if not next(ret) then 
			print("当前玩家不在线，无法发送消息")
			local sql = string.format("update t_with_draw set status = 3 where withdraw_id = '%s'",withdraw_id)
			local ret_v = db:query(sql)
			if ret_v.errno then
				print("...error...sql:",sql)
				return false
			end
			return true
		end 
		skynet.send(ret.agent,"lua","Send_Message_val")
		skynet.send(ret.agent,"lua","Send_ConvertRecord")
		skynet.send(ret.agent,"lua","save_money",money)
		return true
	end
	return false
end
function CMD.select_states_convert(guid)
	local sql = string.format("select withdraw_amount as gold from t_with_draw where guid = '%d' and status = 3",guid)
	local ret_v = db:query(sql)
	if ret_v.errno then
		print("...error...sql:",sql)
		return nil
	end
	local msql = string.format("update t_with_draw set status = 2 where status = 3 and guid = '%d'",guid)
	local ret = db:query(msql)
	if ret.errno then
		print("...error...sql:",msql)
		return nil
	end
	return ret_v
end

function print_table(tb, sp)
	print ((sp or "") .. "{")
	for k, v in pairs(tb or {}) do
        if type(v) ~= "table" then
			if type(v) == "string" then
				print (sp or "", k .. ' = "' .. v .. '"')
			elseif type(v) == "boolean" then
				print (sp or "", k .. ' = "' .. tostring(v) .. '"')
			elseif type(v) ~= "userdata" then
				print (sp or "", k .. " = " .. v)
			end
        else
			print (sp or "", k .. " = ")
            print_table(v, (sp or "") .. "\t")
        end
    end
	print ((sp or "") .. "}")
end

function CMD.get_accountinfo(guid)
	
	-- 帐号 密码
	local sql = string.format("select `nickname`,bank_password,`password` from t_account where guid = '%d'",guid);
	local ret = db:query(sql);
	
	if (ret.errno ~= nil) then
        print("sql exec err: " .. sql)
        return nil
    end 

	local r = {}

	r.bank_password = ret[1].bank_password == nil and "" or ret[1].bank_password

	r.password = ret[1].password
	r.nickname = ret[1].nickname

	return r;
end
--添加订单
function CMD.saveOrder(guid,orderid,money)
---------------------------------------------------------------------------------玩家上家验证
	--获取 上家guid
	local sql = string.format("select superior_guid from t_account where guid = '%d'",guid)
	local id = db:query(sql)
	if id == nil then
		print("=============== saveOrder ==========",id[1].superior_guid)
		id[1].superior_guid=0
	end
	print("============ 添加订单到数据库 ==============")
	--添加订单到数据库
	local msql = string.format("insert into t_recharge_order(guid,serial_order_no,order_status,payment_amt,superior_guid) values('%d','%s','%d','%d','%d')",guid,orderid,0,money,id[1].superior_guid)
	local ret = db:query(msql)
	if ret then
		print("=========== 添加成功 ========")
	else 
		print("=========== 失败 ========")
		return
	end
	return id[1].superior_guid;
end
-- 给代理分成
function CMD.update_business(guid,money)
	money=tonumber(money)
	 local sql = string.format("select tax, total_income from channel_business where guid = '%d'",guid);
	 local ret = db:query(sql);
	 if next(ret) then
	 	local total_income_ = tonumber(ret[1].tax)/100 * money
	 	total_income_ = total_income_+tonumber(ret[1].total_income)
		CMD.charge_val_account_num("channel_business","total_income",total_income_,guid)
	 end
end
--修改account数据库下表的一个str字段 条件guid
function CMD.charge_val_account_str(tbl_name,name_,_val,guid)
	local sql = string.format("update %s set %s = '%s' where guid = '%d'",tbl_name,name_,_val,guid);
	local ret = db:query(sql);
	if ret.errno ~= nil then
		print("===== charge_val_account_str == error == =====")
	end
end
--修改account数据库下表的一个num字段 条件guid
function CMD.charge_val_account_num(tbl_name,name_,_val,guid)
	--print("=========",tbl_name,name_,_val,guid)
	local sql = string.format("update %s set %s = '%f' where guid = '%d'",tbl_name,name_,_val,guid);
	local ret = db:query(sql);
	if ret.errno ~= nil then
		print("=== charge_val_account_num ==== error =======")
	end
end
function CMD.select_val(tbl_name,name,guid)
	print("select_val=====================",tbl_name,name,guid)
	local sql = string.format("select %s from %s where guid = '%d'",name,tbl_name,guid)
	local ret = db:query(sql);
	if ret.errno ~= nil then
		print("=== select_val ==== error =======")
	end
	return ret[1].recharge_count
end
--通过guid查找t_account的上家id，并获取上家的信息，计算抽水分成
function CMD.select_val_num(guid)
	local sql = string.format("select superior_guid,is_guest from t_account where guid = '%d'",guid)
	local ret = db:query(sql);
	if ret.errno ~= nil then
		print("=== select_val ==== error =======")
	end
	print("======3453",ret)
	print("======3453",ret[1])
	print("======3453",ret[1].superior_guid)
	if next(ret[1]) and ret[1].superior_guid and ret[1].superior_guid ~= 0 and ret[1].is_guest == 0 then
		print("next...........")
		local sql2 = string.format("select * from tax_business where guid = '%d'",ret[1].superior_guid)
		local ret2 = db:query(sql2);
		if ret2.errno ~= nil then
			print("=== select_val_num ==== error =======")
		end
		return ret2[1]
	end
	return false
end
function CMD.insert_Online_acc(guid)
	local sql = string.format("insert into t_online_account(guid) values('%d')",guid)
	local ret = db:query(sql);
	if ret.errno then
		print("======== insert_Online_acc =========error=======")
	end
end
function CMD.update_Online_val(first,serond,g_state,guid)
	local sql = string.format("UPDATE t_online_account set first_game_type = '%d', second_game_type= '%d', in_game= '%d' WHERE guid = '%d'",first,serond,g_state,guid)
	local ret = db:query(sql);
	if ret.errno then
		print("======== update_Online_val =========error=======")
	end
end
function CMD.saveplayer(guid,info)
	-- 帐号 密码
	local sql = string.format("update t_account set bank_password = '%s',password = '%s',`nickname` = '%s' where guid = '%d'"
		,info.bank_password,info.password,info.nickname,guid);
	local ret = db:query(sql);
	if (ret.errno ~= nil) then
        print("sql exec err: " .. sql)
        return nil
    end 
	return ret;
end

function CMD.save_player_account(guid, info)
	local sql = string.format("update t_account set account = '%s', is_guest = '%d' where guid = '%d'",
		info.account, info.accountinfo.is_guest, guid);
	local ret = db:query(sql);
	if (ret.errno ~= nil) then
        print("sql exec err: " .. sql)
        return nil
    end 
	return ret;
end

function CMD.get_accountbytel(phone)
	local sql = string.format("select guid from t_account where account = '%s'", phone);
	local ret = db:query(sql);
	if (ret.errno ~= nil) then
        print("sql exec err: " .. sql)
        return nil
    end 
	local guid = ""
	if (ret[1] ~= nil and ret[1].guid ~= nil) then
    	guid = tostring(ret[1].guid) 
	end
	print("guid"..guid)
	return guid;
end

local cheatModeList= false
--查询是否有玩家开作弊器 id = guid
function CMD.cleckCheatMode()
	if  not cheatModeList then 
		local sql = string.format("select account,is_cycle,game_type, brand_type from t_card_list");
		local ret = db:query(sql);
	
		if (ret.errno ~= nil) then
			print("sql exec err: " .. sql)
			return nil
		end 

		cheatModeList = {}
		for k ,v in pairs(ret) do 
			cheatModeList[v.account] = v
			cheatModeList[v.account].brand_type = cjson.decode(cheatModeList[v.account].brand_type)
		end 
	end
	return cheatModeList
end
--插入玩家聊天信息
function CMD.insterBackText(data)
	local sql = string.format("INSERT INTO feedback SET username = '%s',account='%s',content='%s';",data.name,data.guid,data.text)
	local ret = db:query(sql);
	return ret
end 
--添加兑换记录
function CMD.insert_log_convert(convert_id,gold,ip,state,guid,msg_info)
	local sql = string.format("insert into t_with_draw(guid,withdraw_id,withdraw_amount,withdraw_ip,status,exception) values('%d','%s','%f','%s','%d','%s')",guid,convert_id,gold,ip,state,msg_info)
	local ret = db:query(sql);
	if ret.errno then
		print("===error===sql:",sql)
	end	

	local t_sql = string.format("update t_account set convert_count = convert_count +'%f' where guid = '%d'",gold,guid)
	local t_ret = db:query(t_sql);
	if t_ret.errno then
		print("===error===sql:",t_sql)
	end	
end
--抽成log
function CMD.insert_tax_log(tax,tax_val,tax_bus_super_guid,guid)
	print(tax,tax_val,tax_bus_super_guid,guid)
	local sql = string.format("INSERT INTO tex_bus_log(tax,tax_val,tax_bus_super_guid,guid) values('%f','%d','%d','%d')",tax,tax_val,tax_bus_super_guid,guid)
	local ret = db:query(sql);
	if ret.errno then
		print("===error===sql:",sql)
	end
end 
--查询玩家聊天信息
function CMD.cleckBackText(guid)
	local sql = string.format("select * from feedback where account = '%s' ORDER BY created_at DESC LIMIT 50 ", guid);

	local ret = db:query(sql);
	if (ret.errno ~= nil) then
		print("sql exec err: " .. sql)
		return nil
	end
	return ret
end 
--更改玩家聊天状态
function CMD.updateBackTextStatus(guid)
	local sql = string.format("UPDATE feedback SET is_read=%d WHERE account=%s;",1,guid);
	local ret = db:query(sql);
end
 --给所有玩家发送信息 name :消息名字 msg：消息内容
 function CMD.allagentsMsg(name,msg)
	-- 获取所有在线玩家
	local loginmgr = skynet.uniqueservice("loginmgr")
	local agents = skynet.call(loginmgr, "lua", "get_all_agents")
	print("online player number:", #agents)
	if agents == nil then
		return
	end
	for k , v in pairs(agents) do 
		local gateid_ = v.gateid
		local fd_ = v.fd
		skynet.send(gateid_,"lua","send2c",fd_,name,msg)
		print("=============== 消息发送出去了 ",gateid_,fd_)
	end
	return true
 end
-- id ： 1 为客服聊天消息 2 跑马灯及公告消息 3 消息
--接受后台协议
function CMD.houtaixiyi(guid,id)
	print("=====================account 接受到了后台协议",guid,id)
	if id == 1 then 
		local msg_data = {
			list = nil,
		}
		msg_data.list = CMD.cleckBackText(guid)
		local loginmgr = skynet.uniqueservice("loginmgr")
		local ret = skynet.call(loginmgr,"lua","get_agent_by_guid",guid)
		if not next(ret) then 
			print("当前玩家不在线，无法发送消息")
			return false
		end 
		local gateid_ = ret.gateid
		local fd_ = ret.fd
		local name = "SC_NotifyCustomerServer"
		skynet.send(gateid_,"lua","send2c",fd_,name,msg_data)
		print("消息发送出去了 ",gateid_,fd_)
		return true 
	elseif id == 2 then 
		--跑马灯及公告
		print("给所有在线玩家发送更新的公告列表")
		marqueeDataList = nil
		marqueeDataList= CMD.getMarqueeData()
		local msg = {
			pb_msg_data = nil,
		}
		msg.pb_msg_data = marqueeDataList
		msg.Time = tostring(os.time())
		local name = "SC_QueryPlayerMarquee"
		local ret = CMD.allagentsMsg(name,msg)
	elseif id == 3 then 
		--消息系统
		local msg_data = {
			list = nil,
		}
		msg_data.list = CMD.getMsgData(guid)
		
		local loginmgr = skynet.uniqueservice("loginmgr")
		local ret = skynet.call(loginmgr,"lua","get_agent_by_guid",guid)
		if not next(ret) then 
			print("当前玩家不在线，无法发送消息")
			return false
		end 
		local gateid = ret.gateid
		local fd = ret.fd
		local name = "SC_NotifyMsgData"
		skynet.send(gateid,"lua","send2c",fd,name,msg_data)
		print("消息发送出去了 ",gateid_,fd_)
	end 
	return true
end

--获取跑马灯及公告内容 按照最新时间往前查询最多20条
function CMD.getMarqueeData()
	
	if not marqueeDataList then 
		local Time = os.date("%c")
		--local sql = string.format("select * from t_notice where  `end_time` >= '%s'",Time);
		local sql = string.format("select * from t_notice");
		local ret = db:query(sql);
		if (ret.errno ~= nil) then
			print("sql exec err: " .. sql)
			return nil
		end
		marqueeDataList = ret
	end 
	return marqueeDataList
end 
--通过账号查找用户
function CMD.select_acc_by_phone(phone)
	local sql = string.format("select * from t_account where account = '%s'",phone)
	local ret = db:query(sql)
	if (ret.errno ~= nil) then
        print("sql exec err: " .. sql)
        return nil
	end
	return ret 
end
--设置公告状态 屏蔽
--[[
function CMD.noticeStatus(id)
	local sql = string.format("UPDATE t_notice SET is_read=%d WHERE id=%s;",1,id);
	local ret = db:query(sql);
	return true
end
]]

--获取消息
function CMD.getMsgData(guid)
	local sql = string.format("select * from t_notice_private where guid = '%s' ORDER BY created_time DESC LIMIT 50 ", guid);
	local ret = db:query(sql);
	if (ret.errno ~= nil) then
		print("sql exec err: " .. sql)
		return nil
	end
	return ret
end

--更改消息状态 
function CMD.updateMsgStatus(id)
	local sql = string.format("UPDATE t_notice_private SET is_read=%d WHERE id=%s;",1,id);
	local ret = db:query(sql);
	return true
end
--删除消息 
function CMD.deleteMsg(id,guid)
	if id == -1 then
		local sql = string.format("DELETE FROM t_notice_private WHERE guid=%s;",guid);
		local ret = db:query(sql);
		return true
	end 
	local sql = string.format("DELETE FROM t_notice_private WHERE id=%s;",id);
	local ret = db:query(sql);
	return true
end
--添加消息
function CMD.insertMsg(msg)
	local sql = string.format("insert into t_notice_private(guid,type,name,content) values('%d','%d','%s','%s')",msg.guid,msg.type,msg.name,msg.content)
	local ret = db:query(sql);
	if ret.errno then
		print("======== insertMsg =========error=======")
		return false
	end
	return true
end
function CMD.show_num(guid,name_)
	local sql = string.format("select * from %s where guid = '%d'",name_,guid)
	local ret = db:query(sql);
	if ret.errno then
		print("======== show_num =========error=======",sql)
		return nil
	end
	return ret
end
function CMD.count_money_time(guid)
	local sql = string.format("select SUM(withdraw_amount) money from t_with_draw where guid = '%d' and created_at >= '%s'",guid, os.date("%Y-%m-%d", os.time()))
	local ret = db:query(sql);
	if ret.errno then
		print("======== show_num =========error=======")
		return nil
	end
	return ret
end
function CMD.c_time_conert(guid)
	local sql = string.format("SELECT created_at FROM t_recharge_order WHERE guid = '%d' ORDER BY created_at DESC LIMIT 1",guid)
	local ret = db:query(sql)
	if ret.errno then
		print("======== show_num =========error=======")
		return nil
	end
	if ret and next(ret) then
		local logdb = skynet.uniqueservice("logservice")
		local count_game = skynet.call(logdb,"lua","count_game_log",ret[1].created_at,guid)
		if count_game and next(count_game) then
			return count_game
		end
	end
	return nil
end

function CMD.start(conf)
	local function on_connect(db)
		db:query("set charset utf8");
	end
	db=mysql.connect({
		host=conf.ip,
		port=conf.port,
		database=conf.database,
		user=conf.user,
		password=conf.password,
		max_packet_size = 1024 * 1024,
		on_connect = on_connect
	})

	if not db then
		print("failed to connect")
	end
	
end
skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd,  ...)
	
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f( ...)))
		
	end)

end)


