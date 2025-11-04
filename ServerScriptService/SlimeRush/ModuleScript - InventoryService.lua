-- from: ServerScriptService.SlimeRush.InventoryService

-- CORRIGÉ InventoryService_v2.lua
-- Place: ServerScriptService/SlimeRush/InventoryService (ModuleScript)
-- FIX: Position Y correcte + pas de prompt duplicate + pas de billboard

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local M = {}

local playerInventories = {}

local function getInventory(player)
	if not playerInventories[player.UserId] then
		playerInventories[player.UserId] = {
			slimes = {},
			maxSlots = 25,
		}
	end
	return playerInventories[player.UserId]
end

function M.GetInventorySlimes(player)
	return getInventory(player).slimes
end

function M.GetMaxSlots(player)
	return getInventory(player).maxSlots
end

function M.GetUsedSlots(player)
	return #getInventory(player).slimes
end

function M.AddSlimeToInventory(player, slimeData)
	local inv = getInventory(player)
	if #inv.slimes >= inv.maxSlots then
		return false, "Inventaire plein"
	end

	table.insert(inv.slimes, {
		mood = slimeData.mood,
		sizeName = slimeData.sizeName,
		rarityIndex = slimeData.rarityIndex,
		stateIndex = slimeData.stateIndex,
		prodPerSec = slimeData.prodPerSec,
		price = slimeData.price,
		podNumber = slimeData.podNumber,
		baseName = slimeData.baseName,
		addedAt = os.time(),
	})

	return true, "Slime ajouté"
end

function M.RemoveSlimeFromInventory(player, index)
	local inv = getInventory(player)
	if index < 1 or index > #inv.slimes then
		return false, "Index invalide"
	end
	local slime = inv.slimes[index]
	table.remove(inv.slimes, index)
	return true, slime
end

function M.SellSlime(player, index)
	local inv = getInventory(player)
	if index < 1 or index > #inv.slimes then
		return false, nil
	end
	local slime = inv.slimes[index]
	local sellPrice = math.floor(slime.price * 0.5)
	table.remove(inv.slimes, index)
	return true, sellPrice
end

function M.UpgradeInventory(player, level)
	local inv = getInventory(player)
	local newMax = 25 + (level * 5)
	inv.maxSlots = newMax
	return true, "Inventaire: " .. newMax .. " slots"
end

-- ===== REMOTES =====
local remotes = RS:WaitForChild("Remotes")

local getInvRemote = remotes:WaitForChild("GetInventory")
getInvRemote.OnServerInvoke = function(player)
	local slimes = M.GetInventorySlimes(player)
	local used = M.GetUsedSlots(player)
	local max = M.GetMaxSlots(player)
	return {
		slimes = slimes,
		used = used,
		max = max,
	}
end

local moveRemote = remotes:WaitForChild("MoveSlimeToInventory")
moveRemote.OnServerInvoke = function(player, slimeData)
	return M.AddSlimeToInventory(player, slimeData)
end

local sellRemote = remotes:WaitForChild("SellSlime")
sellRemote.OnServerInvoke = function(player, index)
	local ok, price = M.SellSlime(player, index)
	if ok then
		return true, price
	end
	return false, "Erreur vente"
end

