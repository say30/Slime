--[[
    InventoryUI.lua
    VERSION 2 ONGLETS - Interface d'inventaire complète
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Modules
local FormatNumbers = require(ReplicatedStorage.Modules.Shared.FormatNumbers)
local SlimeConfig = require(ReplicatedStorage.Modules.Shared.SlimeConfig)

-- Remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestInventoryEvent = RemoteEvents:WaitForChild("RequestInventoryEvent")
local ReplaceSlimeEvent = RemoteEvents:WaitForChild("ReplaceSlimeEvent")
local SellSlimeEvent = RemoteEvents:WaitForChild("SellSlimeEvent")
local DeleteSlimeEvent = RemoteEvents:WaitForChild("DeleteSlimeEvent")

-- ============================================
-- 📐 CONSTANTES
-- ============================================
local SLOT_SIZE = 100
local SLOTS_PER_ROW = 4
local SLOT_PADDING = 10
local MAX_SLOTS = 20

local inventoryData = {Items = {}, MaxSlots = 20}
local currentSelectedSlot = nil
local currentTab = "slimes" -- "slimes" ou "objects"

-- ============================================
-- 🎨 CRÉER L'UI PRINCIPALE
-- ============================================
local screenGui = playerGui:FindFirstChild("InventoryUI")
if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 12
	screenGui.Parent = playerGui
end

-- Frame principale (cachée au départ)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 450, 0, 600)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -300)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 15)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 100, 150)
mainStroke.Thickness = 3
mainStroke.Parent = mainFrame

-- ============================================
-- 📋 HEADER
-- ============================================
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 15)
headerCorner.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -100, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🎒 INVENTAIRE (0/20)"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 20
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

-- Bouton fermer
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 20
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- ============================================
-- 🔀 ONGLETS
-- ============================================
local tabsFrame = Instance.new("Frame")
tabsFrame.Name = "TabsFrame"
tabsFrame.Size = UDim2.new(1, -20, 0, 45)
tabsFrame.Position = UDim2.new(0, 10, 0, 60)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = mainFrame

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabsLayout.Padding = UDim.new(0, 10)
tabsLayout.Parent = tabsFrame

-- Fonction pour créer un bouton d'onglet
local function createTabButton(name, text, icon)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 200, 0, 40)
	button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	button.Text = icon .. " " .. text
	button.TextColor3 = Color3.fromRGB(200, 200, 200)
	button.TextSize = 16
	button.Font = Enum.Font.GothamBold
	button.Parent = tabsFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local slimesTabButton = createTabButton("SlimesTab", "SLIMES", "🧪")
local objectsTabButton = createTabButton("ObjectsTab", "OBJETS", "⚡")

-- ============================================
-- 📜 SCROLLING FRAME
-- ============================================
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ScrollFrame"
scrollFrame.Size = UDim2.new(1, -20, 1, -200)
scrollFrame.Position = UDim2.new(0, 10, 0, 115)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 8
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

-- Grid Layout
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, SLOT_SIZE, 0, SLOT_SIZE)
gridLayout.CellPadding = UDim2.new(0, SLOT_PADDING, 0, SLOT_PADDING)
gridLayout.FillDirectionMaxCells = SLOTS_PER_ROW
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Parent = scrollFrame

-- ============================================
-- 🎯 PANEL D'ACTIONS
-- ============================================
local actionsPanel = Instance.new("Frame")
actionsPanel.Name = "ActionsPanel"
actionsPanel.Size = UDim2.new(1, -20, 0, 70)
actionsPanel.Position = UDim2.new(0, 10, 1, -80)
actionsPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
actionsPanel.BorderSizePixel = 0
actionsPanel.Visible = false
actionsPanel.Parent = mainFrame

local actionsCorner = Instance.new("UICorner")
actionsCorner.CornerRadius = UDim.new(0, 10)
actionsCorner.Parent = actionsPanel

local actionsLayout = Instance.new("UIListLayout")
actionsLayout.FillDirection = Enum.FillDirection.Horizontal
actionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
actionsLayout.Padding = UDim.new(0, 10)
actionsLayout.Parent = actionsPanel

-- Fonction pour créer un bouton d'action
local function createActionButton(text, color, callback)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 95, 0, 50)
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 14
	button.Font = Enum.Font.GothamBold
	button.Parent = actionsPanel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	button.MouseButton1Click:Connect(callback)

	return button
