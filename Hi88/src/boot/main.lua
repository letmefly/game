
cc.FileUtils:getInstance():addSearchPath("src")
cc.FileUtils:getInstance():addSearchPath("res")
cc.FileUtils:getInstance():addSearchPath("src/network")

-- CC_USE_DEPRECATED_API = true
require "cocos.init"

-- cclog
cclog = function(...)
    print(string.format(...))
end


-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    cclog("----------------------------------------")
    return msg
end

local function main()
    collectgarbage("collect")
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
    
    --Game engine configure
    cc.Director:getInstance():setAnimationInterval(1.0/30)
    local policy = cc.ResolutionPolicy.FIXED_HEIGHT
    local frameSize = cc.Director:getInstance():getOpenGLView():getFrameSize()
    if frameSize.width*1.0/1334 < frameSize.height*1.0/750 then
        policy = cc.ResolutionPolicy.FIXED_WIDTH
    end
    cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(1334, 750, policy)
    cc.Director:getInstance():setDisplayStats(false)

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

    local scene = {}
    if isModuleAvailable("lfs") and false then
        --update support
        scene = require("src.boot.UpdateScene"):create()
    else
        --Initialize the whole run envirement
        local Initialization = require("src.boot.Initialization")
        Initialization:start()

        --first scene 
        scene = require("LoginScene"):create()
    end
    
    if cc.Director:getInstance():getRunningScene() then
        cc.Director:getInstance():replaceScene(scene)
    else
        cc.Director:getInstance():runWithScene(scene)
    end
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    error(msg)
end

