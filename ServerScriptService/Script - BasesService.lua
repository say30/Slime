-- from: ServerScriptService.BasesService

-- ServerScriptService/BasesService.lua
-- Bases : assignation, "Base de <DisplayName>", likes sécurisés, sauvegarde.
-- Version robuste : recherche TitleLabel / LikeCount par nom dans tous les descendants.

local DEBUG = true

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")

-- ==== Remotes ===============================================================
local Remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = RS

local BasesRemotes = Remotes:FindFirstChild("Bases") or Instance.new("Folder")
BasesRemotes.Name = "Bases"
BasesRemotes.Parent = Remotes

local LikeRequest = BasesRemotes:FindFirstChild("LikeRequest") or Instance.new("RemoteEvent")
LikeRequest.Name = "LikeRequest"
LikeRequest.Parent = BasesRemotes

-- ==== Monde =================================================================
local BasesFolder = WS:WaitForChild("Base") -- contient "Base 1" .. "Base 8"

-- ==== DataStore (likes totaux joueurs) ======================================
local LikesStore = DataStoreService:GetDataStore("PlayerTotalLikes_v1")
local playerToBase = {}                 -- [Player] = Model
local totalLikesByUserId = {}           -- [userId] = number (persisté)
local likedOnce = {}                    -- [likerUserId] = { [ownerUserId] = true }
local lastSaveAt = {}

-- ==== Utils =================================================================
local function toBaseId(baseModel)
	if not baseModel then return nil end
	return tonumber(string.match(baseModel.Name or "", "%d+"))
end

local function allBases()
	local list = {}
	for _, m in ipairs(BasesFolder:GetChildren()) do
		if m:IsA("Model") and string.match(m.Name, "^Base%s*%d+") then
			table.insert(list, m)
		end
	end
	table.sort(list, function(a,b) return (toBaseId(a) or 9999) < (toBaseId(b) or 9999) end)
	return list
end

-- Recherche un descendant par nom, avec petit wait (Studio charge parfois en retard)
local function waitDescendantByName(root, name, timeout)
	local t0 = os.clock()
	while os.clock() - t0 < (timeout or 2) do
		local inst = root:FindFirstChild(name, true)
		if inst then return inst end
		task.wait(0.1)
	end
	return nil
end

local function getTitleLabel(baseModel)      -- TextLabel "TitleLabel" n'importe où dans la Base
	return waitDescendantByName(baseModel, "TitleLabel", 3)
end

local function getLikeCountLabel(baseModel)  -- TextLabel "LikeCount" n'importe où dans la Base
	return waitDescendantByName(baseModel, "LikeCount", 3)
end

local function setTitle(baseModel, text)
	local lbl = getTitleLabel(baseModel)
	if lbl and lbl:IsA("TextLabel") then
		lbl.Text = text
		if DEBUG then print(("[BasesService] %s -> Title = %s"):format(baseModel.Name, text)) end
	else
		if DEBUG then warn(("[BasesService] TitleLabel introuvable dans %s"):format(baseModel.Name)) end
	end
end

local function setLikeCount(baseModel, value)
	local lbl = getLikeCountLabel(baseModel)
	if lbl and lbl:IsA("TextLabel") then
		lbl.Text = tostring(value)
		if DEBUG then print(("[BasesService] %s -> LikeCount = %d"):format(baseModel.Name, value)) end
	else
		if DEBUG then warn(("[BasesService] LikeCount introuvable dans %s"):format(baseModel.Name)) end
	end
	baseModel:SetAttribute("Likes", value)
end

local function findStructureHome(baseModel)
	return baseModel:FindFirstChild("structure base home", true)
end

local function teleportToBase(player, baseModel)
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
	local home = findStructureHome(baseModel)
	if hrp and home and home:IsA("BasePart") then
		hrp.CFrame = CFrame.new(home.Position + Vector3.new(0, 3, 0))
	end
end

local function initializeBase(baseModel)
	if baseModel:GetAttribute("OwnerUserId") == nil then baseModel:SetAttribute("OwnerUserId", 0) end
	if baseModel:GetAttribute("OwnerName")   == nil then baseModel:SetAttribute("OwnerName", "") end
	if baseModel:GetAttribute("Likes")       == nil then baseModel:SetAttribute("Likes", 0) end
	setTitle(baseModel, "Libre")
	setLikeCount(baseModel, 0)
end

