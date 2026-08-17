local extension = Package:new("xuexi")
extension.extensionName = "study"
extension:loadSkillSkelsByPath("./packages/study/pkg/xuexi/skills")
Fk:loadTranslationTable{
  ["xuexi"] = "学习",
}

local jiaxu = General:new(extension, "st__jiaxu", "qun", 3, 4)
jiaxu.subkingdom = "wei"

jiaxu:addSkill("st__yushi")
jiaxu:addSkill("st__fushi")
jiaxu:addSkill("st__bingjue")
jiaxu:addSkill("st__weimu")
jiaxu:addSkill("st__chouwo")
jiaxu:addSkill("st__zhenlue")

-- 设置技能路径并加载
local skillPath = "./packages/study/pkg/xuexi/skills"
print("技能加载路径:", skillPath)
extension:loadSkillSkelsByPath(skillPath)

-- 加载技能翻译文本
Fk:loadTranslationTable{
  ["st__yushi"] = "驭势",
  [":st__yushi"] = "锁定技，你记录与你同势力的角色被牌指定为目标的次数（同一张牌至多记录一次）。"..
  "当一张牌指定目标时，若记录次数不小于3，你可以：变更势力至（群/魏），或保持不变，然后你根据当前势力从牌堆中随机获得一张（装备牌/智囊牌），并清除〖驭势〗的记录次数。",
  
  ["st__fushi"] = "覆世",
  [":st__fushi"] = "觉醒技，出牌阶段开始时，若你通过〖驭势〗清除记录达到三次后，你减1点体力上限并摸等同你当前体力值的牌，最后失去〖驭势〗，获得〖完杀〗〖连破〗。",
 
  -- 群势力技能
  ["st__bingjue"] = "兵谲",
  [":st__bingjue"] = "群势力技，出牌阶段限一次，你可以将一张装备牌置入一名其他角色的装备区或替换其原有装备。当你的装备牌被其他角色获得时，你可视为对其使用一张【借刀杀人】（需指定合法目标）。当你使用的借刀杀人结算后，若其因此使用杀，你可视为对其攻击范围内的一名其他角色使用一张杀；否则你可以令其流失1点体力。",
 
  ["st__weimu"] = "帷幕",
  [":st__weimu"] = "群势力技，锁定技，当你成为黑色锦囊牌目标后，取消之。当你于回合内受到伤害时，你防止此伤害，然后摸2张牌。",
 
  -- 魏势力技能
  ["st__chouwo"] = "筹幄",
  [":st__chouwo"] = "魏势力技，你记录你于回合内使用基本牌和锦囊牌指定目标的次数。当你使用第三张基本牌或锦囊牌指定目标时，你选择一项：1.此牌对其中一个目标额外结算一次；2.此牌目标加一；3.此牌结算后，你摸3-X张牌（X为手牌花色数）。然后清除〖筹幄〗的记录次数。",

  ["st__zhenlue"] = "缜略",
  [":st__zhenlue"] = "魏势力技，锁定技，你使用的普通锦囊牌不能被【无懈可击】响应，延时类锦囊牌对你无效。",
}

Fk:loadTranslationTable{
    ["xuexi"] = "学习",
    ["st"] = "势",
}

Fk:loadTranslationTable{
  ["st"+"__"+"jiaxu"] = "贾诩",
  ["#st__jiaxu"] = "殃流百世",
  ["designer:st__jiaxu"] = "moi",
  ["cv:st__jiaxu"] = "官方",
  ["illustrator:st__jiaxu"] = "第七个桔子",
}

return extension
