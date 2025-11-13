# 🔧 SCRIPTS CORRIGÉS - Copier-Coller dans Studio

## ⚠️ IMPORTANT : Remplacer TOUS les scripts dans ServerScriptService par ces versions

---

## 1. BaseManager (Script)

```lua
-- ServerScriptService/BaseManager

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreManager = require(script.Parent.DataStoreManager)
local EconomyConfig = require(ReplicatedStorage.Modules.EconomyConfig)

local BaseManager = {}

local BASE_FOLDER = Workspace:WaitForChild("Base")
local TOTAL_BASES = 8
local BasesAssignments = {}
local PlayerBases = {}

function BaseManager.AssignBaseToPlayer(player)
    if PlayerBases[player.UserId] then
        return PlayerBases[player.UserId]
    end

    for i = 1, TOTAL_BASES do
        if not BasesAssignments[i] then
            BasesAssignments[i] = player
            PlayerBases[player.UserId] = i
            print(string.format("[BaseManager] ✅ %s assigné Base %d", player.Name, i))
            BaseManager.UpdateBasePanneau(i, player)
            BaseManager.InitializeBaseProduction(i, player)
            return i
        end
    end

    warn(string.format("[BaseManager] ⚠️ Aucune base pour %s", player.Name))
    return nil
end

function BaseManager.ReleaseBase(player)
    local baseIndex = PlayerBases[player.UserId]
    if baseIndex then
        BasesAssignments[baseIndex] = nil
        PlayerBases[player.UserId] = nil
        print(string.format("[BaseManager] 🔓 Base %d libérée", baseIndex))
        BaseManager.ClearBasePanneau(baseIndex)
        BaseManager.ClearBaseSlimes(baseIndex)
    end
end

function BaseManager.UpdateBasePanneau(baseIndex, player)
    local base = BASE_FOLDER:FindFirstChild("Base " .. baseIndex)
    if not base then return end

    local panneau = base:FindFirstChild("Panneau")
    if not panneau then return end

    local titleLabel = panneau:FindFirstChild("Part")
    if titleLabel and titleLabel:FindFirstChild("SurfaceGui") then
        local mainFrame = titleLabel.SurfaceGui:FindFirstChild("MainFrame")
        if mainFrame and mainFrame:FindFirstChild("TitleLabel") then
            mainFrame.TitleLabel.Text = string.format("Base de %s", player.Name)
        end
    end
end

function BaseManager.ClearBasePanneau(baseIndex)
    local base = BASE_FOLDER:FindFirstChild("Base " .. baseIndex)
    if not base then return end

    local panneau = base:FindFirstChild("Panneau")
    if not panneau then return end

    local titleLabel = panneau:FindFirstChild("Part")
    if titleLabel and titleLabel:FindFirstChild("SurfaceGui") then
        local mainFrame = titleLabel.SurfaceGui:FindFirstChild("MainFrame")
        if mainFrame and mainFrame:FindFirstChild("TitleLabel") then
            mainFrame.TitleLabel.Text = "Base Libre"
        end
        if mainFrame and mainFrame:FindFirstChild("LikeContainer") then
            local likeCount = mainFrame.LikeContainer:FindFirstChild("LikeCount")
            if likeCount then
                likeCount.Text = "0"
            end
        end
    end
end

function BaseManager.InitializeBaseProduction(baseIndex, player)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    local playerBasesFolder = Workspace:FindFirstChild("PlayerBases")
    if not playerBasesFolder then
        playerBasesFolder = Instance.new("Folder")
        playerBasesFolder.Name = "PlayerBases"
        playerBasesFolder.Parent = Workspace
    end

    local playerFolder = playerBasesFolder:FindFirstChild("Player_" .. player.UserId)
    if not playerFolder then
        playerFolder = Instance.new("Folder")
        playerFolder.Name = "Player_" .. player.UserId
        playerFolder.Parent = playerBasesFolder
    end

    BaseManager.LoadPlacedSlimes(baseIndex, player)
end

function BaseManager.LoadPlacedSlimes(baseIndex, player)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData or not playerData.PlacedSlimes then return end

    local base = BASE_FOLDER:FindFirstChild("Base " .. baseIndex)
    if not base then return end

    local podsSlimeFolder = base:FindFirstChild("PodsSlime")
    if not podsSlimeFolder then return end

    for podIndex, slimeData in pairs(playerData.PlacedSlimes) do
        local pod = podsSlimeFolder:FindFirstChild("PodsSlime" .. podIndex)
        if pod then
            local SlimeSpawner = require(script.Parent.SlimeSpawner)
            SlimeSpawner.CreateServerSlime(player, slimeData, pod, podIndex)
        end
    end

    print(string.format("[BaseManager] ✅ Slimes chargés pour %s", player.Name))
end

function BaseManager.ClearBaseSlimes(baseIndex)
    local base = BASE_FOLDER:FindFirstChild("Base " .. baseIndex)
    if not base then return end

    local podsSlimeFolder = base:FindFirstChild("PodsSlime")
    if not podsSlimeFolder then return end

    for _, pod in ipairs(podsSlimeFolder:GetChildren()) do
        for _, child in ipairs(pod:GetChildren()) do
            if child:IsA("Model") and child.Name:find("Slime") then
                child:Destroy()
            end
        end
    end
end

function BaseManager.GetPlayerBase(player)
    return PlayerBases[player.UserId]
end

function BaseManager.GetBaseOwner(baseIndex)
    return BasesAssignments[baseIndex]
end

function BaseManager.GetAvailablePod(player)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return nil end

    local unlockedPods = EconomyConfig.GetUnlockedPods(playerData.BaseLevel)

    for i = 1, unlockedPods do
        if not playerData.PlacedSlimes[i] then
            return i
        end
    end

    return nil
end

Players.PlayerRemoving:Connect(function(player)
    BaseManager.ReleaseBase(player)
end)

return BaseManager
```