local function setBaseOwner(baseModel, player) -- player ou nil
	if player then
		baseModel:SetAttribute("OwnerUserId", player.UserId)
		baseModel:SetAttribute("OwnerName", player.DisplayName)
		local total = totalLikesByUserId[player.UserId] or 0
		setTitle(baseModel, ("Base de %s"):format(player.DisplayName))
		setLikeCount(baseModel, total)
	else
		baseModel:SetAttribute("OwnerUserId", 0)
		baseModel:SetAttribute("OwnerName", "")
		setTitle(baseModel, "Libre")
		setLikeCount(baseModel, 0)
	end
end

local function findFreeBase()
	for _, base in ipairs(allBases()) do
		local ownerId = base:GetAttribute("OwnerUserId")
		if not ownerId or ownerId == 0 then
			return base
		end
	end
	return nil
end

-- ==== Sauvegarde ============================================================
local function loadTotalLikes(userId)
	local ok, data = pcall(function() return LikesStore:GetAsync(("u:%d"):format(userId)) end)
	return (ok and typeof(data) == "number") and data or 0
end

local function saveTotalLikes(userId)
	local now = os.clock()
	if lastSaveAt[userId] and now - lastSaveAt[userId] < 3 then return end
	lastSaveAt[userId] = now
	local value = totalLikesByUserId[userId] or 0
	pcall(function() LikesStore:SetAsync(("u:%d"):format(userId), value) end)
end

-- ==== Likes sécurisés =======================================================
LikeRequest.OnServerEvent:Connect(function(liker, baseId)
	if typeof(baseId) ~= "number" then return end

	local targetBase
	for _, b in ipairs(allBases()) do
		if toBaseId(b) == baseId then targetBase = b break end
	end
	if not targetBase then return end

	local ownerId = targetBase:GetAttribute("OwnerUserId")
	if not ownerId or ownerId == 0 then return end
	if ownerId == liker.UserId then return end

	local ownerOnline = Players:GetPlayerByUserId(ownerId) ~= nil
	if not ownerOnline then return end

	likedOnce[liker.UserId] = likedOnce[liker.UserId] or {}
	if likedOnce[liker.UserId][ownerId] then return end

	likedOnce[liker.UserId][ownerId] = true
	totalLikesByUserId[ownerId] = (totalLikesByUserId[ownerId] or 0) + 1
	setLikeCount(targetBase, totalLikesByUserId[ownerId])
	saveTotalLikes(ownerId)
end)

-- ==== Cycle de vie joueur ===================================================
local function onCharacterAdded(player)
	local base = playerToBase[player]
	if base then
		task.wait(0.25)
		teleportToBase(player, base)
	end
end

local function assignBase(player)
	totalLikesByUserId[player.UserId] = loadTotalLikes(player.UserId)

	local base = findFreeBase()
	if not base then
		if DEBUG then warn("[BasesService] Aucune base libre pour", player.Name) end
		return
	end

	playerToBase[player] = base
	setBaseOwner(base, player)

	player.CharacterAdded:Connect(function() onCharacterAdded(player) end)
	if player.Character then onCharacterAdded(player) end

	if DEBUG then print(("[BasesService] %s assigné à %s"):format(player.Name, base.Name)) end
end

local function releaseBase(player)
	local base = playerToBase[player]
	playerToBase[player] = nil
	if base and base.Parent then
		setBaseOwner(base, nil) -- Libre + 0
	end
	saveTotalLikes(player.UserId)
end

Players.PlayerAdded:Connect(function(player)
	for _, b in ipairs(allBases()) do
		if b:GetAttribute("OwnerUserId") == nil then
			initializeBase(b)
		else
			-- réaligne UI à l'état courant
			local ownerId = b:GetAttribute("OwnerUserId")
			if ownerId and ownerId > 0 then
				setTitle(b, ("Base de %s"):format(b:GetAttribute("OwnerName") or ""))
				setLikeCount(b, b:GetAttribute("Likes") or 0)
			else
				setTitle(b, "Libre")
				setLikeCount(b, 0)
			end
		end
	end
	task.defer(assignBase, player)
end)

Players.PlayerRemoving:Connect(function(player)
	releaseBase(player)
end)

-- Boot Studio
for _, b in ipairs(allBases()) do
	initializeBase(b)
end
for _, p in ipairs(Players:GetPlayers()) do
	totalLikesByUserId[p.UserId] = loadTotalLikes(p.UserId)
	assignBase(p)
end
