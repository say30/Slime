-- from: ServerScriptService.SlimeRush.PodAvailabilityService

-- ServerScriptService/SlimeRush/PodAvailabilityService.lua - Gère la disponibilité des pods par joueur
-- Place: ServerScriptService/SlimeRush (ModuleScript)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local M = {}

-- {[userId]: {[baseName]: {[podNumber]: occupied (boolean)}}}
local podStates = {}

-- Initialiser l'état des pods pour un joueur
local function initializePodStates(player)
	if podStates[player.UserId] then return end

	podStates[player.UserId] = {}

	-- Chercher les bases du joueur
	local basesFolder = Workspace:FindFirstChild("Base")
	if not basesFolder then return end

	for _, base in ipairs(basesFolder:GetChildren()) do
		if base:IsA("Model") then
			-- Vérifier si c'est la base du joueur
			local panneau = base:FindFirstChild("Panneau")
			local part = panneau and panneau:FindFirstChild("Part", true)
			local sg = part and part:FindFirstChildOfClass("SurfaceGui")
			local tl = sg and sg:FindFirstChild("MainFrame") and sg.MainFrame:FindFirstChild("TitleLabel")

			if tl and tl:IsA("TextLabel") then
				local title = tl.Text or ""
				if title == "Base de " .. player.DisplayName or title == "Base de " .. player.Name then
					podStates[player.UserId][base.Name] = {}

					-- Initialiser les 22 pods
					for i = 1, 22 do
						podStates[player.UserId][base.Name][i] = false -- false = disponible
					end

					-- Marquer les pods occupés
					local ownedSlimes = Workspace:FindFirstChild("OwnedSlimes")
					if ownedSlimes then
						for _, slime in ipairs(ownedSlimes:GetChildren()) do
							local ownerId = slime:GetAttribute("OwnerUserId")
							if ownerId == player.UserId then
								local podNum = slime:GetAttribute("PodNumber")
								local baseName = slime:GetAttribute("BaseName")
								if podNum and baseName and podStates[player.UserId][baseName] then
									podStates[player.UserId][baseName][podNum] = true -- true = occupé
								end
							end
						end
					end
				end
			end
		end
	end
end

-- ===== PUBLIC API =====

function M.IsPodAvailable(player, baseName, podNumber)
	if not podStates[player.UserId] or not podStates[player.UserId][baseName] then
		return false
	end
	return podStates[player.UserId][baseName][podNumber] == false
end

function M.SetPodOccupied(player, baseName, podNumber, occupied)
	if not podStates[player.UserId] then
		initializePodStates(player)
	end

	if podStates[player.UserId][baseName] then
		podStates[player.UserId][baseName][podNumber] = occupied
	end
end

function M.FindAvailablePod(player, baseName)
	if not podStates[player.UserId] then
		initializePodStates(player)
	end

	-- Si baseName spécifié, chercher un pod dans cette base
	if baseName and podStates[player.UserId][baseName] then
		for i = 1, 22 do
			if podStates[player.UserId][baseName][i] == false then
				return i
			end
		end
	end

	-- Sinon chercher dans n'importe quelle base du joueur
	for base, pods in pairs(podStates[player.UserId]) do
		for i = 1, 22 do
			if pods[i] == false then
				return i, base
			end
		end
	end

	return nil, nil
end

function M.GetPlayerBases(player)
	if not podStates[player.UserId] then
		initializePodStates(player)
	end

	local bases = {}
	for baseName, _ in pairs(podStates[player.UserId]) do
		table.insert(bases, baseName)
	end
	return bases
end

-- ===== INITIALIZATION =====

Players.PlayerAdded:Connect(function(player)
	task.wait(0.5)
	initializePodStates(player)
	print("✅ PodStates initialized pour " .. player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
	podStates[player.UserId] = nil
end)

-- Écouter les changements dans OwnedSlimes
local function setupOwnedSlimesListener()
	local ownedSlimes = Workspace:FindFirstChild("OwnedSlimes")
	if not ownedSlimes then
		ownedSlimes = Instance.new("Folder", Workspace)
		ownedSlimes.Name = "OwnedSlimes"
	end

	ownedSlimes.ChildAdded:Connect(function(slime)
		if slime:IsA("Model") then
			local ownerId = slime:GetAttribute("OwnerUserId")
			local podNum = slime:GetAttribute("PodNumber")
			local baseName = slime:GetAttribute("BaseName")

			if ownerId and podNum and baseName then
				local player = Players:GetPlayerByUserId(ownerId)
				if player then
					M.SetPodOccupied(player, baseName, podNum, true)
				end
			end
		end
	end)

	ownedSlimes.ChildRemoving:Connect(function(slime)
		if slime:IsA("Model") then
			local ownerId = slime:GetAttribute("OwnerUserId")
			local podNum = slime:GetAttribute("PodNumber")
			local baseName = slime:GetAttribute("BaseName")

			if ownerId and podNum and baseName then
				local player = Players:GetPlayerByUserId(ownerId)
				if player then
					M.SetPodOccupied(player, baseName, podNum, false)
				end
			end
		end
	end)
end

setupOwnedSlimesListener()

return M
