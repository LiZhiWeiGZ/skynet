local skynet = require "skynet"
local queue = require "skynet.queue"
local socket = require "skynet.socket"
local snax = require "skynet.snax"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local cplayer = require "moduletest.cplayer"
local hall= require "moduletest.hall"

local modules = {
	require "moduletest.cplayer",
	require "moduletest.hall"
}

local i = 0
local hello = "hello client"

local WATCHDOG
local host
local send_request
local client_fd

-- response.sleep and accept.hello share one lock
local lock
-- local cplayer = {}
cplayer = {}
local c2sMap = {}

function c2sMap:ping()
	-- skynet.sleep(100)
	skynet.error("ping-----------")
	return {msg = "hello client"}
end

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

local function sendMsg(path, ... )
	-- body
	send_package(send_request (path,...))
end

local function moduleInit()
	-- body
	for _,module in ipairs(modules)do
		for k,v in pairs(module) do
			c2sMap[k] = v
		end
	end
end

function accept.sleep(queue, n)
	if queue then
		lock(
		function()
			print("queue=",queue, n)
			skynet.sleep(n)
		end)
	else
		print("queue=",queue, n)
		skynet.sleep(n)
	end
end

function accept.send2client( ... )
	-- body
	sendMsg(...)
end

function accept.hello()
	lock(function()
	i = i + 1
	print (i, hello)
	end)
end

function accept.exit(...)
	snax.exit(...)
end

function response.error()
	error "throw an error"
end

local function c2sDispatch(name, args, response)
	-- 请求方法、函数分发
	-- skynet.error("request-----------%s",c2sMap[name])
	local f = assert(c2sMap[name])
	local r = f(args)
	-- skynet.error("request-----------%s",r)
	-- if response then
	-- 	skynet.error("response-----------")
	-- 	return response(r)
	-- end
end

function init( ... )
	print ("ping server start:", ...)
	snax.enablecluster()	-- enable cluster call
	-- init queue
	lock = queue()
	moduleInit()

	skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = function (msg, sz)
			return host:dispatch(msg, sz)
		end,
		dispatch = function (fd, _, type, ...)
			assert(fd == client_fd)	-- You can use fd to reply message
			skynet.ignoreret()	-- session is fd, don't call skynet.ret
			skynet.trace()
			if type == "REQUEST" then
				-- skynet.error("REQUEST-----------")
				local ok, result  = pcall(c2sDispatch, ...)
				if ok then
					if result then
						send_package(result)
					end
				else
					skynet.error(result)
				end
			else
				assert(type == "RESPONSE")
				error "This example doesn't support request client"
			end
		end
	}
end

function accept.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- slot 1,2 set at main.lua
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	-- skynet.fork(function()
	-- 	while true do
	-- 		send_package(send_request ("heartbeat"))
	-- 		skynet.sleep(500)
	-- 		skynet.error("heartbeat")
	-- 	end
	-- end)

	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end

function exit(...)
	print ("ping server exit:", ...)
end