end

local replaceButton = createActionButton("🔄 Replacer", Color3.fromRGB(100, 200, 100), function()
	if currentSelectedSlot then
		ReplaceSlimeEvent:FireServer(currentSelectedSlot)
		actionsPanel.Visible = false
		currentSelectedSlot = nil
	end
end)

local sellButton = createActionButton("💰 Vendre", Color3.fromRGB(255, 215, 0), function()
	if currentSelectedSlot then
		SellSlimeEvent:FireServer(currentSelectedSlot)
		actionsPanel.Visible = false
		currentSelectedSlot = nil
	end
end)

local deleteButton = createActionButton("🗑️ Supprimer", Color3.fromRGB(200, 50, 50), function()
	if currentSelectedSlot then
		DeleteSlimeEvent:FireServer(currentSelectedSlot)
		actionsPanel.Visible = false
		currentSelectedSlot = nil
	end
end)

-- ============================================
-- 🎨 CRÉER UN SLOT (SLIME)
-- ============================================
local function createSlimeSlot(index, slimeData)
	local slot = Instance.new("Frame")
	slot.Name = "Slot" .. index
	slot.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	slot.BackgroundTransparency = 0.3
	slot.BorderSizePixel = 0
	slot.Parent = scrollFrame

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 10)
	slotCorner.Parent = slot

	if slimeData then
		local rarityData = SlimeConfig:GetRarityByName(slimeData.rarity)

		-- Contour coloré selon rareté
		local stroke = Instance.new("UIStroke")
		stroke.Color = rarityData and rarityData.Color or Color3.fromRGB(150, 150, 150)
		stroke.Thickness = 3
		stroke.Parent = slot

		-- Container pour les infos
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 1, 0)
		container.BackgroundTransparency = 1
		container.Parent = slot

		local layout = Instance.new("UIListLayout")
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 2)
		layout.Parent = container

		-- Nom
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0, 16)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = slimeData.mood .. " " .. slimeData.sizeName
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextSize = 10
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextWrapped = true
		nameLabel.Parent = container

		-- Rareté
		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Size = UDim2.new(1, 0, 0, 14)
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Text = slimeData.rarity
		rarityLabel.TextColor3 = rarityData and rarityData.Color or Color3.new(1, 1, 1)
		rarityLabel.TextSize = 11
		rarityLabel.Font = Enum.Font.GothamBold
		rarityLabel.Parent = container

		-- Production
		local prodLabel = Instance.new("TextLabel")
		prodLabel.Size = UDim2.new(1, 0, 0, 12)
		prodLabel.BackgroundTransparency = 1
		prodLabel.Text = "💧 " .. FormatNumbers:Format(slimeData.production) .. "/s"
		prodLabel.TextColor3 = Color3.fromHex("64C8FF")
		prodLabel.TextSize = 9
		prodLabel.Font = Enum.Font.Gotham
		prodLabel.Parent = container

		-- Coût
		local costLabel = Instance.new("TextLabel")
		costLabel.Size = UDim2.new(1, 0, 0, 12)
		costLabel.BackgroundTransparency = 1
		costLabel.Text = "💰 " .. FormatNumbers:Format(slimeData.cost or 0)
		costLabel.TextColor3 = Color3.fromHex("FFD700")
		costLabel.TextSize = 9
		costLabel.Font = Enum.Font.Gotham
		costLabel.Parent = container

		-- Bouton de sélection
		local selectButton = Instance.new("TextButton")
		selectButton.Size = UDim2.new(1, 0, 1, 0)
		selectButton.BackgroundTransparency = 1
		selectButton.Text = ""
		selectButton.Parent = slot

		selectButton.MouseButton1Click:Connect(function()
			-- ✅ VÉRIFIER SI ON EST EN MODE SÉLECTION POUR FUSION
			local fusionSelectionActive = _G.FusionSelectionActive == true

			if fusionSelectionActive then
				local FusionSelectionEvent = ReplicatedStorage:FindFirstChild("FusionSelectionEvent")
				if not FusionSelectionEvent then
					warn("[Inventory] ❌ FusionSelectionEvent introuvable")
					return
				end
				-- Envoyer la sélection à FusionUI
				FusionSelectionEvent:Fire({
					type = "slime",
					index = index,
					data = slimeData
				})
				print("[Inventory] 🎯 Slime sélectionné pour fusion:", index)

				-- Fermer l'inventaire
				mainFrame.Visible = false
				actionsPanel.Visible = false
			else
				-- Comportement normal (afficher les actions)
				currentSelectedSlot = index
				actionsPanel.Visible = true
				print("[Inventory] 🎯 Slot sélectionné:", index)
			end
		end)

	else
		-- Slot vide
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 1, 0)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "Vide"
		emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		emptyLabel.TextSize = 12
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = slot

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(60, 60, 70)
		stroke.Thickness = 2
		stroke.Transparency = 0.7
		stroke.Parent = slot
	end

	return slot
