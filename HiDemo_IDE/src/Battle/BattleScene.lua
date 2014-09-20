require "Cocos2d"

local DEBUGDRAW_SHAPE   = 0x01
local DEBUGDRAW_JOINT   = 0x02
local DEBUGDRAW_CONTACT = 0x04
local DEBUGDRAW_ALL     = 0x07

local BattleScene = class("BattleScene",function() 
    local scene = cc.Scene:createWithPhysics()
    return scene
end)

function BattleScene:create()
    local scene = BattleScene.new()
    scene:initM()
    return scene
end

function BattleScene:ctor()
end

function BattleScene:initM()
    self:getPhysicsWorld():setDebugDrawMask(DEBUGDRAW_ALL)
    self:getPhysicsWorld():setGravity(cc.p(0, 0))
    --self:getPhysicsWorld():setCollisionBitmask(1)
    
    self.counter = 0
    
    self.bgLayer = require("Battle.BgLayer"):create()
    self:addChild(self.bgLayer)
    
    self.heroLayer = require("Battle.HeroLayer"):create()
    self:addChild(self.heroLayer)
    
    local function scheduleUpdate(dt)
        self:updateM(dt)
    end
    --self:scheduleUpdateWithPriorityLua(scheduleUpdate, 1)
end

function BattleScene:updateM(dt)
    self.counter = self.counter + 1
    if self.counter % (60*2) == 0 then
        cclog("updateM %d", self.counter)
    end
    self.bgLayer:updateM(dt)
end

return BattleScene
