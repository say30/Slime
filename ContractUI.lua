--[[
    ContractUI.lua
    Interface des contrats quotidiens
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Modules
local FormatNumbers = require(ReplicatedStorage.Modules.Shared.FormatNumbers)

-- Remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestContractsEvent = RemoteEvents:WaitForChild("RequestContractsEvent")
local ClaimContractRewardEvent = RemoteEvents:WaitForChild("ClaimContractRewardEvent")
local UpdateContractProgressEvent = RemoteEvents:WaitForChild("UpdateContractProgressEvent")

-- ============================================
-- 📐 CONSTANTES
-- ============================================

local TIER_COLORS = {
	Easy = Color3.fromRGB(100, 200, 100),
	Medium = Color3.fromRGB(255, 200, 50),
	Hard = Color3.fromRGB(255, 100, 100)
}

local TIER_NAMES = {
	Easy = "FACILE",
	Medium = "MOYEN",
	Hard = "DIFFICILE"
}

local contractsData = {}

-- ============================================
-- 🎨 CRÉER L'UI PRINCIPALE
-- ============================================

local screenGui = playerGui:FindFirstChild("ContractUI")
if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ContractUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 13
	screenGui.Parent = playerGui
end

-- Frame principale (cachée au départ)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 500, 0, 650)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -325)
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
titleLabel.Text = "📋 CONTRATS QUOTIDIENS"
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
-- 📜 CONTAINER DES CONTRATS
-- ============================================

local contractsContainer = Instance.new("Frame")
contractsContainer.Name = "ContractsContainer"
contractsContainer.Size = UDim2.new(1, -20, 1, -80)
contractsContainer.Position = UDim2.new(0, 10, 0, 70)
contractsContainer.BackgroundTransparency = 1
contractsContainer.Parent = mainFrame

local containerLayout = Instance.new("UIListLayout")
containerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
containerLayout.VerticalAlignment = Enum.VerticalAlignment.Top
containerLayout.Padding = UDim.new(0, 15)
containerLayout.Parent = contractsContainer

-- ============================================
-- 🎨 CRÉER UNE CARTE DE CONTRAT
-- ============================================

local function createContractCard(contractData)
	local card = Instance.new("Frame")
	card.Name = "ContractCard"
	card.Size = UDim2.new(1, 0, 0, 180)
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	card.BackgroundTransparency = 0.3
	card.BorderSizePixel = 0
	card.Parent = contractsContainer

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = TIER_COLORS[contractData.tier] or Color3.fromRGB(150, 150, 150)
	cardStroke.Thickness = 3
	cardStroke.Parent = card

	-- Bande de difficulté
	local tierBand = Instance.new("Frame")
	tierBand.Size = UDim2.new(1, 0, 0, 35)
	tierBand.BackgroundColor3 = TIER_COLORS[contractData.tier] or Color3.fromRGB(150, 150, 150)
	tierBand.BorderSizePixel = 0
	tierBand.Parent = card

	local tierCorner = Instance.new("UICorner")
	tierCorner.CornerRadius = UDim.new(0, 12)
	tierCorner.Parent = tierBand

	local tierLabel = Instance.new("TextLabel")
	tierLabel.Size = UDim2.new(1, 0, 1, 0)
	tierLabel.BackgroundTransparency = 1
	tierLabel.Text = TIER_NAMES[contractData.tier] or "CONTRAT"
	tierLabel.TextColor3 = Color3.new(1, 1, 1)
	tierLabel.TextSize = 16
	tierLabel.Font = Enum.Font.GothamBold
	tierLabel.Parent = tierBand

	-- Description
	local descText = contractData.objective.description:gsub("{target}", tostring(contractData.objective.target))
	descText = descText:gsub("{count}", tostring(contractData.objective.count or ""))

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -20, 0, 40)
	descLabel.Position = UDim2.new(0, 10, 0, 45)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = descText
	descLabel.TextColor3 = Color3.new(1, 1, 1)
	descLabel.TextSize = 14
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = card

	-- Barre de progression
	local progressBg = Instance.new("Frame")
	progressBg.Size = UDim2.new(1, -20, 0, 20)
	progressBg.Position = UDim2.new(0, 10, 0, 95)
	progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = card

	local progressBgCorner = Instance.new("UICorner")
	progressBgCorner.CornerRadius = UDim.new(0, 10)
	progressBgCorner.Parent = progressBg

	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.BackgroundColor3 = TIER_COLORS[contractData.tier] or Color3.fromRGB(100, 200, 100)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBg

	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(0, 10)
	progressBarCorner.Parent = progressBar

	-- Texte de progression
	local progressLabel = Instance.new("TextLabel")
	progressLabel.Name = "ProgressLabel"
	progressLabel.Size = UDim2.new(1, 0, 1, 0)
	progressLabel.BackgroundTransparency = 1
	progressLabel.Text = "0 / 0"
	progressLabel.TextColor3 = Color3.new(1, 1, 1)
	progressLabel.TextSize = 12
	progressLabel.Font = Enum.Font.GothamBold
	progressLabel.ZIndex = 2
	progressLabel.Parent = progressBg

	-- Récompenses
	local rewardsLabel = Instance.new("TextLabel")
	rewardsLabel.Size = UDim2.new(1, -20, 0, 25)
	rewardsLabel.Position = UDim2.new(0, 10, 0, 125)
	rewardsLabel.BackgroundTransparency = 1
	rewardsLabel.TextColor3 = Color3.fromHex("FFD700")
	rewardsLabel.TextSize = 13
	rewardsLabel.Font = Enum.Font.GothamBold
	rewardsLabel.TextXAlignment = Enum.TextXAlignment.Left
	rewardsLabel.Parent = card

	-- Construire le texte des récompenses
	local rewardsText = "🎁 "
	if contractData.rewards.gelatin > 0 then
		rewardsText = rewardsText .. FormatNumbers:Format(contractData.rewards.gelatin) .. " 💧  "
	end
	if contractData.rewards.essence > 0 then
		rewardsText = rewardsText .. FormatNumbers:Format(contractData.rewards.essence) .. " ✨  "
	end
	if contractData.rewards.catalysts and #contractData.rewards.catalysts > 0 then
		for _, catalyst in ipairs(contractData.rewards.catalysts) do
			rewardsText = rewardsText .. catalyst.quantity .. "x " .. catalyst.type .. " ⚡  "
		end
	end
	rewardsLabel.Text = rewardsText

	-- Bouton Claim
	local claimButton = Instance.new("TextButton")
	claimButton.Name = "ClaimButton"
	claimButton.Size = UDim2.new(0, 120, 0, 35)
	claimButton.Position = UDim2.new(1, -130, 1, -45)
	claimButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	claimButton.Text = "🔒 Incomplet"
	claimButton.TextColor3 = Color3.fromRGB(150, 150, 150)
	claimButton.TextSize = 14
	claimButton.Font = Enum.Font.GothamBold
	claimButton.Parent = card

	local claimCorner = Instance.new("UICorner")
	claimCorner.CornerRadius = UDim.new(0, 8)
	claimCorner.Parent = claimButton

	-- Sauvegarder les références
	card:SetAttribute("ContractId", contractData.id)

	return card
