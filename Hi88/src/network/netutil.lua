local protobuf = require "protobuf"
local protohelper = require "proto.protohelper"
local clientsocket = require "clientsocket"

local netutil = {}
local msghandlers = {}

function netutil.register(msgname, handler)
	msghandlers[msgname] = handler
end

function netutil.unregister(msgname)
	msghandlers[msgname] = nil
end

function netutil.connect(ip, port)
	local fd = clientsocket.connect(ip, port)
	if fd <= 0 then
		return false
	end
	return true
end

function netutil.send(msgname, msg)
	local pbtype = protohelper.gettype(msgname)
	if pbtype == nil then
		print("[ERR]no such proto:" ..msgname)
		return
	end
	local pbdata = protobuf.encode(msgname, msg)
	if pbdata == nil then
		print("[ERR]pbc encode fail:" ..msgname)
		return
	end
	-- pbdata is c string type
	clientsocket.send(pbtype, pbdata)
end

local function recvmsg()
	local msgname, msg
	local pbtype, pbdata, pbsize = clientsocket.recv()
	if pbtype and pbdata and pbsize > 0 then
		msgname = protohelper.getname(pbtype)
		msg = protobuf.decode(msgname, pbdata, pbsize)
	end
	return msgname, msg
end

local function tick()
	local msgname, msg = recvmsg()
	if msgname and msg then
		local handler = msghandlers[msgname]
		if handler then
			handler(msg)
		end
	end
end

local scheduler = cc.Director:getInstance():getScheduler()
local schedulerID = scheduler:scheduleScriptFunc(tick, 0, false)

return netutil
