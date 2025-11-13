-- ========================================
-- SLIME RUSH - SERVER MATCHMAKING
-- Script (Serveur)
-- Localisation: ServerScriptService/ServerMatchmaking
-- ========================================

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local ServerMatchmaking = {}

-- ========================================
-- TÉLÉPORTER VERS SERVEUR DISPONIBLE
-- ========================================

function ServerMatchmaking.TeleportToAvailableServer(player)
    local placeId = game.PlaceId

    print(string.format("[ServerMatchmaking] 🔄 Téléportation de %s vers serveur disponible...", player.Name))

    -- Téléporter vers nouvelle instance
    local success, errorMessage = pcall(function()
        TeleportService:TeleportAsync(placeId, {player})
    end)

    if not success then
        warn(string.format("[ServerMatchmaking] ❌ Échec téléportation: %s", tostring(errorMessage)))
    end
end

-- ========================================
-- VÉRIFIER OCCUPATION SERVEUR
-- ========================================

function ServerMatchmaking.GetServerOccupancy()
    local TOTAL_BASES = 8
    local playerCount = #Players:GetPlayers()

    return {
        Players = playerCount,
        MaxPlayers = TOTAL_BASES,
        IsFull = playerCount >= TOTAL_BASES
    }
end

return ServerMatchmaking
