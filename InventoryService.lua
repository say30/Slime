--[[
    InventoryService.lua
    VERSION 2 ONGLETS - Gestion de l'inventaire
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local DataStoreManager = require(ServerScriptService:WaitForChild("DataStoreManager"))

-- Remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local StoreSlimeEvent = RemoteEvents:WaitForChild("StoreSlimeEvent")
local ReplaceSlimeEvent = RemoteEvents:WaitForChild("ReplaceSlimeEvent")
local SellSlimeEvent = RemoteEvents:WaitForChild("SellSlimeEvent")
local DeleteSlimeEvent = RemoteEvents:WaitForChild("DeleteSlimeEvent")
local RequestInventoryEvent = RemoteEvents:WaitForChild("RequestInventoryEvent")

print("[InventoryService] ✅ Service initialisé")

-- ============================================
-- 🎒 STOCKER UN SLIME (Non utilisé car géré par ProximityPrompt)
-- ============================================
StoreSlimeEvent.OnServerEvent:Connect(function(player, slimeModel)
	warn("[Inventory] ⚠️ StoreSlimeEvent appelé - Utiliser ProximityPrompt à la place")
end)

-- ============================================
-- 🔄 REPLACER UN SLIME
-- ============================================
ReplaceSlimeEvent.OnServerEvent:Connect(function(player, slotIndex)
	-- Vérifier qu'il y a un item à cet index
	local itemData = DataStoreManager.RemoveFromInventory(player, slotIndex)

	if not itemData then
		warn("[Inventory] ❌ Pas d'item à l'index", slotIndex)
		return
	end

	-- Vérifier que c'est bien un slime
	if itemData.type ~= "slime" then
		warn("[Inventory] ❌ Cet item n'est pas un slime")
		-- Remettre l'item dans l'inventaire
		DataStoreManager.AddToInventory(player, itemData)
		return
	end

	-- Trouver un pod disponible
	local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
	if not PlayerInfo then return end

	local playerFolder = PlayerInfo:FindFirstChild(player.Name)
	if not playerFolder then return end

	local baseNumber = playerFolder:GetAttribute("BaseNumber")
	if not baseNumber then return end

	local basesFolder = Workspace:FindFirstChild("Base")
	if not basesFolder then return end

	local base = basesFolder:FindFirstChild("Base " .. baseNumber)
	if not base then return end

	-- Chercher un pod libre
	local podsFolder = base:FindFirstChild("PodsSlime")
	if not podsFolder then return end

	local serverSlimesFolder = playerFolder:FindFirstChild("ServerSlimes")
	if not serverSlimesFolder then return end

	-- Trouver les pods occupés
	local occupiedPods = {}
	for _, slime in ipairs(serverSlimesFolder:GetChildren()) do
		if slime:IsA("Model") then
			local podNum = slime:GetAttribute("PodNumber")
			if podNum then
				occupiedPods[podNum] = true
			end
		end
	end

	-- Trouver le premier pod libre
	local availableSpawn, podNumber
	for i = 1, 10 do
		if not occupiedPods[i] then
			local podContainer = podsFolder:FindFirstChild("PodsSlime" .. i)
			if podContainer then
				local baseFolder = podContainer:FindFirstChild("Base")
				if baseFolder then
					local spawn = baseFolder:FindFirstChild("Spawn")
					if spawn and spawn:IsA("BasePart") then
						availableSpawn = spawn
						podNumber = i
						break
					end
				end
			end
		end
	end

	if not availableSpawn then
		warn("[Inventory] ❌ Aucun pod disponible")
		-- Remettre le slime dans l'inventaire
		DataStoreManager.AddToInventory(player, itemData)
		return
	end

	-- Créer le modèle 3D du slime
	local SlimesFolder = ReplicatedStorage:WaitForChild("Slimes")
	local moodFolder = SlimesFolder:FindFirstChild(itemData.mood)
	if not moodFolder then
		warn("[Inventory] ❌ Mood folder introuvable")
		DataStoreManager.AddToInventory(player, itemData)
		return
	end

	local modelName = itemData.mood .. " " .. itemData.sizeName
	local baseModel = moodFolder:FindFirstChild(modelName)
	if not baseModel then
		warn("[Inventory] ❌ Modèle introuvable:", modelName)
		DataStoreManager.AddToInventory(player, itemData)
		return
	end

	local slimeClone = baseModel:Clone()
	slimeClone.Name = "ServerSlime_" .. tick()

	for _, part in ipairs(slimeClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	-- ✅ TOUS LES ATTRIBUTS INCLUANT COST
	slimeClone:SetAttribute("Mood", itemData.mood)
	slimeClone:SetAttribute("Rarity", itemData.rarity)
	slimeClone:SetAttribute("Size", itemData.sizeName)
	slimeClone:SetAttribute("Production", itemData.production)
	slimeClone:SetAttribute("Owner", player.Name)
	slimeClone:SetAttribute("PodNumber", podNumber)
	slimeClone:SetAttribute("State", itemData.state or "Aucun")
	slimeClone:SetAttribute("Cost", itemData.cost or 0) -- ✅ CRITIQUE

	print("[Inventory] 📊 Replacement - Cost:", itemData.cost)

	slimeClone.Parent = serverSlimesFolder
	slimeClone:PivotTo(CFrame.new(availableSpawn.Position))

	-- Créer le billboard
	local SlimeConfig = require(ReplicatedStorage.Modules.Shared.SlimeConfig)
	local FormatNumbers = require(ReplicatedStorage.Modules.Shared.FormatNumbers)

	local function createBillboard(model, mood, rarity, size, production, cost)
		local moodData = SlimeConfig:GetMoodByName(mood)
		local rarityData = SlimeConfig:GetRarityByName(rarity)
		local sizeData = SlimeConfig:GetSizeByName(size)

		if not moodData or not rarityData or not sizeData then return end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "SlimeInfo"
		billboard.Size = UDim2.new(0, 200, 0, 120)
		billboard.StudsOffset = Vector3.new(0, 4, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = model

		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 1, 0)
		container.BackgroundTransparency = 1
		container.Parent = billboard

		local layout = Instance.new("UIListLayout")
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.Padding = UDim.new(0, 2)
		layout.Parent = container

		local function createLabel(text, textColor, textSize)
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 0, textSize + 4)
			label.BackgroundTransparency = 1
			label.Text = text
			label.TextColor3 = textColor
			label.TextSize = textSize
			label.Font = Enum.Font.GothamBold
			label.TextStrokeTransparency = 0.5
			label.Parent = container
		end

		createLabel(moodData.Name .. " " .. sizeData.Name, Color3.new(1, 1, 1), 14)
		createLabel(rarityData.Name, rarityData.Color, 16)
		createLabel("💧 " .. FormatNumbers:Format(production) .. "/s", Color3.fromHex("64C8FF"), 13)
		createLabel("💧 " .. FormatNumbers:Format(cost), Color3.fromHex("FFD700"), 13)
	end

	createBillboard(slimeClone, itemData.mood, itemData.rarity, itemData.sizeName, itemData.production, itemData.cost)

	-- Sauvegarder dans le DataStore
	local baseName = "Base " .. baseNumber
	local podData = {
		mood = itemData.mood,
		sizeName = itemData.sizeName,
		rarity = itemData.rarity,
		production = itemData.production,
		cost = itemData.cost,
		baseName = baseName,
		podNumber = podNumber,
		placedAt = os.time()
	}

	DataStoreManager.AddPod(player, podData)

	-- Envoyer l'inventaire mis à jour au client
	local inventory = DataStoreManager.GetInventory(player)
	RequestInventoryEvent:FireClient(player, inventory)

	print("[Inventory] ✅", player.Name, "a replacé:", itemData.mood, itemData.sizeName, "sur Pod", podNumber, "- Cost:", itemData.cost)
end)

-- ============================================
-- 💰 VENDRE UN SLIME
-- ============================================
SellSlimeEvent.OnServerEvent:Connect(function(player, slotIndex)
	local itemData = DataStoreManager.RemoveFromInventory(player, slotIndex)

	if not itemData then
		warn("[Inventory] ❌ Pas d'item à l'index", slotIndex)
		return
	end

	-- Vérifier que c'est un slime
	if itemData.type ~= "slime" then
		warn("[Inventory] ❌ Impossible de vendre cet item")
		DataStoreManager.AddToInventory(player, itemData)
		return
	end

	-- Calculer le prix de vente (50% du coût)
	local sellPrice = math.floor((itemData.cost or 0) * 0.5)

	DataStoreManager.AddGelatine(player, sellPrice)

	-- Envoyer l'inventaire mis à jour
	local inventory = DataStoreManager.GetInventory(player)
	RequestInventoryEvent:FireClient(player, inventory)

	print("[Inventory] ✅", player.Name, "a vendu:", itemData.mood, itemData.sizeName, "pour", sellPrice)
end)

-- ============================================
-- 🗑️ SUPPRIMER UN ITEM
-- ============================================
DeleteSlimeEvent.OnServerEvent:Connect(function(player, slotIndex)
	local itemData = DataStoreManager.RemoveFromInventory(player, slotIndex)

	if not itemData then
		warn("[Inventory] ❌ Pas d'item à l'index", slotIndex)
		return
	end

	-- Envoyer l'inventaire mis à jour
	local inventory = DataStoreManager.GetInventory(player)
	RequestInventoryEvent:FireClient(player, inventory)

	local itemName = itemData.type == "slime" and (itemData.mood .. " " .. itemData.sizeName) or (itemData.catalystType or "item")
	print("[Inventory] ✅", player.Name, "a supprimé:", itemName)
end)

-- ============================================
-- 📨 DEMANDE D'INVENTAIRE
-- ============================================
RequestInventoryEvent.OnServerEvent:Connect(function(player)
	local inventory = DataStoreManager.GetInventory(player)
	RequestInventoryEvent:FireClient(player, inventory)
end)

print("[InventoryService] ✅ Service chargé")
