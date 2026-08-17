print("=== 加载兵谲技能(st__bingjue) ===")
local bingjue = fk.CreateSkill {
  name = "st__bingjue",
  tags = { Skill.AttachedKingdom },
  attached_kingdom = {"qun"},
}

Fk:loadTranslationTable {
  ["st__bingjue"] = "兵谲",
  [":st__bingjue"] = "群势力技，出牌阶段限一次，你可以将一张装备牌置入一名其他角色的装备区或替换其原有装备。" ..
    "当你的装备牌被其他角色获得时，你可视为对其使用一张【借刀杀人】（需指定合法目标）。" ..
    "当你使用的借刀杀人结算后，若其因此使用杀，你可视为对其攻击范围内的一名其他角色使用一张杀；否则你可以令其流失1点体力。",

  ["#st__bingjue-active"] = "兵谲：你可以将一张装备牌置入一名其他角色的装备区（替换原装备）",
  ["#st__bingjue-invoke"] = "兵谲：你可以视为使用一张【借刀杀人】",
  ["#st__bingjue-slash"] = "兵谲：你可以对 %src 攻击范围内的一名其他角色使用一张【杀】",
  ["#st__bingjue-losehp"] = "兵谲：是否令 %src 流失1点体力？",
}

-- 主动效果：出牌阶段限一次，置入装备
bingjue:addEffect("active", {
  anim_type = "support",
  prompt = "#st__bingjue-active",
  max_phase_use_time = 1,
  card_num = 1,
  target_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and #selected_cards == 1 and to_select ~= player and
           to_select:canMoveCardIntoEquip(selected_cards[1], true)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardIntoEquip(target, effect.cards[1], bingjue.name, true, player)
  end,
})

-- 被动效果1：当你的装备牌被其他角色获得时，视为对获得装备的角色使用【借刀杀人】
bingjue:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(bingjue.name) then return false end
    for _, move in ipairs(data) do
      if move.from == player and move.to and move.to ~= player then
        for _, info in ipairs(move.moveInfo) do
          if table.contains({ Card.PlayerHand, Card.PlayerEquip }, info.fromArea) then
            local card = Fk:getCardById(info.cardId)
            if card.type == Card.TypeEquip then
              local obtainer = move.to
              if obtainer then
                -- 检查该角色是否有武器，且其攻击范围内有至少一个其他角色
                if #obtainer:getEquipments(Card.SubtypeWeapon) > 0 then
                  for _, p in ipairs(player.room.alive_players) do
                    if p ~= obtainer and obtainer:inMyAttackRange(p) then
                      return true
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    -- 重新找到获得装备的角色（取第一个符合条件的）
    local fixedTarget = nil
    for _, move in ipairs(data) do
      if move.from == player and move.to and move.to ~= player then
        for _, info in ipairs(move.moveInfo) do
          if table.contains({ Card.PlayerHand, Card.PlayerEquip }, info.fromArea) then
            local card = Fk:getCardById(info.cardId)
            if card.type == Card.TypeEquip then
              fixedTarget = move.to
              if fixedTarget then break end
            end
          end
        end
      end
      if fixedTarget then break end
    end
    if not fixedTarget then return false end

    local room = player.room
    -- 使用 must_targets 强制第一目标为 fixedTarget，子目标自由选择
    local use = room:askToUseVirtualCard(player, {
      name = "collateral",
      skill_name = bingjue.name,
      prompt = "#st__bingjue-invoke",
      skip = true,
      cancelable = true,
      extra_data = {
        must_targets = {fixedTarget.id},  -- 强制第一目标为 fixedTarget
      }
    })
    if use then
      event:setCostData(self, { use = use, fixedTarget = fixedTarget })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local costData = event:getCostData(self)
    room:useCard(costData.use)
  end,
})

-- 被动效果2：监听杀的使用，标记由借刀杀人引发的杀
bingjue:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(bingjue.name) then return false end
    if not data or not data.card then return false end
    if data.card.trueName ~= "slash" then return false end
    local collateralEffect = data.extra_data and data.extra_data.event_data
    if not collateralEffect then return false end
    return collateralEffect.from == player
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local collateralEffect = data.extra_data.event_data
    collateralEffect._bingjue_slash_used = true
  end,
})

-- 被动效果3：监听借刀杀人效果结束，根据标记触发后续
bingjue:addEffect(fk.CardEffectFinished, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(bingjue.name) then return false end
    if not data or not data.card then return false end
    if data.isCancellOut then return false end
    if data.from ~= player then return false end
    if data.card.trueName ~= "collateral" then return false end
    return true
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local collateralEffect = data
    local mainTarget = collateralEffect.to

    if collateralEffect._bingjue_slash_used then
      -- 目标使用了杀
      local candidates = {}
      for _, p in ipairs(room.alive_players) do
        if p ~= player and p ~= mainTarget and mainTarget:inMyAttackRange(p) then
          table.insert(candidates, p)
        end
      end
      if #candidates == 0 then return end

      local use = room:askToUseVirtualCard(player, {
        name = "slash",
        skill_name = bingjue.name,
        prompt = "#st__bingjue-slash:" .. mainTarget.id,
        cancelable = true,
        target_filter = function(self, player, to_select, selected)
          return #selected == 0 and table.contains(candidates, to_select)
        end,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          extraUse = true,
        },
      })
      if use then
        room:useCard(use)
      end
    else
      -- 目标未使用杀
      local invoke = room:askToSkillInvoke(player, {
        skill_name = bingjue.name,
        prompt = "#st__bingjue-losehp:" .. mainTarget.id,
      })
      if invoke then
        room:loseHp(mainTarget, 1, bingjue.name)
      end
    end
  end,
})

print("兵谲技能(st__bingjue)加载完成")
return bingjue