BoulderMining_Context = {}

function BoulderMining_Context.onFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end

    local playerObj = getSpecificPlayer(player)
    if not playerObj or playerObj:isAsleep() then return false end

    local targetObj = nil
    local targetSpriteName = nil

    for _, isoObject in ipairs(worldobjects) do
        local sprite = isoObject:getSprite()
        if sprite then
            local spriteName = sprite:getName()
            if spriteName then
                local tileIndex = BoulderMining.getTileIndexFromSpriteName(spriteName)
                if tileIndex then
                    local _, group = BoulderMining.getGroupByTileIndex(tileIndex)
                    if group then
                        targetObj = isoObject
                        targetSpriteName = spriteName
                        break
                    end
                end
            end
        end
    end

    if not targetObj then return false end
    if test then return ISWorldObjectContextMenu.setTest() end

    local tileIndex = BoulderMining.getTileIndexFromSpriteName(targetSpriteName)
    local groupName, group = BoulderMining.getGroupByTileIndex(tileIndex)
    if not group then return false end

    local canMine, toolType, toolItem, hammerItem = BoulderMining.canMine(playerObj)

    if group.blocks then
        if not canMine then
            local option = context:addOption(group.label, worldobjects, nil)
            option.notAvailable = true
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip:setName(group.label)
            tooltip.description = "Requires a Pickaxe or Hammer + Chisel."
            option.toolTip = tooltip
            return true
        end

        local adjustedTime = BoulderMining.getAdjustedTime(group.baseTime, playerObj:getPerkLevel(Perks.Strength))
        local timeStr = math.floor(adjustedTime / 20) .. "s"

        local option = context:addOption(group.label, worldobjects, BoulderMining_Context.onMine, playerObj, targetObj, groupName, group)

        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip:setName(group.label)
        if toolType == "Pickaxe" then
            tooltip.description = "Tool: " .. toolItem:getName()
        elseif toolType == "HammerChisel" then
            tooltip.description = "Tool: " .. hammerItem:getName() .. " + " .. toolItem:getName()
        end
        tooltip.description = tooltip.description .. "\nTime: ~" .. timeStr
        tooltip.description = tooltip.description .. "\nDrops: " .. group.dropCountMin .. "x " .. string.gsub(group.drops[1], "Base.", "")
        tooltip.description = tooltip.description .. "\nXP: " .. group.xp .. " Strength"
        option.toolTip = tooltip

        return true
    else
        local adjustedTime = BoulderMining.getAdjustedTime(group.baseTime, playerObj:getPerkLevel(Perks.Strength))
        local timeStr = math.floor(adjustedTime / 20) .. "s"

        local option = context:addOption(group.label, worldobjects, BoulderMining_Context.onPickup, playerObj, targetObj, groupName, group)

        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip:setName(group.label)
        tooltip.description = "Time: ~" .. timeStr
        tooltip.description = tooltip.description .. "\nDrops: 1x " .. string.gsub(group.drops[1], "Base.", "")
        tooltip.description = tooltip.description .. "\nXP: " .. group.xp .. " Strength"
        option.toolTip = tooltip

        return true
    end
end

function BoulderMining_Context.onMine(worldobjects, playerObj, targetObj, groupName, group)
    if luautils.walkAdj(playerObj, targetObj:getSquare()) then
        local canMine, toolType, toolItem, hammerItem = BoulderMining.canMine(playerObj)
        if canMine then
            ISTimedActionQueue.add(ISBoulderMiningAction:new(playerObj, targetObj, group, toolItem, toolType, hammerItem, groupName))
        end
    end
end

function BoulderMining_Context.onPickup(worldobjects, playerObj, targetObj, groupName, group)
    if luautils.walkAdj(playerObj, targetObj:getSquare()) then
        ISTimedActionQueue.add(ISBoulderMiningAction:new(playerObj, targetObj, group, nil, "Pickup", nil, groupName))
    end
end

Events.OnFillWorldObjectContextMenu.Add(BoulderMining_Context.onFillWorldObjectContextMenu)
