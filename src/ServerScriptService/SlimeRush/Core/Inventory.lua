local Inventory = {}
Inventory.__index = Inventory

local SLOT_UPGRADES = {
    {multiplier = 1.2, gelatin = 2500, essence = 0},
    {multiplier = 1.3, gelatin = 7500, essence = 5},
    {multiplier = 1.5, gelatin = 20000, essence = 20},
    {multiplier = 1.8, gelatin = 60000, essence = 65},
    {multiplier = 2.0, gelatin = 0, essence = 0, robuxProductId = 123456},
}

local BASE_SLOTS = 25

function Inventory.createInventory(userId)
    local inventory = setmetatable({
        UserId = userId,
        Capacity = BASE_SLOTS,
        Slimes = {},
        UpgradeLevel = 0,
    }, Inventory)

    return inventory
end

function Inventory:addSlime(slime)
    if #self.Slimes >= self.Capacity then
        return false, "FULL"
    end

    table.insert(self.Slimes, slime)
    return true, slime
end

function Inventory:removeSlime(slimeId)
    for index, slime in ipairs(self.Slimes) do
        if slime.Id == slimeId then
            table.remove(self.Slimes, index)
            return slime
        end
    end
    return nil
end

function Inventory.getNextUpgrade(level)
    return SLOT_UPGRADES[level + 1]
end

function Inventory.attemptUpgrade(inventory, wallet)
    local nextUpgrade = Inventory.getNextUpgrade(inventory.UpgradeLevel)
    if not nextUpgrade then
        return false, "MAX_LEVEL"
    end

    if nextUpgrade.robuxProductId then
        return false, "ROBLOX_PURCHASE_REQUIRED"
    end

    if not wallet:CanAfford(nextUpgrade.gelatin, nextUpgrade.essence) then
        return false, "INSUFFICIENT_FUNDS"
    end

    wallet:Withdraw(nextUpgrade.gelatin, nextUpgrade.essence)
    inventory.UpgradeLevel = inventory.UpgradeLevel + 1
    inventory.Capacity = math.floor(BASE_SLOTS * nextUpgrade.multiplier)

    return true, {
        capacity = inventory.Capacity,
        level = inventory.UpgradeLevel,
    }
end

function Inventory.serialize(inventory)
    local payload = {
        capacity = inventory.Capacity,
        level = inventory.UpgradeLevel,
        slimes = {},
    }

    for _, slime in ipairs(inventory.Slimes) do
        table.insert(payload.slimes, slime)
    end

    return payload
end

return Inventory
