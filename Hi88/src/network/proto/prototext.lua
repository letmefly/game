local cjson = require "cjson"

local prototext = [[

message handshake {
  optional int32 sn = 1;
}

message server_push {
	optional int32 sn = 1;
	optional int32 money = 2;
	optional int32 cash = 3;
	optional int32 lotteryPoint = 4;
	optional int32 lotteryHighCoupon =5;
	optional int32 lotteryCoupon = 6;
	optional int32 heart = 7;
	optional string heartTime = 8;
	optional int32 heartTimeSeconds = 9;
}

message user_register {
	optional string email = 1;
	optional string password = 2;
}

message user_register_ack {
	optional int32 errno = 1;
}

message user_login {
	optional string email = 1;
	optional string password = 2;
}

message user_login_ack {
	optional int32 errno = 1;
	optional int32 attendanceCount = 2;
	optional int32 attendanceDays = 3;
	optional int32 attendanceReward = 4;
	optional int32 heart = 5;
	optional string heartTime = 6;
	optional int32 heartTimeSeconds = 7;
	optional int32 vipRemainSeconds = 8;
	optional string bannerID = 9;
	optional string bannerImageURL = 10;
	optional string bannerLinkURL = 11;
	optional int32 userID = 12;
	optional string nickname = 13;
	optional int32 level = 14;
	optional int32 exp = 15;
	optional int32 money = 16;
	optional int32 cash = 17;
	optional int32 tutorial = 18;
	optional int32 review = 19;
	optional int32 inviteCount = 20;
	optional int32 lotteryPoint = 21;
	optional int32 lotteryHighCoupon =22;
	optional int32 lotteryCoupon = 23;
	optional int32 skillSlot = 24;
	optional int32 treasureSlot = 25;
	optional int32 treasureInventory = 26;
	optional int32 bestScore = 27;
	optional int32 agreeMessage = 28;
	optional int32 daliyEventActive = 29;
	optional int32 videoRebornTimes = 30;
	optional int32 watchVideoTimes = 31;
}

message game_lobby {
	optional int32 userID = 1;
}

message game_lobby_ack {
	optional int32 errno = 1;
	optional int32 money = 2;
	optional int32 cash = 3;
	optional int32 lotteryPoint = 4;
	optional int32 lotteryHighCoupon =5;
	optional int32 lotteryCoupon = 6;
	optional int32 attendanceCount = 7;
	optional int32 attendanceDays = 8;
	optional int32 attendanceReward = 9;
	optional int32 heart = 10;
	optional string heartTime = 11;
	optional int32 heartTimeSeconds = 12;
	optional int32 vipRemainSeconds = 13;
	optional int32 messageCount = 14;
	optional int32 friendRequestCount = 15;
}

message game_start {
	optional int32 userID = 1;
	optional int32 stageID = 2;
	optional int32 friendUserID = 3;
	repeated int32 useItems = 4;
}

message slot_character {
	optional int32 character_id = 1;
	optional int32 level = 2;
	optional int32 character_info_id = 3;
}
message slot_skill {
	optional int32 skill_id = 1;
	optional int32 skill_info_id = 2;
	optional int32 level = 3;
	optional int32 slot_number = 4;
}
message slot_treasure {
	optional int32 treasure_id = 1;
	optional int32 treasure_info_id = 2;
	optional int32 level = 3;
	optional int32 slot_number = 4;
}
message game_start_ack {
	optional int32 errno = 1;
	optional int32 money = 2;
	optional int32 cash = 3;
	optional int32 lotteryPoint = 4;
	optional int32 lotteryHighCoupon =5;
	optional int32 lotteryCoupon = 6;
	optional int32 heart = 7;
	optional string heartTime = 8;
	optional int32 heartTimeSeconds = 9;
	optional int32 playCode = 10;
	repeated slot_character slotCharacter = 11;
	repeated slot_skill slotSkills = 12;
	repeated slot_treasure slotTreasures = 13;
}

message game_result {
	optional int32 playCode = 1;
	optional int32 userID = 2;
	optional int32 gainExp = 3;
	optional int32 gainMoney = 4;
	optional int32 score = 5;
	optional int32 maxCombo = 6;
	optional int32 isClear = 7;
	optional int32 isPerfect = 8;
	optional int32 killCount = 9;
}

message game_result_ack {
	optional int32 errno = 1;
	optional int32 money = 2;
	optional int32 cash = 3;
	optional int32 lotteryPoint = 4;
	optional int32 lotteryHighCoupon =5;
	optional int32 lotteryCoupon = 6;
	optional int32 heart = 7;
	optional string heartTime = 8;
	optional int32 heartTimeSeconds = 9;

	message grade_reward {
		optional int32 type = 1;
		optional int32 amount = 2;
		optional int32 itemID = 3;
	}

	message instant_item {
		optional int32 instantItemID = 1;
		optional int32 amount = 2;
	}

	repeated grade_reward gradeReward = 10;
	repeated instant_item items = 11;
}

message game_characters {
	optional int32 userID = 1;
}

message character_item {
	optional int32 character_id = 1;
	optional int32 level = 2;
	optional int32 character_info_id = 3;
	optional int32 slot = 4;
}
message game_characters_ack {
	optional int32 errno = 1;
	repeated character_item characters = 2;
}

message game_achievements {
	optional int32 userID = 1;
}

message game_achievements_ack {
	optional int32 errno = 1;

	message achievement_item {
		optional int32 achievement_info_id = 1;
		optional int32 progress = 2;
		optional int32 reward_ok = 3;
	}

	repeated achievement_item achievements = 2;
}

message game_missions {
	optional int32 userID = 1;
}

message game_missions_ack {
	optional int32 errno = 1;
	message mission_item {
		optional int32 mission_id = 1;
		optional int32 mission_info_id = 2;
		optional int32 is_clear = 3;
	}
	repeated mission_item missions = 2;
}

message game_shop {
	optional int32 userID = 1;
}

message game_shop_ack {
	optional int32 errno = 1;

	message shop_item {
		optional int32 product_id = 1;
		optional int32 item_id = 2;
		optional int32 amount = 3;
		optional int32 more_amount = 4;
		optional int32 more_percent = 5;
		optional int32 count = 6;
	}

	repeated shop_item shop = 2;
}

message game_skills {
	optional int32 userID = 1;
}

message game_skills_ack {
	optional int32 errno = 1;

	message skill_item {
		optional int32 skill_id = 1;
		optional int32 skill_info_id = 2;
		optional int32 level = 3;
		optional int32 slot_number = 4;
	}
	repeated skill_item skills = 2;
}

message game_treasures {
	optional int32 userID = 1;
}

message game_treasures_ack {
	optional int32 errno = 1;

	message treasure_item {
		optional int32 treasure_id = 1;
		optional int32 treasure_info_id = 2;
		optional int32 level = 3;
		optional int32 slot_number = 4;
	}
	repeated treasure_item treasures = 2;
}

message game_stages {
	optional int32 userID = 1;
}

message game_stages_ack {
	optional int32 errno = 1;
	message stage_item {
		optional int32 stage_id = 1;
		optional int32 clear_type = 2;
		optional int32 clear_count = 3;
		optional int32 best_score = 4;
		optional int32 perfect = 5;
	}
	repeated stage_item stages = 2;
}

message game_notice {
	optional int32 userID = 1;
}

message game_notice_ack {
	optional int32 errno = 1;
	message notice_item {
		optional int32 NOTICE_ID = 1;
		optional string TITLE = 2;
		optional string CONTENT = 3;
		optional string START_DATE = 4;
		optional string END_DATE = 5;
		optional string IS_SHOW = 6;
	}
	repeated notice_item notice = 2;
}

message game_userdetail {
	optional int32 userID = 1;
	optional int32 detailUserID = 2;
}

message game_userdetail_ack {
	optional int32 errno = 1;
	optional string nickname = 2;
	optional int32 level = 3;
	optional int32 leagueGrade = 4;
	optional int32 score = 5;
	optional int32 bestCcore = 6;
	optional string loginDate = 7;
	optional string loginDateTime = 8;
	optional slot_character character = 9;
	repeated slot_skill skills = 10;
	repeated slot_treasure treasures = 11;
}


]]


local type2name_json = [[

{
	"1": "user_check_version",
	"10": "user_register",
	"2": "user_register_ack", 
	"3": "user_login", 
	"4": "user_login_ack",
	"5": "handshake",
	"6": "game_start",
	"7": "game_start_ack",
	"8": "game_result",
	"9": "game_result_ack"
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
-- 	[1] = "user_register",
-- 	[2] = "user_register_ack", 
-- 	[3] = "user_login", 
-- 	[4] = "user_login_ack",
-- 	[5] = "handshake"
-- }

return prototext
