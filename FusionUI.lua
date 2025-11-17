--[[
    FusionUI.lua
    Interface de fusion avec 2 onglets
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Modules
local FormatNumbers = require(ReplicatedStorage.Modules.Shared.FormatNumbers)
local FusionConfig = require(ReplicatedStorage.Modules.Shared.FusionConfig)
local SlimeConfig = require(ReplicatedStorage.Modules.Shared.SlimeConfig)

-- Remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local StartFusionEvent = RemoteEvents:WaitForChild("StartFusionEvent")
local ClaimFusionResultEvent = RemoteEvents:WaitForChild("ClaimFusionResultEvent")
local SkipFusionTimerEvent = RemoteEvents:WaitForChild("SkipFusionTimerEvent")
local RequestInventoryEvent = RemoteEvents:WaitForChild("RequestInventoryEvent")

-- ============================================
-- 📐 CONSTANTES
-- ============================================

local currentTab = "Fusion2" -- "Fusion2" ou "Fusion3"
local selectedSlots = {} -- {slotIndex, slimeData}
local selectedCatalyst = nil -- {slotIndex, catalystData}
local inventoryData = {Items = {}, MaxSlots = 20}
_G.FusionSelectionActive = false

-- ============================================
-- 🎨 CRÉER L'UI PRINCIPALE
-- ============================================

local screenGui = playerGui:FindFirstChild("FusionUI")
if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FusionUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 14
	screenGui.Parent = playerGui
end

-- Frame principale
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 600, 0, 700)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -350)
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
header.Size = UDim2.new(1, 0, 0, 60)
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
titleLabel.Text = "⚡ FUSION"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 22
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

-- Bouton fermer
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0, 10)
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
tabsFrame.Position = UDim2.new(0, 10, 0, 70)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = mainFrame

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabsLayout.Padding = UDim.new(0, 10)
tabsLayout.Parent = tabsFrame

local function createTabButton(name, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 280, 0, 40)
	button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(200, 200, 200)
	button.TextSize = 16
	button.Font = Enum.Font.GothamBold
	button.Parent = tabsFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local fusion2TabButton = createTabButton("Fusion2Tab", "⚡ FUSION À 2 (ÉTATS)")
local fusion3TabButton = createTabButton("Fusion3Tab", "🔥 FUSION À 3 (AMÉLIORATION)")

-- ============================================
-- 📦 CONTAINER PRINCIPAL
-- ============================================

local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -20, 1, -230)
contentFrame.Position = UDim2.new(0, 10, 0, 125)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- ============================================
-- 🎯 SLOTS DE SLIMES
-- ============================================

local slotsFrame = Instance.new("Frame")
slotsFrame.Name = "SlotsFrame"
slotsFrame.Size = UDim2.new(1, 0, 0, 150)
slotsFrame.BackgroundTransparency = 1
slotsFrame.Parent = contentFrame

local slotsLayout = Instance.new("UIListLayout")
slotsLayout.FillDirection = Enum.FillDirection.Horizontal
slotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
slotsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
slotsLayout.Padding = UDim.new(0, 15)
slotsLayout.Parent = slotsFrame

local function createSlot(slotNumber)
	local slot = Instance.new("TextButton")
	slot.Name = "Slot" .. slotNumber
	slot.Size = UDim2.new(0, 150, 0, 150)
	slot.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	slot.BackgroundTransparency = 0.3
	slot.BorderSizePixel = 0
	slot.Text = ""
	slot.Parent = slotsFrame

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 12)
	slotCorner.Parent = slot

	local slotStroke = Instance.new("UIStroke")
	slotStroke.Color = Color3.fromRGB(100, 100, 150)
	slotStroke.Thickness = 2
	slotStroke.Transparency = 0.7
	slotStroke.Parent = slot

	-- Container pour le contenu
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = slot

	local containerLayout = Instance.new("UIListLayout")
	containerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	containerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	containerLayout.Padding = UDim.new(0, 5)
	containerLayout.Parent = container

	-- Texte par défaut
	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Name = "EmptyLabel"
	emptyLabel.Size = UDim2.new(1, 0, 0, 30)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Text = "SLOT " .. slotNumber
	emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	emptyLabel.TextSize = 18
	emptyLabel.Font = Enum.Font.GothamBold
	emptyLabel.Parent = container

	local clickLabel = Instance.new("TextLabel")
	clickLabel.Name = "ClickLabel"
	clickLabel.Size = UDim2.new(1, 0, 0, 20)
	clickLabel.BackgroundTransparency = 1
	clickLabel.Text = "Cliquez pour choisir"
	clickLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	clickLabel.TextSize = 12
	clickLabel.Font = Enum.Font.Gotham
	clickLabel.Parent = container

	slot:SetAttribute("SlotNumber", slotNumber)

	return slot
end

local slot1 = createSlot(1)
local slot2 = createSlot(2)
local slot3 = createSlot(3)

