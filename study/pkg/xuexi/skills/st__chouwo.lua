-- ========== 筹幄技能 (st__chouwo) ==========
print("=== 加载筹幄技能(st__chouwo) ===")
local st__chouwo = fk.CreateSkill {
  name = "st__chouwo",
  tags = { Skill.AttachedKingdom },
  attached_kingdom ={"wei"} ,
}

Fk:loadTranslationTable{
  ["st__chouwo"] = "筹幄",
  [":st__chouwo"] = "魏势力技，你记录你于回合内使用基本牌和锦囊牌指定目标的次数。" ..
    "当你使用第三张基本牌或锦囊牌指定目标时，你选择一项：1.此牌对其中一个目标额外结算一次；2.此牌目标加一；3.此牌结算后，你摸3-X张牌（X为手牌花色数）。然后清除〖筹幄〗的记录次数。",
  
  ["@st__chouwo"] = "筹幄",
  ["#st__chouwo-choose"] = "筹幄：请选择一项",
  ["#st__ChouwoExtraUse"] = "%from 的【筹幄】触发，%arg 将额外结算一次",
  ["#st__ChouwoAddTarget"] = "%from 的【筹幄】触发，%arg 增加目标 %to",
  ["#st__ChouwoDrawAfterUse"] = "%from 的【筹幄】触发，%arg 将在 %arg2 结算后摸 %arg 张牌",
  ["#st__chouwo-add-target"] = "筹幄：请为此%arg额外指定一个目标",
}

st__chouwo:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(st__chouwo.name) and player.phase == Player.Play and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      data.firstTarget then
      
      -- 检查这张牌是否已为本玩家计数过（与驭势相同的逻辑）
      local cardMarkName = "st__chouwo_card_counted_" .. data.card.id
      if player:getMark(cardMarkName) > 0 then
        return false
      end
      
      -- 标记这张牌已计数
      player:setMark(cardMarkName, 1)
      
      -- 获取当前回合使用的基本牌和锦囊牌数量
      local room = player.room
      local currentCount = player:getMark("@st__chouwo") or 0
      local newCount = currentCount + 1
      player.room:setPlayerMark(player, "@st__chouwo", newCount)
      
      -- 当计数达到3时触发效果
      if newCount == 3 then
        return true
      end
    end
    return false
  end,
  
  on_use = function(self, event, target, player, data)
    local room = player.room
    
    -- 提供三个选项
    local choices = {
      "此牌对其中一个目标额外结算一次",
      "此牌目标加一", 
      "此牌结算后，你摸3-X张牌（X为手牌花色数）",
    }
    
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = st__chouwo.name,
      prompt = "#st__chouwo-choose",
    })
    
    if not choice or choice == "" then
      choice = choices[1]  -- 默认选择第一个选项
    end
    
    if choice == "此牌对其中一个目标额外结算一次" then
      -- 设置标记让牌额外结算一次
      data.use.additionalEffect = (data.use.additionalEffect or 0) + 1
      room:sendLog{
        type = "#st__ChouwoExtraUse",
        from = player.id,
        arg = data.card.name
      }
      
    elseif choice == "此牌目标加一" then
      -- 使用 benxi 风格的额外目标选择
      local extraTargets = data:getExtraTargets()
      if #extraTargets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = extraTargets,
          min_num = 1,
          max_num = 1,
          prompt = "#st__chouwo-add-target:::"..data.card.name,
          skill_name = st__chouwo.name,
          cancelable = true,
        })
        if #to > 0 then
          data:addTarget(to[1])
          room:sendLog{
            type = "#st__ChouwoAddTarget",
            from = player.id,
            to = {to[1].id},
            arg = data.card.name
          }
        end
      end
      
    elseif choice == "此牌结算后，你摸3-X张牌（X为手牌花色数）" then
      -- 计算手牌花色数
      local handcards = player:getCardIds(Player.Hand)
      local suits = {}
      for _, id in ipairs(handcards) do
        local card = Fk:getCardById(id)
        if card then
          suits[card.suit] = true
        end
      end
      local suitCount = 0
      for _ in pairs(suits) do
        suitCount = suitCount + 1
      end
      
      local drawNum = 3 - suitCount
      if drawNum < 0 then drawNum = 0 end
      
      -- 设置标记，在牌结算后摸牌
      room:setCardMark(data.card, "st__chouwo_draw_after", drawNum)
      room:setCardMark(data.card, "st__chouwo_draw_player", player.id)
      
      room:sendLog{
        type = "#st__ChouwoDrawAfterUse",
        from = player.id,
        arg = tostring(drawNum),
        arg2 = data.card.name
      }
    end
    
    -- 清除计数（第三张牌触发后清除）
    player.room:setPlayerMark(player, "@st__chouwo", 0)
    
    -- 清除所有牌计数标记
    for _, mark in ipairs(player:getMarkNames()) do
      if string.find(mark, "^st__chouwo_card_counted_") then
        player:setMark(mark, 0)
      end
    end
  end,
})

-- 牌结算后摸牌效果
st__chouwo:addEffect(fk.CardEffectFinished, {
  can_trigger = function(self, event, target, player, data)
    if not data or not data.card then return false end
    return data.card:getMark("st__chouwo_draw_after") > 0
  end,
  
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local card = data.card
    local drawNum = card:getMark("st__chouwo_draw_after")
    local playerId = card:getMark("st__chouwo_draw_player")
    local p = room:getPlayerById(playerId)
    
    if p and drawNum > 0 then
      room:drawCards(p, drawNum, st__chouwo.name)
    end
    
    -- 清除标记
    room:setCardMark(card, "st__chouwo_draw_after", 0)
    room:setCardMark(card, "st__chouwo_draw_player", 0)
  end,
})

print("筹幄技能(st__chouwo)加载完成")
return st__chouwo