require "Cocos2d"

local MATERIAL_DEFAULT = cc.PhysicsMaterial(0.1, 0.5, 0.5)

local HeroLayer = class("HeroLayer", function() 
    return cc.Layer:create()
end)

function HeroLayer:create()
    local heroLayer = HeroLayer.new()
    heroLayer:initM()
    return heroLayer
end

function HeroLayer:ctor()
end

function HeroLayer:initM()    
    self.testSprite1 = cc.Sprite:create("dog.png")
    self.testSprite1:setPosition(100, 100)
    self.testSprite1:setPhysicsBody(cc.PhysicsBody:createCircle(50, cc.PhysicsMaterial(0.1, 1, 0.0)))
    self.testSprite1:getPhysicsBody():setMass(1.0)
    self.testSprite1:getPhysicsBody():setMoment(0x1e50f)
    self.testSprite1:getPhysicsBody():setCategoryBitmask(1)    -- 0001
    self.testSprite1:getPhysicsBody():setContactTestBitmask(0xffff) -- 0100
    self.testSprite1:getPhysicsBody():setCollisionBitmask(0xffff)  -- 0011
 
    local velocity = cc.p((math.random() - 0.5)*200, (math.random() - 0.5)*1000)
    self.testSprite1:getPhysicsBody():setVelocity(velocity)
    self:addChild(self.testSprite1)
    
    self.testSprite2 = cc.Sprite:create("dog.png")
    self.testSprite2:setPosition(400, 100)
    self.testSprite2:setPhysicsBody(cc.PhysicsBody:createCircle(50, cc.PhysicsMaterial(0.1, 1, 0.0)))
    self.testSprite2:getPhysicsBody():setMass(1.0)
    self.testSprite2:getPhysicsBody():setMoment(0x1e50f)
    self.testSprite2:getPhysicsBody():setVelocity(velocity)
    self.testSprite2:getPhysicsBody():setVelocity(velocity)
    self.testSprite2:getPhysicsBody():setCategoryBitmask(2)    -- 0010
    self.testSprite2:getPhysicsBody():setContactTestBitmask(0xffff) -- 0010
    self.testSprite2:getPhysicsBody():setCollisionBitmask(0xffff)  -- 0010
    self:addChild(self.testSprite2)
    
    local wall = cc.Node:create()
    wall:setAnchorPoint(0.5, 0.5)
    wall:setPhysicsBody(cc.PhysicsBody:createEdgeBox(cc.size(480,320), cc.PhysicsMaterial(0.1, 1, 0.0)))
    wall:setPosition(cc.p(240, 160))
    wall:getPhysicsBody():setCategoryBitmask(4)    -- 0010
    wall:getPhysicsBody():setContactTestBitmask(0xffff) -- 0001
    wall:getPhysicsBody():setCollisionBitmask(0xffff)  -- 0001
    self:addChild(wall)
    
    --Add Collide Listener
    local function onContactBegin(contact)
        --cclog("onContactBegin!!!")
        return true;
    end
    
    local function onContackEnd(contact)
        cclog("onContackEnd!!!")
    end
    
    local contactListener = cc.EventListenerPhysicsContact:create()
    contactListener:registerScriptHandler(onContactBegin, cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)
    --contactListener:registerScriptHandler(onContackEnd, cc.Handler.EVENT_PHYSICS_CONTACT_POSTSOLVE)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(contactListener, 1)
    
    --Add Touch Event Listener
    local function onTouchBegan(touch, event)
        return true
    end

    local function onTouchEnded(touch, event)

        local location = touch:getLocation()

        local s = self.testSprite1
        s:stopAllActions()
        s:runAction(cc.MoveTo:create(1, cc.p(location.x, location.y)))
        local posX, posY = s:getPosition()
        local o = location.x - posX
        local a = location.y - posY
        local at = math.atan(o / a) / math.pi * 180.0

        if a < 0 then
            if o < 0 then
                at = 180 + math.abs(at)
            else
                at = 180 - math.abs(at)
            end
        end
        --s:runAction(cc.RotateTo:create(1, at))
    end
    local touchListener = cc.EventListenerTouchOneByOne:create()
    touchListener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    touchListener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(touchListener, self)
end

return HeroLayer