-- ============================================
-- ⚡ SLOT CATALYSEUR
-- ============================================

local catalystFrame = Instance.new("Frame")
catalystFrame.Name = "CatalystFrame"
catalystFrame.Size = UDim2.new(1, 0, 0, 100)
catalystFrame.Position = UDim2.new(0, 0, 0, 170)
catalystFrame.BackgroundTransparency = 1
catalystFrame.Parent = contentFrame

local catalystLabel = Instance.new("TextLabel")
catalystLabel.Size = UDim2.new(1, 0, 0, 20)
catalystLabel.BackgroundTransparency = 1
catalystLabel.Text = "⚡ CATALYSEUR (Optionnel)"
catalystLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
catalystLabel.TextSize = 14
catalystLabel.Font = Enum.Font.GothamBold
catalystLabel.Parent = catalystFrame

local catalystSlot = Instance.new("TextButton")
catalystSlot.Name = "CatalystSlot"
catalystSlot.Size = UDim2.new(0, 200, 0, 70)
catalystSlot.Position = UDim2.new(0.5, -100, 0, 30)
catalystSlot.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
catalystSlot.BackgroundTransparency = 0.3
catalystSlot.BorderSizePixel = 0
catalystSlot.Text = ""
catalystSlot.Parent = catalystFrame

local catalystCorner = Instance.new("UICorner")
catalystCorner.CornerRadius = UDim.new(0, 10)
catalystCorner.Parent = catalystSlot

local catalystStroke = Instance.new("UIStroke")
catalystStroke.Color = Color3.fromRGB(255, 215, 0)
catalystStroke.Thickness = 2
catalystStroke.Transparency = 0.7
catalystStroke.Parent = catalystSlot

local catalystEmptyLabel = Instance.new("TextLabel")
catalystEmptyLabel.Name = "EmptyLabel"
catalystEmptyLabel.Size = UDim2.new(1, 0, 1, 0)
catalystEmptyLabel.BackgroundTransparency = 1
catalystEmptyLabel.Text = "Aucun catalyseur\n(Bonus: 0%)"
catalystEmptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
catalystEmptyLabel.TextSize = 12
catalystEmptyLabel.Font = Enum.Font.Gotham
catalystEmptyLabel.Parent = catalystSlot

-- ============================================
-- 📊 INFORMATIONS DE FUSION
-- ============================================

local infoFrame = Instance.new("Frame")
infoFrame.Name = "InfoFrame"
infoFrame.Size = UDim2.new(1, 0, 0, 120)
infoFrame.Position = UDim2.new(0, 0, 0, 290)
infoFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
infoFrame.BackgroundTransparency = 0.5
infoFrame.BorderSizePixel = 0
infoFrame.Parent = contentFrame

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 10)
infoCorner.Parent = infoFrame

local infoLayout = Instance.new("UIListLayout")
infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
infoLayout.Padding = UDim.new(0, 8)
infoLayout.Parent = infoFrame

-- Coût
local costLabel = Instance.new("TextLabel")
costLabel.Name = "CostLabel"
costLabel.Size = UDim2.new(1, -20, 0, 25)
costLabel.BackgroundTransparency = 1
costLabel.Text = "💧 Coût: --- | ✨ Essence: ---"
costLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
costLabel.TextSize = 14
costLabel.Font = Enum.Font.GothamBold
costLabel.Parent = infoFrame

-- Timer
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, -20, 0, 25)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "⏱️ Durée: ---"
timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
timerLabel.TextSize = 14
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Parent = infoFrame

-- Chance
local chanceLabel = Instance.new("TextLabel")
chanceLabel.Name = "ChanceLabel"
chanceLabel.Size = UDim2.new(1, -20, 0, 25)
chanceLabel.BackgroundTransparency = 1
chanceLabel.Text = "🎲 Chance de succès: ---%"
chanceLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
chanceLabel.TextSize = 16
chanceLabel.Font = Enum.Font.GothamBold
chanceLabel.Parent = infoFrame

-- Message de validation
local validationLabel = Instance.new("TextLabel")
validationLabel.Name = "ValidationLabel"
validationLabel.Size = UDim2.new(1, -20, 0, 20)
validationLabel.BackgroundTransparency = 1
validationLabel.Text = ""
validationLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
validationLabel.TextSize = 12
validationLabel.Font = Enum.Font.Gotham
validationLabel.Parent = infoFrame

-- ============================================
-- 🎮 BOUTON DE FUSION
-- ============================================

local fusionButton = Instance.new("TextButton")
fusionButton.Name = "FusionButton"
fusionButton.Size = UDim2.new(0, 400, 0, 50)
fusionButton.Position = UDim2.new(0.5, -200, 1, -70)
fusionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
fusionButton.Text = "🔒 Sélectionnez les slimes"
fusionButton.TextColor3 = Color3.fromRGB(150, 150, 150)
fusionButton.TextSize = 18
fusionButton.Font = Enum.Font.GothamBold
fusionButton.Parent = mainFrame

