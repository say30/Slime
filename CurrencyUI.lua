--[[
    CurrencyUI.lua
    HUD avec timer intelligent
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Modules
local FormatNumbers = require(ReplicatedStorage.Modules.Shared.FormatNumbers)

-- Remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateCurrencyEvent = RemoteEvents:WaitForChild("UpdateCurrencyEvent")
local UpdateRareTimerEvent = RemoteEvents:WaitForChild("UpdateRareTimerEvent")

-- ============================================
-- 🎨 CRÉATION DE L'UI
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CurrencyUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

-- Container principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 320, 0, 200)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 100, 150)
stroke.Thickness = 2
stroke.Transparency = 0.5
stroke.Parent = mainFrame

-- Layout vertical
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.Parent = mainFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 15)
padding.PaddingRight = UDim.new(0, 15)
padding.Parent = mainFrame

-- ============================================
-- 💧 FONCTION POUR CRÉER UNE LIGNE
-- ============================================

local function createCurrencyRow(iconText, labelText, initialValue, textColor)
	local row = Instance.new("Frame")
	row.Name = labelText .. "Row"
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundTransparency = 1
	row.Parent = mainFrame

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 30, 0, 30)
	icon.Position = UDim2.new(0, 0, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = iconText
	icon.TextSize = 20
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.Parent = row

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0, 90, 0, 30)
	label.Position = UDim2.new(0, 35, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextSize = 14
	label.Font = Enum.Font.Gotham
	label.TextColor3 = Color3.fromRGB(200, 200, 220)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.Size = UDim2.new(1, -130, 0, 30)
	value.Position = UDim2.new(0, 130, 0, 0)
	value.BackgroundTransparency = 1
	value.Text = FormatNumbers:Format(initialValue)
	value.TextSize = 16
	value.Font = Enum.Font.GothamBold
	value.TextColor3 = textColor or Color3.fromRGB(100, 255, 150)
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Parent = row

	return row, value
end

-- ============================================
-- 💰 CRÉER LES LIGNES DE MONNAIE
-- ============================================

local gelatineRow, gelatineValue = createCurrencyRow("💧", "Gélatine", 100, Color3.fromRGB(100, 200, 255))
local essenceRow, essenceValue = createCurrencyRow("✨", "Essence", 0, Color3.fromRGB(255, 150, 255))
local totalRow, totalValue = createCurrencyRow("📊", "Total Récolté", 0, Color3.fromRGB(255, 215, 0))

-- ============================================
-- ⏱️ CRÉER LE TIMER (AVEC RICHTEXT)
-- ============================================

local timerRow = Instance.new("Frame")
timerRow.Name = "TimerRow"
timerRow.Size = UDim2.new(1, 0, 0, 45)
timerRow.BackgroundTransparency = 1
timerRow.Parent = mainFrame

local separator = Instance.new("Frame")
separator.Name = "Separator"
separator.Size = UDim2.new(1, 0, 0, 2)
separator.Position = UDim2.new(0, 0, 0, 0)
separator.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
separator.BackgroundTransparency = 0.7
separator.BorderSizePixel = 0
separator.Parent = timerRow

local timerIcon = Instance.new("TextLabel")
timerIcon.Name = "Icon"
timerIcon.Size = UDim2.new(0, 30, 0, 30)
timerIcon.Position = UDim2.new(0, 0, 0, 8)
timerIcon.BackgroundTransparency = 1
timerIcon.Text = "⭐"
timerIcon.TextSize = 18
timerIcon.Font = Enum.Font.GothamBold
timerIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
timerIcon.Parent = timerRow

-- RICHTEXT pour colorer uniquement la rareté
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, -35, 0, 35)
timerLabel.Position = UDim2.new(0, 35, 0, 8)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "Spawn slime aléatoire dans 10:00"
timerLabel.TextSize = 13
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.TextWrapped = true
timerLabel.RichText = true
timerLabel.Parent = timerRow

-- ============================================
-- 🔄 MISE À JOUR VIA REMOTE
-- ============================================

UpdateCurrencyEvent.OnClientEvent:Connect(function(currencyData)
	if currencyData.gelatine then
		gelatineValue.Text = FormatNumbers:Format(currencyData.gelatine)
	end

	if currencyData.essence then
		essenceValue.Text = FormatNumbers:Format(currencyData.essence)
	end

	if currencyData.totalCollected then
		totalValue.Text = FormatNumbers:Format(currencyData.totalCollected)
	end
end)

-- ============================================
-- ⏱️ MISE À JOUR DU TIMER AVEC ANIMATION
-- ============================================

local lastRarityIndex = 1
local animationActive = false
local currentTimeRemaining = 0

UpdateRareTimerEvent.OnClientEvent:Connect(function(data)
	if not data.rarityName or not data.rarityColor or not data.timeRemaining then return end

	-- STOCKER le temps restant
	currentTimeRemaining = data.timeRemaining

	local minutes = math.floor(data.timeRemaining / 60)
	local seconds = math.floor(data.timeRemaining % 60)
	local timeText = string.format("%d:%02d", minutes, seconds)

	-- Convertir Color3 en hex pour RichText
	local function color3ToHex(color)
		local r = math.floor(color.R * 255)
		local g = math.floor(color.G * 255)
		local b = math.floor(color.B * 255)
		return string.format("#%02X%02X%02X", r, g, b)
	end

	if data.shouldReveal then
		-- Entre 30s et 2s : Animation de raretés aléatoires
		if data.timeRemaining > 1 then

			if not animationActive then
				animationActive = true

				task.spawn(function()
					local SlimeConfig = require(ReplicatedStorage.Modules.Shared.SlimeConfig)
					local eligibleRarities = {"Épique", "Légendaire", "Mythique", "Occulte", "Céleste", "Abyssal", "Prismatique", "Oméga"}

					while currentTimeRemaining > 1 and animationActive do
						-- Mettre à jour le temps affiché
						local min = math.floor(currentTimeRemaining / 60)
						local sec = math.floor(currentTimeRemaining % 60)
						local time = string.format("%d:%02d", min, sec)

						-- Changer de rareté aléatoirement
						lastRarityIndex = (lastRarityIndex % #eligibleRarities) + 1
						local randomRarity = SlimeConfig:GetRarityByName(eligibleRarities[lastRarityIndex])

						if randomRarity then
							local colorHex = color3ToHex(randomRarity.Color)
							timerLabel.Text = string.format('Spawn <font color="%s">%s</font> dans %s', 
								colorHex, randomRarity.Name, time)
							timerIcon.TextColor3 = randomRarity.Color
						end

						task.wait(0.3) -- Changer toutes les 0.3 secondes
					end

					-- Animation terminée
					animationActive = false
				end)
			end
		else
			-- À 1s ou moins : Arrêter l'animation et montrer la vraie rareté
			animationActive = false

			local colorHex = color3ToHex(data.rarityColor)
			timerLabel.Text = string.format('Spawn <font color="%s">%s</font> dans %s', 
				colorHex, data.rarityName, timeText)
			timerIcon.TextColor3 = data.rarityColor
		end
	else
		-- Avant 30s : Afficher "slime aléatoire"
		animationActive = false
		timerLabel.Text = string.format("Spawn slime aléatoire dans %s", timeText)
		timerIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
	end
end)
