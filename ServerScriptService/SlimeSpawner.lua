-- ========================================
-- SLIME RUSH - SLIME SPAWNER (Serveur)
-- Script (Serveur)
-- Localisation: ServerScriptService/SlimeSpawner
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SlimeConfig = require(ReplicatedStorage.Modules.SlimeConfig)
local DataManager = require(ReplicatedStorage.Modules.DataManager)

local SlimeSpawner = {}

-- ========================================
-- DOSSIER SLIMES MODELS
-- ========================================
local SLIMES_FOLDER = ReplicatedStorage:WaitForChild("Slimes")

-- ========================================
-- CRÉER SLIME SERVEUR
-- ========================================

function SlimeSpawner.CreateServerSlime(player, slimeData, targetPod, podIndex)
    local mood = SlimeConfig.Moods[slimeData.Mood]
    local rarity = SlimeConfig.Rarities[slimeData.Rarity]
    local size = SlimeConfig.Sizes[slimeData.Size]
    local state = SlimeConfig.States[slimeData.State]

    -- Trouver model correspondant
    local slimeModel = SlimeSpawner.GetSlimeModel(slimeData.Mood, slimeData.Size)
    if not slimeModel then
        warn("[SlimeSpawner] Model non trouvé:", mood.Name, size.Name)
        return nil
    end

    -- Cloner slime
    local slimeClone = slimeModel:Clone()
    slimeClone.Name = string.format("Slime_%s_%s_%s", mood.Name, rarity.Name, size.Name)

    -- Appliquer couleur rareté
    SlimeSpawner.ApplyRarityColor(slimeClone, rarity.Color)

    -- Positionner sur pod
    local podPosition = targetPod:GetPivot().Position
    slimeClone:PivotTo(CFrame.new(podPosition + Vector3.new(0, 2, 0)))

    -- Créer BillboardGui
    SlimeSpawner.CreateBillboard(slimeClone, slimeData)

    -- Créer ProximityPrompt pour collecter
    SlimeSpawner.CreateProximityPrompt(slimeClone, player, podIndex)

    -- Stocker données dans slime
    local dataValue = Instance.new("Folder")
    dataValue.Name = "SlimeData"
    dataValue.Parent = slimeClone

    local moodValue = Instance.new("IntValue")
    moodValue.Name = "Mood"
    moodValue.Value = slimeData.Mood
    moodValue.Parent = dataValue

    local rarityValue = Instance.new("IntValue")
    rarityValue.Name = "Rarity"
    rarityValue.Value = slimeData.Rarity
    rarityValue.Parent = dataValue

    local sizeValue = Instance.new("IntValue")
    sizeValue.Name = "Size"
    sizeValue.Value = slimeData.Size
    sizeValue.Parent = dataValue

    local stateValue = Instance.new("IntValue")
    stateValue.Name = "State"
    stateValue.Value = slimeData.State
    stateValue.Parent = dataValue

    local uniqueIDValue = Instance.new("StringValue")
    uniqueIDValue.Name = "UniqueID"
    uniqueIDValue.Value = slimeData.UniqueID
    uniqueIDValue.Parent = dataValue

    local ownerValue = Instance.new("ObjectValue")
    ownerValue.Name = "Owner"
    ownerValue.Value = player
    ownerValue.Parent = dataValue

    local podIndexValue = Instance.new("IntValue")
    podIndexValue.Name = "PodIndex"
    podIndexValue.Value = podIndex
    podIndexValue.Parent = dataValue

    -- Parent final
    slimeClone.Parent = targetPod

    return slimeClone
end

-- ========================================
-- OBTENIR MODEL SLIME
-- ========================================

function SlimeSpawner.GetSlimeModel(moodIndex, sizeIndex)
    local moodName = SlimeConfig.Moods[moodIndex].Name
    local sizeName = SlimeConfig.Sizes[sizeIndex].Name

    -- Structure: Slimes/[Mood]/[Size]/Model
    local moodFolder = SLIMES_FOLDER:FindFirstChild(moodName)
    if not moodFolder then return nil end

    local sizeFolder = moodFolder:FindFirstChild(sizeName)
    if not sizeFolder then return nil end

    -- Retourner premier model trouvé
    return sizeFolder:FindFirstChildWhichIsA("Model")
end

-- ========================================
-- APPLIQUER COULEUR RARETÉ
-- ========================================

