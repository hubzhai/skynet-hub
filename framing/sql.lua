local skynet = require "skynet"
local statement = require "gamepublic/statement"
local sql ={}

local m_statement = {}

m_statement["getallacc"] = statement.New("select * from t_account")

function sql.GetStatement(skey )
	if m_statement[skey] then
		return m_statement[skey]
	end
end

return sql