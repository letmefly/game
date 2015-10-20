local protobuf = require "protobuf"
local protohelper = require "proto.protohelper"
local clientsocket = require "clientsocket"


local netutil = {}

function netutil.send(msgname, msg)
	local pbctype = protohelper.gettype(msgname)
	if pbctype == nil then
		print("[ERR]no such proto:" ..msgname)
		return
	end
	local pbcdata = protobuf.encode(msgname, msg)
	if pbcdata == nil then
		print("[ERR]pbc encode fail:" ..msgname)
		return
	end
	-- pbcdata is c string type
	clientsocket.send(pbctype, pbcdata)
end

function netutil.pbencode(msgname, msg)
	local msgtype = protohelper.gettype(msgname)
	local msgdata = protobuf.encode(msgname, msg)
	local buff, size = netpack.packpbc(msgtype, msgdata)
	return buff, size
end

function netutil.pbdecode(msgbuff, buffsize)
	local msgtype, buff, size = netpack.unpackpbc(msgbuff, buffsize)
	local msgname = protohelper.getname(msgtype)
	local msg = protobuf.decode(msgname, buff, size)
	return msgname, msg
end

return netutil
