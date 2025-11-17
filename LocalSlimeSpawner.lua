--[[
    LocalSlimeSpawner.lua
    VERSION FINALE COMPLÈTE - Avec système de spawn rare
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
player.CharacterAdded:Wait()

-- Modules
local SlimeConfig = require(ReplicatedStorage.Modules.Shared.SlimeConfig)
local SlimeCalculator = require(ReplicatedStorage.Modules.Shared.SlimeCalculator)
local FormatNumbers = require(ReplicatedStorage.Modules.Shared.FormatNumbers)

-- Remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local GetRareRarityFunc = RemoteFunctions:WaitForChild("GetCurrentRareRarityFunc")

-- Configuration
local MAX_LOCAL_SLIMES = 10
local SPAWN_INTERVAL = 4.5
local SPAWN_RADIUS = 130
local SPAWN_HEIGHT_ABOVE = 20
local LIFETIME_MIN = 72
local LIFETIME_MAX = 76
local LAND_EPSILON = 0.05
local WANDER_MARGIN = 4
local WANDER_STEP_MIN = 3
local WANDER_STEP_MAX = 6
local WANDER_DUR_MIN = 2.0
local WANDER_DUR_MAX = 3.6
local WANDER_PAUSE_MIN = 0.8
local WANDER_PAUSE_MAX = 1.4

-- Références
local MapCenter = Workspace:WaitForChild("MapCenter")
local DropPlate = Workspace:WaitForChild("DropPlate")
local PlayerInfo = Workspace:WaitForChild("PlayerInfo")
local SlimesFolder = ReplicatedStorage:WaitForChild("Slimes")

-- Pool des slimes
local pool = {}
local spawnZoneIndex = 1

-- ============================================
-- 📐 FONCTIONS DE CALCUL
-- ============================================

local function plateauTopY()
	return DropPlate.Position.Y + DropPlate.Size.Y * 0.5
end

local function getBottomY(model)
	local cf, size = model:GetBoundingBox()
	return cf.Position.Y - size.Y * 0.5
end

local function yawOnly(cf, yaw)
	local pos = cf.Position
	if not yaw then
		local look = cf.LookVector
		yaw = math.atan2(-look.X, -look.Z)
	end
	return CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
end

local function tweenPivot(model, fromCF, toCF, dur, style, dir)
	style = style or Enum.EasingStyle.Quad
	dir = dir or Enum.EasingDirection.Out

	local nv = Instance.new("NumberValue")
	nv.Value = 0

	local tw = TweenService:Create(nv, TweenInfo.new(dur, style, dir), {Value = 1})

	nv.Changed:Connect(function(v)
		model:PivotTo(fromCF:Lerp(toCF, v))
	end)

	tw.Completed:Connect(function()
		nv:Destroy()
	end)

	tw:Play()
	tw.Completed:Wait()
end

local function clampOnPlateauXZ(x, z, margin)
	margin = margin or WANDER_MARGIN

	local localV = DropPlate.CFrame:PointToObjectSpace(Vector3.new(x, DropPlate.Position.Y, z))
	local halfX = DropPlate.Size.X / 2 - margin
	local halfZ = DropPlate.Size.Z / 2 - margin

	localV = Vector3.new(
		math.clamp(localV.X, -halfX, halfX),
		0,
		math.clamp(localV.Z, -halfZ, halfZ)
	)

	local world = DropPlate.CFrame:PointToWorldSpace(localV)
	return world.X, world.Z
end

-- ============================================
-- 🎲 POSITION ALÉATOIRE AVEC DISPERSION UNIFORME
-- ============================================
local function getRandomSpawnPosition()
	local numZones = 8
	local zoneAngle = (math.pi * 2) / numZones

	local baseAngle = (spawnZoneIndex - 1) * zoneAngle
	local angleVariation = (math.random() - 0.5) * zoneAngle * 0.8
	local angle = baseAngle + angleVariation

	local minDistance = SPAWN_RADIUS * 0.3
	local maxDistance = SPAWN_RADIUS * 0.95
	local distance = minDistance + math.random() * (maxDistance - minDistance)

	spawnZoneIndex = (spawnZoneIndex % numZones) + 1

	local x = MapCenter.Position.X + math.cos(angle) * distance
	local y = plateauTopY() + SPAWN_HEIGHT_ABOVE
	local z = MapCenter.Position.Z + math.sin(angle) * distance

	return Vector3.new(x, y, z)
end

-- ============================================
-- 👻 ANCHOR ET NOCOLLIDE
-- ============================================
local function anchorGhost(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		end
	end
end

-- ============================================
-- 🎨 CRÉATION DU BILLBOARD
-- ============================================
local function createBillboard(model, moodData, rarityData, sizeData, production, cost)
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

	createLabel(moodData.Name .. " " .. sizeData.Name, Color3.new(1, 1, 1), 14)
	createLabel(rarityData.Name, rarityData.Color, 16)
	createLabel("💧 " .. FormatNumbers:Format(production) .. "/s", Color3.fromHex("64C8FF"), 13)
	createLabel("💧 " .. FormatNumbers:Format(cost), Color3.fromHex("FFD700"), 13)
end

-- ============================================
-- 🛬 ATTERRISSAGE PROPRE
-- ============================================
local function landClean(model, startPos)
	local initialYaw = math.random() * math.pi * 2
	model:PivotTo(yawOnly(CFrame.new(startPos), initialYaw))

	local currentBottom = getBottomY(model)
	local targetBottomY = plateauTopY() + LAND_EPSILON
	local deltaY = targetBottomY - currentBottom

	local fromCF = model:GetPivot()
	local toCF = yawOnly(
		CFrame.new(fromCF.Position.X, fromCF.Position.Y + deltaY, fromCF.Position.Z),
		initialYaw
	)

	tweenPivot(model, fromCF, toCF, 1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

-- ============================================
-- 🚶 DÉPLACEMENT ALÉATOIRE
-- ============================================
local function startWander(model)
	task.spawn(function()
		while model.Parent do
			local pivot = model:GetPivot()
			local cur = pivot.Position

			local r = WANDER_STEP_MIN + math.random() * (WANDER_STEP_MAX - WANDER_STEP_MIN)
			local a = math.random() * math.pi * 2

			local rawX = cur.X + r * math.cos(a)
			local rawZ = cur.Z + r * math.sin(a)

			local cx, cz = clampOnPlateauXZ(rawX, rawZ, WANDER_MARGIN)
			local goal = Vector3.new(cx, cur.Y, cz)

			local dist = (goal - cur).Magnitude
			local dur = math.clamp(dist / 3.5, WANDER_DUR_MIN, WANDER_DUR_MAX)

			local fromCF = yawOnly(pivot)
			local dir = goal - cur
			local yaw = math.atan2(-dir.X, -dir.Z)
			local toCF = yawOnly(CFrame.new(goal), yaw)

			tweenPivot(model, fromCF, toCF, dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

			task.wait(WANDER_PAUSE_MIN + math.random() * (WANDER_PAUSE_MAX - WANDER_PAUSE_MIN))
		end
	end)
end

-- ============================================
-- 🗑️ GESTION DU POOL
-- ============================================
local function destroyEntry(e)
	if not e then return end
	if e.model and e.model.Parent then
		e.model:Destroy()
	end
end

local function trimPool()
	while #pool > MAX_LOCAL_SLIMES do
		local first = table.remove(pool, 1)
		destroyEntry(first)
	end
end

task.spawn(function()
	while true do
		local now = os.clock()
		for i = #pool, 1, -1 do
			local e = pool[i]
			if not e.model or not e.model.Parent or (e.dieAt and now >= e.dieAt) then
				destroyEntry(e)
				table.remove(pool, i)
			end
		end
		task.wait(0.25)
	end
end)

local function getLocalSlimesFolder()
	local playerFolder = PlayerInfo:FindFirstChild(player.Name)
	if playerFolder then
		return playerFolder:FindFirstChild("LocalSlimes")
	end
	return nil
end

-- ============================================
-- 🌟 SPAWN UN SLIME LOCAL
-- ============================================
local function spawnLocalSlime()
	local localSlimesFolder = getLocalSlimesFolder()
	if not localSlimesFolder then return end

	local moodData = SlimeConfig:GetRandomMood()
	local rarityData = SlimeConfig:GetRandomRarity()
	local sizeData = SlimeConfig:GetRandomSize()

	local success, rareRarityData = pcall(function()
		return GetRareRarityFunc:InvokeServer()
	end)

	if success and rareRarityData then
		rarityData = rareRarityData
	end

	local production = SlimeCalculator:CalculateProduction(moodData.Name, rarityData.Name, sizeData.Name, "Aucun")
	local cost = SlimeCalculator:CalculateCost(production, moodData.Name, rarityData.Name, sizeData.Name, "Aucun")

	local moodFolder = SlimesFolder:FindFirstChild(moodData.Name)
	if not moodFolder then return end

	local modelName = moodData.Name .. " " .. sizeData.Name
	local base = moodFolder:FindFirstChild(modelName)
	if not base then return end

	local clone = base:Clone()
	clone.Name = "LocalSlime_" .. tick()

	local startPos = getRandomSpawnPosition()

	anchorGhost(clone)
	clone.Parent = localSlimesFolder

	landClean(clone, startPos)
	createBillboard(clone, moodData, rarityData, sizeData, production, cost)

	local primaryPart = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
	if primaryPart then
		-- Créer ProximityPrompt
		local proximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.ActionText = "Acheter"
		proximityPrompt.ObjectText = rarityData.Name .. " - " .. FormatNumbers:Format(cost) .. " 💧"
		proximityPrompt.MaxActivationDistance = 8
		proximityPrompt.HoldDuration = 0.5
		proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
		proximityPrompt.RequiresLineOfSight = false
		proximityPrompt.Style = Enum.ProximityPromptStyle.Default
		proximityPrompt.Parent = primaryPart
	end

	clone:SetAttribute("Mood", moodData.Name)
	clone:SetAttribute("Rarity", rarityData.Name)
	clone:SetAttribute("Size", sizeData.Name)
	clone:SetAttribute("Production", production)
	clone:SetAttribute("Cost", cost)

	startWander(clone)

	local life = LIFETIME_MIN + math.random() * (LIFETIME_MAX - LIFETIME_MIN)
	table.insert(pool, {model = clone, dieAt = os.clock() + life})
	trimPool()
end

-- ============================================
-- 🔄 BOUCLE DE SPAWN
-- ============================================
local function startSpawnLoop()
	local attempts = 0
	while not getLocalSlimesFolder() and attempts < 50 do
		task.wait(0.1)
		attempts = attempts + 1
	end

	if not getLocalSlimesFolder() then
		return
	end

	spawnLocalSlime()

	while true do
		task.wait(SPAWN_INTERVAL)
		spawnLocalSlime()
	end
end

-- ============================================
-- 🎮 INITIALISATION
-- ============================================
task.wait(1)
task.spawn(startSpawnLoop)
