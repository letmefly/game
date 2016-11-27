local Initialization = {}

local function addSearchPath(path)
    --local updateDir = cc.FileUtils:getInstance():getWritablePath().."update_package"
    local updateDir = cc.FileUtils:getInstance():getWritablePath().."HiCard"
    if cc.FileUtils:getInstance():isFileExist(updateDir) then
        cc.FileUtils:getInstance():addSearchPath(updateDir.."/"..path)
        --cclog("Add update search path:"..updateDir.."/"..path)
    end
    cc.FileUtils:getInstance():addSearchPath(path)
end

function Initialization:start()
    --1. add search path for LUA code and image resource
    addSearchPath("src")
    addSearchPath("src/boot")
    addSearchPath("src/config")
    addSearchPath("src/common")
    addSearchPath("src/network")
    addSearchPath("src/data")
    addSearchPath("src/scene/login")
    addSearchPath("res")
    addSearchPath("res/ccs")
    addSearchPath("res/ccs/ui")
    addSearchPath("res/ccs/animation")
    addSearchPath("res/font")
    addSearchPath("res/plist")
    addSearchPath("res/sound")
    
    --2. require module
    require ("common.HelperFunc")
    require ("network.Http")
end

return Initialization