---

## 2. ProductionManager (Script)

```lua
-- ServerScriptService/ProductionManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SlimeConfig = require(ReplicatedStorage.Modules.SlimeConfig)
local EconomyConfig = require(ReplicatedStorage.Modules.EconomyConfig)
local DataManager = require(ReplicatedStorage.Modules.DataManager)
local DataStoreManager = require(script.Parent.DataStoreManager)

local ProductionManager = {}

local UPDATE_INTERVAL = 1
local ProductionLoops = {}

function ProductionManager.StartProduction(player)
    if ProductionLoops[player.UserId] then return end

    print(string.format("[Production] ▶️ Démarrage pour %s", player.Name))
    ProductionLoops[player.UserId] = true

    spawn(function()
        while ProductionLoops[player.UserId] and player:IsDescendantOf(Players) do
            wait(UPDATE_INTERVAL)

            local playerData = DataStoreManager.GetPlayerData(player)
            if not playerData then continue end

            for podIndex, slimeData in pairs(playerData.PlacedSlimes) do
                local production = SlimeConfig.GetProduction(slimeData.Size, slimeData.Rarity)

                local productionBonus = EconomyConfig.GetProductionBonus(playerData.ProductionUpgradeLevel)
                production = production * (1 + productionBonus)

                local rebirthMultiplier = EconomyConfig.GetRebirthMultiplier(playerData.RebirthLevel)
                production = production * rebirthMultiplier

                local hasProductionBoost, _ = DataManager.HasActiveBoost(playerData, "Production")
                if hasProductionBoost then
                    for _, boost in ipairs(playerData.ActiveBoosts) do
                        if boost.Type:find("Production") and boost.EndTime > tick() then
                            if boost.Type:find("100") then
                                production = production * 2
                            elseif boost.Type:find("200") then
                                production = production * 3
                            elseif boost.Type:find("50") then
                                production = production * 1.5
                            end
                            break
                        end
                    end
                end

                playerData.AccumulatedProduction[podIndex] = (playerData.AccumulatedProduction[podIndex] or 0) + production
            end

            DataStoreManager.UpdatePlayerData(player, playerData)
            ProductionManager.UpdateProductionDisplay(player)
        end
    end)
end

function ProductionManager.StopProduction(player)
    ProductionLoops[player.UserId] = nil
    print(string.format("[Production] ⏸️ Arrêt pour %s", player.Name))
end

function ProductionManager.CalculateTotalProduction(playerData)
    local total = 0

    for _, slimeData in pairs(playerData.PlacedSlimes) do
        local production = SlimeConfig.GetProduction(slimeData.Size, slimeData.Rarity)
        local productionBonus = EconomyConfig.GetProductionBonus(playerData.ProductionUpgradeLevel)
        production = production * (1 + productionBonus)
        local rebirthMultiplier = EconomyConfig.GetRebirthMultiplier(playerData.RebirthLevel)
        production = production * rebirthMultiplier
        total = total + production
    end

    return total
end

function ProductionManager.CollectFromPod(player, podIndex)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return false end

    local accumulated = playerData.AccumulatedProduction[podIndex]
    if not accumulated or accumulated <= 0 then return false end

    playerData.Gelatin = playerData.Gelatin + accumulated
    playerData.GelatinLifetime = playerData.GelatinLifetime + accumulated
    playerData.AccumulatedProduction[podIndex] = 0

    DataStoreManager.UpdatePlayerData(player, playerData)

    print(string.format("[Production] 💧 %s collecté %.0f", player.Name, accumulated))

    local ContractManager = require(script.Parent.ContractManager)
    ContractManager.UpdateProgress(player, "Collect", accumulated)

    return true
end

function ProductionManager.CollectAll(player)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return 0 end

    local totalCollected = 0

    for podIndex, accumulated in pairs(playerData.AccumulatedProduction) do
        if accumulated > 0 then
            totalCollected = totalCollected + accumulated
            playerData.AccumulatedProduction[podIndex] = 0
        end
    end

    if totalCollected > 0 then
        playerData.Gelatin = playerData.Gelatin + totalCollected
        playerData.GelatinLifetime = playerData.GelatinLifetime + totalCollected
        DataStoreManager.UpdatePlayerData(player, playerData)

        print(string.format("[Production] 💧 %s collecté %.0f (TOTAL)", player.Name, totalCollected))

        local ContractManager = require(script.Parent.ContractManager)
        ContractManager.UpdateProgress(player, "Collect", totalCollected)
    end

    return totalCollected
end

function ProductionManager.UpdateProductionDisplay(player)
    local playerData = DataStoreManager.GetPlayerData(player)
    if not playerData then return end

    local BaseManager = require(script.Parent.BaseManager)
    local baseIndex = BaseManager.GetPlayerBase(player)
    if not baseIndex then return end

    local base = workspace.Base:FindFirstChild("Base " .. baseIndex)
    if not base then return end

    local recolte = base:FindFirstChild("Recolte")
    if not recolte then return end

    local totalAccumulated = 0
    for _, amount in pairs(playerData.AccumulatedProduction) do
        totalAccumulated = totalAccumulated + amount
    end

    local collectLabel = recolte.Main.CollectorGui:FindFirstChild("SR_CollectLabel")
    if collectLabel then
        collectLabel.Text = EconomyConfig.FormatNumber(totalAccumulated)
    end

    local productionRate = ProductionManager.CalculateTotalProduction(playerData)
    local rateLabel = recolte.Main.CollectorGui:FindFirstChild("SR_RateLabel")
    if rateLabel then
        rateLabel.Text = string.format("%s/s", EconomyConfig.FormatNumber(productionRate))
    end
end

function ProductionManager.SetupCollectionHitbox(player, baseIndex)
    local base = workspace.Base:FindFirstChild("Base " .. baseIndex)
    if not base then return end

    local recolte = base:FindFirstChild("Recolte")
    if not recolte then return end

    local hitbox = recolte:FindFirstChild("Hitbox")
    if not hitbox then return end

    hitbox.Touched:Connect(function(hit)
        local character = hit.Parent
        if character and character:FindFirstChild("Humanoid") then
            local touchedPlayer = Players:GetPlayerFromCharacter(character)
            if touchedPlayer == player then
                ProductionManager.CollectAll(player)
            end
        end
    end)
end

Players.PlayerRemoving:Connect(function(player)
    ProductionManager.StopProduction(player)
end)

return ProductionManager
```

