package.cpath = "luaclib/?.so"

local socket = require "client.socket"
local cjson = require "cjson"

local fd = socket.connect("127.0.0.1", 8888)

local last
local result = {}

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"
	end
	return unpack_package(last .. r)
end


local function dispatch()
	while true do
		local status
		-- status, last = socket.recv(fd, last, result)
		print("dispatch",last)
		status, last = recv_package(last)
		if status == nil then
			error "Server closed"
		end
		if not status then
			break
		end
		for _, v in ipairs(result) do
			local session,t,str = string.match(v, "(%d+)(.)(.*)")
			assert(t == '-' or t == '+')
			session = tonumber(session)
			local result = cjson.decode(str)
			print("Response:",session, result[1], result[2])
		end
	end
end

local session = 0

local function send_request(v)
	session = session + 1
	local str = string.format("%d+%s",session, cjson.encode(v))
	socket.send(fd, str)
	print("Request:", session)
end

while true do
	dispatch()
	local cmd = socket.readline()
	if cmd then
		local args = {}
		string.gsub(cmd, '[^ ]+', function(v) table.insert(args, v) end )
		send_request(args)
	else
		socket.usleep(100)
	end
end