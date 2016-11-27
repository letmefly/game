local cjson = require("cjson")
local userData = {}

function userData:setUserInfo(info)
    self.userInfo = {}
    self.userInfo.userId = info.userId
    self.userInfo.nickname = info.nickname
    self.userInfo.sexType = info.sexType
    self.userInfo.iconUrl = info.iconUrl
    self.userInfo.roomCardNum = info.roomCardNum
    self.userInfo.level = info.level
    self.userInfo.playerId = info.playerId
end

function userData:getUserInfo()
    return self.userInfo
end

function userData:set(k, v)
    self.userInfo[k] = v
end

return userData
