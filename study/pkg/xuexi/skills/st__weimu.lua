-- ========== 帷幕技能 (st__weimu) ==========
local st__weimu = fk.CreateSkill {
  name = "st__weimu",
  tags = { Skill.AttachedKingdom, Skill.Compulsory },
  attached_kingdom = {"qun"},
}

Fk:loadTranslationTable {
  ["st__weimu"] = "帷幕",
  [":st__weimu"] = "群势力技，锁定技，当你成为黑色锦囊牌目标后，取消之。当你于回合内受到伤害时，你防止此伤害，然后摸两张牌。",
  
  -- 日志翻译
  ["#st__WeimuCancel"] = "%from 的【%arg】效果被触发，黑色锦囊【%arg2】的目标被取消",
  ["#st__WeimuPreventDamage"] = "%from 的【帷幕】防止了伤害，并摸了 %arg 张牌",
}

-- ===== 第一部分：黑色锦囊牌对你无效 =====
st__weimu:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return 
      target == player and 
      player:hasSkill(self.skeleton.name) and 
      data.card.type == Card.TypeTrick and 
      data.card.color == Card.Black and
      not data.cancelled
  end,
  
  on_use = function(self, event, target, player, data)
    data:cancelCurrentTarget()
    player.room:sendLog{
      type = "#st__WeimuCancel",
      from = player.id,
      arg = self.skeleton.name,
      arg2 = data.card.name
    }
  end
})

-- ===== 第二部分：回合内受到伤害时，防止此伤害并摸2张牌 =====
st__weimu:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(st__weimu.name) and
           player.room.current == player
  end,
  
  on_use = function(self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    room:drawCards(player, 2, st__weimu.name)
    room:sendLog{
      type = "#st__WeimuPreventDamage",
      from = player.id,
      arg = "2"
    }
  end,
})

return st__weimu