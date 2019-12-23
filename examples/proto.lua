local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

handshake 1 {
	response {
		msg 0  : string
	}
}

heartbeat 2 {}

get 3 {
	request {
		what 0 : string
	}
	response {
		result 0 : string
	}
}

set 4 {
	request {
		what 0 : string
		value 1 : string
	}
}

quit 5 {}

ping 6 {
	response {
		msg 0  : string
	}
}

helloworld 7 {
	response {
		msg 0  : string
	}
}

hall 8 {
	response {
		msg 0  : string
	}
}
]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

heartbeat 1 {}

handshake 2 {
	request {
		msg 0  : string
	}
}

]]

return proto
