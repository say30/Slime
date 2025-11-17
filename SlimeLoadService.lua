--[[
    SlimeLoadService.lua
    VERSION CORRIGÉE - Avec Cost
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))
local SlimeConfig = require(ReplicatedStorage.Modules.Shared.SlimeConfig)
local FormatNumbers = require(ReplicatedStorage.Modules.Shared.FormatNumbers)

-- ============================================
-- 📊 CRÉER LE BILLBOARD
-- ============================================
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

-- ============================================
-- 🔄 CHARGER LES SLIMES D'UN JOUEUR
-- ============================================
local function loadPlayerSlimes(player)
	task.wait(2) -- Attendre que tout soit chargé

	local pods = DataStoreManager.GetPods(player)

	if not pods or #pods == 0 then
		print("[SlimeLoad] ✅ Aucun slime à charger pour", player.Name)
		return
	end

	print("[SlimeLoad] 📦 Chargement de", #pods, "slimes pour", player.Name)

	local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
	if not PlayerInfo then return end

	local playerFolder = PlayerInfo:FindFirstChild(player.Name)
	if not playerFolder then return end

	local serverSlimesFolder = playerFolder:FindFirstChild("ServerSlimes")
	if not serverSlimesFolder then return end

	local SlimesFolder = ReplicatedStorage:WaitForChild("Slimes")

	for _, podData in ipairs(pods) do
		local moodFolder = SlimesFolder:FindFirstChild(podData.mood)
		if moodFolder then
			local modelName = podData.mood .. " " .. podData.sizeName
			local baseModel = moodFolder:FindFirstChild(modelName)

			if baseModel then
				local slimeClone = baseModel:Clone()
				slimeClone.Name = "ServerSlime_" .. tick()

				for _, part in ipairs(slimeClone:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Anchored = true
						part.CanCollide = false
					end
				end

				-- ✅ TOUS LES ATTRIBUTS INCLUANT COST
				slimeClone:SetAttribute("Mood", podData.mood)
				slimeClone:SetAttribute("Rarity", podData.rarity)
				slimeClone:SetAttribute("Size", podData.sizeName)
				slimeClone:SetAttribute("Production", podData.production)
				slimeClone:SetAttribute("Owner", player.Name)
				slimeClone:SetAttribute("PodNumber", podData.podNumber)
				slimeClone:SetAttribute("Cost", podData.cost or 0) -- ✅ CRITIQUE

				print("[SlimeLoad] 💰 Cost chargé:", podData.cost or 0)

				-- Trouver la position du spawn
				local basesFolder = Workspace:FindFirstChild("Base")
				if basesFolder then
					local base = basesFolder:FindFirstChild(podData.baseName)
					if base then
						local podsFolder = base:FindFirstChild("PodsSlime")
						if podsFolder then
							local podContainer = podsFolder:FindFirstChild("PodsSlime" .. podData.podNumber)
							if podContainer then
								local baseFolder = podContainer:FindFirstChild("Base")
								if baseFolder then
									local spawn = baseFolder:FindFirstChild("Spawn")
									if spawn then
										slimeClone.Parent = serverSlimesFolder
										slimeClone:PivotTo(CFrame.new(spawn.Position))

										createBillboard(slimeClone, podData.mood, podData.rarity, podData.sizeName, podData.production, podData.cost or 0)

										print("[SlimeLoad] ✅ Slime chargé:", podData.mood, podData.sizeName, "Pod", podData.podNumber, "- Cost:", podData.cost or 0)
									end
								end
							end
						end
					end
				end
			end
		end
	end

	print("[SlimeLoad] ✅ Chargement terminé pour", player.Name)
end

-- ============================================
-- 🎮 ÉVÉNEMENTS
-- ============================================
Players.PlayerAdded:Connect(function(player)
	loadPlayerSlimes(player)
end)

print("[SlimeLoadService] ✅ Service chargé (VERSION AVEC COST)")
