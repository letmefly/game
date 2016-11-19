local protobuf = require "protobuf"
local protohelper = require "proto.protohelper"
local clientsocket = require "clientsocket"

local MSG_TICK_TIME = 1.0/30

-- connect status value
-- enum connect_status {
--     STATUS_NOT_CONNECT,
--     STATUS_CONNECTING,
--     STATUS_CONNECT_OK,
--     STATUS_CONNECT_FAIL,
--     STATUS_DISCONNECT
-- };
local STATUS_NOT_CONNECT = 0
local STATUS_CONNECTING = 1
local STATUS_CONNECT_OK = 2
local STATUS_CONNECT_FAIL = 3
local STATUS_DISCONNECT = 4
local connectstatus = STATUS_NOT_CONNECT

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
	if connectstatus ~= STATUS_CONNECT_OK then return end
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
	connectstatus = clientsocket.connectstatus()
	if connectstatus ~= STATUS_CONNECT_OK then return end
	-- receive message
	while true do
		local msgname, msg = recvmsg()
		if msgname and msg then
			print (msgname)
			local handler = msghandlers[msgname]
			if handler then
				handler(msg)
			end
		else
			break;
		end
	end
end

local scheduler = cc.Director:getInstance():getScheduler()
local schedulerID = scheduler:scheduleScriptFunc(tick, MSG_TICK_TIME, false)
print ("--require netutil--")
return netutil