end

-- ============================================
-- 🎨 CRÉER UN SLOT (OBJET)
-- ============================================
local function createObjectSlot(index, objectData)
	local slot = Instance.new("Frame")
	slot.Name = "Slot" .. index
	slot.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	slot.BackgroundTransparency = 0.3
	slot.BorderSizePixel = 0
	slot.Parent = scrollFrame

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 10)
	slotCorner.Parent = slot

	if objectData then
		-- Contour pour objets
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(100, 150, 255)
		stroke.Thickness = 3
		stroke.Parent = slot

		-- Container pour les infos
		local container = Instance.new("Frame")
		container.Size = UDim2.new(1, 0, 1, 0)
		container.BackgroundTransparency = 1
		container.Parent = slot

		local layout = Instance.new("UIListLayout")
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 5)
		layout.Parent = container

		-- Icône
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(1, 0, 0, 30)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = "⚡"
		iconLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		iconLabel.TextSize = 24
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.Parent = container

		-- Nom de l'objet
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0, 16)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = objectData.catalystType or "Objet"
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextSize = 11
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextWrapped = true
		nameLabel.Parent = container

		-- Quantité (si applicable)
		if objectData.quantity then
			local qtyLabel = Instance.new("TextLabel")
			qtyLabel.Size = UDim2.new(1, 0, 0, 14)
			qtyLabel.BackgroundTransparency = 1
			qtyLabel.Text = "x" .. objectData.quantity
			qtyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			qtyLabel.TextSize = 10
			qtyLabel.Font = Enum.Font.Gotham
			qtyLabel.Parent = container
		end

		-- Bouton de sélection
		local selectButton = Instance.new("TextButton")
		selectButton.Size = UDim2.new(1, 0, 1, 0)
		selectButton.BackgroundTransparency = 1
		selectButton.Text = ""
		selectButton.Parent = slot

		selectButton.MouseButton1Click:Connect(function()
			-- ✅ VÉRIFIER SI ON EST EN MODE SÉLECTION POUR FUSION
			local fusionSelectionActive = _G.FusionSelectionActive == true

			if fusionSelectionActive then
				local FusionSelectionEvent = ReplicatedStorage:FindFirstChild("FusionSelectionEvent")
				if not FusionSelectionEvent then
					warn("[Inventory] ❌ FusionSelectionEvent introuvable")
					return
				end
				-- Envoyer la sélection à FusionUI
				FusionSelectionEvent:Fire({
					type = "catalyst",
					index = index,
					data = objectData
				})
				print("[Inventory] 🎯 Catalyseur sélectionné pour fusion:", index)

				-- Fermer l'inventaire
				mainFrame.Visible = false
				actionsPanel.Visible = false
			else
				-- Comportement normal (afficher les actions)
				currentSelectedSlot = index
				actionsPanel.Visible = true
				print("[Inventory] 🎯 Objet sélectionné:", index)
			end
		end)

	else
		-- Slot vide
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 1, 0)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "Vide"
		emptyLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		emptyLabel.TextSize = 12
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = slot

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(60, 60, 70)
		stroke.Thickness = 2
		stroke.Transparency = 0.7
		stroke.Parent = slot
	end

	return slot
end