local fusionCorner = Instance.new("UICorner")
fusionCorner.CornerRadius = UDim.new(0, 10)
fusionCorner.Parent = fusionButton

-- ============================================
-- ⏱️ TIMER DE FUSION (si fusion en cours)
-- ============================================

local timerFrame = Instance.new("Frame")
timerFrame.Name = "TimerFrame"
timerFrame.Size = UDim2.new(0, 450, 0, 150)
timerFrame.Position = UDim2.new(0.5, -225, 1, -180)
timerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
timerFrame.BackgroundTransparency = 0.2
timerFrame.BorderSizePixel = 0
timerFrame.Visible = false
timerFrame.Parent = mainFrame

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 12)
timerCorner.Parent = timerFrame

local timerStroke = Instance.new("UIStroke")
timerStroke.Color = Color3.fromRGB(255, 150, 100)
timerStroke.Thickness = 3
timerStroke.Parent = timerFrame

-- Titre
local timerTitle = Instance.new("TextLabel")
timerTitle.Size = UDim2.new(1, 0, 0, 30)
timerTitle.Position = UDim2.new(0, 0, 0, 10)
timerTitle.BackgroundTransparency = 1
timerTitle.Text = "⚗️ FUSION EN COURS..."
timerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
timerTitle.TextSize = 18
timerTitle.Font = Enum.Font.GothamBold
timerTitle.Parent = timerFrame

-- Timer texte
local timerText = Instance.new("TextLabel")
timerText.Name = "TimerText"
timerText.Size = UDim2.new(1, 0, 0, 40)
timerText.Position = UDim2.new(0, 0, 0, 50)
timerText.BackgroundTransparency = 1
timerText.Text = "00:00"
timerText.TextColor3 = Color3.fromRGB(100, 255, 255)
timerText.TextSize = 32
timerText.Font = Enum.Font.GothamBold
timerText.Parent = timerFrame

-- Barre de progression
local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(0.9, 0, 0, 15)
progressBg.Position = UDim2.new(0.05, 0, 0, 100)
progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
progressBg.BorderSizePixel = 0
progressBg.Parent = timerFrame

local progressBgCorner = Instance.new("UICorner")
progressBgCorner.CornerRadius = UDim.new(0, 8)
progressBgCorner.Parent = progressBg

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(100, 255, 255)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg

local progressBarCorner = Instance.new("UICorner")
progressBarCorner.CornerRadius = UDim.new(0, 8)
progressBarCorner.Parent = progressBar

-- Bouton Claim (caché au départ)
local claimButton = Instance.new("TextButton")
claimButton.Name = "ClaimButton"
claimButton.Size = UDim2.new(0, 300, 0, 45)
claimButton.Position = UDim2.new(0.5, -150, 0, 125)
claimButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
claimButton.Text = "🎁 RÉCUPÉRER LE RÉSULTAT"
claimButton.TextColor3 = Color3.new(1, 1, 1)
claimButton.TextSize = 16
claimButton.Font = Enum.Font.GothamBold
claimButton.Visible = false
claimButton.Parent = timerFrame

local claimCorner = Instance.new("UICorner")
claimCorner.CornerRadius = UDim.new(0, 10)
claimCorner.Parent = claimButton

-- Bouton Skip (Robux)
local skipButton = Instance.new("TextButton")
skipButton.Name = "SkipButton"
skipButton.Size = UDim2.new(0, 150, 0, 30)
skipButton.Position = UDim2.new(0.5, -75, 0, 125)
skipButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
skipButton.Text = "⏭️ SKIP (X R$)"
skipButton.TextColor3 = Color3.new(1, 1, 1)
skipButton.TextSize = 14
skipButton.Font = Enum.Font.GothamBold
skipButton.Parent = timerFrame

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 8)
skipCorner.Parent = skipButton

	-- ============================================
	-- ⏱️ GESTION DU TIMER
	-- ============================================

	local currentFusionTimer = nil

