local skynet = require "skynet"
local socket = require "skynet.socket"
-- local cjson = require "cjson"
local netpack = require "skynet.netpack"
local jsonpack = require "jsonpack"

local CMD = {}

local client_fd
local WATCHDOG

local function send_client(v)
	skynet.error("send_client")
	socket.write(client_fd, netpack.pack(jsonpack.pack(0, {true, v})))
end

local function response_client(session,v)
	socket.write(client_fd, netpack.pack(jsonpack.response(session,v)))
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return jsonpack.unpack(skynet.tostring(msg,sz))
	end,
	dispatch = function (_, _, session, args)
		local ok, result = pcall(skynet.call,"SIMPLEDB", "lua", table.unpack(args))
		if ok then
			response_client(session, { true, result })
		else
			response_client(session, { false, "Invalid command" })
		end
	end
}

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	skynet.fork(function()
		while true do
			skynet.error("heartbeat")
			send_client "heartbeat"
			-- send_package(send_request "heartbeat")
			skynet.sleep(500)
		end
	end)

	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