---

## 3. FusionHandler, ContractManager, ShopManager, RebirthHandler (Scripts)

**Ces scripts sont déjà corrects car ils chargent depuis `ReplicatedStorage.Modules.*`**

Vérifiez juste que les lignes de `require` ressemblent à :
```lua
local FusionConfig = require(ReplicatedStorage.Modules.FusionConfig)
local DataManager = require(ReplicatedStorage.Modules.DataManager)
local DataStoreManager = require(script.Parent.DataStoreManager)
```

---

## 4. SlimeSpawner (Script)

```lua
-- ServerScriptService/SlimeSpawner

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SlimeConfig = require(ReplicatedStorage.Modules.SlimeConfig)
local DataManager = require(ReplicatedStorage.Modules.DataManager)

local SlimeSpawner = {}

local SLIMES_FOLDER = ReplicatedStorage:WaitForChild("Slimes")

function SlimeSpawner.CreateServerSlime(player, slimeData, targetPod, podIndex)
    local mood = SlimeConfig.Moods[slimeData.Mood]
    local rarity = SlimeConfig.Rarities[slimeData.Rarity]
    local size = SlimeConfig.Sizes[slimeData.Size]
    local state = SlimeConfig.States[slimeData.State]

    local slimeModel = SlimeSpawner.GetSlimeModel(slimeData.Mood, slimeData.Size)
    if not slimeModel then
        warn("[SlimeSpawner] Model non trouvé:", mood.Name, size.Name)
        return nil
    end

    local slimeClone = slimeModel:Clone()
    slimeClone.Name = string.format("Slime_%s_%s_%s", mood.Name, rarity.Name, size.Name)

    SlimeSpawner.ApplyRarityColor(slimeClone, rarity.Color)

    local podPosition = targetPod:GetPivot().Position
    slimeClone:PivotTo(CFrame.new(podPosition + Vector3.new(0, 2, 0)))

    SlimeSpawner.CreateBillboard(slimeClone, slimeData)
    SlimeSpawner.CreateProximityPrompt(slimeClone, player, podIndex)

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

    slimeClone.Parent = targetPod

    return slimeClone
end

function SlimeSpawner.GetSlimeModel(moodIndex, sizeIndex)
    local moodName = SlimeConfig.Moods[moodIndex].Name
    local sizeName = SlimeConfig.Sizes[sizeIndex].Name

    local moodFolder = SLIMES_FOLDER:FindFirstChild(moodName)
    if not moodFolder then return nil end

    local sizeFolder = moodFolder:FindFirstChild(sizeName)
    if not sizeFolder then return nil end

    return sizeFolder:FindFirstChildWhichIsA("Model")
end

function SlimeSpawner.ApplyRarityColor(slimeModel, color)
    for _, part in ipairs(slimeModel:GetDescendants()) do
        if part:IsA("BasePart") and not part:FindFirstChild("NoColorChange") then
            part.Color = color
        end
    end
end

function SlimeSpawner.CreateBillboard(slimeModel, slimeData)
    local mood = SlimeConfig.Moods[slimeData.Mood]
    local rarity = SlimeConfig.Rarities[slimeData.Rarity]
    local size = SlimeConfig.Sizes[slimeData.Size]
    local state = SlimeConfig.States[slimeData.State]

    local production = SlimeConfig.GetProduction(slimeData.Size, slimeData.Rarity)

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "SlimeBillboard"
    billboard.Size = UDim2.new(0, 200, 0, 150)
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

    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, 0, 0.15, 0)
    rarityLabel.Position = UDim2.new(0, 0, 0.42, 0)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = rarity.Name
    rarityLabel.TextColor3 = rarity.Color
    rarityLabel.TextScaled = true
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.Parent = frame

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

function SlimeSpawner.CreateProximityPrompt(slimeModel, owner, podIndex)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CollectPrompt"
    prompt.ActionText = "Récupérer"
    prompt.ObjectText = "Gélatine"
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = false
    prompt.Parent = slimeModel:FindFirstChild("HumanoidRootPart") or slimeModel.PrimaryPart

    prompt.Triggered:Connect(function(playerWhoTriggered)
        if playerWhoTriggered == owner then
            local ProductionManager = require(script.Parent.ProductionManager)
            ProductionManager.CollectFromPod(owner, podIndex)
        end
    end)
end

function SlimeSpawner.RemoveServerSlime(slimeModel)
    if slimeModel and slimeModel:IsA("Model") then
        slimeModel:Destroy()
    end
end

return SlimeSpawner
```

---

# 📝 INSTRUCTIONS DE COPIE

1. **Ouvrir chaque script dans ServerScriptService**
2. **Sélectionner TOUT le contenu** (Ctrl+A)
3. **Coller** le code corrigé ci-dessus
4. **Sauvegarder** (Ctrl+S)

Les scripts qui doivent être remplacés :
- ✅ DataStoreManager
- ✅ MainServer
- ✅ BaseManager
- ✅ ProductionManager
- ✅ SlimeSpawner

Les autres (FusionHandler, ContractManager, ShopManager, RebirthHandler, EventManager, ServerMatchmaking) devraient déjà fonctionner.
