local protobuf = require "protobuf"
local protohelper = require "proto.protohelper"
local clientsocket = require "clientsocket"
local cjson = require "cjson"

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

netutil = {}
local msghandlers = {}
local scheduleId = nil
local statusCallback = {}

function netutil.register(msgname, handler)
	msghandlers[msgname] = handler
end

function netutil.unregister(msgname)
	msghandlers[msgname] = nil
end

function netutil.onConnectSuccess(cb)
    statusCallback.onConnectSuccess = cb
end

function netutil.onDisconnect(cb)
    statusCallback.onDisconnect = cb
end

function netutil.onConnectFail(cb)
    statusCallback.onConnectFail = cb
end

local function dump(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("    ", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end

function netutil.connect(ip, port)
	local ret = clientsocket.connect(ip, port)
	if ret < 0 then
		return false
	end
    if scheduleId == nil then
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
            if connectstatus == STATUS_CONNECT_OK then
                if statusCallback.onConnectSuccess then
                    statusCallback.onConnectSuccess()
                    statusCallback.onConnectSuccess = nil
                end
            elseif connectstatus == STATUS_CONNECT_FAIL then
                if statusCallback.onConnectFail then
                    statusCallback.onConnectFail()
                    statusCallback.onConnectFail = nil
                end
            elseif connectstatus == STATUS_DISCONNECT then
                if statusCallback.onDisconnect then
                    statusCallback.onDisconnect()
                    statusCallback.onDisconnect = nil
                end
            end
            
            if connectstatus ~= STATUS_CONNECT_OK then return end
            -- receive message
            while true do
                local msgname, msg = recvmsg()
                if msgname and msg then
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
        scheduleId = scheduler:scheduleScriptFunc(tick, MSG_TICK_TIME, false)
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

return netutil
