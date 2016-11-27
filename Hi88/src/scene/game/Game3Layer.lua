--Game3Layer.lua, created by php script. chris.li--

local Game3Layer = class("Game3Layer", function()
    return cc.Layer:create()
end)

function Game3Layer:create()
    local layer = Game3Layer.new()
    layer:initM()
    return layer
end

function Game3Layer:ctor()
end

function Game3Layer:onEnter()
end

function Game3Layer:onExit()
end

function Game3Layer:initM()
    local function onNodeEvent(event)
        if event == "enter" then self:onEnter() 
        elseif event == "exit" then self:onExit() end
    end
    self:registerScriptHandler(onNodeEvent)

    self.rootNode = ccs.GUIReader:getInstance():widgetFromBinaryFile("Game3Layer.csb")
    self:addChild(self.rootNode)

    local function touchEventHandler(sender, event)
        self:handleTouchEvent(sender, event)
    end

    --m_roomNum: Text
    self.m_roomNum = ccui.Helper:seekWidgetByName(self.rootNode, "m_roomNum")

    --m_settingBtn: Button
    self.m_settingBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_settingBtn")
    self.m_settingBtn:addTouchEventListener(touchEventHandler)

    --m_deleteRoomBtn: Button
    self.m_deleteRoomBtn = ccui.Helper:seekWidgetByName(self.rootNode, "m_deleteRoomBtn")
    self.m_deleteRoomBtn:addTouchEventListener(touchEventHandler)

    --m_currPlayCount: Text
    self.m_currPlayCount = ccui.Helper:seekWidgetByName(self.rootNode, "m_currPlayCount")

    --m_jiaoFenImg: ImageView
    self.m_jiaoFenImg = ccui.Helper:seekWidgetByName(self.rootNode, "m_jiaoFenImg")

    --m_gameLevel: LabelBMFont
    self.m_gameLevel = ccui.Helper:seekWidgetByName(self.rootNode, "m_gameLevel")

    --m_maxBoom: LabelBMFont
    self.m_maxBoom = ccui.Helper:seekWidgetByName(self.rootNode, "m_maxBoom")

    --m_headIcon_1: ImageView
    self.m_headIcon_1 = ccui.Helper:seekWidgetByName(self.rootNode, "m_headIcon_1")

    --m_userName_1: Text
    self.m_userName_1 = ccui.Helper:seekWidgetByName(self.rootNode, "m_userName_1")

    --m_headIcon_2: ImageView
    self.m_headIcon_2 = ccui.Helper:seekWidgetByName(self.rootNode, "m_headIcon_2")

    --m_userName_2: Text
    self.m_userName_2 = ccui.Helper:seekWidgetByName(self.rootNode, "m_userName_2")

    --m_headIcon_3: ImageView
    self.m_headIcon_3 = ccui.Helper:seekWidgetByName(self.rootNode, "m_headIcon_3")

    --m_userName_3: Text
    self.m_userName_3 = ccui.Helper:seekWidgetByName(self.rootNode, "m_userName_3")

    self:initUI()
end

function Game3Layer:handleTouchEvent(sender, event)
    if sender == nil then
        cclog("[ERR]unknown sender")

    elseif sender == self.m_settingBtn and event == cc.EventCode.ENDED then
        cclog("[Game3Layer]--m_settingBtn touched--")

    elseif sender == self.m_deleteRoomBtn and event == cc.EventCode.ENDED then
        cclog("[Game3Layer]--m_deleteRoomBtn touched--")

    end
end

--init your ui here
function Game3Layer:initUI()
end

--refresh all ui here
function Game3Layer:refreshUI()
end

return Game3Layer
