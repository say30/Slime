-- ========================================
-- SLIME RUSH - SHOP MANAGER
-- Script (Serveur)
-- Localisation: ServerScriptService/ShopManager
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local ShopConfig = require(ReplicatedStorage.Modules.ShopConfig)
local DataManager = require(ReplicatedStorage.Modules.DataManager)
local DataStoreManager = require(script.Parent.DataStoreManager)

local ShopManager = {}

-- ========================================
-- INITIALISER SHOP
-- ========================================

function ShopManager.InitializeShop(player)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    -- Vérifier reset journalier
    if os.time() >= playerData.LastShopReset + 86400 then
        playerData.ShopCooldowns = {}
        playerData.LastShopReset = os.time()
        DataStoreManager.UpdatePlayerData(player, playerData)
    end
end

-- ========================================
-- ACHETER ITEM
-- ========================================

function ShopManager.PurchaseItem(player, itemID)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    -- Trouver item
    local item = nil
    for _, boost in ipairs(ShopConfig.TemporaryBoosts) do
        if boost.ID == itemID then
            item = boost
            break
        end
    end

    if not item then
        for _, catalyst in ipairs(ShopConfig.Catalysts) do
            if catalyst.ID == itemID then
                item = catalyst
                break
            end
        end
    end

    if not item then
        for _, perm in ipairs(ShopConfig.PermanentUpgrades) do
            if perm.ID == itemID then
                item = perm
                break
            end
        end
    end

    if not item then return end

    -- Vérifier cooldown
    if DataManager.IsShopItemOnCooldown(playerData, itemID) then
        ReplicatedStorage.RemoteEvents.BuyShopItem:FireClient(player, false, "Item en cooldown")
        return
    end

    -- Calculer coût avec réductions
    local cost = ShopConfig.ApplyDiscount({Gelatin = item.CostGelatin or 0, Essence = item.CostEssence or 0}, playerData)

    -- Vérifier ressources
    if not EconomyConfig.CanAfford(playerData, cost.Gelatin, cost.Essence) then
        ReplicatedStorage.RemoteEvents.BuyShopItem:FireClient(player, false, "Ressources insuffisantes")
        return
    end

    -- Déduire coût
    playerData.Gelatin = playerData.Gelatin - cost.Gelatin
    playerData.Essence = playerData.Essence - cost.Essence

    -- Appliquer effet
    if item.Duration then
        -- Boost temporaire
        DataManager.AddActiveBoost(playerData, itemID, item.Duration)
        DataManager.SetShopCooldown(playerData, itemID, item.Cooldown or 0)
    elseif item.Type then
        -- Catalyseur
        DataManager.AddCatalyst(playerData, item.Type, 1)
    elseif item.Effect then
        -- Amélioration permanente
        playerData.PermanentUpgrades[itemID] = true
    end

    DataStoreManager.UpdatePlayerData(player, playerData)

    -- Mettre à jour contrat
    local ContractManager = require(script.Parent.ContractManager)
    ContractManager.UpdateProgress(player, "ShopPurchase", 1)

    ReplicatedStorage.RemoteEvents.BuyShopItem:FireClient(player, true, "Item acheté !")

    print(string.format("[ShopManager] 🛒 %s a acheté %s", player.Name, itemID))
end

-- ========================================
-- ACHATS ROBUX (Gamepasses/Produits)
-- ========================================

-- TODO: Configurer dans Roblox Studio les DevProducts et Gamepasses
-- Exemple IDs (à remplacer par vrais IDs)
local GAMEPASS_IDS = {
    VIPPremium = 0,
    AutoFusion = 0,
    MegaInventory = 0,
    DoubleRebirth = 0
}

function ShopManager.ProcessGamepassPurchase(player, gamepassId)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    -- Identifier gamepass
    for name, id in pairs(GAMEPASS_IDS) do
        if id == gamepassId then
            playerData.Gamepasses[name] = true
            DataStoreManager.UpdatePlayerData(player, playerData)
            print(string.format("[ShopManager] 💎 %s a acheté gamepass: %s", player.Name, name))
            break
        end
    end
end

return ShopManager
