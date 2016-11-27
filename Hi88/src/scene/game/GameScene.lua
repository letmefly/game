local Game3Layer = require "scene.game.Game3Layer"

local GameScene = class("GameScene", function()
    return cc.Scene:create()
end)

function GameScene:create()
    local scene = GameScene.new()
    scene:initM()
    return scene
end

function GameScene:ctor()
end

function GameScene:initM()
    self.layer = Game3Layer:create()
    self:addChild(self.layer)
end

return GameScene
