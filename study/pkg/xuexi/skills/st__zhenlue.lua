-- ========== 缜略技能 (st__zhenlue) ==========
print("=== 加载缜略技能(st__zhenlue) ===")
local st__zhenlue = fk.CreateSkill {
  name = "st__zhenlue",
  tags = { Skill.AttachedKingdom, Skill.Compulsory },
  attached_kingdom = {"wei"},
}

Fk:loadTranslationTable {
  ["st__zhenlue"] = "缜略",
  [":st__zhenlue"] = "魏势力技，锁定技，你使用的普通锦囊牌不能被【无懈可击】响应，延时类锦囊牌对你无效。",
}

-- 效果1：你使用的普通锦囊牌不能被【无懈可击】响应
st__zhenlue:addEffect(fk.AfterCardUseDeclared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(st__zhenlue.name) and
           data and data.card and data.card:isCommonTrick()
  end,
  on_use = function(self, event, target, player, data)
    if data.unoffsetableList then
      -- 如果已经有不可被无懈的列表，合并进去
      for _, p in ipairs(player.room.players) do
        table.insertIfNeed(data.unoffsetableList, p)
      end
    else
      -- 创建一个包含所有玩家的不可被无懈列表
      data.unoffsetableList = table.simpleClone(player.room.players)
    end
    print("缜略: 玩家", player.general, "使用的", data.card.name, "不能被无懈可击响应")
  end,
})

-- 效果2a：禁止成为延时锦囊牌的目标
st__zhenlue:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    if not to or not card then return false end
    return to:hasSkill(st__zhenlue.name) and 
           card.sub_type == Card.SubtypeDelayedTrick
  end,
})

-- 效果2b：处理延时锦囊牌移动到贾诩判定区的情况
st__zhenlue:addEffect(fk.BeforeCardsMove, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if not player or not player:hasSkill(st__zhenlue.name) then return false end
    if not data then return false end
    
    -- 检查是否有牌要移动到玩家的判定区
    for _, move in ipairs(data) do
      if move and move.to == player and move.toArea == Card.PlayerJudge then
        for _, info in ipairs(move.moveInfo) do
          if info and info.cardId then
            local card = Fk:getCardById(info.cardId)
            -- 使用 sub_type 检查是否为延时锦囊
            if card and card.sub_type == Card.SubtypeDelayedTrick then
              return true
            end
          end
        end
      end
    end
    return false
  end,
  
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mirror_moves = {}
    
    -- 遍历所有移动，找到需要处理的
    for i = #data, 1, -1 do
      local move = data[i]
      if move and move.to == player and move.toArea == Card.PlayerJudge then
        for j = #move.moveInfo, 1, -1 do
          local info = move.moveInfo[j]
          if info and info.cardId then
            local card = Fk:getCardById(info.cardId)
            -- 使用 sub_type 检查是否为延时锦囊
            if card and card.sub_type == Card.SubtypeDelayedTrick then
              -- 获取移动来源区域
              local fromArea = info.fromArea
              
              -- 检查移动来源：如果是从其他角色的判定区移动（闪电传递），则允许传递到下家
              if move.from and fromArea == Card.PlayerJudge and 
                 move.from ~= player then
                -- 这是闪电从上家传递到下家，允许继续传递
                -- 但是缜略要求延时锦囊对贾诩无效，所以不能停留在贾诩这里
                -- 我们需要将这个延时锦囊移动到弃牌堆
                table.remove(move.moveInfo, j)
                if #move.moveInfo == 0 then
                  table.remove(data, i)
                end
                
                -- 创建新的移动到弃牌堆的移动
                local mirror_move = {
                  from = move.from,
                  to = nil,
                  fromArea = fromArea,
                  toArea = Card.DiscardPile,
                  ids = {info.cardId},
                  moveInfo = {{cardId = info.cardId, fromArea = fromArea}},
                  moveReason = fk.ReasonJustMove,
                  skillName = st__zhenlue.name,
                }
                table.insert(mirror_moves, mirror_move)
              else
                -- 这是直接对贾诩使用延时锦囊，将其改为移动到弃牌堆
                table.remove(move.moveInfo, j)
                if #move.moveInfo == 0 then
                  table.remove(data, i)
                end
                
                local mirror_move = {
                  from = move.from,
                  to = nil,
                  fromArea = fromArea,
                  toArea = Card.DiscardPile,
                  ids = {info.cardId},
                  moveInfo = {{cardId = info.cardId, fromArea = fromArea}},
                  moveReason = fk.ReasonJustMove,
                  skillName = st__zhenlue.name,
                }
                table.insert(mirror_moves, mirror_move)
              end
            end
          end
        end
      end
    end
    
    -- 添加新的移动到弃牌堆的移动
    for _, mirror_move in ipairs(mirror_moves) do
      table.insert(data, mirror_move)
    end
    
    if #mirror_moves > 0 then
      print("缜略: 拦截了", #mirror_moves, "张延时锦囊移动到贾诩的判定区")
    end
  end,
})

print("缜略技能(st__zhenlue)加载完成")
return st__zhenlue