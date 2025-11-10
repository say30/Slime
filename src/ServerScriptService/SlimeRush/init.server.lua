local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Core = script:WaitForChild("Core")

local BaseManager = require(Core:WaitForChild("BaseManager"))
local Economy = require(Core:WaitForChild("Economy"))
local Inventory = require(Core:WaitForChild("Inventory"))
local Shop = require(Core:WaitForChild("Shop"))
local FusionSystem = require(Core:WaitForChild("FusionSystem"))
local Contracts = require(Core:WaitForChild("Contracts"))

local RemoteFolder = Instance.new("Folder")
RemoteFolder.Name = "SlimeRushRemotes"
RemoteFolder.Parent = ReplicatedStorage

local Remotes = {
    PurchaseSlime = Instance.new("RemoteFunction"),
    ClaimPreview = Instance.new("RemoteEvent"),
    RequestInventory = Instance.new("RemoteFunction"),
    UpdateSlimePlacement = Instance.new("RemoteEvent"),
    RequestFusion = Instance.new("RemoteFunction"),
    ClaimContractReward = Instance.new("RemoteFunction"),
    RequestShopStock = Instance.new("RemoteFunction"),
    RequestContracts = Instance.new("RemoteFunction"),
    UpgradeInventory = Instance.new("RemoteFunction"),
    UpgradeBase = Instance.new("RemoteFunction"),
}

for name, remote in pairs(Remotes) do
    remote.Name = name
    remote.Parent = RemoteFolder
end

local playerProfiles = {}

local function bootstrapPlayer(player)
    local profile = {
        Currency = Economy.newWallet(100),
        Inventory = Inventory.createInventory(player.UserId),
        Base = BaseManager.assignBase(player),
        Contracts = Contracts.generateDailySet(player.UserId),
    }

    Shop.seedPersonalPreview(player, profile)
    playerProfiles[player] = profile
end

local function teardownPlayer(player)
    local profile = playerProfiles[player]
    if profile then
        BaseManager.releaseBase(profile)
        Contracts.persistContracts(player.UserId, profile.Contracts)
        playerProfiles[player] = nil
    end
end

Players.PlayerAdded:Connect(bootstrapPlayer)
Players.PlayerRemoving:Connect(teardownPlayer)

Remotes.RequestInventory.OnServerInvoke = function(player)
    local profile = playerProfiles[player]
    if not profile then
        return nil
    end

    return Inventory.serialize(profile.Inventory)
end

Remotes.PurchaseSlime.OnServerInvoke = function(player, previewId, catalystId)
    local profile = playerProfiles[player]
    if not profile then
        return false, "PROFILE_MISSING"
    end

    return Shop.finalizePurchase(player, profile, previewId, catalystId)
end

Remotes.UpdateSlimePlacement.OnServerEvent:Connect(function(player, slimeId, podIndex)
    local profile = playerProfiles[player]
    if not profile then
        return
    end

    BaseManager.placeSlime(profile, slimeId, podIndex)
end)

Remotes.RequestFusion.OnServerInvoke = function(player, params)
    local profile = playerProfiles[player]
    if not profile then
        return false, "PROFILE_MISSING"
    end

    return FusionSystem.attemptFusion(profile, params)
end

Remotes.UpgradeInventory.OnServerInvoke = function(player)
    local profile = playerProfiles[player]
    if not profile then
        return false, "PROFILE_MISSING"
    end

    return Inventory.attemptUpgrade(profile.Inventory, profile.Currency)
end

Remotes.RequestShopStock.OnServerInvoke = function(player)
    local profile = playerProfiles[player]
    if not profile then
        return nil
    end

    return Shop.getShopSnapshot(profile)
end

Remotes.RequestContracts.OnServerInvoke = function(player)
    local profile = playerProfiles[player]
    if not profile then
        return nil
    end

    return Contracts.serialize(profile.Contracts)
end

Remotes.ClaimContractReward.OnServerInvoke = function(player, contractId)
    local profile = playerProfiles[player]
    if not profile then
        return false, "PROFILE_MISSING"
    end

    return Contracts.claimReward(profile, contractId)
end

Remotes.UpgradeBase.OnServerInvoke = function(player)
    local profile = playerProfiles[player]
    if not profile then
        return false, "PROFILE_MISSING"
    end

    return BaseManager.upgradeBase(profile.Base, profile.Currency)
end