local function updateTimer()
	-- Demander le temps restant au serveur via un attribut
	local PlayerInfo = workspace:FindFirstChild("PlayerInfo")
	if not PlayerInfo then return end

	local playerFolder = PlayerInfo:FindFirstChild(player.Name)
	if not playerFolder then return end

	-- On va utiliser un attribut pour communiquer le temps restant
	local timeRemaining = playerFolder:GetAttribute("FusionTimeRemaining")

	if timeRemaining and timeRemaining > 0 then
		-- Afficher le timer
		timerFrame.Visible = true

		local minutes = math.floor(timeRemaining / 60)
		local seconds = timeRemaining % 60
		timerText.Text = string.format("%02d:%02d", minutes, seconds)

		-- Calculer le pourcentage (on a besoin de la durée totale)
		local totalDuration = playerFolder:GetAttribute("FusionTotalDuration") or timeRemaining
		local progress = 1 - (timeRemaining / totalDuration)

		-- Animer la barre
		TweenService:Create(
			progressBar,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(progress, 0, 1, 0)}
		):Play()

		-- Calculer le coût de skip
		local skipCost = math.ceil(timeRemaining / 60)
		skipButton.Text = "⏭️ SKIP (" .. skipCost .. " R$)"
		skipButton.Visible = true
		claimButton.Visible = false

	elseif timeRemaining and timeRemaining == 0 then
		-- Fusion terminée !
		timerFrame.Visible = true
		timerText.Text = "TERMINÉ !"
		timerText.TextColor3 = Color3.fromRGB(100, 255, 100)
		progressBar.Size = UDim2.new(1, 0, 1, 0)

		skipButton.Visible = false
		claimButton.Visible = true

	else
		-- Pas de fusion en cours
		timerFrame.Visible = false
	end
end

-- Boucle de mise à jour du timer
task.spawn(function()
	while true do
		task.wait(1)
		if mainFrame.Visible then
			updateTimer()
		end
	end
end)

-- ============================================
-- 🎁 BOUTON CLAIM
-- ============================================

claimButton.MouseButton1Click:Connect(function()
	print("[FusionUI] 🎁 Claim résultat")
	ClaimFusionResultEvent:FireServer()

	-- Cacher le timer
	timerFrame.Visible = false

	-- Rafraîchir l'inventaire
	task.wait(0.5)
	RequestInventoryEvent:FireServer()
end)

-- ============================================
-- ⏭️ BOUTON SKIP
-- ============================================

skipButton.MouseButton1Click:Connect(function()
	print("[FusionUI] ⏭️ Skip timer (Robux)")
	SkipFusionTimerEvent:FireServer()

	-- Note: Le serveur gérera le prompt Robux
	-- Si le paiement réussit, le timer sera mis à 0
end)

-- ============================================
-- 🔔 NOTIFICATIONS
-- ============================================

local notificationFrame = Instance.new("Frame")
notificationFrame.Name = "NotificationFrame"
notificationFrame.Size = UDim2.new(0, 400, 0, 120)
notificationFrame.Position = UDim2.new(0.5, -200, 0, -150)
notificationFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
notificationFrame.BackgroundTransparency = 0.1
notificationFrame.BorderSizePixel = 0
notificationFrame.Visible = false
notificationFrame.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 12)
notifCorner.Parent = notificationFrame

local notifStroke = Instance.new("UIStroke")
notifStroke.Color = Color3.fromRGB(100, 100, 150)
notifStroke.Thickness = 3
notifStroke.Parent = notificationFrame

local notifLayout = Instance.new("UIListLayout")
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Center
notifLayout.Padding = UDim.new(0, 8)
notifLayout.Parent = notificationFrame

local function showNotification(success, resultData)
	notificationFrame.Visible = true

	-- Nettoyer le contenu précédent
	for _, child in ipairs(notificationFrame:GetChildren()) do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	if success then
		-- ✅ SUCCÈS
		notifStroke.Color = Color3.fromRGB(100, 255, 100)

		local successIcon = Instance.new("TextLabel")
		successIcon.Size = UDim2.new(1, 0, 0, 40)
		successIcon.BackgroundTransparency = 1
		successIcon.Text = "🎉 FUSION RÉUSSIE !"
		successIcon.TextColor3 = Color3.fromRGB(100, 255, 100)
		successIcon.TextSize = 22
		successIcon.Font = Enum.Font.GothamBold
		successIcon.Parent = notificationFrame

		if resultData then
			local resultText = Instance.new("TextLabel")
			resultText.Size = UDim2.new(1, -20, 0, 60)
			resultText.BackgroundTransparency = 1
			resultText.Text = string.format(
				"Tu as obtenu :\n%s %s %s %s\n💧 %s/s",
				resultData.mood or "",
				resultData.sizeName or "",
				resultData.rarity or "",
				resultData.state or "",
				FormatNumbers:Format(resultData.production or 0)
			)
			resultText.TextColor3 = Color3.fromRGB(255, 255, 255)
			resultText.TextSize = 14
			resultText.Font = Enum.Font.Gotham
			resultText.TextWrapped = true
			resultText.Parent = notificationFrame
		end

	else
		-- ❌ ÉCHEC
		notifStroke.Color = Color3.fromRGB(255, 100, 100)

		local failIcon = Instance.new("TextLabel")
		failIcon.Size = UDim2.new(1, 0, 0, 40)
		failIcon.BackgroundTransparency = 1
		failIcon.Text = "💔 FUSION ÉCHOUÉE..."
		failIcon.TextColor3 = Color3.fromRGB(255, 100, 100)
		failIcon.TextSize = 22
		failIcon.Font = Enum.Font.GothamBold
		failIcon.Parent = notificationFrame

		if resultData then
			local compensationText = Instance.new("TextLabel")
			compensationText.Size = UDim2.new(1, -20, 0, 60)
			compensationText.BackgroundTransparency = 1
			compensationText.Text = string.format(
				"Compensation :\n💧 %s | ✨ %s",
				FormatNumbers:Format(resultData.gelatin or 0),
				FormatNumbers:Format(resultData.essence or 0)
			)
			compensationText.TextColor3 = Color3.fromRGB(255, 200, 100)
			compensationText.TextSize = 16
			compensationText.Font = Enum.Font.GothamBold
			compensationText.TextWrapped = true
			compensationText.Parent = notificationFrame
		end
	end

	-- Animation d'apparition
	notificationFrame.Position = UDim2.new(0.5, -200, 0, -150)
	TweenService:Create(
		notificationFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -200, 0, 50)}
	):Play()

	-- Disparaître après 5 secondes
	task.delay(5, function()
		TweenService:Create(
			notificationFrame,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, -200, 0, -150)}
		):Play()

		task.wait(0.5)
		notificationFrame.Visible = false
	end)
