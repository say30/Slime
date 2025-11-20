-- ========================================
-- SLIME RUSH - REBIRTH HANDLER
-- Script (Serveur)
-- Localisation: ServerScriptService/RebirthHandler
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyConfig = require(ReplicatedStorage.Modules.EconomyConfig)
local DataManager = require(ReplicatedStorage.Modules.DataManager)
local DataStoreManager = require(script.Parent.DataStoreManager)

local RebirthHandler = {}

-- ========================================
-- PROCESSUS REBIRTH
-- ========================================

function RebirthHandler.ProcessRebirth(player, sacrificedSlimes)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    local nextLevel = playerData.RebirthLevel + 1
    local rebirthData = EconomyConfig.Rebirths[nextLevel]

    if not rebirthData then
        ReplicatedStorage.RemoteEvents.DoRebirth:FireClient(player, false, "Rebirth maximum atteint")
        return
    end

    -- Vérifier ressources
    if playerData.Gelatin < rebirthData.CostGelatin or playerData.Essence < rebirthData.CostEssence then
        ReplicatedStorage.RemoteEvents.DoRebirth:FireClient(player, false, "Ressources insuffisantes")
        return
    end

    -- Valider slimes sacrifiés
    if not RebirthHandler.ValidateSacrifice(playerData, sacrificedSlimes, rebirthData) then
        ReplicatedStorage.RemoteEvents.DoRebirth:FireClient(player, false, "Slimes sacrifiés invalides")
        return
    end

    -- Déduire coût
    playerData.Gelatin = playerData.Gelatin - rebirthData.CostGelatin
    playerData.Essence = playerData.Essence - rebirthData.CostEssence

    -- Retirer slimes sacrifiés de l'inventaire
    for _, slimeID in ipairs(sacrificedSlimes) do
        DataManager.RemoveFromInventory(playerData, slimeID)
    end

    -- Appliquer rebirth
    playerData.RebirthLevel = nextLevel

    DataStoreManager.UpdatePlayerData(player, playerData)

    ReplicatedStorage.RemoteEvents.DoRebirth:FireClient(player, true, string.format("Rebirth %d obtenu !", nextLevel))

    print(string.format("[RebirthHandler] 🌟 %s a effectué Rebirth %d", player.Name, nextLevel))
end

-- ========================================
-- VALIDER SACRIFICE
-- ========================================

function RebirthHandler.ValidateSacrifice(playerData, sacrificedSlimes, rebirthData)
    -- TODO: Implémenter validation selon critères rebirthData.RequiredSlimes
    -- Pour l'instant, juste vérifier quantité
    return #sacrificedSlimes >= rebirthData.RequiredSlimes.Count
end

return RebirthHandler
