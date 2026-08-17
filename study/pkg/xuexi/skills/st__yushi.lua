print("=== 加载驭势技能(st__yushi) ===")
local st__yushi = fk.CreateSkill {
  name = "st__yushi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["st__yushi"] = "驭势",
  [":st__yushi"] = "锁定技，你记录与你同势力的角色被牌指定为目标的次数（同一张牌至多记录一次）。"..
    "当一张牌指定目标时，若此时记录次数不小于3，你可以：变更势力至（群/魏），或保持不变，然后你根据当前势力从牌堆中随机获得一张（装备牌/智囊牌），并清除〖驭势〗的记录次数。",
  ["@st__yushi_count"] = "驭势",
  ["#st__YushiReady"] = "驭势计数已达到 %arg，下一张牌可触发变更",
  ["#st__YushiChangeKingdom"] = "%from 的势力由 %arg 变更为 %arg2",
  ["#st__YushiKeepKingdom"] = "%from 保持 %arg 势力不变",
  ["#st__YushiGetReward"] = "%from 通过驭势获得一张 %arg：%arg2",
}

-- 计数逻辑：在目标确认后，若目标与玩家同势力且未被取消，则计数
st__yushi:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(st__yushi.name) then return false end
    if not data or not data.card then return false end
    if target.kingdom ~= player.kingdom then return false end
    local cardMarkName = "st__yushi_card_counted_" .. data.card.id
    if player:getMark(cardMarkName) > 0 then
      return false
    end
    return true
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local card = data.card

    local cardMarkName = "st__yushi_card_counted_" .. card.id
    player:setMark(cardMarkName, 1)

    local currentCount = player:getMark("st__yushi_count") or 0
    local newCount = currentCount + 1
    player:setMark("st__yushi_count", newCount)
    room:setPlayerMark(player, "@st__yushi_count", newCount)

    if newCount >= 3 then
      player:setMark("st__yushi_waiting", 1)
      room:sendLog{
        type = "#st__YushiReady",
        from = player.id,
        arg = tostring(newCount)
      }
    end
  end,
})

-- 触发逻辑：在指定目标阶段，若有等待标记，则触发势力变更
st__yushi:addEffect(fk.TargetSpecifying, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(st__yushi.name) then return false end
    if player:getMark("st__yushi_waiting") == 0 then
      return false
    end
    return true
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local currentKingdom = player.kingdom

    local choices = {}
    if currentKingdom ~= "qun" then
      table.insert(choices, "变更势力至「群」")
    end
    if currentKingdom ~= "wei" then
      table.insert(choices, "变更势力至「魏」")
    end
    table.insert(choices, "保持势力不变")

    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = st__yushi.name,
      prompt = "驭势触发，请选择势力变更",
    })
    if not choice or choice == "" then
      choice = "保持势力不变"
    end

    event:setCostData(self, { choice = choice })
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local costData = event:getCostData(self)
    local choice = costData.choice
    local oldKingdom = player.kingdom
    local newKingdom = oldKingdom

    player:setMark("st__yushi_waiting", 0)

    if choice == "变更势力至「群」" then
      newKingdom = "qun"
      room:changeKingdom(player, newKingdom, true)
      room:sendLog{
        type = "#st__YushiChangeKingdom",
        from = player.id,
        arg = oldKingdom,
        arg2 = newKingdom
      }
    elseif choice == "变更势力至「魏」" then
      newKingdom = "wei"
      room:changeKingdom(player, newKingdom, true)
      room:sendLog{
        type = "#st__YushiChangeKingdom",
        from = player.id,
        arg = oldKingdom,
        arg2 = newKingdom
      }
    else
      room:sendLog{
        type = "#st__YushiKeepKingdom",
        from = player.id,
        arg = oldKingdom
      }
    end

    if choice ~= "保持势力不变" then
      player.room:setPlayerMark(player, "@st__chouwo", 0)
    end

    local drawPile = room.draw_pile
    local candidateCards = {}
    if newKingdom == "qun" then
      for _, cardId in ipairs(drawPile) do
        local card = Fk:getCardById(cardId)
        if card and card.type == Card.TypeEquip then
          table.insert(candidateCards, cardId)
        end
      end
    elseif newKingdom == "wei" then
      local wisdomNames = { "ex_nihilo", "nullification", "dismantlement" }
      for _, cardId in ipairs(drawPile) do
        local card = Fk:getCardById(cardId)
        if card and table.contains(wisdomNames, card.name) then
          table.insert(candidateCards, cardId)
        end
      end
    end

    if #candidateCards > 0 then
      local selectedCardId = candidateCards[math.random(1, #candidateCards)]
      local cardObj = Fk:getCardById(selectedCardId)
      room:moveCardTo(selectedCardId, Card.PlayerHand, player, fk.ReasonPrey, st__yushi.name, nil, true, player)
      room:sendLog{
        type = "#st__YushiGetReward",
        from = player.id,
        arg = newKingdom == "qun" and "装备牌" or "智囊牌",
        arg2 = cardObj.name
      }
    end

    player:setMark("st__yushi_count", 0)
    player.room:setPlayerMark(player, "@st__yushi_count", 0)
    for _, mark in ipairs(player:getMarkNames()) do
      if string.find(mark, "^st__yushi_card_counted_") then
        player:setMark(mark, 0)
      end
    end

    local clearCount = player:getMark("@st__yushi_clear") or 0
    player:setMark("@st__yushi_clear", clearCount + 1)
  end,
})

-- 回合结束清理等待标记
st__yushi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(st__yushi.name) and player.phase == Player.NotActive
  end,
  on_trigger = function(self, event, target, player, data)
    player:setMark("st__yushi_waiting", 0)
  end,
})

print("驭势技能(st__yushi)加载完成")
return st__yushi