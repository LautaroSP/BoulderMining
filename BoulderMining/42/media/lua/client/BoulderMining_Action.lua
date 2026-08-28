ISBoulderMiningAction = ISBaseTimedAction:derive("ISBoulderMiningAction")

function ISBoulderMiningAction:new(character, targetObj, group, toolItem, toolType, hammerItem, groupName)
    local o = ISBaseTimedAction.new(self, character)
    o.targetObj = targetObj
    o.group = group
    o.groupName = groupName
    o.toolItem = toolItem
    o.toolType = toolType
    o.hammerItem = hammerItem
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = BoulderMining.getAdjustedTime(group.baseTime, character:getPerkLevel(Perks.Strength))
    o.sound = 0
    o.done = false
    return o
end

function ISBoulderMiningAction:isValid()
    return self.targetObj ~= nil
end

function ISBoulderMiningAction:start()
    if self.toolType == "Pickaxe" then
        self:setActionAnim("HammerOre")
        self:setOverrideHandModels(self.toolItem, nil)
        self.character:playSound(self.toolItem:getSwingSound())
    elseif self.toolType == "HammerChisel" then
        self:setActionAnim("DestroyFloor")
        local displayItem = self.hammerItem or self.toolItem
        self:setOverrideHandModels(displayItem, nil)
    else
        self:setActionAnim("DestroyFloor")
    end
end

function ISBoulderMiningAction:stop()
    if self.sound and self.sound ~= 0 then
        self.character:stopOrTriggerSound(self.sound)
    end
    ISBaseTimedAction.stop(self)
end

function ISBoulderMiningAction:animEvent(event, parameter)
    if event == "PlaySwingSound" then
        if self.toolType == "Pickaxe" then
            self.character:playSound(self.toolItem:getSwingSound())
        elseif self.toolType == "HammerChisel" then
            self.character:playSound(self.hammerItem:getSwingSound())
        end
    end
    if event == "PlayHitSound" then
        if self.toolType == "Pickaxe" then
            self.character:setMeleeHitSurface("Default")
            self.character:playSound(self.toolItem:getDoorHitSound())
        elseif self.toolType == "HammerChisel" then
            self.character:setMeleeHitSurface("Default")
            self.character:playSound(self.hammerItem:getDoorHitSound())
        end
    end
end

function ISBoulderMiningAction:update()
    if self.toolType == "HammerChisel" then
        if not self.sound or self.sound == 0 or not self.character:getEmitter():isPlaying(self.sound) then
            self.sound = self.character:getEmitter():playSound(self.hammerItem:getSwingSound())
        end
    end
end

function ISBoulderMiningAction:perform()
    if self.sound and self.sound ~= 0 then
        self.character:stopOrTriggerSound(self.sound)
    end

    self:removeBoulder()

    if isClient() then
        sendClientCommand("BoulderMining", "mineBoulder", {
            x = self.targetObj:getSquare():getX(),
            y = self.targetObj:getSquare():getY(),
            z = self.targetObj:getSquare():getZ(),
            groupName = self.groupName,
            toolType = self.toolType,
        })
    else
        self:spawnDrops()
        self:grantXP()
        self:damageTool()
    end

    self.done = true
    ISBaseTimedAction.perform(self)
end

function ISBoulderMiningAction:removeBoulder()
    local square = self.targetObj:getSquare()
    if not square then return end

    if self.group.multiTile then
        self:removeMultiTileBoulder(square)
    else
        self:removeSingleTileBoulder(square)
    end
end

function ISBoulderMiningAction:removeMultiTileBoulder(square)
    local sprite = self.targetObj:getSprite()
    if not sprite then return end

    local spriteGrid = sprite:getSpriteGrid()
    if not spriteGrid then
        self:removeSingleTileBoulder(square)
        return
    end

    local posX = spriteGrid:getSpriteGridPosX(sprite)
    local posY = spriteGrid:getSpriteGridPosY(sprite)
    local baseX = square:getX() - posX
    local baseY = square:getY() - posY
    local z = square:getZ()

    for x = 0, spriteGrid:getWidth() - 1 do
        for y = 0, spriteGrid:getHeight() - 1 do
            local tileSquare = getCell():getGridSquare(baseX + x, baseY + y, z)
            if tileSquare then
                local tileSprite = spriteGrid:getSprite(x, y)
                if tileSprite then
                    local tileName = tileSprite:getName()
                    for i = tileSquare:getObjects():size() - 1, 0, -1 do
                        local obj = tileSquare:getObjects():get(i)
                        if obj:getSprite() and obj:getSprite():getName() == tileName then
                            if isClient() then
                                sledgeDestroy(obj)
                            else
                                tileSquare:transmitRemoveItemFromSquare(obj)
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end

function ISBoulderMiningAction:removeSingleTileBoulder(square)
    local sprite = self.targetObj:getSprite()
    if not sprite then return end

    local spriteName = sprite:getName()
    for i = square:getObjects():size() - 1, 0, -1 do
        local obj = square:getObjects():get(i)
        if obj:getSprite() and obj:getSprite():getName() == spriteName then
            if isClient() then
                sledgeDestroy(obj)
            else
                square:transmitRemoveItemFromSquare(obj)
            end
            break
        end
    end
end

function ISBoulderMiningAction:spawnDrops()
    local square = self.targetObj:getSquare()
    if not square then return end

    local dropCount = ZombRand(self.group.dropCountMin, self.group.dropCountMax + 1)
    for i = 1, dropCount do
        local itemName = self.group.drops[1]
        local itemInstance = instanceItem(itemName)
        if itemInstance then
            square:AddWorldInventoryItem(itemInstance, 0, 0, 0)
        end
    end
end

function ISBoulderMiningAction:grantXP()
    addXp(self.character, Perks.Strength, self.group.xp)
end

function ISBoulderMiningAction:damageTool()
    if not self.toolItem then return end

    if ZombRand(100) < 10 then
        self.toolItem:setBroken(true)
    else
        self.toolItem:setCondition(self.toolItem:getCondition() - ZombRand(3, 8))
    end
end
