local LoginUILayer = require "scene.login.LoginLayer"

local LoginScene = class("LoginScene", function()
    return cc.Scene:create()
end)

function LoginScene:create()
    local scene = LoginScene.new()
    scene:initM()
    return scene
end

function LoginScene:ctor()
end

function LoginScene:initM()
    self.loginUILayer = LoginUILayer:create()
    self:addChild(self.loginUILayer)
end

return LoginScene