function SlimeSpawner.ApplyRarityColor(slimeModel, color)
    for _, part in ipairs(slimeModel:GetDescendants()) do
        if part:IsA("BasePart") and not part:FindFirstChild("NoColorChange") then
            part.Color = color
        end
    end
end

-- ========================================
-- CRÉER BILLBOARD
-- ========================================

function SlimeSpawner.CreateBillboard(slimeModel, slimeData)
    local mood = SlimeConfig.Moods[slimeData.Mood]
    local rarity = SlimeConfig.Rarities[slimeData.Rarity]
    local size = SlimeConfig.Sizes[slimeData.Size]
    local state = SlimeConfig.States[slimeData.State]

    local production = SlimeConfig.GetProduction(slimeData.Size, slimeData.Rarity)

    -- Créer BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SlimeBillboard"
    billboard.Size = UDim2.new(0, 200, 0, 150)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.MaxDistance = 50
    billboard.AlwaysOnTop = true
    billboard.Parent = slimeModel:FindFirstChild("HumanoidRootPart") or slimeModel.PrimaryPart

    -- Frame principal
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = rarity.Color
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Mood + Size
    local moodLabel = Instance.new("TextLabel")
    moodLabel.Size = UDim2.new(1, 0, 0.2, 0)
    moodLabel.Position = UDim2.new(0, 0, 0.05, 0)
    moodLabel.BackgroundTransparency = 1
    moodLabel.Text = string.format("%s %s", mood.Icon, mood.Name)
    moodLabel.TextColor3 = mood.Color
    moodLabel.TextScaled = true
    moodLabel.Font = Enum.Font.GothamBold
    moodLabel.Parent = frame

    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Size = UDim2.new(1, 0, 0.15, 0)
    sizeLabel.Position = UDim2.new(0, 0, 0.25, 0)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Text = size.Name
    sizeLabel.TextColor3 = Color3.new(1, 1, 1)
    sizeLabel.TextScaled = true
    sizeLabel.Font = Enum.Font.Gotham
    sizeLabel.Parent = frame

    -- Rareté
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, 0, 0.15, 0)
    rarityLabel.Position = UDim2.new(0, 0, 0.42, 0)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = rarity.Name
    rarityLabel.TextColor3 = rarity.Color
    rarityLabel.TextScaled = true
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.Parent = frame

    -- État (si présent)
    if slimeData.State > 1 then
        local stateLabel = Instance.new("TextLabel")
        stateLabel.Size = UDim2.new(1, 0, 0.15, 0)
        stateLabel.Position = UDim2.new(0, 0, 0.58, 0)
        stateLabel.BackgroundTransparency = 1
        stateLabel.Text = string.format("%s %s", state.Icon, state.Name)
        stateLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        stateLabel.TextScaled = true
        stateLabel.Font = Enum.Font.GothamBold
        stateLabel.Parent = frame
    end

    -- Production
    local productionLabel = Instance.new("TextLabel")
    productionLabel.Size = UDim2.new(1, 0, 0.15, 0)
    productionLabel.Position = UDim2.new(0, 0, 0.75, 0)
    productionLabel.BackgroundTransparency = 1
    productionLabel.Text = string.format("💧 %d/s", production)
    productionLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    productionLabel.TextScaled = true
    productionLabel.Font = Enum.Font.GothamBold
    productionLabel.Parent = frame
end

-- ========================================
-- CRÉER PROXIMITY PROMPT
-- ========================================

function SlimeSpawner.CreateProximityPrompt(slimeModel, owner, podIndex)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CollectPrompt"
    prompt.ActionText = "Récupérer"
    prompt.ObjectText = "Gélatine"
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = false
    prompt.Parent = slimeModel:FindFirstChild("HumanoidRootPart") or slimeModel.PrimaryPart

    -- Événement trigger (géré par ProductionManager)
    prompt.Triggered:Connect(function(playerWhoTriggered)
        if playerWhoTriggered == owner then
            local ProductionManager = require(script.Parent.ProductionManager)
            ProductionManager.CollectFromPod(owner, podIndex)
        end
    end)
end

-- ========================================
-- SUPPRIMER SLIME SERVEUR
-- ========================================

function SlimeSpawner.RemoveServerSlime(slimeModel)
    if slimeModel and slimeModel:IsA("Model") then
        slimeModel:Destroy()
    end
end

return SlimeSpawner
