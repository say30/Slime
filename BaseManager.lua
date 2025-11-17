--[[
    BaseManager.lua
    Attribution des 8 bases aux joueurs
]]

local BaseManager = {}

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local workspace = game.Workspace

local MAX_PLAYERS = 8
local assignedBases = {}
local availableBases = {}

-- ============================================
-- 🏠 INITIALISATION
-- ============================================
function BaseManager:Initialize()
	for i = 1, MAX_PLAYERS do
		table.insert(availableBases, i)
	end

	print("[BaseManager] ✅ Initialisé avec 8 bases")
end

-- ============================================
-- 🎯 ASSIGNER UNE BASE
-- ============================================
function BaseManager:AssignBase(player)
	if #Players:GetPlayers() > MAX_PLAYERS then
		warn("[BaseManager] Serveur plein, téléportation de " .. player.Name)
		self:TeleportToAvailableServer(player)
		return nil
	end

	if #availableBases == 0 then
		warn("[BaseManager] ❌ Aucune base disponible pour " .. player.Name)
		return nil
	end

	local baseNumber = table.remove(availableBases, 1)
	assignedBases[player] = baseNumber

	print("[BaseManager] ✅ Base " .. baseNumber .. " assignée à " .. player.Name)

	self:UpdateBaseTitleLabel(baseNumber, player.Name)

	return baseNumber
end

-- ============================================
-- 🔄 LIBÉRER UNE BASE
-- ============================================
function BaseManager:FreeBase(player)
	local baseNumber = assignedBases[player]

	if baseNumber then
		table.insert(availableBases, baseNumber)
		assignedBases[player] = nil

		print("[BaseManager] ✅ Base " .. baseNumber .. " libérée")

		self:UpdateBaseTitleLabel(baseNumber, "Base Libre")
		self:CleanupPlayerSlimes(player)
	end
end

-- ============================================
-- 📍 TÉLÉPORTER JOUEUR À SA BASE
-- ============================================
function BaseManager:TeleportPlayerToBase(player, baseNumber)
	local base = workspace.Base:FindFirstChild("Base " .. baseNumber)

	if not base then
		warn("[BaseManager] Base " .. baseNumber .. " introuvable")
		return
	end

	local spawnLocation = base:FindFirstChild("structure base home", true)

	if not spawnLocation then
		warn("[BaseManager] structure base home introuvable dans Base " .. baseNumber)
		return
	end

	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart and spawnLocation:IsA("BasePart") then
		humanoidRootPart.CFrame = spawnLocation.CFrame + Vector3.new(0, 3, 0)
		print("[BaseManager] ✅ " .. player.Name .. " téléporté à Base " .. baseNumber)
	end
end

-- ============================================
-- 📝 METTRE À JOUR TITLELABEL
-- ============================================
function BaseManager:UpdateBaseTitleLabel(baseNumber, playerName)
	local base = workspace.Base:FindFirstChild("Base " .. baseNumber)

	if not base then return end

	local titleLabel = base:FindFirstChild("Panneau")
		and base.Panneau:FindFirstChild("Part")
		and base.Panneau.Part:FindFirstChild("SurfaceGui")
		and base.Panneau.Part.SurfaceGui:FindFirstChild("MainFrame")
		and base.Panneau.Part.SurfaceGui.MainFrame:FindFirstChild("TitleLabel")

	if titleLabel then
		titleLabel.Text = "Base de " .. playerName
	end
end

-- ============================================
-- 🧹 NETTOYER SLIMES DU JOUEUR
-- ============================================
function BaseManager:CleanupPlayerSlimes(player)
	-- Les slimes sont maintenant dans PlayerInfo/[PlayerName]/
	-- La suppression du dossier PlayerInfo dans ServerMain suffit
	print("[BaseManager] 🧹 Slimes nettoyés (via PlayerInfo)")
end

-- ============================================
-- 🌐 TÉLÉPORTER VERS SERVEUR DISPONIBLE
-- ============================================
function BaseManager:TeleportToAvailableServer(player)
	local placeId = game.PlaceId

	local success, errorMessage = pcall(function()
		TeleportService:Teleport(placeId, player)
	end)

	if not success then
		warn("[BaseManager] Échec téléportation: " .. errorMessage)
	else
		print("[BaseManager] ✅ " .. player.Name .. " téléporté vers un autre serveur")
	end
end

-- ============================================
-- 🔍 OBTENIR NUMÉRO DE BASE DU JOUEUR
-- ============================================
function BaseManager:GetPlayerBase(player)
	return assignedBases[player]
end

-- ============================================
-- 📊 OBTENIR BASES DISPONIBLES
-- ============================================
function BaseManager:GetAvailableBasesCount()
	return #availableBases
end

return BaseManager
