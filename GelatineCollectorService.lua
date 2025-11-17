--[[
    GelatineCollectorService.lua
    VERSION FINALE - Inspiré du CollectService qui fonctionne
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

-- Modules
local DataStoreManager = ServerScriptService:WaitForChild("DataStoreManager")
DataStoreManager = require(DataStoreManager)

print("[GelatineCollectorService] ✅ DataStoreManager chargé")

-- ============================================
-- 🔧 FONCTION : Connecter une hitbox
-- ============================================
local function hookHitbox(base, baseNumber)
	local recolte = base:FindFirstChild("Recolte")
	local hitbox = recolte and recolte:FindFirstChild("Hitbox")

	if not (hitbox and hitbox:IsA("BasePart")) then
		warn("[GelatineCollector] ⚠️ Hitbox introuvable pour", base.Name)
		return
	end

	-- ✅ CONNEXION UNIQUE par base
	hitbox.Touched:Connect(function(part)
		local character = part.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Vérifier que c'est SA base
		local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
		if not PlayerInfo then return end

		local playerFolder = PlayerInfo:FindFirstChild(player.Name)
		if not playerFolder then return end

		local playerBaseNumber = playerFolder:GetAttribute("BaseNumber")
		if playerBaseNumber ~= baseNumber then return end

		-- ✅ VÉRIFIER QU'IL Y A QUELQUE CHOSE À COLLECTER
		local accumulated = DataStoreManager.GetAccumulatedGelatin(player)
		if accumulated <= 0 then return end -- ← CLEF DU SYSTÈME !

                local amount = math.floor(accumulated)

                -- Ajouter au wallet
                DataStoreManager.AddGelatine(player, amount)

                -- Mettre à jour les contrats de collecte
                if _G.UpdateContractProgress then
                        _G.UpdateContractProgress(player, "CollectGelatin", {
                                amount = amount
                        })
                end

                -- ✅ RESET À 0 (empêche le spam automatiquement)
                DataStoreManager.SetAccumulatedGelatin(player, 0)

		-- Mettre à jour le temps
		DataStoreManager.UpdateLastCollectionTime(player)

		-- Mettre à jour le NumberValue
		local accumulatedValue = playerFolder:FindFirstChild("AccumulatedGelatin")
		if accumulatedValue then
			accumulatedValue.Value = 0
		end

		print("[GelatineCollector] ✅", player.Name, "a collecté", amount, "gélatine")
	end)

	print("[GelatineCollector] ✅ Hitbox connectée pour Base " .. baseNumber)
end

-- ============================================
-- 🎯 INITIALISER TOUTES LES BASES
-- ============================================
local basesFolder = Workspace:WaitForChild("Base")

for i = 1, 8 do
	local base = basesFolder:FindFirstChild("Base " .. i)
	if base then
		hookHitbox(base, i)
	end
end

print("[GelatineCollectorService] ✅ Service chargé")
