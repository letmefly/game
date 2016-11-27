local function Login_handler(data)
    cclog("[CMDMap]Login_handler called")
    local Player = require "data.Player"
    Player:setData(data.player)
end

local function Roler_handler(data)
    cclog("[CMDMap]Roler_handler called")
    local Roler = require "data.Roler"
    Roler:setData(data.roler)
    Roler:setData(data.constCfg)
end

local function Default_handler(data)
    cclog("[CMDMap]Default_handler called")
end

------------------------------CMD map table-------------------------------------
local CMDMap = {
    -----From PtLoginProto.proto-----
    ["PtLogin"] = {["cmdId"]=1,["cmdHandler"]=Default_handler},

    -----From LandProto.proto-----
    ["Login"] = {["cmdId"]=101,["cmdHandler"]=Login_handler},
    ["RoleList"] = {["cmdId"]=103, ["cmdHandler"]=Default_handler},
    ["CreateRole"] = {["cmdId"]=105, ["cmdHandler"]=Default_handler},
    ["DeleteRole"] = {["cmdId"]=107, ["cmdHandler"]=Default_handler},
    ["RandomName"] = {["cmdId"]=109, ["cmdHandler"]=Default_handler},
    ["RolerReconnection"] = {["cmdId"]=111, ["cmdHandler"]=Default_handler},
    ["RolerGoBack"] = {["cmdId"]=113, ["cmdHandler"]=Default_handler},

    -----From TownProto.proto-----
    ["BuildLockInfo"] = {["cmdId"]=201, ["cmdHandler"]=Default_handler},
    ["ButtonLockInfo"] = {["cmdId"]=203, ["cmdHandler"]=Default_handler},
    ["rolerAddTown"] = {["cmdId"]=205, ["cmdHandler"]=Default_handler},
    ["rolerLeftTown"] = {["cmdId"]=207, ["cmdHandler"]=Default_handler},
    ["ToBuyCoins"] = {["cmdId"]=209, ["cmdHandler"]=Default_handler},
    ["BuyCoins"] = {["cmdId"]=211, ["cmdHandler"]=Default_handler},
    ["GetRedDot"] = {["cmdId"]=213, ["cmdHandler"]=Default_handler},

    -----From RoleProto.proto-----
    ["GetRoler"] = {["cmdId"]=301, ["cmdHandler"]=Roler_handler},
    ["GoldVip"] = {["cmdId"]=303, ["cmdHandler"]=Default_handler},
    ["AddCP"] = {["cmdId"]=305, ["cmdHandler"]=Default_handler},
    ["Vip"] = {["cmdId"]=307, ["cmdHandler"]=Default_handler},

    -----From ShopProto.proto-----
    ["GetShopList"] = {["cmdId"]=401, ["cmdHandler"]=Default_handler},
    ["BuyItem"] = {["cmdId"]=403, ["cmdHandler"]=Default_handler},
    ["VipShopList"] = {["cmdId"]=405, ["cmdHandler"]=Default_handler},
    ["VipRecharge"] = {["cmdId"]=407, ["cmdHandler"]=Default_handler},

    -----From RoleProto.proto-----
    ["BagList"] = {["cmdId"]=501, ["cmdHandler"]=Default_handler},
    ["BagUse"] = {["cmdId"]=503, ["cmdHandler"]=Default_handler},
    ["SoulExpList"] = {["cmdId"]=505, ["cmdHandler"]=Default_handler},
    ["BagCompose"] = {["cmdId"]=507, ["cmdHandler"]=Default_handler},

    -----From SoulProto.proto-----
    ["ComposeFragment"] = {["cmdId"]=613, ["cmdHandler"]=Default_handler},
    ["EnsureAdvance"] = {["cmdId"]=619, ["cmdHandler"]=Default_handler},
    ["GetAllSoul"] = {["cmdId"]=621, ["cmdHandler"]=Default_handler},
    ["GetSoul"] = {["cmdId"]=623, ["cmdHandler"]=Default_handler},
    ["GetSoulUp"] = {["cmdId"]=625, ["cmdHandler"]=Default_handler},
    ["SoulUp"] = {["cmdId"]=627, ["cmdHandler"]=Default_handler},
    ["GetNewBookUp"] = {["cmdId"]=629, ["cmdHandler"]=Default_handler},
    ["NewBookUp"] = {["cmdId"]=631, ["cmdHandler"]=Default_handler},

    -----From FieldProto.proto-----
    ["GetAllStage"] = {["cmdId"]=801, ["cmdHandler"]=Default_handler},
    ["NewStartCheck"] = {["cmdId"]=825, ["cmdHandler"]=Default_handler},
    ["NewBattleFinish"] = {["cmdId"]=849, ["cmdHandler"]=Default_handler},
    ["Sweep"] = {["cmdId"]=851, ["cmdHandler"]=Default_handler},
    ["BuyPveCount"] = {["cmdId"]=853, ["cmdHandler"]=Default_handler},
    ["GetBattleReport"] = {["cmdId"]=855, ["cmdHandler"]=Default_handler},

    -----From SportProto.proto-----
    ["SportMainRank"] = {["cmdId"]=1001, ["cmdHandler"]=Default_handler},
    ["SprotChallenge"] = {["cmdId"]=1003, ["cmdHandler"]=Default_handler},
    ["SprotRankList"] = {["cmdId"]=1005, ["cmdHandler"]=Default_handler},
    ["SportStore"] = {["cmdId"]=1007, ["cmdHandler"]=Default_handler},
    ["BuySportItem"] = {["cmdId"]=1009, ["cmdHandler"]=Default_handler},
    ["SportClerCD"] = {["cmdId"]=1011, ["cmdHandler"]=Default_handler},
    ["ChangeSportMatrix"] = {["cmdId"]=1013, ["cmdHandler"]=Default_handler},
    ["BuyChallengeCnt"] = {["cmdId"]=1015, ["cmdHandler"]=Default_handler},
    ["SportReportList"] = {["cmdId"]=1017, ["cmdHandler"]=Default_handler},

    -----From StrengProto.proto-----
    ["AllEquipmentList"] = {["cmdId"]=1101, ["cmdHandler"]=Default_handler},
    ["PrepareStreng"] = {["cmdId"]=1103, ["cmdHandler"]=Default_handler},
    ["Streng"] = {["cmdId"]=1105, ["cmdHandler"]=Default_handler},
    ["PrepareEquipmentAdvance"] = {["cmdId"]=1107, ["cmdHandler"]=Default_handler},
    ["Advance"] = {["cmdId"]=1109, ["cmdHandler"]=Default_handler},

    -----From ChatProto.proto-----
    ["OpenChat"] = {["cmdId"]=1301, ["cmdHandler"]=Default_handler},
    ["Chat"] = {["cmdId"]=1303, ["cmdHandler"]=Default_handler},

    -----From EmailProto.proto-----
    ["GetEmailList"] = {["cmdId"]=1501, ["cmdHandler"]=Default_handler},
    ["ReadEmail"] = {["cmdId"]=1503, ["cmdHandler"]=Default_handler},
    ["ReceiveFujian"] = {["cmdId"]=1505, ["cmdHandler"]=Default_handler},
    ["DeleteMail"] = {["cmdId"]=1507, ["cmdHandler"]=Default_handler},

    -----From HeroProto.proto-----
    ["BagTip"] = {["cmdId"]=1705, ["cmdHandler"]=Default_handler},
    ["OnekeyEquip"] = {["cmdId"]=1709, ["cmdHandler"]=Default_handler}, 
    ["EquipList"] = {["cmdId"]=1715, ["cmdHandler"]=Default_handler},
    ["Equip"] = {["cmdId"]=1717, ["cmdHandler"]=Default_handler},
    ["GetWholeSoul"] = {["cmdId"]=1729, ["cmdHandler"]=Default_handler},

    -----From BookProto.proto-----
    ["getChallengeRolerList"] = {["cmdId"]=2105, ["cmdHandler"]=Default_handler},
    ["RobBook"] = {["cmdId"]=2107, ["cmdHandler"]=Default_handler},

    -----From DailyTaskProto.proto-----
    ["GetMainDt"] = {["cmdId"]=2201, ["cmdHandler"]=Default_handler},
    ["GetDtReward"] = {["cmdId"]=2211, ["cmdHandler"]=Default_handler},

    -----From MovementProto.proto-----
    ["GetMovement"] = {["cmdId"]=2401, ["cmdHandler"]=Default_handler},
    ["EnterCoinsEctype"] = {["cmdId"]=2403, ["cmdHandler"]=Default_handler},

    -----From GemProto.proto-----
    ["GetGemMain"] = {["cmdId"]=2501, ["cmdHandler"]=Default_handler},
    ["GetGemList"] = {["cmdId"]=2503, ["cmdHandler"]=Default_handler},
    ["Inlay"] = {["cmdId"]=2505, ["cmdHandler"]=Default_handler},
    ["UnInlay"] = {["cmdId"]=2507, ["cmdHandler"]=Default_handler},
    ["GetAllGemEquip"] = {["cmdId"]=2509, ["cmdHandler"]=Default_handler},
    ["ComposeGem"] = {["cmdId"]=2511, ["cmdHandler"]=Default_handler},

    -----From SettingProto.proto-----
    ["ChangeName"] = {["cmdId"]=2701, ["cmdHandler"]=Default_handler},
    ["SetTheSettingStatus"] = {["cmdId"]=2703, ["cmdHandler"]=Default_handler},
    ["GetExchangeCodeReward"] = {["cmdId"]=2705, ["cmdHandler"]=Default_handler},

    -----From OpenActProto.proto-----
    ["GetFirstRechargeReward"] = {["cmdId"]=2807, ["cmdHandler"]=Default_handler},

    -----From SmeltProto.proto-----
    ["GetSmeltMain"] = {["cmdId"]=2901, ["cmdHandler"]=Default_handler},
    ["GetSmeltMaterial"] = {["cmdId"]=2903, ["cmdHandler"]=Default_handler},
    ["CheckSmeltMaterial"] = {["cmdId"]=2905, ["cmdHandler"]=Default_handler},
    ["SmeltMaterial"] = {["cmdId"]=2907, ["cmdHandler"]=Default_handler},

    -----From ChatProto.proto-----
    ["WorldChat"] = {["cmdId"]=1303, ["cmdHandler"]=Default_handler},

    -----From PickCardProto.proto----
    ["MainPickCardStart"] = {["cmdId"]=1801, ["cmdHandler"]=Default_handler},
    ["PickCardComplete"] = {["cmdId"]=1803, ["cmdHandler"]=Default_handler},


    -----From GuildProto.proto----
    ["CreatGuildRequest"] = {["cmdId"]=1401, ["cmdHandler"]=Default_handler},--创建公会
    ["GuildInfoRequest"] = {["cmdId"]=1403, ["cmdHandler"]=Default_handler},--获取公会信息
    ["GuildListRequest"] = {["cmdId"]=1405, ["cmdHandler"]=Default_handler},--公会列表
    ["ModifyNoticeRequest"] = {["cmdId"]=1407, ["cmdHandler"]=Default_handler},--修改公告
    ["GuildRolerListRequest"] = {["cmdId"]=1409, ["cmdHandler"]=Default_handler},--公会成员列表
    ["AssignGuildPosRequest"] = {["cmdId"]=1411, ["cmdHandler"]=Default_handler},--分配公会职位
    ["LeaveGuildRequest"] = {["cmdId"]=1413, ["cmdHandler"]=Default_handler},--离开公会
    ["ApplyGuildRequest"] = {["cmdId"]=1415, ["cmdHandler"]=Default_handler},--申请加入公会
    ["ApplyGuildRolerListRequest"] = {["cmdId"]=1417, ["cmdHandler"]=Default_handler},--申请者列表
    ["DealGuildApplyRequest"] = {["cmdId"]=1419, ["cmdHandler"]=Default_handler},--同意/拒绝 申请
    ["GetGuildShopRequest"] = {["cmdId"]=1421, ["cmdHandler"]=Default_handler},--显示公会商店列表
    ["BuyGuildShopRequest"] = {["cmdId"]=1423, ["cmdHandler"]=Default_handler},--购买公会商店物品
    ["RefreshGuildShopRequest"] = {["cmdId"]=1425, ["cmdHandler"]=Default_handler},--刷新公会商店物品
    ["GetGuildDinnerRequest"] = {["cmdId"]=1427, ["cmdHandler"]=Default_handler},--公会大餐列表
    ["EatGuildDinnerRequest"] = {["cmdId"]=1429, ["cmdHandler"]=Default_handler},--品尝一下
    ["GuildSettingRequest"] = {["cmdId"]=1431, ["cmdHandler"]=Default_handler},--公会设置
    ["GetGuildBigStageListRequest"] = {["cmdId"]=1433, ["cmdHandler"]=Default_handler},--获得公会大副本列表
    ["OpenGuildBigStageRequest"] = {["cmdId"]=1435, ["cmdHandler"]=Default_handler},--开启公会大副本
    ["GetGuildStageRequest"] = {["cmdId"]=1437, ["cmdHandler"]=Default_handler},-- 获得当前可攻打的公会小副本
    ["ChallengeGuildStageRequest"] = {["cmdId"]=1439, ["cmdHandler"]=Default_handler},-- 攻打副本
    ["GetGuildBagRequest"] = {["cmdId"]=1441, ["cmdHandler"]=Default_handler},-- 获得公会仓库
    ["ApplyGuildBagItemRequest"] = {["cmdId"]=1443, ["cmdHandler"]=Default_handler},-- 申请公会仓库物品
    ["DetailGuildBagItemRequest"] = {["cmdId"]=1445, ["cmdHandler"]=Default_handler},-- 公会仓库物品详情

    -----From TaskProto.proto----------
    ["taskStart"]={["cmdId"]=1601,["cmdHandler"]=Default_handler},
    ["taskCompleted"]={["cmdId"]=1603,["cmdHandler"]=Default_handler},


    -----From OpenActProto.proto----------
    ["GetOpenActRequest"]={["cmdId"]=2801,["cmdHandler"]=Default_handler},
    ["GetOpenActRewardRequest"]={["cmdId"]=2803,["cmdHandler"]=Default_handler},
    ["GetFirstRechargeRewardRequest"]={["cmdId"]=2807,["cmdHandler"]=Default_handler},


    -----From ConvoyProto.proto----------
    ["GetConvoyMainRequest"]={["cmdId"]=3001,["cmdHandler"]=Default_handler},
    ["RefreshConvoyTruckRequest"]={["cmdId"]=3003,["cmdHandler"]=Default_handler},
    ["GetConvoySoulsRequest"]={["cmdId"]=3005,["cmdHandler"]=Default_handler},
    ["CheckConvoySoulsRequest"]={["cmdId"]=3007,["cmdHandler"]=Default_handler},
    ["RefreshRobTruckRequest"]={["cmdId"]=3009,["cmdHandler"]=Default_handler},
    ["RobTruckRequest"]={["cmdId"]=3011,["cmdHandler"]=Default_handler},
    ["GetConvoyBattleReportListRequest"]={["cmdId"]=3013,["cmdHandler"]=Default_handler},
    ["GetConvoyRewardRequest"]={["cmdId"]=3015,["cmdHandler"]=Default_handler}

}

return CMDMap
