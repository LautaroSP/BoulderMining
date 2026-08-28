BoulderMining = {}

BoulderMining.TilesetName = "boulders"

BoulderMining.Groups = {
    DECORATIVE_1x1 = {
        tiles = {0, 1, 2, 3, 4, 5, 6, 7},
        blocks = true,
        multiTile = false,
        drops = {"Base.LargeStone"},
        dropCountMin = 1,
        dropCountMax = 1,
        baseTime = 300,
        xp = 10,
        label = "Pick Boulder",
    },
    GROUND_COVER = {
        tiles = {8, 9, 10, 11, 12, 13, 14, 15},
        blocks = false,
        multiTile = false,
        drops = {"Base.Stone2"},
        dropCountMin = 1,
        dropCountMax = 1,
        baseTime = 100,
        xp = 5,
        label = "Pick Up Stone",
    },
    LARGE_2x2 = {
        tiles = {16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31},
        blocks = true,
        multiTile = true,
        tilesPerGroup = 4,
        drops = {"Base.LargeStone"},
        dropCountMin = 2,
        dropCountMax = 2,
        baseTime = 600,
        xp = 15,
        label = "Pick Boulder",
    },
    MEDIUM = {
        tiles = {32, 33, 34, 35},
        blocks = true,
        multiTile = true,
        tilesPerGroup = 2,
        drops = {"Base.LargeStone"},
        dropCountMin = 1,
        dropCountMax = 1,
        baseTime = 400,
        xp = 10,
        label = "Pick Boulder",
    },
    FLOOR_STONE = {
        tiles = {40, 41, 42, 43, 44, 45, 46, 47},
        blocks = false,
        multiTile = false,
        drops = {"Base.Stone2"},
        dropCountMin = 1,
        dropCountMax = 1,
        baseTime = 100,
        xp = 5,
        label = "Pick Up Stone",
    },
    GROUND_COVER_2 = {
        tiles = {48, 49, 50, 51, 52, 53, 54, 55},
        blocks = false,
        multiTile = false,
        drops = {"Base.Stone2"},
        dropCountMin = 1,
        dropCountMax = 1,
        baseTime = 100,
        xp = 5,
        label = "Pick Up Stone",
    },
    FLOOR_STONE_2 = {
        tiles = {56, 57, 58, 59, 60, 61, 62, 63},
        blocks = false,
        multiTile = false,
        drops = {"Base.Stone2"},
        dropCountMin = 1,
        dropCountMax = 1,
        baseTime = 100,
        xp = 5,
        label = "Pick Up Stone",
    },
}

BoulderMining.HammerTypes = {
    "Hammer", "HammerForged", "HammerStone",
    "BallPeenHammer", "BallPeenHammerForged", "SmithingHammer",
    "ClubHammer", "ClubHammerForged",
}

BoulderMining.ChiselTypes = {
    "StoneChisel", "MasonsChisel", "CarpentryChisel",
}

function BoulderMining.getGroupByTileIndex(tileIndex)
    for name, group in pairs(BoulderMining.Groups) do
        for _, idx in ipairs(group.tiles) do
            if idx == tileIndex then
                return name, group
            end
        end
    end
    return nil, nil
end

function BoulderMining.getTileIndexFromSpriteName(spriteName)
    if not spriteName then return nil end
    local prefix = BoulderMining.TilesetName .. "_"
    if string.sub(spriteName, 1, #prefix) ~= prefix then return nil end
    local numStr = string.sub(spriteName, #prefix + 1)
    return tonumber(numStr)
end

function BoulderMining.getAdjustedTime(baseTime, strengthLevel)
    local multiplier = 1 + (0.10 * (5 - strengthLevel))
    return math.floor(baseTime * multiplier)
end

function BoulderMining.canMine(playerObj)
    local toolType, toolItem, hammerItem = BoulderMining.getToolType(playerObj)
    return toolType ~= nil, toolType, toolItem, hammerItem
end

function BoulderMining.getToolType(playerObj)
    local inv = playerObj:getInventory()

    local pickaxe = inv:Find("PickAxe")
    if pickaxe and not pickaxe:isBroken() then
        return "Pickaxe", pickaxe
    end
    pickaxe = inv:Find("PickAxeForged")
    if pickaxe and not pickaxe:isBroken() then
        return "Pickaxe", pickaxe
    end

    for _, hammerType in ipairs(BoulderMining.HammerTypes) do
        local hammer = inv:Find(hammerType)
        if hammer and not hammer:isBroken() then
            for _, chiselType in ipairs(BoulderMining.ChiselTypes) do
                local chisel = inv:Find(chiselType)
                if chisel and not chisel:isBroken() then
                    return "HammerChisel", chisel, hammer
                end
            end
        end
    end

    return nil, nil, nil
end
