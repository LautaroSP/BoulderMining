BoulderMining_Server = {}

function BoulderMining_Server.onClientCommand(module, command, player, args)
    if module ~= "BoulderMining" then return end

    if command == "mineBoulder" then
        local squareX = args.x
        local squareY = args.y
        local squareZ = args.z
        local groupName = args.groupName
        local toolType = args.toolType

        local playerObj = getSpecificPlayer(player)
        if not playerObj then return end

        local group = BoulderMining.Groups[groupName]
        if not group then return end

        local square = getCell():getGridSquare(squareX, squareY, squareZ)
        if not square then return end

        local dist = playerObj:DistTo(square:getX(), square:getY())
        if dist > 3 then return end

        if group.blocks then
            if toolType ~= "Pickaxe" and toolType ~= "HammerChisel" then return end
        end

        local toolItem = nil
        if toolType == "Pickaxe" then
            toolItem = playerObj:getInventory():Find("PickAxe")
            if not toolItem or toolItem:isBroken() then
                toolItem = playerObj:getInventory():Find("PickAxeForged")
            end
        elseif toolType == "HammerChisel" then
            for _, hammerType in ipairs(BoulderMining.HammerTypes) do
                local item = playerObj:getInventory():Find(hammerType)
                if item and not item:isBroken() then
                    toolItem = item
                    break
                end
            end
        end

        if group.blocks and not toolItem then return end

        addXp(playerObj, Perks.Strength, group.xp)

        local dropCount = ZombRand(group.dropCountMin, group.dropCountMax + 1)
        for i = 1, dropCount do
            local itemInstance = instanceItem(group.drops[1])
            if itemInstance then
                square:AddWorldInventoryItem(itemInstance, 0, 0, 0)
            end
        end

        if toolItem then
            if ZombRand(100) < 10 then
                toolItem:setBroken(true)
            else
                toolItem:setCondition(toolItem:getCondition() - ZombRand(3, 8))
            end
        end
    end
end

if isServer() then
    Events.OnClientCommand.Add(BoulderMining_Server.onClientCommand)
end
