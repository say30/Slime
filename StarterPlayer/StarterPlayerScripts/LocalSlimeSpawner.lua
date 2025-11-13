-- ========================================
-- SLIME RUSH - LOCAL SLIME SPAWNER (Client)
-- LocalScript
-- Localisation: StarterPlayer/StarterPlayerScripts/LocalSlimeSpawner
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local SlimeConfig = require(ReplicatedStorage.Modules.SlimeConfig)
local EconomyConfig = require(ReplicatedStorage.Modules.EconomyConfig)

-- ========================================
-- CONFIGURATION
-- ========================================
local MAP_CENTER = Workspace:WaitForChild("MapCenter")
local DROP_PLATE = Workspace:WaitForChild("DropPlate")
local LOCAL_SLIMES_FOLDER = Workspace:WaitForChild("LocalSlimes")
local SLIMES_MODELS = ReplicatedStorage:WaitForChild("Slimes")

local SPAWN_INTERVAL = SlimeConfig.SpawnSettings.SpawnInterval
local MAX_SLIMES = SlimeConfig.SpawnSettings.MaxSlimesOnPlate
local SPAWN_RADIUS = SlimeConfig.SpawnSettings.SpawnRadius
local DROP_HEIGHT = SlimeConfig.SpawnSettings.DropHeight
local FALL_DURATION = 3 -- Durée descente (secondes)

-- Dossier local joueur
local playerSlimesFolder = LOCAL_SLIMES_FOLDER:FindFirstChild(player.Name)
if not playerSlimesFolder then
    playerSlimesFolder = Instance.new("Folder")
    playerSlimesFolder.Name = player.Name
    playerSlimesFolder.Parent = LOCAL_SLIMES_FOLDER
end

-- ========================================
-- SPAWN LOCAL SLIME
-- ========================================

local function SpawnLocalSlime()
    -- Vérifier limite
    if #playerSlimesFolder:GetChildren() >= MAX_SLIMES then
        return
    end

    -- Générer slime aléatoire
    local slimeData = SlimeConfig.GenerateRandomSlime()

    -- Obtenir model
    local slimeModel = GetSlimeModel(slimeData.Mood, slimeData.Size)
    if not slimeModel then
        warn("[LocalSlimeSpawner] Model non trouvé")
        return
    end

    -- Cloner
    local slimeClone = slimeModel:Clone()
    slimeClone.Name = "LocalSlime_" .. slimeData.UniqueID

    -- Position spawn (au-dessus de MapCenter, rayon aléatoire)
    local angle = math.random() * math.pi * 2
    local distance = math.random() * SPAWN_RADIUS
    local spawnPos = MAP_CENTER.Position + Vector3.new(
        math.cos(angle) * distance,
        DROP_HEIGHT,
        math.sin(angle) * distance
    )

    slimeClone:PivotTo(CFrame.new(spawnPos))

    -- Appliquer couleur rareté
    ApplyRarityColor(slimeClone, SlimeConfig.Rarities[slimeData.Rarity].Color)

    -- Créer billboard
    CreateLocalBillboard(slimeClone, slimeData)

    -- Créer ClickDetector pour achat
    CreateClickDetector(slimeClone, slimeData)

    -- Stocker données
    local dataFolder = Instance.new("Folder")
    dataFolder.Name = "SlimeData"
    dataFolder.Parent = slimeClone

    local moodValue = Instance.new("IntValue")
    moodValue.Name = "Mood"
    moodValue.Value = slimeData.Mood
    moodValue.Parent = dataFolder

    local rarityValue = Instance.new("IntValue")
    rarityValue.Name = "Rarity"
    rarityValue.Value = slimeData.Rarity
    rarityValue.Parent = dataFolder

    local sizeValue = Instance.new("IntValue")
    sizeValue.Name = "Size"
    sizeValue.Value = slimeData.Size
    sizeValue.Parent = dataFolder

    local stateValue = Instance.new("IntValue")
    stateValue.Name = "State"
    stateValue.Value = slimeData.State
    stateValue.Parent = dataFolder

    local uniqueIDValue = Instance.new("StringValue")
    uniqueIDValue.Name = "UniqueID"
    uniqueIDValue.Value = slimeData.UniqueID
    uniqueIDValue.Parent = dataFolder

    slimeClone.Parent = playerSlimesFolder

    -- Animation descente vers DropPlate
    AnimateSlimeDescend(slimeClone)

    print("[LocalSlimeSpawner] ✅ Slime local spawné:", slimeData.Mood, slimeData.Rarity, slimeData.Size)
end

-- ========================================
-- OBTENIR MODEL SLIME
-- ========================================

function GetSlimeModel(moodIndex, sizeIndex)
    local moodName = SlimeConfig.Moods[moodIndex].Name
    local sizeName = SlimeConfig.Sizes[sizeIndex].Name

    local moodFolder = SLIMES_MODELS:FindFirstChild(moodName)
    if not moodFolder then return nil end

    local sizeFolder = moodFolder:FindFirstChild(sizeName)
    if not sizeFolder then return nil end

    return sizeFolder:FindFirstChildWhichIsA("Model")
