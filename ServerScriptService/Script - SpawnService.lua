-- from: ServerScriptService.SpawnService

-- ServerScriptService/SpawnService.lua (FIXED)
-- Crée des offres (spawns locaux côté client) + gère l'achat sécurisé
-- FIX: Appelle SpawnDirector.BuildOffer() au lieu de faire son propre calcul

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

-- Remotes
local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
Remotes.Name = "Remotes"
local SpawnEvent   = Remotes:FindFirstChild("SpawnSlimeEvent") or Instance.new("RemoteEvent", Remotes)
SpawnEvent.Name = "SpawnSlimeEvent"
local PurchaseFunc = Remotes:FindFirstChild("PurchaseSlime") or Instance.new("RemoteFunction", Remotes)
PurchaseFunc.Name = "PurchaseSlime"

-- Modules
local Balance = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameBalance"))
local SpawnDirector = require(script.Parent:WaitForChild("SpawnDirector"))
local Economy = require(script.Parent:WaitForChild("EconomyService"))
local OwnedSlimeService = require(script.Parent:WaitForChild("OwnedSlimeService"))

-- Monde
local Plateau   = Workspace:FindFirstChild("Part") or Workspace:FindFirstChildWhichIsA("BasePart")
local MapCenter = Workspace:WaitForChild("MapCenter")

local function plateauTopY()
	if Plateau and Plateau:IsA("BasePart") then
		return Plateau.Position.Y + Plateau.Size.Y*0.5
	end
	return MapCenter.Position.Y
end

-- Params
local R_MAX, H_SPAWN = 130, 30

-- Offres
local offersByPlayer = {}
local nextIdByPlayer = {}

local function uniformInDisk(R)
	local r = math.sqrt(math.random()) * R
	local a = math.random()*math.pi*2
	return r*math.cos(a), r*math.sin(a)
end

local function makeOfferFor(player)
	-- ✅ FIX: Appelle SpawnDirector au lieu de faire directement
	local offer = SpawnDirector.BuildOffer(player)

	local dx, dz = uniformInDisk(R_MAX)
	local pos = Vector3.new(MapCenter.Position.X + dx, plateauTopY() + H_SPAWN, MapCenter.Position.Z + dz)

	nextIdByPlayer[player] = (nextIdByPlayer[player] or 0) + 1
	local id = nextIdByPlayer[player]

	local offerToSend = {
		offerId=id,
		mood=offer.mood,
		sizeName=offer.sizeName,
		rarityIndex=offer.rarityIndex,
		stateIndex=nil,
		price=offer.price,
		prodPerSec=offer.prodPerSec,
		position=pos,
	}

	offersByPlayer[player] = offersByPlayer[player] or {}
	offersByPlayer[player][id] = offerToSend
	return offerToSend
end

local function clearOffersFor(player)
	offersByPlayer[player] = nil
	nextIdByPlayer[player] = nil
end

PurchaseFunc.OnServerInvoke = function(player, offerId, startCF)
	local per = offersByPlayer[player]
	if not per then return false, "Offre expirée." end

	local offer = per[offerId]
	if not offer then return false, "Offre introuvable." end

	-- Recompute secure price
	local securePrice = Balance.ComputePrice(offer.mood, offer.sizeName, offer.rarityIndex, nil)
	if not Economy.TryPurchase(player, securePrice) then
		return false, "Pas assez de gélatine"
	end

	-- Crée le slime owned sur le serveur
	local ok = OwnedSlimeService.CreateOwned(player, {
		mood=offer.mood,
		sizeName=offer.sizeName,
		rarityIndex=offer.rarityIndex,
		stateIndex=nil,
		price=securePrice,
		prodPerSec=offer.prodPerSec,
		position=offer.position,
	}, startCF)

	if not ok then
		return false, "Erreur création slime"
	end

	-- Record purchase pour pity & staging
	SpawnDirector.RecordPurchase(player, offer)

	per[offerId] = nil
	return true, "Achat réussi"
end

local function startLoop(p)
	task.spawn(function()
		task.wait(1.2)
		while p.Parent do
			local o = makeOfferFor(p)
			SpawnEvent:FireClient(p, o)
			task.wait(4 + math.random()) -- 4-5 sec
		end
	end)
end

Players.PlayerAdded:Connect(startLoop)
Players.PlayerRemoving:Connect(clearOffersFor)
for _,p in ipairs(Players:GetPlayers()) do
	startLoop(p)
end
