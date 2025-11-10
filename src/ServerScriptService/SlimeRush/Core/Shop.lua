local HttpService = game:GetService("HttpService")

local Economy = require(script.Parent:WaitForChild("Economy"))
local SlimeCatalog = require(script.Parent:WaitForChild("SlimeCatalog"))

local Shop = {}

local PREVIEW_TIMEOUT = 45
local CATALYST_STOCK = {
    rarity = {baseCost = 4200, essenceCost = 12, dailyStock = 30},
    state = {baseCost = 6800, essenceCost = 18, dailyStock = 20},
    omni = {baseCost = 14000, essenceCost = 42, dailyStock = 6},
}

local function now()
    return os.time()
end

function Shop.seedPersonalPreview(player, profile)
    profile.Previews = {}
    for index = 1, 3 do
        local archetype = SlimeCatalog.rollArchetype(profile)
        profile.Previews[index] = {
            id = HttpService:GenerateGUID(false),
            archetype = archetype,
            expiresAt = now() + PREVIEW_TIMEOUT,
            cost = Economy.calculateSlimeCost(archetype),
        }
    end
end

local function getPreview(profile, previewId)
    for _, preview in pairs(profile.Previews) do
        if preview.id == previewId then
            return preview
        end
    end
    return nil
end

function Shop.finalizePurchase(player, profile, previewId, catalystId)
    local preview = getPreview(profile, previewId)
    if not preview then
        return false, "INVALID_PREVIEW"
    end

    if preview.expiresAt < now() then
        return false, "PREVIEW_EXPIRED"
    end

    local wallet = profile.Currency
    local catalyst = catalystId and Shop.consumeCatalyst(profile, catalystId) or nil

    local totalCost = preview.cost
    if catalyst and catalyst.type == "rarity" then
        totalCost = math.floor(totalCost * 0.85)
    end

    if not wallet:CanAfford(totalCost) then
        return false, "INSUFFICIENT_FUNDS"
    end

    wallet:Withdraw(totalCost)

    local slimeId = HttpService:GenerateGUID(false)
    local archetype = table.clone(preview.archetype)
    archetype.Id = slimeId
    archetype.Owner = player.UserId

    local ok, reason = profile.Inventory:addSlime(archetype)
    if not ok then
        wallet:Deposit(totalCost)
        if catalyst then
            profile.Catalysts = profile.Catalysts or {}
            table.insert(profile.Catalysts, catalyst)
        end
        return false, reason
    end

    Shop.seedPersonalPreview(player, profile)

    return true, archetype
end

function Shop.consumeCatalyst(profile, catalystId)
    profile.Catalysts = profile.Catalysts or {}
    for index, catalyst in ipairs(profile.Catalysts) do
        if catalyst.id == catalystId then
            table.remove(profile.Catalysts, index)
            return catalyst
        end
    end
    return nil
end

function Shop.refreshCatalystStock(state)
    state.CatalystStock = {}
    for key, config in pairs(CATALYST_STOCK) do
        state.CatalystStock[key] = {
            remaining = config.dailyStock,
            config = config,
        }
    end
    state.StockRefreshedAt = now()
end

function Shop.ensureDailyStock(profile)
    Shop.GlobalState = Shop.GlobalState or {}
    local state = Shop.GlobalState
    if not state.StockRefreshedAt then
        Shop.refreshCatalystStock(state)
    end

    local day = os.date("*t", now()).yday
    if state.LastRefreshDay ~= day then
        Shop.refreshCatalystStock(state)
        state.LastRefreshDay = day
    end

    profile.Catalysts = profile.Catalysts or {}
    return state
end

function Shop.purchaseCatalyst(profile, catalystType)
    local state = Shop.ensureDailyStock(profile)
    local stock = state.CatalystStock[catalystType]
    if not stock or stock.remaining <= 0 then
        return false, "OUT_OF_STOCK"
    end

    local config = stock.config
    if not profile.Currency:CanAfford(config.baseCost, config.essenceCost) then
        return false, "INSUFFICIENT_FUNDS"
    end

    profile.Currency:Withdraw(config.baseCost, config.essenceCost)
    stock.remaining = stock.remaining - 1

    local catalyst = {
        id = HttpService:GenerateGUID(false),
        type = catalystType,
        expiresAt = now() + (24 * 60 * 60),
    }

    table.insert(profile.Catalysts, catalyst)
    return true, catalyst
end

function Shop.getShopSnapshot(profile)
    local state = Shop.ensureDailyStock(profile)
    local snapshot = {
        previews = {},
        catalysts = {},
    }

    for _, preview in ipairs(profile.Previews) do
        table.insert(snapshot.previews, {
            id = preview.id,
            archetype = preview.archetype,
            cost = preview.cost,
            expiresAt = preview.expiresAt,
        })
    end

    for catalystType, stock in pairs(state.CatalystStock) do
        snapshot.catalysts[catalystType] = {
            remaining = stock.remaining,
            cost = stock.config.baseCost,
            essenceCost = stock.config.essenceCost,
        }
    end

    return snapshot
end

return Shop
