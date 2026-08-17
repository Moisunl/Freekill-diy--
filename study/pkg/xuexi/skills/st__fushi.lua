local st__fushi = fk.CreateSkill{
  name = "st__fushi",
  tags = {Skill.Wake},
}

Fk:loadTranslationTable{
  ["st__fushi"] = "覆世",
  [":st__fushi"] = "觉醒技，出牌阶段开始时，若你通过〖驭势〗清除记录达到三次后，你减1点体力上限并摸等同你当前体力值的牌，最后失去〖驭势〗，获得〖完杀〗〖连破〗。",
}

st__fushi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(st__fushi.name) and player:usedSkillTimes(st__fushi.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    if player.phase ~= Player.Play then return false end
    local count = player:getMark("@st__yushi_clear")
    return count >= 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if player.dead then return end
    local draw_num = math.max(0, player.hp)
    if draw_num > 0 then
      player:drawCards(draw_num, st__fushi.name)
    end
    room:handleAddLoseSkills(player, "-st__yushi|ol_ex__wansha|lianpo")
    room:sendLog{
      type = "#WakeSkill",
      from = player.id,
      arg = st__fushi.name,
      arg2 = ""
    }
  end,
})

return st__fushi