end

-- ============================================
-- 📡 ÉCOUTER LES RÉSULTATS DE FUSION
-- ============================================

-- On va créer un RemoteEvent pour notifier le client du résultat
local FusionResultEvent = RemoteEvents:FindFirstChild("FusionResultEvent")

if not FusionResultEvent then
	warn("[FusionUI] ⚠️ FusionResultEvent introuvable - Créer manuellement")
else
	FusionResultEvent.OnClientEvent:Connect(function(success, resultData)
		print("[FusionUI] 📬 Résultat reçu - Succès:", success)
		showNotification(success, resultData)
	end)
end

-- ============================================
-- 🔄 FONCTIONS UTILITAIRES
-- ============================================

local function formatTime(seconds)
	if seconds < 60 then
		return seconds .. "s"
	elseif seconds < 3600 then
		return math.floor(seconds / 60) .. "min " .. (seconds % 60) .. "s"
	else
		return math.floor(seconds / 3600) .. "h " .. math.floor((seconds % 3600) / 60) .. "min"
	end
end

local function clearSlot(slotNumber)
	local slot = slotsFrame:FindFirstChild("Slot" .. slotNumber)
	if not slot then return end

	local container = slot:FindFirstChild("Container")
	if not container then return end

	-- Nettoyer le container
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Remettre les labels par défaut
	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Name = "EmptyLabel"
	emptyLabel.Size = UDim2.new(1, 0, 0, 30)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Text = "SLOT " .. slotNumber
	emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	emptyLabel.TextSize = 18
	emptyLabel.Font = Enum.Font.GothamBold
	emptyLabel.Parent = container

	local clickLabel = Instance.new("TextLabel")
	clickLabel.Name = "ClickLabel"
	clickLabel.Size = UDim2.new(1, 0, 0, 20)
	clickLabel.BackgroundTransparency = 1
	clickLabel.Text = "Cliquez pour choisir"
	clickLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	clickLabel.TextSize = 12
	clickLabel.Font = Enum.Font.Gotham
	clickLabel.Parent = container
end

local function fillSlot(slotNumber, slimeData)
	local slot = slotsFrame:FindFirstChild("Slot" .. slotNumber)
	if not slot then return end

	local container = slot:FindFirstChild("Container")
	if not container then return end

	-- Nettoyer le container
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	-- Afficher les infos du slime
	local rarityData = SlimeConfig:GetRarityByName(slimeData.rarity)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = slimeData.mood .. " " .. slimeData.sizeName
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextSize = 11
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.Parent = container

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 0, 18)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = slimeData.rarity
	rarityLabel.TextColor3 = rarityData and rarityData.Color or Color3.new(1, 1, 1)
	rarityLabel.TextSize = 13
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = container

	local stateLabel = Instance.new("TextLabel")
	stateLabel.Size = UDim2.new(1, 0, 0, 16)
	stateLabel.BackgroundTransparency = 1
	stateLabel.Text = (slimeData.state or "Aucun")
	stateLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
	stateLabel.TextSize = 11
	stateLabel.Font = Enum.Font.Gotham
	stateLabel.Parent = container

	local prodLabel = Instance.new("TextLabel")
	prodLabel.Size = UDim2.new(1, 0, 0, 14)
	prodLabel.BackgroundTransparency = 1
	prodLabel.Text = "💧 " .. FormatNumbers:Format(slimeData.production) .. "/s"
	prodLabel.TextColor3 = Color3.fromHex("64C8FF")
	prodLabel.TextSize = 10
	prodLabel.Font = Enum.Font.Gotham
	prodLabel.Parent = container
end

