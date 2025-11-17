--[[
    PurchaseSlimeHandler.lua
    VERSION FINALE CORRIGÉE - Billboard identique + Sauvegarde
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Services
local DataStoreManager = require(game.ServerScriptService:WaitForChild("DataStoreManager"))

-- Modules
local FormatNumbers = require(ReplicatedStorage.Modules.Shared.FormatNumbers)
local SlimeConfig = require(ReplicatedStorage.Modules.Shared.SlimeConfig)

-- Remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PurchaseSlimeEvent = RemoteEvents:FindFirstChild("PurchaseSlimeEvent")

if not PurchaseSlimeEvent then
	PurchaseSlimeEvent = Instance.new("RemoteEvent")
	PurchaseSlimeEvent.Name = "PurchaseSlimeEvent"
	PurchaseSlimeEvent.Parent = RemoteEvents
end

print("[PurchaseSlime] ✅ Service initialisé")

-- ============================================
-- 🔍 TROUVER LA BASE DU JOUEUR
-- ============================================
local function getPlayerBase(player)
	local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
	if not PlayerInfo then
		warn("[PurchaseSlime] ❌ PlayerInfo introuvable")
		return nil
	end

	local playerFolder = PlayerInfo:FindFirstChild(player.Name)
	if not playerFolder then
		warn("[PurchaseSlime] ❌ Player folder introuvable")
		return nil
	end

	-- ✅ CORRECTION : Utiliser GetAttribute au lieu d'IntValue
	local baseNumber = playerFolder:GetAttribute("BaseNumber")
	if not baseNumber then
		warn("[PurchaseSlime] ❌ BaseNumber attribute introuvable")
		return nil
	end

	print("[PurchaseSlime] 📍 BaseNumber trouvé:", baseNumber)

	local basesFolder = Workspace:FindFirstChild("Base")
	if not basesFolder then
		warn("[PurchaseSlime] ❌ Dossier Base introuvable")
		return nil
	end

	local base = basesFolder:FindFirstChild("Base " .. baseNumber)
	if not base then
		warn("[PurchaseSlime] ❌ Base " .. baseNumber .. " introuvable")
		return nil
	end

	return base
end

-- ============================================
-- 🔍 TROUVER UN POD DISPONIBLE
-- ============================================
local function findAvailablePod(player, base)
	local podsFolder = base:FindFirstChild("PodsSlime")
	if not podsFolder then return nil, nil end

	-- Récupérer tous les pods déjà occupés par ce joueur
	local occupiedPods = {}

	local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
	if PlayerInfo then
		local playerFolder = PlayerInfo:FindFirstChild(player.Name)
		if playerFolder then
			local serverSlimesFolder = playerFolder:FindFirstChild("ServerSlimes")
			if serverSlimesFolder then
				for _, slime in ipairs(serverSlimesFolder:GetChildren()) do
					if slime:IsA("Model") then
						local podNum = slime:GetAttribute("PodNumber")
						if podNum then
							occupiedPods[podNum] = true
						end
					end
				end
			end
		end
	end

	-- ✅ CORRECTION : Afficher les pods occupés sans vim.tbl_keys
	local occupiedList = {}
	for podNum, _ in pairs(occupiedPods) do
		table.insert(occupiedList, tostring(podNum))
	end
	print("[PurchaseSlime] 🔍 Pods occupés:", table.concat(occupiedList, ", "))

	-- Chercher le premier pod libre (1-10)
	for i = 1, 10 do
		if not occupiedPods[i] then
			local podContainer = podsFolder:FindFirstChild("PodsSlime" .. i)
			if podContainer then
				local baseFolder = podContainer:FindFirstChild("Base")
				if baseFolder then
					local spawn = baseFolder:FindFirstChild("Spawn")
					if spawn and spawn:IsA("BasePart") then
						print("[PurchaseSlime] ✅ Pod disponible trouvé:", i)
						return spawn, i
					end
				end
			end
		else
			print("[PurchaseSlime] ⚠️ Pod", i, "déjà occupé")
		end
	end

	warn("[PurchaseSlime] ❌ Aucun pod disponible")
	return nil, nil
end

-- ============================================
-- 🚶 DÉPLACER LE SLIME VERS LE POD
-- ============================================
local function moveSlimeToPod(slimeModel, homeStructure, targetSpawn, podNumber)
	local function yawOnly(cf)
		local pos = cf.Position
		local look = cf.LookVector
		local yaw = math.atan2(-look.X, -look.Z)
		return CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	end

	local function tweenPivot(model, fromCF, toCF, duration)
		local nv = Instance.new("NumberValue")
		nv.Value = 0

		local tween = TweenService:Create(
			nv, 
			TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), 
			{Value = 1}
		)

		nv.Changed:Connect(function(v)
			model:PivotTo(fromCF:Lerp(toCF, v))
		end)

		tween.Completed:Connect(function()
			nv:Destroy()
		end)

		tween:Play()
		tween.Completed:Wait()
	end

	local WALK_SPEED = 12
	local startCF = slimeModel:GetPivot()

	-- Étape 1 : Marcher vers structure home
	local homeCF = CFrame.new(homeStructure.Position.X, startCF.Position.Y, homeStructure.Position.Z)
	local distance1 = (startCF.Position - homeCF.Position).Magnitude
	local duration1 = distance1 / WALK_SPEED

	tweenPivot(slimeModel, yawOnly(startCF), yawOnly(homeCF), duration1)

	-- Étape 2 : Marcher vers le pod (collé au spawn)
	local podCF = CFrame.new(targetSpawn.Position)
	local distance2 = (homeCF.Position - podCF.Position).Magnitude
	local duration2 = distance2 / WALK_SPEED

	tweenPivot(slimeModel, yawOnly(homeCF), yawOnly(podCF), duration2)
end

-- ============================================
-- 📊 CRÉER LE BILLBOARD (IDENTIQUE AU LOCAL)
-- ============================================
local function createBillboard(model, mood, rarity, size, production, cost)
	local moodData = SlimeConfig:GetMoodByName(mood)
	local rarityData = SlimeConfig:GetRarityByName(rarity)
	local sizeData = SlimeConfig:GetSizeByName(size)

	if not moodData or not rarityData or not sizeData then
		warn("[PurchaseSlime] ❌ Impossible de créer le billboard - données manquantes")
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SlimeInfo"
	billboard.Size = UDim2.new(0, 200, 0, 120)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = model

	local container = Instance.new("Frame")
	container.Name = "Container"
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
		return label
	end

	-- ⬇️ FORMAT IDENTIQUE AU LOCAL
	createLabel(moodData.Name .. " " .. sizeData.Name, Color3.new(1, 1, 1), 14)
	createLabel(rarityData.Name, rarityData.Color, 16)
	createLabel("💧 " .. FormatNumbers:Format(production) .. "/s", Color3.fromHex("64C8FF"), 13)
	createLabel("💧 " .. FormatNumbers:Format(cost), Color3.fromHex("FFD700"), 13)

	print("[PurchaseSlime] ✅ Billboard créé (format local)")
end

-- ============================================
-- 🛒 GÉRER L'ACHAT
-- ============================================
PurchaseSlimeEvent.OnServerEvent:Connect(function(player, slimeData)
	print("[PurchaseSlime] 🎯 Demande d'achat de", player.Name)

	if not slimeData or not slimeData.mood or not slimeData.rarity or not slimeData.size or not slimeData.cost or not slimeData.position then
		warn("[PurchaseSlime] ❌ Données invalides")
		return
	end

	print("[PurchaseSlime] 📦 Slime:", slimeData.mood, slimeData.size, slimeData.rarity, "- Coût:", slimeData.cost)

	local currentGelatine = DataStoreManager.GetGelatine(player)

	if currentGelatine < slimeData.cost then
		warn("[PurchaseSlime] ❌ Pas assez de gélatine")
		return
	end

	local base = getPlayerBase(player)
	if not base then
		warn("[PurchaseSlime] ❌ Base introuvable")
		return
	end

	local availableSpawn, podNumber = findAvailablePod(player, base)
	if not availableSpawn then
		warn("[PurchaseSlime] ❌ Aucun pod disponible")
		return
	end

	local success = DataStoreManager.RemoveGelatine(player, slimeData.cost)
	if not success then
		warn("[PurchaseSlime] ❌ Échec retrait gélatine")
		return
	end

	print("[PurchaseSlime] 💸 Gélatine retirée:", slimeData.cost)

	local SlimesFolder = ReplicatedStorage:WaitForChild("Slimes")
	local moodFolder = SlimesFolder:FindFirstChild(slimeData.mood)
	if not moodFolder then
		warn("[PurchaseSlime] ❌ Mood folder introuvable")
		DataStoreManager.AddGelatine(player, slimeData.cost)
		return
	end

	local modelName = slimeData.mood .. " " .. slimeData.size
	local baseModel = moodFolder:FindFirstChild(modelName)
	if not baseModel then
		warn("[PurchaseSlime] ❌ Modèle introuvable:", modelName)
		DataStoreManager.AddGelatine(player, slimeData.cost)
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

	slimeClone:SetAttribute("Mood", slimeData.mood)
	slimeClone:SetAttribute("Rarity", slimeData.rarity)
	slimeClone:SetAttribute("Size", slimeData.size)
	slimeClone:SetAttribute("Production", slimeData.production)
	slimeClone:SetAttribute("Owner", player.Name)
	slimeClone:SetAttribute("PodNumber", podNumber)
	slimeClone:SetAttribute("Cost", slimeData.cost) -- ✅ AJOUTER CETTE LIGNE

	local PlayerInfo = Workspace:FindFirstChild("PlayerInfo")
	if not PlayerInfo then
		warn("[PurchaseSlime] ❌ PlayerInfo introuvable")
		DataStoreManager.AddGelatine(player, slimeData.cost)
		return
	end

	local playerFolder = PlayerInfo:FindFirstChild(player.Name)
	if not playerFolder then
		warn("[PurchaseSlime] ❌ Player folder introuvable")
		DataStoreManager.AddGelatine(player, slimeData.cost)
		return
	end

	local serverSlimesFolder = playerFolder:FindFirstChild("ServerSlimes")
	if not serverSlimesFolder then
		warn("[PurchaseSlime] ❌ ServerSlimes folder introuvable")
		DataStoreManager.AddGelatine(player, slimeData.cost)
		return
	end

        slimeClone.Parent = serverSlimesFolder

        local startCF = CFrame.new(slimeData.position.X, slimeData.position.Y, slimeData.position.Z)
        slimeClone:PivotTo(startCF)

	-- ⬇️ CRÉER LE BILLBOARD IDENTIQUE
	createBillboard(slimeClone, slimeData.mood, slimeData.rarity, slimeData.size, slimeData.production, slimeData.cost)

	print("[PurchaseSlime] ✅ Slime créé à position:", slimeData.position)

	-- ⬇️ SAUVEGARDER DANS DATASTORE
	local baseNumber = tonumber(base.Name:match("%d+"))
	local baseName = "Base " .. baseNumber

	local podData = {
		mood = slimeData.mood,
		sizeName = slimeData.size,
		rarity = slimeData.rarity,
		production = slimeData.production,
		cost = slimeData.cost,
		baseName = baseName,
		podNumber = podNumber,
		placedAt = os.time()
	}

        DataStoreManager.AddPod(player, podData)
        print("[PurchaseSlime] 💾 Pod sauvegardé:", baseName, "Pod", podNumber)

        -- 🚀 Mettre à jour les contrats (achats & pods occupés)
        if _G.UpdateContractProgress then
                _G.UpdateContractProgress(player, "BuySlime", {
                        count = 1,
                        rarity = slimeData.rarity,
                        size = slimeData.size
                })

                _G.UpdateContractProgress(player, "PodsSlimes", {
                        count = #serverSlimesFolder:GetChildren()
                })
        end

        local homeStructure = base:FindFirstChild("structure base home", true)
        if not homeStructure then
                warn("[PurchaseSlime] ❌ Structure home introuvable")
                slimeClone:Destroy()
		DataStoreManager.AddGelatine(player, slimeData.cost)
		return
	end

	print("[PurchaseSlime] 🚶 Début du déplacement...")

	task.spawn(function()
		moveSlimeToPod(slimeClone, homeStructure, availableSpawn, podNumber)
		print("[PurchaseSlime] ✅ Slime placé dans pod", podNumber)
	end)
end)

print("[PurchaseSlimeHandler] ✅ Service chargé (version finale)")