local placeRemote = remotes:WaitForChild("PlaceSlimeFromInventory")
placeRemote.OnServerInvoke = function(player, slimeIndex, podNumber)
	local inv = getInventory(player)
	if slimeIndex < 1 or slimeIndex > #inv.slimes then
		return false, "Index invalide"
	end

	local slimeData = inv.slimes[slimeIndex]
	local targetPodNumber = slimeData.podNumber or podNumber or 1
	local targetBaseName = slimeData.baseName

	local basesFolder = Workspace:FindFirstChild("Base")
	if not basesFolder then
		return false, "Pas de bases"
	end

	local targetPod = nil
	local targetBase = nil

	-- Chercher dans la base spécifique
	if targetBaseName then
		for _, base in ipairs(basesFolder:GetChildren()) do
			if base:IsA("Model") and base.Name == targetBaseName then
				local podsFolder = base:FindFirstChild("PodsSlime", true)
				if podsFolder then
					local podSlot = podsFolder:FindFirstChild("PodsSlime" .. targetPodNumber)
					if podSlot then
						local ownedSlimes = Workspace:FindFirstChild("OwnedSlimes")
						if not ownedSlimes then
							targetPod = podSlot
							targetBase = base
							break
						end

						local occupied = false
						for _, slime in ipairs(ownedSlimes:GetChildren()) do
							local slot = slime:GetAttribute("SlotPath")
							if slot and slot:find("PodsSlime" .. targetPodNumber) then
								occupied = true
								break
							end
						end

						if not occupied then
							targetPod = podSlot
							targetBase = base
							break
						end
					end
				end
			end
		end
	end

	-- Chercher un pod libre
	if not targetPod then
		for podNum = 1, 22 do
			for _, base in ipairs(basesFolder:GetChildren()) do
				if base:IsA("Model") then
					local podsFolder = base:FindFirstChild("PodsSlime", true)
					if podsFolder then
						local podSlot = podsFolder:FindFirstChild("PodsSlime" .. podNum)
						if podSlot then
							local ownedSlimes = Workspace:FindFirstChild("OwnedSlimes")
							local occupied = false

							if ownedSlimes then
								for _, slime in ipairs(ownedSlimes:GetChildren()) do
									local slot = slime:GetAttribute("SlotPath")
									if slot and slot:find("PodsSlime" .. podNum) then
										occupied = true
										break
									end
								end
							end

							if not occupied then
								targetPod = podSlot
								targetBase = base
								targetPodNumber = podNum
								break
							end
						end
					end
				end
			end
			if targetPod then break end
		end
	end

	if not targetPod then
		return false, "Aucun pod libre"
	end

	-- Créer le slime owned
	local ownedSlimes = Workspace:FindFirstChild("OwnedSlimes") or Instance.new("Folder", Workspace)
	ownedSlimes.Name = "OwnedSlimes"

	local slimeModel = Instance.new("Model")
	slimeModel.Name = slimeData.mood .. " " .. slimeData.sizeName
	slimeModel.Parent = ownedSlimes

	slimeModel:SetAttribute("OwnerUserId", player.UserId)
	slimeModel:SetAttribute("SlotPath", targetPod:GetFullName())
	slimeModel:SetAttribute("Mood", slimeData.mood)
	slimeModel:SetAttribute("SizeName", slimeData.sizeName)
	slimeModel:SetAttribute("RarityIndex", slimeData.rarityIndex)
	slimeModel:SetAttribute("StateIndex", slimeData.stateIndex or 0)
	slimeModel:SetAttribute("ProdPerSec", slimeData.prodPerSec)
	slimeModel:SetAttribute("Price", slimeData.price)
	slimeModel:SetAttribute("PodNumber", targetPodNumber)
	slimeModel:SetAttribute("BaseName", targetBase.Name)

	-- Positionner sur le pod
	local part = targetPod:IsA("BasePart") and targetPod or targetPod:FindFirstChildWhichIsA("BasePart", true)
	if part then
		local primaryPart = Instance.new("Part")
		primaryPart.Name = "PrimaryPart"
		primaryPart.Size = Vector3.new(2, 2, 2)
		primaryPart.Material = Enum.Material.Neon
		primaryPart.Color = Color3.fromRGB(0, 255, 0)
		primaryPart.Anchored = false
		primaryPart.CanCollide = false
		primaryPart.Parent = slimeModel
		slimeModel.PrimaryPart = primaryPart

		-- ✅ FIX: Position Y = 0.5 (pas 3) pour poser sur le pod
		slimeModel:PivotTo(part.CFrame * CFrame.new(0, 0.5, 0))
	end

	table.remove(inv.slimes, slimeIndex)
	return true, "Placé sur pod " .. targetPodNumber
end

Players.PlayerRemoving:Connect(function(player)
	playerInventories[player.UserId] = nil
end)

return M