-- ============================================
-- 🔄 RAFRAÎCHIR L'INVENTAIRE
-- ============================================
local function refreshInventory()
	-- Nettoyer les slots existants
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- ✅ FILTRER LES ITEMS SELON L'ONGLET
	local filteredItems = {}
	local itemIndexMap = {} -- Pour garder l'index original

	for i, item in ipairs(inventoryData.Items) do
		if currentTab == "slimes" and item.type == "slime" then
			table.insert(filteredItems, item)
			table.insert(itemIndexMap, i)
		elseif currentTab == "objects" and item.type ~= "slime" then
			table.insert(filteredItems, item)
			table.insert(itemIndexMap, i)
		end
	end

	-- Créer les slots filtrés
	for i = 1, MAX_SLOTS do
		local itemData = filteredItems[i]
		local originalIndex = itemIndexMap[i]

		if itemData then
			if currentTab == "slimes" then
				createSlimeSlot(originalIndex, itemData)
			else
				createObjectSlot(originalIndex, itemData)
			end
		else
			-- Slot vide
			if currentTab == "slimes" then
				createSlimeSlot(i, nil)
			else
				createObjectSlot(i, nil)
			end
		end
	end

	-- Mettre à jour le canvas size
	local rows = math.ceil(MAX_SLOTS / SLOTS_PER_ROW)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, (SLOT_SIZE + SLOT_PADDING) * rows)

	-- ✅ COMPTER SLIMES ET OBJETS
	local slimeCount = 0
	local objectCount = 0

	for _, item in ipairs(inventoryData.Items) do
		if item.type == "slime" then
			slimeCount = slimeCount + 1
		else
			objectCount = objectCount + 1
		end
	end

	-- Mettre à jour le titre
	local totalCount = #inventoryData.Items
	titleLabel.Text = string.format("🎒 INVENTAIRE (%d/%d) | 🧪 %d | ⚡ %d", totalCount, MAX_SLOTS, slimeCount, objectCount)

	print("[Inventory] ✅ Interface rafraîchie -", totalCount, "items (", slimeCount, "slimes,", objectCount, "objets)")
end

-- ============================================
-- 🔀 CHANGER D'ONGLET
-- ============================================
local function switchTab(tabName)
	currentTab = tabName
	actionsPanel.Visible = false
	currentSelectedSlot = nil

	-- Mettre à jour l'apparence des boutons
	if tabName == "slimes" then
		slimesTabButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		slimesTabButton.TextColor3 = Color3.new(1, 1, 1)
		objectsTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		objectsTabButton.TextColor3 = Color3.fromRGB(200, 200, 200)

		-- Afficher/Cacher boutons selon contexte
		replaceButton.Visible = true
		sellButton.Visible = true
	else
		objectsTabButton.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
		objectsTabButton.TextColor3 = Color3.new(1, 1, 1)
		slimesTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		slimesTabButton.TextColor3 = Color3.fromRGB(200, 200, 200)

		-- Dans l'onglet objets, on ne peut pas replacer
		replaceButton.Visible = false
		sellButton.Visible = false
	end

	refreshInventory()
	print("[Inventory] 🔀 Onglet changé:", tabName)
end

-- Événements des boutons d'onglets
slimesTabButton.MouseButton1Click:Connect(function()
	switchTab("slimes")
end)

objectsTabButton.MouseButton1Click:Connect(function()
	switchTab("objects")
end)

-- ============================================
-- 🎮 ÉVÉNEMENTS
-- ============================================

-- Recevoir l'inventaire du serveur
RequestInventoryEvent.OnClientEvent:Connect(function(inventory)
	inventoryData = inventory
	refreshInventory()
end)

-- Ouvrir/Fermer l'inventaire
local MenuUI = playerGui:WaitForChild("MenuUI")
local menuFrame = MenuUI:WaitForChild("MainFrame")
local inventoryButton = menuFrame:FindFirstChild("InventaireButton")

if inventoryButton then
	inventoryButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = not mainFrame.Visible

		if mainFrame.Visible then
			-- Réinitialiser à l'onglet Slimes
			switchTab("slimes")
			-- Demander l'inventaire au serveur
			RequestInventoryEvent:FireServer()
			print("[Inventory] 📂 Ouverture de l'inventaire")
		else
			actionsPanel.Visible = false
			currentSelectedSlot = nil
			print("[Inventory] 📁 Fermeture de l'inventaire")
		end
	end)
end

-- Bouton fermer
closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	actionsPanel.Visible = false
	currentSelectedSlot = nil
end)

-- Initialiser l'onglet par défaut
switchTab("slimes")

print("[InventoryUI] ✅ Interface chargée (VERSION 2 ONGLETS)")
