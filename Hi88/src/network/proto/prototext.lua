local cjson = require "cjson"

local prototext = [[

message UserInfo_t {
    // player 1, 2, 3
    optional string userId = 1;
    optional string nickname = 2;
    // 1 male or 2 female
    optional int32 sexType = 3;
    optional string iconUrl = 4;
    optional int32 level = 5;
    optional int32 roomCardNum = 6;
    optional int32 playerId = 7;
}

message handshake {
  optional int32 sn = 1;
}

message gameLogin {
    optional string userId = 1;
    optional string authCode = 2;
    optional int32 version = 3;
}

message gameLogin_ack {
    // 0 success, -1 auth code invalid, -2 version too low
    optional int32 errno = 1;
    optional UserInfo_t userInfo = 2;
}

message createRoom {
    optional int32 roomType = 1;
}

message createRoom_ack {
    // 0 success, -1 room card not enough
    optional int32 errno = 1;
    optional string roomNo = 2;
}

message joinRoom {
    optional string roomNo = 1;
}

message joinRoom_ack {
    // 0 success, -1 room number invalid
    optional int32 errno = 1;
    optional int32 playerId = 2;
}

message leaveRoom {
    // player 1, 2, 3
    optional int32 playerId = 1;
}

message leaveRoom_ntf {
    // player 1, 2, 3
    optional int32 playerId = 1;
}

// when client load res ok and switch to game screen, 
// notify server that client is ready
message getReady {
    optional int32 status = 1;
}

message getReady_ntf {
    repeated UserInfo_t userInfoList = 1;
}

message start_ntf {
    // 17 poker
    repeated int32 pokerList = 1;
}

message restartGame_ntf {
    optional int32 errno = 1;
}

message whoGrabLandlord_ntf {
    // player 1, 2, 3
    optional int32 playerId = 1;
}

message grabLandlord {
    // player 1, 2, 3
    optional int32 playerId = 1;
    // 1, skip, 2 grab level 1, 3 grab level 2
    optional int32 grabAction = 2;
}

message grabLandlord_ntf {
    // player 1, 2, 3
    optional int32 playerId = 1;
    // 1, skip, 2 grab level 1, 3 grab level 2
    optional int32 grabAction = 2;
}

message landlord_ntf {
    optional int32 playerId = 1;
    repeated int32 bottomPokerList = 2;
}

// whose token for choosing poker 
message whoPlay_ntf {
    // player 1, 2, 3
    optional int32 playerId = 1;
}

message playPoker {
    optional int32 playerId = 1;
    // 1 skip, 2 play poker
    optional int32 playAction = 2;
    // 1 - single, 2 - pair, 3 - joker boom, 4 - 3poker, 5 - boom, 6 - 3+1,
    // 7 - sequence, 8 - 4+2, 9 - pair sequence, 10 - airplane
    optional int32 pokerType = 3;
    repeated int32 pokerList = 4;
}

message playPoker_ntf {
    // player 1, 2, 3
    optional int32 playerId = 1;
    // 1 skip, 2 grab landlord, 3 skip
    optional int32 playAction = 2;
    optional int32 pokerType = 3;
    repeated int32 pokerList = 4;
}

message playTimeout_ntf {
    // player 1, 2, 3
    optional int32 playerId = 1;
}

message lastPoker_ntf {
    optional int32 playerId = 1;
    // 2 or 1
    optional int32 pokerNum = 2;
}

message chat {
    optional int32 fastTalkId = 1;
    optional string talkText = 2;
}

message chat_ntf {
    // player 1, 2, 3
    optional int32 playerId = 1;
    optional int32 fastTalkId = 2;
    optional string talkText = 3;
}

message gameResult_ntf {
    optional int32 totalFactor = 1;
    optional int32 visiblePokeFactor = 2;
    optional int32 grapLandlordFactor = 3;
    optional int32 boomFactor = 4;
    optional int32 springFactor = 5;

    message GameResultInfo {
        optional int32 playerId = 1;
        // 1 win, 2 lose
        optional int32 result = 2;
        optional int32 isLandlord = 3;
        optional int32 totalFactor = 4;
        optional int32 score = 5;
    }
    repeated GameResultInfo resultList = 6;
}

message roomResult_ntf {

}

]]


local type2name_json = [[

{
    "1": "handshake",
    "2": "gameLogin",
    "3": "gameLogin_ack", 
    "4": "createRoom", 
    "5": "createRoom_ack",
    "6": "joinRoom",
    "7": "joinRoom_ack",
    "8": "leaveRoom",
    "9": "leaveRoom_ntf",
    "10": "getReady",
    "11": "getReady_ntf",
    "12": "start_ntf",
    "13": "restartGame_ntf",
    "14": "whoGrabLandlord_ntf",
    "15": "grabLandlord_ntf",
    "16": "landlord_ntf",
    "17": "grabLandlord",
    "18": "whoPlay_ntf",
    "19": "playPoker",
    "20": "playPoker_ntf",
    "21": "playTimeout_ntf",
    "22": "lastPoker_ntf",
    "23": "chat",
    "24": "chat_ntf",
    "25": "gameResult_ntf",
    "26": "roomResult_ntf",
    "27": "",
    "28": "",
    "29": "",
    "30": "",
    "31": ""
}

]]

local errno2desp_json = [[

{
    "1000": "用户已存在",
    "1001": "数据库错误",
    "1002": "用户名或者密码错误",
    "2000": "好友已存在"
}

]]

PROTO_TYPE2NAME = {}

local type2name = cjson.decode(type2name_json)
for k, v in pairs(type2name) do
    PROTO_TYPE2NAME[tonumber(k)] = v
end

-- PROTO_TYPE2NAME = {
--  [1] = "user_register",
--  [2] = "user_register_ack", 
--  [3] = "user_login", 
--  [4] = "user_login_ack",
--  [5] = "handshake"
-- }

return prototext
