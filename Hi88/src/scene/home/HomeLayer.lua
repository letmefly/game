local userData = require("userData")

--HomeLayer.lua, created by php script. chris.li--
local HomeLayer = class("HomeLayer", function()
	return cc.Layer:create()
end)

function HomeLayer:create()
	local layer = HomeLayer.new()
	layer:initM()
	return layer
end

function HomeLayer:ctor()
end

function HomeLayer:onEnter()
end

function HomeLayer:onExit()
end

function HomeLayer:initM()
	local function onNodeEvent(event)
		if event == "enter" then self:onEnter() 
		elseif event == "exit" then self:onExit() end
	end
	self:registerScriptHandler(onNodeEvent)

	self.rootNode = ccs.GUIReader:getInstance():widgetFromBinaryFile("HomeLayer.csb")
	self:addChild(self.rootNode)

	local function touchEventHandler(sender, event)
		self:handleTouchEvent(sender, event)
	end

	--m_userName: Text
	self.m_userName = ccui.Helper:seekWidgetByName(self.rootNode, "m_userName")

	--m_roomCardNum: Text
	self.m_roomCardNum = ccui.Helper:seekWidgetByName(self.rootNode, "m_roomCardNum")

	--m_addRoomCardBtn: Button
	self.m_addRoomCardBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_addRoomCardBtn")
	self.m_addRoomCardBtn:addTouchEventListener(touchEventHandler)

	--m_headIconBtn: Button
	self.m_headIconBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_headIconBtn")
	self.m_headIconBtn:addTouchEventListener(touchEventHandler)

	--m_seeCombatRecordBtn: Button
	self.m_seeCombatRecordBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_seeCombatRecordBtn")
	self.m_seeCombatRecordBtn:addTouchEventListener(touchEventHandler)

	--m_questionAskBtn: Button
	self.m_questionAskBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_questionAskBtn")
	self.m_questionAskBtn:addTouchEventListener(touchEventHandler)

	--m_shareFriendBtn: Button
	self.m_shareFriendBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_shareFriendBtn")
	self.m_shareFriendBtn:addTouchEventListener(touchEventHandler)

	--m_activityBtn: Button
	self.m_activityBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_activityBtn")
	self.m_activityBtn:addTouchEventListener(touchEventHandler)

	--m_gameRuleBtn: Button
	self.m_gameRuleBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_gameRuleBtn")
	self.m_gameRuleBtn:addTouchEventListener(touchEventHandler)

	--m_authBtn: Button
	self.m_authBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_authBtn")
	self.m_authBtn:addTouchEventListener(touchEventHandler)

	--m_createRoomBtn: Button
	self.m_createRoomBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_createRoomBtn")
	self.m_createRoomBtn:addTouchEventListener(touchEventHandler)

	--m_joinRoomBtn: Button
	self.m_joinRoomBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_joinRoomBtn")
	self.m_joinRoomBtn:addTouchEventListener(touchEventHandler)

	--m_settingBtn: Button
	self.m_settingBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_settingBtn")
	self.m_settingBtn:addTouchEventListener(touchEventHandler)

	--m_msgBtn: Button
	self.m_msgBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_msgBtn")
	self.m_msgBtn:addTouchEventListener(touchEventHandler)

	--m_msgTip: Text
	self.m_msgTip = ccui.Helper:seekWidgetByName(self.rootNode, "m_msgTip")

	self:initUI()
end

function HomeLayer:handleTouchEvent(sender, event)
	if sender == nil then
		cclog("[ERR]unknown sender")

	elseif sender == self.m_addRoomCardBtn and event == cc.EventCode.ENDED then
		cclog("[HomeLayer]--m_addRoomCardBtn touched--")

	elseif sender == self.m_headIconBtn and event == cc.EventCode.ENDED then
		cclog("[HomeLayer]--m_headIconBtn touched--")

	elseif sender == self.m_seeCombatRecordBtn and event == cc.EventCode.ENDED then
		cclog("[HomeLayer]--m_seeCombatRecordBtn touched--")

	elseif sender == self.m_questionAskBtn and event == cc.EventCode.ENDED then
		cclog("[HomeLayer]--m_questionAskBtn touched--")

	elseif sender == self.m_shareFriendBtn and event == cc.EventCode.ENDED then
		cclog("[HomeLayer]--m_shareFriendBtn touched--")

	elseif sender == self.m_activityBtn and event == cc.EventCode.ENDED then
		cclog("[HomeLayer]--m_activityBtn touched--")

	elseif sender == self.m_gameRuleBtn and event == cc.EventCode.ENDED then
		cclog("[HomeLayer]--m_gameRuleBtn touched--")

	elseif sender == self.m_authBtn and event == cc.EventCode.ENDED then
		cclog("[HomeLayer]--m_authBtn touched--")

	elseif sender == self.m_createRoomBtn and event == cc.EventCode.ENDED then
		cclog("[HomeLayer]--m_createRoomBtn touched--")
		self:createRoom(1)

	elseif sender == self.m_joinRoomBtn and event == cc.EventCode.ENDED then
		cclog("[HomeLayer]--m_joinRoomBtn touched--")

	elseif sender == self.m_settingBtn and event == cc.EventCode.ENDED then
		cclog("[HomeLayer]--m_settingBtn touched--")

	elseif sender == self.m_msgBtn and event == cc.EventCode.ENDED then
		cclog("[HomeLayer]--m_msgBtn touched--")

	end
end

--init your ui here
function HomeLayer:initUI()
    local userInfo = userData:getUserInfo()
    self.m_userName:setString(userInfo.nickname)
    self.m_roomCardNum:setString(userInfo.roomCardNum.."")
end

function HomeLayer:createRoom(rootType)
    netutil.send("createRoom", {roomType = rootType})
    netutil.register("createRoom_ack", function(msg)
        if msg.errno == 1000 then
            cclog("roomNo "..msg.roomNo)
            self:joinRoom(msg.roomNo)
        end
    end)
end

function HomeLayer:joinRoom(roomNo)
    netutil.send("joinRoom", {roomNo = roomNo})
    netutil.register("joinRoom_ack", function(msg)
        if msg.errno == 1000 then
            cclog("playerId "..msg.playerId)
            userData:set("playerId", msg.playerId)
            local scene = require("scene.game.GameScene"):create()
            cc.Director:getInstance():replaceScene(scene)
        end
    end)
end

--refresh all ui here
function HomeLayer:refreshUI()
end

return HomeLayer
