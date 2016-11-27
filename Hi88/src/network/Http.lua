require ("json")

local function isModuleAvailable(name)
    if package.loaded[name] then
        return true
    else
        for _, searcher in ipairs(package.searchers or package.loaders) do
            local loader = searcher(name)
            if type(loader) == 'function' then
                package.preload[name] = loader
                return true
            end
        end
        return false
    end
end
local zlib = nil
local json = json
local md5 = nil
if isModuleAvailable("zlib") then
    zlib = require("zlib")
    local test_string = "Hello World"
    local deflated = zlib.deflate()(test_string, "finish")
    local inflated = zlib.inflate()(deflated, "finish")
    if test_string==inflated then
        print("zlib worked!")
    end
end
cjson = json
if isModuleAvailable("cjson") then
    cjson = require("cjson")
    print("cjson worked!")
end

if isModuleAvailable("md5.core") then
    md5 = require("md5.core")
    print(md5.sum("chrisli"))
    print("md5 worked!")
end

-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
local function base64encode(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
local function base64decode(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local function MD5(data)
    if md5 then
        local function sumhexa (k)
            print("md5_pre_str:"..k)
            k = md5.sum(k)
            return (string.gsub(k, ".", function (c)
                return string.format("%02x", string.byte(c))
            end))
        end
        return sumhexa(json.encode(data).."angelababy")
    end
    return nil
end

local CMDMap = require "network.CMDMap"
--LOAD_DLG = (require "common.LoadingDialog"):create()
--LOAD_DLG:retain()
--TIP_DLG = (require "common.PopDialog")
g_timeoutDilog = {}
g_HttpCmd = ""
g_HttpData = {}
g_HttpCallback = {}

local HttpClass = class("Http")
--local URL = "http://192.168.16.128:12002/lsl"
local URL = "http://115.231.81.10:12002/lsl"
local TOKEN_KEY = "0x0"


function HttpClass:setServerUrl(url)
    URL = url
end

--------------------------------------------------------------------
--- function: Http:req
--- params: cmd         string
--- params: data        {}
--- params: callback    function
--------------------------------------------------------------------
function HttpClass:req(cmd, data, ntfCallback)
    assert(type(cmd) == "string", "[Http] cmd invalid")
    assert(type(data) == "table" or data==nil, "[Http] data invalid")
    assert(type(ntfCallback) == "function", "[Http] callback invalid")
    g_HttpCmd = cmd
    g_HttpData = data
    g_HttpCallback = ntfCallback
    
    local cmdId = CMDMap[cmd].cmdId
    local cmdHandler = CMDMap[cmd].cmdHandler
    
    assert(cmdId ~= nil and cmdHandler~=nil, "[Http]no cmdId in CMDMap table for this cmd")
    
    --if data == nil or data == {} then data = "" end
    local httpContent = {key=TOKEN_KEY, cmd=cmdId, data=data}
    
    local http = cc.XMLHttpRequest:new()
    
    local function httpCallback()
        local result = {}
        local responseStr = http.response
        
        --local responseStr = zlib.inflate()(responseStr, "finish")
        cclog("--[Http_Recv]--"..responseStr)
        --LOAD_DLG:stop()
        if responseStr == nil or responseStr == "" then
            result.err = 1
            --TIP_DLG:getInstance():popText("网络超时")
            --g_timeoutDilog = require("common.ClickDialog"):create({name="重新发送", tip="网络连接超时", cb=function()
                --cc.Director:getInstance():getRunningScene():removeChild(g_timeoutDilog) 
                --Http:req(g_HttpCmd, g_HttpData, g_HttpCallback)
            --end})
            g_timeoutDilog:setLocalZOrder(10000)
            cc.Director:getInstance():getRunningScene():addChild(g_timeoutDilog)
            return
        end
        
        local responseData = cjson.decode(responseStr)
        
        if responseData==nil or responseData=={} then
            --TIP_DLG:getInstance():popText("网络数据错误")
            return
        end
        
        --when cmd is Login, get the token key, which is used to be client ID for sever
        if cmd == "Login" then TOKEN_KEY = responseData.key end
        
        if responseData.err ~= nil and responseData.err ~=0 then
            result.err = responseData.err
            --TIP_DLG:getInstance():popText(result.err)
        else
            --[[
            if md5 then
                if responseData.reqid and MD5(responseData.data) ~= responseData.reqid then
                    TIP_DLG:getInstance():popText("网络数据被修改!!")
                    return
                end
            end
            ]]
            cmdHandler(responseData.data)
            result.data = responseData.data
        end
        
        if result.data ~= nil then
            ntfCallback(result)
        end
        --push
        if  responseData.push  ~= nil then
            local Roler = require "data.Roler"
            Roler:setData(responseData.push)
        end
    end
    
    http.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    http:open("POST", URL)
    http:registerScriptHandler(httpCallback)
    --[[
    if md5 then
        local function sumhexa (k)
            k = md5.sum(k)
            return (string.gsub(k, ".", function (c)
                return string.format("%02x", string.byte(c))
            end))
        end
        local md5Str = sumhexa(json.encode(httpContent.data).."angelababy")
        httpContent.reqid = md5Str
    end]]
    httpContent.reqid = MD5(httpContent.data)
    local jsonStr = json.encode(httpContent)
    cclog("--[Http_Send]--"..jsonStr)
    g_tmpJsonStr = jsonStr
    http:send(jsonStr)
    --LOAD_DLG:start()
end

Http = HttpClass.new()