local function clearCatalystSlot()
	-- Nettoyer le slot
	for _, child in ipairs(catalystSlot:GetChildren()) do
		if child.Name ~= "EmptyLabel" and not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end

	local emptyLabel = catalystSlot:FindFirstChild("EmptyLabel")
	if emptyLabel then
		emptyLabel.Visible = true
		emptyLabel.Text = "Aucun catalyseur\n(Bonus: 0%)"
	end
end

local function fillCatalystSlot(catalystData)
	local emptyLabel = catalystSlot:FindFirstChild("EmptyLabel")
	if emptyLabel then
		emptyLabel.Visible = false
	end

	local catalystInfo = FusionConfig.Catalysts[catalystData.catalystType]
	if not catalystInfo then return end

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 30)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = catalystInfo.icon .. " " .. catalystInfo.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = catalystSlot

	local bonusLabel = Instance.new("TextLabel")
	bonusLabel.Size = UDim2.new(1, 0, 0, 25)
	bonusLabel.Position = UDim2.new(0, 0, 0, 35)
	bonusLabel.BackgroundTransparency = 1
	bonusLabel.Text = "Bonus: +" .. catalystInfo.bonus .. "%"
	bonusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	bonusLabel.TextSize = 12
	bonusLabel.Font = Enum.Font.Gotham
	bonusLabel.Parent = catalystSlot
end

-- ============================================
-- 🔍 VALIDATION ET MISE À JOUR
-- ============================================

local function updateFusionInfo()
	-- Vérifier le nombre de slots remplis
	local requiredSlots = currentTab == "Fusion2" and 2 or 3
	local filledCount = #selectedSlots

	if filledCount < requiredSlots then
		costLabel.Text = "💧 Coût: --- | ✨ Essence: ---"
		timerLabel.Text = "⏱️ Durée: ---"
		chanceLabel.Text = "🎲 Chance de succès: ---%"
		validationLabel.Text = "Sélectionnez " .. (requiredSlots - filledCount) .. " slime(s) supplémentaire(s)"

		fusionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		fusionButton.Text = "🔒 Sélectionnez les slimes"
		fusionButton.TextColor3 = Color3.fromRGB(150, 150, 150)
		return
	end

	-- Validation selon le type de fusion
	local isValid = false
	local errorMessage = ""
	local fusionSubType = nil

	if currentTab == "Fusion2" then
		local slime1 = selectedSlots[1].data
		local slime2 = selectedSlots[2].data

		isValid, errorMessage = FusionConfig:ValidateFusion2(slime1, slime2)

	else -- Fusion3
		local slime1 = selectedSlots[1].data
		local slime2 = selectedSlots[2].data
		local slime3 = selectedSlots[3].data

		isValid, fusionSubType = FusionConfig:ValidateFusion3(slime1, slime2, slime3)

		if not isValid then
			errorMessage = fusionSubType -- En cas d'erreur, c'est le message
		end
	end

	if not isValid then
		validationLabel.Text = "❌ " .. errorMessage
		fusionButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		fusionButton.Text = "🔒 Conditions non remplies"
		fusionButton.TextColor3 = Color3.fromRGB(150, 150, 150)
		return
	end

	-- Calculer les coûts et infos
	local slime1 = selectedSlots[1].data
	local costs, timer, chance
	local catalystBonus = selectedCatalyst and FusionConfig:GetCatalystBonus(selectedCatalyst.data.catalystType) or 0

	if currentTab == "Fusion2" then
		costs = FusionConfig:CalculateFusion2Cost(slime1.rarity, slime1.sizeName, slime1.state or "Aucun")
		timer = FusionConfig:CalculateFusion2Timer(slime1.rarity, slime1.sizeName, slime1.state or "Aucun")
		chance = FusionConfig:CalculateFusion2Chance(slime1.rarity, slime1.sizeName, catalystBonus)
	else
		costs = FusionConfig:CalculateFusion3Cost(slime1.rarity, slime1.sizeName)
		timer = FusionConfig:CalculateFusion3Timer(slime1.rarity, slime1.sizeName)
		chance = FusionConfig:CalculateFusion3Chance(fusionSubType, slime1.rarity, slime1.sizeName, catalystBonus)
	end

	-- Afficher les infos
	costLabel.Text = "💧 Coût: " .. FormatNumbers:Format(costs.gelatin) .. " | ✨ Essence: " .. FormatNumbers:Format(costs.essence)
	timerLabel.Text = "⏱️ Durée: " .. formatTime(timer)
	chanceLabel.Text = "🎲 Chance de succès: " .. chance .. "%"

	-- Colorer la chance
	if chance >= 40 then
		chanceLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	elseif chance >= 20 then
		chanceLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	else
		chanceLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end

	validationLabel.Text = "✅ Prêt pour la fusion !"
	validationLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

	-- Activer le bouton
	fusionButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	fusionButton.Text = "⚡ LANCER LA FUSION"
	fusionButton.TextColor3 = Color3.new(1, 1, 1)
end