end

-- ============================================
-- 🔄 RAFRAÎCHIR LES CONTRATS
-- ============================================

local function refreshContracts()
	-- Nettoyer les cartes existantes
	for _, child in ipairs(contractsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Créer les nouvelles cartes
	for _, contractData in ipairs(contractsData) do
		createContractCard(contractData)
	end

	print("[ContractUI] ✅ Interface rafraîchie -", #contractsData, "contrats")
end

-- ============================================
-- 🔄 METTRE À JOUR LA PROGRESSION
-- ============================================

local function updateProgress()
	for _, card in ipairs(contractsContainer:GetChildren()) do
		if card:IsA("Frame") then
			local contractId = card:GetAttribute("ContractId")

			-- Trouver le contrat correspondant
			local contractData = nil
			for _, data in ipairs(contractsData) do
				if data.id == contractId then
					contractData = data
					break
				end
			end

			if contractData then
				local progressBar = card:FindFirstChild("ProgressBar", true)
				local progressLabel = card:FindFirstChild("ProgressLabel", true)
				local claimButton = card:FindFirstChild("ClaimButton", true)

				if progressBar and progressLabel and claimButton then
					local progress = contractData.progress or 0
					local target = contractData.objective.target

					-- Gérer les cas spéciaux
					if contractData.type == "CollectGelatin" then
						-- Target en heures de production
						local PlayerInfo = workspace:FindFirstChild("PlayerInfo")
						local playerFolder = PlayerInfo and PlayerInfo:FindFirstChild(player.Name)
						local productionValue = playerFolder and playerFolder:FindFirstChild("ProductionRate")
						local totalProduction = productionValue and productionValue.Value or 1

						target = totalProduction * 3600 * target
					elseif contractData.type == "BuyRarity" or contractData.type == "BuySize" then
						target = contractData.objective.count or 1
					end

					local percent = math.clamp(progress / math.max(target, 1), 0, 1)

					-- Animer la barre
					local tween = TweenService:Create(
						progressBar,
						TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Size = UDim2.new(percent, 0, 1, 0)}
					)
					tween:Play()

					-- Mettre à jour le texte
					progressLabel.Text = FormatNumbers:Format(math.floor(progress)) .. " / " .. FormatNumbers:Format(math.floor(target))

					-- Mettre à jour le bouton
					if progress >= target then
						claimButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
						claimButton.Text = "🎁 CLAIM"
						claimButton.TextColor3 = Color3.new(1, 1, 1)

						claimButton.MouseButton1Click:Connect(function()
							ClaimContractRewardEvent:FireServer(contractId)
							claimButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
							claimButton.Text = "⏳ Claim..."
							claimButton.TextColor3 = Color3.fromRGB(150, 150, 150)
						end)
					else
						claimButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
						claimButton.Text = "🔒 Incomplet"
						claimButton.TextColor3 = Color3.fromRGB(150, 150, 150)
					end
				end
			end
		end
	end
end

-- ============================================
-- 🎮 ÉVÉNEMENTS
-- ============================================

-- Recevoir les contrats du serveur
RequestContractsEvent.OnClientEvent:Connect(function(contracts)
contractsData = contracts
refreshContracts()
updateProgress()
end)

-- Mise à jour en temps réel de la progression
UpdateContractProgressEvent.OnClientEvent:Connect(function(contractId, progress)
for _, contract in ipairs(contractsData) do
if contract.id == contractId then
contract.progress = progress
end
end

updateProgress()
end)

-- Ouvrir/Fermer l'interface
local MenuUI = playerGui:WaitForChild("MenuUI")
local menuFrame = MenuUI:WaitForChild("MainFrame")
local contractButton = menuFrame:FindFirstChild("ContratButton")

if contractButton then
	contractButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = not mainFrame.Visible

		if mainFrame.Visible then
			-- Demander les contrats au serveur
			RequestContractsEvent:FireServer()
			print("[ContractUI] 📂 Ouverture des contrats")
		else
			print("[ContractUI] 📁 Fermeture des contrats")
		end
	end)
end

-- Bouton fermer
closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

-- Rafraîchir la progression régulièrement
task.spawn(function()
	while true do
		task.wait(2)
		if mainFrame.Visible and #contractsData > 0 then
			updateProgress()
		end
	end
end)

print("[ContractUI] ✅ Interface chargée")
