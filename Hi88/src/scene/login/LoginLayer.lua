--LoginLayer.lua, created by php script. chris.li--
local netutil = require("netutil")

local LoginLayer = class("LoginLayer", function()
	return cc.Layer:create()
end)

function LoginLayer:create()
	local layer = LoginLayer.new()
	layer:initM()
	return layer
end

function LoginLayer:ctor()
end

function LoginLayer:onEnter()
end

function LoginLayer:onExit()
end

function LoginLayer:initM()
	local function onNodeEvent(event)
		if event == "enter" then self:onEnter() 
		elseif event == "exit" then self:onExit() end
	end
	self:registerScriptHandler(onNodeEvent)

	self.rootNode = ccs.GUIReader:getInstance():widgetFromBinaryFile("LoginLayer.csb")
	self:addChild(self.rootNode)

	local function touchEventHandler(sender, event)
		self:handleTouchEvent(sender, event)
	end

	--m_loginBtn: Button
	self.m_loginBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_loginBtn")
	self.m_loginBtn:addTouchEventListener(touchEventHandler)

	self:initUI()
	

	
end

function LoginLayer:handleTouchEvent(sender, event)
	if sender == nil then
		cclog("[ERR]unknown sender")

	elseif sender == self.m_loginBtn and event == cc.EventCode.ENDED then
		cclog("[LoginLayer]--m_loginBtn touched--")
        -- connect network
        local ret = netutil.connect("172.16.8.72", 8888)
        if ret == false then
            cclog("connect server fail")
            return
        end
        netutil.onConnectSuccess(function()
            self:loginGameServer()
        end)
	end
end

function LoginLayer:loginGameServer()
    netutil.send("gameLogin", {userId="chris1", authCode="123456", version = 1})
    netutil.register("gameLogin_ack", function(msg)
        if msg.errno == 1000 then
            local userData = require("userData")
            userData:setUserInfo(msg.userInfo)
            local scene = require("scene.home.HomeScene"):create()
            cc.Director:getInstance():replaceScene(scene)
        end
    end)
end


--init your ui here
function LoginLayer:initUI()
end

--refresh all ui here
function LoginLayer:refreshUI()
end

return LoginLayer