-- ============================================
-- 📂 OUVRIR L'INVENTAIRE POUR SÉLECTION
-- ============================================

-- Variable globale pour savoir quel slot on remplit
local currentlySelectingSlot = nil
local currentlySelectingCatalyst = false

local function openInventoryForSelection(slotNumber, selectingCatalyst)
	-- Sauvegarder ce qu'on est en train de sélectionner
	currentlySelectingSlot = slotNumber
	currentlySelectingCatalyst = selectingCatalyst

	-- ✅ ACTIVER LE MODE SÉLECTION
	_G.FusionSelectionActive = true

	-- 🔒 CACHER FusionUI pendant la sélection
	mainFrame.Visible = false

	-- Demander l'inventaire mis à jour
	RequestInventoryEvent:FireServer()

	-- Attendre un peu pour recevoir l'inventaire
	task.wait(0.2)

	-- Ouvrir l'inventaire UI
	local InventoryUI = playerGui:FindFirstChild("InventoryUI")
	if not InventoryUI then
		warn("[FusionUI] ❌ InventoryUI introuvable")
		currentlySelectingSlot = nil
		currentlySelectingCatalyst = false
		mainFrame.Visible = true -- Rouvrir Fusion si erreur
		return
	end

	local inventoryFrame = InventoryUI:FindFirstChild("MainFrame")
	if not inventoryFrame then
		warn("[FusionUI] ❌ MainFrame inventaire introuvable")
		currentlySelectingSlot = nil
		currentlySelectingCatalyst = false
		mainFrame.Visible = true -- Rouvrir Fusion si erreur
		return
	end

	-- Ouvrir l'inventaire (onglet Slimes par défaut)
	inventoryFrame.Visible = true

	print("[FusionUI] 📂 Ouverture inventaire pour slot", slotNumber, "- Catalyseur:", selectingCatalyst)

	-- Afficher un message si c'est pour un catalyseur
	if selectingCatalyst then
		print("[FusionUI] 💡 ASTUCE: Cliquez sur l'onglet OBJETS pour voir les catalyseurs")
	end
end

-- ✅ ÉCOUTER LES SÉLECTIONS DEPUIS L'INVENTAIRE
local FusionSelectionEvent = ReplicatedStorage:FindFirstChild("FusionSelectionEvent")
if FusionSelectionEvent then
	FusionSelectionEvent.Event:Connect(function(selectionData)
		if not currentlySelectingSlot then return end

		print("[FusionUI] 📥 Réception sélection:", selectionData.type, "- Index:", selectionData.index)

		-- 🔓 ROUVRIR FusionUI
		mainFrame.Visible = true

		if selectionData.type == "catalyst" and currentlySelectingCatalyst then
			-- Sélection d'un catalyseur
			selectedCatalyst = {
				index = selectionData.index,
				data = selectionData.data
			}

			fillCatalystSlot(selectionData.data)
			print("[FusionUI] ⚡ Catalyseur sélectionné:", selectionData.data.catalystType)

		elseif selectionData.type == "slime" and not currentlySelectingCatalyst then
			-- Sélection d'un slime
			local slotNumber = currentlySelectingSlot

			-- Vérifier si ce slime n'est pas déjà sélectionné
			for i, slot in ipairs(selectedSlots) do
				if slot and slot.index == selectionData.index then
					warn("[FusionUI] ⚠️ Ce slime est déjà sélectionné dans le slot", i)
					return
				end
			end

			-- Ajouter le slime au slot
			selectedSlots[slotNumber] = {
				index = selectionData.index,
				data = selectionData.data
			}

			fillSlot(slotNumber, selectionData.data)
			print("[FusionUI] 🧪 Slime ajouté au slot", slotNumber, ":", selectionData.data.mood, selectionData.data.sizeName)
		end


		-- Réinitialiser la sélection
		currentlySelectingSlot = nil
		currentlySelectingCatalyst = false

		-- ✅ DÉSACTIVER LE MODE SÉLECTION
		_G.FusionSelectionActive = false

		-- Mettre à jour les infos de fusion
		updateFusionInfo()
	end)
else
	warn("[FusionUI] ⚠️ FusionSelectionEvent introuvable")
end

-- ============================================
-- 🎯 ÉVÉNEMENTS DES SLOTS
-- ============================================

slot1.MouseButton1Click:Connect(function()
	local slotNumber = 1

	-- Si déjà rempli, on le vide
	if selectedSlots[slotNumber] then
		selectedSlots[slotNumber] = nil
		clearSlot(slotNumber)
	else
		-- Ouvrir l'inventaire pour sélection
		openInventoryForSelection(slotNumber, false)
	end

	updateFusionInfo()
end)

slot2.MouseButton1Click:Connect(function()
	local slotNumber = 2

	if selectedSlots[slotNumber] then
		selectedSlots[slotNumber] = nil
		clearSlot(slotNumber)
	else
		openInventoryForSelection(slotNumber, false)
	end

	updateFusionInfo()
end)

