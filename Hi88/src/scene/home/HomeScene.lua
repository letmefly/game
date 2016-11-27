local HomeLayer = require "scene.home.HomeLayer"

local HomeScene = class("HomeScene", function()
    return cc.Scene:create()
end)

function HomeScene:create()
    local scene = HomeScene.new()
    scene:initM()
    return scene
end

function HomeScene:ctor()
end

function HomeScene:initM()
    self.layer = HomeLayer:create()
    self:addChild(self.layer)
end

return HomeScene