end

-- ========================================
-- APPLIQUER COULEUR RARETÉ
-- ========================================

function ApplyRarityColor(slimeModel, color)
    for _, part in ipairs(slimeModel:GetDescendants()) do
        if part:IsA("BasePart") and not part:FindFirstChild("NoColorChange") then
            part.Color = color
        end
    end
end

-- ========================================
-- CRÉER BILLBOARD LOCAL
-- ========================================

function CreateLocalBillboard(slimeModel, slimeData)
    local mood = SlimeConfig.Moods[slimeData.Mood]
    local rarity = SlimeConfig.Rarities[slimeData.Rarity]
    local size = SlimeConfig.Sizes[slimeData.Size]

    local production = SlimeConfig.GetProduction(slimeData.Size, slimeData.Rarity)
    local cost = SlimeConfig.GetCost(slimeData.Size, slimeData.Rarity)

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SlimeBillboard"
    billboard.Size = UDim2.new(0, 200, 0, 180)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.MaxDistance = 50
    billboard.AlwaysOnTop = true
    billboard.Parent = slimeModel:FindFirstChild("HumanoidRootPart") or slimeModel.PrimaryPart

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = rarity.Color
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Mood
    local moodLabel = Instance.new("TextLabel")
    moodLabel.Size = UDim2.new(1, 0, 0.18, 0)
    moodLabel.Position = UDim2.new(0, 0, 0.02, 0)
    moodLabel.BackgroundTransparency = 1
    moodLabel.Text = string.format("%s %s", mood.Icon, mood.Name)
    moodLabel.TextColor3 = mood.Color
    moodLabel.TextScaled = true
    moodLabel.Font = Enum.Font.GothamBold
    moodLabel.Parent = frame

    -- Taille
    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Size = UDim2.new(1, 0, 0.15, 0)
    sizeLabel.Position = UDim2.new(0, 0, 0.22, 0)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Text = size.Name
    sizeLabel.TextColor3 = Color3.new(1, 1, 1)
    sizeLabel.TextScaled = true
    sizeLabel.Font = Enum.Font.Gotham
    sizeLabel.Parent = frame

    -- Rareté
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, 0, 0.15, 0)
    rarityLabel.Position = UDim2.new(0, 0, 0.38, 0)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = rarity.Name
    rarityLabel.TextColor3 = rarity.Color
    rarityLabel.TextScaled = true
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.Parent = frame

    -- Production
    local productionLabel = Instance.new("TextLabel")
    productionLabel.Size = UDim2.new(1, 0, 0.15, 0)
    productionLabel.Position = UDim2.new(0, 0, 0.55, 0)
    productionLabel.BackgroundTransparency = 1
    productionLabel.Text = string.format("💧 %d/s", production)
    productionLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    productionLabel.TextScaled = true
    productionLabel.Font = Enum.Font.GothamBold
    productionLabel.Parent = frame

    -- Coût
    local costLabel = Instance.new("TextLabel")
    costLabel.Size = UDim2.new(1, 0, 0.15, 0)
    costLabel.Position = UDim2.new(0, 0, 0.72, 0)
    costLabel.BackgroundTransparency = 1
    costLabel.Text = string.format("💰 %s", EconomyConfig.FormatNumber(cost))
    costLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    costLabel.TextScaled = true
    costLabel.Font = Enum.Font.GothamBold
    costLabel.Parent = frame
end

-- ========================================
-- CRÉER CLICK DETECTOR
-- ========================================

function CreateClickDetector(slimeModel, slimeData)
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 15
    clickDetector.Parent = slimeModel:FindFirstChild("HumanoidRootPart") or slimeModel.PrimaryPart

    clickDetector.MouseClick:Connect(function()
        -- Envoyer demande achat au serveur
        ReplicatedStorage.RemoteEvents.PurchaseSlime:FireServer(slimeData)
    end)
end

-- ========================================
-- ANIMER DESCENTE
-- ========================================

function AnimateSlimeDescend(slimeModel)
    local dropPosition = DROP_PLATE.Position + Vector3.new(
        (math.random() - 0.5) * 10,
        DROP_PLATE.Size.Y / 2 + 2,
        (math.random() - 0.5) * 10
    )

    local tween = TweenService:Create(slimeModel.PrimaryPart, TweenInfo.new(FALL_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        CFrame = CFrame.new(dropPosition)
    })

    tween:Play()
end

-- ========================================
-- BOUCLE SPAWN
-- ========================================

spawn(function()
    while task.wait(SPAWN_INTERVAL) do
        SpawnLocalSlime()
    end
end)

-- ========================================
-- ÉVÉNEMENT ACHAT RÉUSSI
-- ========================================

ReplicatedStorage.RemoteEvents.PurchaseSlime.OnClientEvent:Connect(function(success, message, podIndex)
    if success then
        print("[LocalSlimeSpawner] ✅ Achat réussi!")
        -- TODO: Afficher notification
    else
        warn("[LocalSlimeSpawner] ❌ Achat échoué:", message)
    end
end)

print("[LocalSlimeSpawner] ✅ Système de spawn local initialisé")