slot3.MouseButton1Click:Connect(function()
	local slotNumber = 3

	if selectedSlots[slotNumber] then
		selectedSlots[slotNumber] = nil
		clearSlot(slotNumber)
	else
		openInventoryForSelection(slotNumber, false)
	end

	updateFusionInfo()
end)

catalystSlot.MouseButton1Click:Connect(function()
	if selectedCatalyst then
		selectedCatalyst = nil
		clearCatalystSlot()
	else
		openInventoryForSelection(0, true) -- 0 = catalyseur
	end

	updateFusionInfo()
end)

-- ============================================
-- 🔀 CHANGER D'ONGLET
-- ============================================

local function switchTab(tabName)
	currentTab = tabName

	-- Réinitialiser les sélections
	selectedSlots = {}
	selectedCatalyst = nil

	clearSlot(1)
	clearSlot(2)
	clearSlot(3)
	clearCatalystSlot()

	-- Mettre à jour l'apparence des boutons
	if tabName == "Fusion2" then
		fusion2TabButton.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
		fusion2TabButton.TextColor3 = Color3.new(1, 1, 1)
		fusion3TabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		fusion3TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)

		-- Masquer le slot 3 pour Fusion2
		slot3.Visible = false
	else
		fusion3TabButton.BackgroundColor3 = Color3.fromRGB(255, 150, 100)
		fusion3TabButton.TextColor3 = Color3.new(1, 1, 1)
		fusion2TabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		fusion2TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)

		-- Afficher le slot 3 pour Fusion3
		slot3.Visible = true
	end

	updateFusionInfo()

	print("[FusionUI] 🔀 Onglet changé:", tabName)
end

fusion2TabButton.MouseButton1Click:Connect(function()
	switchTab("Fusion2")
end)

fusion3TabButton.MouseButton1Click:Connect(function()
	switchTab("Fusion3")
end)

-- ============================================
-- ⚡ LANCER LA FUSION
-- ============================================

fusionButton.MouseButton1Click:Connect(function()
	-- Vérifier que le bouton est actif
	if fusionButton.BackgroundColor3 ~= Color3.fromRGB(100, 200, 100) then
		return
	end

	-- Récupérer les indices des slots
	local slotIndices = {}
	for i, slot in ipairs(selectedSlots) do
		if slot then
			table.insert(slotIndices, slot.index)
		end
	end

	local catalystIndex = selectedCatalyst and selectedCatalyst.index or nil

	-- Envoyer au serveur
	StartFusionEvent:FireServer(currentTab, slotIndices, catalystIndex)

	print("[FusionUI] ⚡ Fusion lancée - Type:", currentTab, "- Slots:", table.concat(slotIndices, ","))

	-- Fermer l'interface
	mainFrame.Visible = false

	-- Réinitialiser
	selectedSlots = {}
	selectedCatalyst = nil
	clearSlot(1)
	clearSlot(2)
	clearSlot(3)
	clearCatalystSlot()
end)

-- ============================================
-- 📨 RECEVOIR L'INVENTAIRE
-- ============================================

RequestInventoryEvent.OnClientEvent:Connect(function(inventory)
	inventoryData = inventory
	print("[FusionUI] 📦 Inventaire reçu -", #inventoryData.Items, "items")
end)

-- ============================================
-- 🎮 CONNEXION AU BOUTON DU MENU
-- ============================================

task.spawn(function()
	task.wait(2)

	local MenuUI = playerGui:FindFirstChild("MenuUI")
	if not MenuUI then
		warn("[FusionUI] ⚠️ MenuUI introuvable")
		return
	end

	local menuFrame = MenuUI:FindFirstChild("MainFrame")
	if not menuFrame then
		warn("[FusionUI] ⚠️ MainFrame introuvable")
		return
	end

	local fusionButton = menuFrame:FindFirstChild("FusionButton")
	if not fusionButton then
		warn("[FusionUI] ⚠️ Bouton Fusion introuvable")
		return
	end

	print("[FusionUI] ✅ Bouton Fusion connecté !")

	fusionButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = not mainFrame.Visible

		if mainFrame.Visible then
			-- Réinitialiser à Fusion2 par défaut
			switchTab("Fusion2")
			-- Demander l'inventaire
			RequestInventoryEvent:FireServer()
			print("[FusionUI] 📂 Ouverture de la fusion")
		else
			print("[FusionUI] 📁 Fermeture de la fusion")
		end
	end)
end)

-- Bouton fermer
closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false

	-- ✅ DÉSACTIVER LE MODE SÉLECTION au cas où
	_G.FusionSelectionActive = false
	currentlySelectingSlot = nil
	currentlySelectingCatalyst = false
end)

-- Initialiser l'onglet par défaut
switchTab("Fusion2")

print("[FusionUI] ✅ Interface chargée")
