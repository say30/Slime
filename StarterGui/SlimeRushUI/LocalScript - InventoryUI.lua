-- from: StarterGui.SlimeRushUI.InventoryUI

-- CORRIGÉ InventoryUI.lua - Erreur ligne 108 FIXED
-- Place: StarterGui/SlimeRushUI/InventoryUI

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local remotes = RS:WaitForChild("Remotes")
local getInvRemote = remotes:WaitForChild("GetInventory")
local sellRemote = remotes:WaitForChild("SellSlime")
local placeRemote = remotes:WaitForChild("PlaceSlimeFromInventory")

local playerGui = LP:WaitForChild("PlayerGui")
local slimeHUD = playerGui:WaitForChild("SlimeHUD")

local invWindow = Instance.new("Frame")
invWindow.Name = "InventoryWindow"
invWindow.BackgroundColor3 = Color3.fromRGB(25, 28, 36)
invWindow.BackgroundTransparency = 0.1
invWindow.Size = UDim2.new(0, 480, 0, 600)
invWindow.Position = UDim2.new(0, 10, 0.5, -300)
invWindow.BorderSizePixel = 0
invWindow.Visible = false
invWindow.Parent = slimeHUD

Instance.new("UICorner", invWindow).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel", invWindow)
title.Text = "📦 INVENTAIRE"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.BackgroundColor3 = Color3.fromRGB(50, 80, 120)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BorderSizePixel = 0
title.Size = UDim2.new(1, 0, 0, 50)

local counter = Instance.new("TextLabel", invWindow)
counter.Text = "0/25"
counter.Font = Enum.Font.GothamBold
counter.TextSize = 14
counter.BackgroundTransparency = 1
counter.TextColor3 = Color3.fromRGB(150, 200, 255)
counter.Position = UDim2.new(1, -70, 0, 15)
counter.Size = UDim2.new(0, 60, 0, 25)

local scrollList = Instance.new("Frame", invWindow)
scrollList.BackgroundTransparency = 1
scrollList.Size = UDim2.new(1, -20, 1, -100)
scrollList.Position = UDim2.new(0, 10, 0, 60)

local scrollLayout = Instance.new("UIListLayout", scrollList)
scrollLayout.Padding = UDim.new(0, 10)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder

Instance.new("UIPadding", scrollList).PaddingTop = UDim.new(0, 5)

local RARITY_NAMES = {"Commun", "Vibrant", "Rare", "Arcane", "Épique", "Légendaire", "Mythique", "Occulte", "Céleste", "Abyssal", "Prismatique", "Oméga"}
local RARITY_COLORS = {
	Color3.fromRGB(150, 150, 150),
	Color3.fromRGB(100, 200, 100),
	Color3.fromRGB(100, 150, 255),
	Color3.fromRGB(200, 100, 255),
	Color3.fromRGB(255, 150, 50),
	Color3.fromRGB(255, 200, 50),
}
local STATE_NAMES = {"Pur", "Muté", "Fusionné", "Cristallisé", "Corrompu"}

local function createSlimeCard(slime, index)
	local card = Instance.new("Frame", scrollList)
	card.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0, 100)
	card.LayoutOrder = index
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

	local colorBand = Instance.new("Frame", card)
	colorBand.BackgroundColor3 = RARITY_COLORS[slime.rarityIndex or 1]
	colorBand.BorderSizePixel = 0
	colorBand.Size = UDim2.new(0, 6, 1, 0)

	local info = Instance.new("TextLabel", card)
	info.BackgroundTransparency = 1
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top
	info.Font = Enum.Font.Gotham
	info.TextSize = 12
	info.TextColor3 = Color3.fromRGB(200, 220, 255)
	info.Size = UDim2.new(0.5, -15, 1, 0)
	info.Position = UDim2.new(0, 15, 0, 8)

	local rarityName = RARITY_NAMES[slime.rarityIndex or 1] or "?"
	local stateName = STATE_NAMES[slime.stateIndex or 1] or "?"

	info.Text = slime.mood .. " - " .. slime.sizeName 
		.. "\n" .. rarityName
		.. "\n🟣 " .. slime.prodPerSec

	local buttonPanel = Instance.new("Frame", card)
	buttonPanel.BackgroundTransparency = 1
	buttonPanel.Size = UDim2.new(0.45, 0, 1, -10)
	buttonPanel.Position = UDim2.new(0.55, 0, 0, 5)

	local buttonLayout = Instance.new("UIListLayout", buttonPanel)
	buttonLayout.FillDirection = Enum.FillDirection.Vertical
	buttonLayout.Padding = UDim.new(0, 3)
	-- ✅ FIX: Stretch → Left (pas de Stretch en HorizontalAlignment)
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

	local function makeBtn(text, color, callback)
		local btn = Instance.new("TextButton", buttonPanel)
		btn.Text = text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 10
		btn.BackgroundColor3 = color
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.BorderSizePixel = 0
		btn.Size = UDim2.new(0.9, 0, 0, 25)
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

		btn.MouseButton1Click:Connect(callback)
		return btn
	end

	makeBtn("📍 PLACER", Color3.fromRGB(100, 150, 255), function()
		local ok = placeRemote:InvokeServer(index, 1)
		if ok then refreshInventory() end
	end)

	makeBtn("💰 VENDRE", Color3.fromRGB(100, 180, 100), function()
		local ok = sellRemote:InvokeServer(index)
		if ok then refreshInventory() end
	end)

	makeBtn("🧬 FUSION", Color3.fromRGB(150, 100, 200), function()
		print("🧬 Fusion: " .. index)
	end)
end

function refreshInventory()
	for _, child in ipairs(scrollList:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "UIListLayout" then child:Destroy() end
	end

	local data = getInvRemote:InvokeServer()
	if data then
		counter.Text = data.used .. "/" .. data.max
		for i, slime in ipairs(data.slimes) do
			createSlimeCard(slime, i)
		end
		if data.used == 0 then
			local empty = Instance.new("TextLabel", scrollList)
			empty.BackgroundTransparency = 1
			empty.Text = "📭 Vide"
			empty.Font = Enum.Font.Gotham
			empty.TextSize = 16
			empty.TextColor3 = Color3.fromRGB(150, 150, 150)
			empty.Size = UDim2.new(1, 0, 0, 50)
		end
	end
end

task.wait(0.5)
local mainFrame = slimeHUD:FindFirstChild("MainFrame")
if mainFrame then
	local buttonsPanel = mainFrame:FindFirstChild("ButtonsPanel")
	if buttonsPanel then
		local invBtn = buttonsPanel:FindFirstChild("InventoryBtn")
		if invBtn then
			invBtn.MouseButton1Click:Connect(function()
				invWindow.Visible = not invWindow.Visible
				if invWindow.Visible then refreshInventory() end
			end)
		end
	end
end
