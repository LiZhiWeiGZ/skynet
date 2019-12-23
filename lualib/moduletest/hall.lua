
if not cplayer then
	cplayer = {}
end

function cplayer:hall()
	return {msg = "this is hall"}
end

function cplayer:handshake()
	return {msg = "handshake success"}
end

return cplayer