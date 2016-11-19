local protoparser = require "protoparser"
-- preload, execute one time
protoparser.load("proto.prototext")

local protohelper = {}

local type2name = PROTO_TYPE2NAME

local name2type = {}
for k, v in pairs(type2name) do
	name2type[v] = k
end
function protohelper.getname(type)
	return type2name[type]
end

function protohelper.gettype(name)
	return name2type[name]
end

return protohelper
