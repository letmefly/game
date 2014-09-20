require "Cocos2d"

local BgLayer = class("BgLayer",function()
    return cc.Layer:create()
end)

function BgLayer:create()
    local bgLayer = BgLayer.new()
    bgLayer:initM()
    return bgLayer
end

function BgLayer:ctor()
end

function BgLayer:initM()
    local bg = cc.Sprite:create("farm.jpg")
    bg:setPositionX(200)
    self:addChild(bg)
end

function BgLayer:updateM(dt)
end

return BgLayer
