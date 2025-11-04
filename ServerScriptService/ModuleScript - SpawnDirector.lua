-- from: ServerScriptService.SpawnDirector

-- ServerScriptService/SpawnDirector.lua (IMPROVED)
-- Chef d'orchestre : applique stages + caps + pity pour calculer une offre joueur
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local WS      = game:GetService("Workspace")

local Balance = require(RS:WaitForChild("Modules"):WaitForChild("GameBalance"))
local Curves  = require(RS:WaitForChild("Modules"):WaitForChild("SpawnCurves"))
local Tun     = require(RS:WaitForChild("Modules"):WaitForChild("SpawnTuning"))

local SlimesFolder = RS:WaitForChild("Slimes")
local OwnedFolder  = WS:FindFirstChild("OwnedSlimes") or Instance.new("Folder", WS)
OwnedFolder.Name = "OwnedSlimes"

local M = {}

-- État par joueur
local State = {}

local function ensure(p)
	State[p] = State[p] or { joinAt = os.clock(), rolls = 0, purchases = 0, pityMiss = {} }
	return State[p]
end

local function minutesSinceJoin(p)
	local st = ensure(p)
	return (os.clock() - (st.joinAt or os.clock())) / 60
end

local function ownedCount(p)
	local uid = p.UserId
	local n = 0
	for _,m in ipairs(OwnedFolder:GetChildren()) do
		if m:IsA("Model") and (m:GetAttribute("OwnerUserId") or 0) == uid then
			n += 1
		end
	end
	return n
end

local function metrics(p)
	return {
		minutes        = minutesSinceJoin(p),
		totalPurchases = ensure(p).purchases,
		ownedSlimes    = ownedCount(p),
		wallet         = tonumber(p:GetAttribute("Wallet")) or 0,
	}
end

local function currentStage(p)
	local m = metrics(p)
	return Tun.GetStageByCriteria(m)
end

local function baseRarityWeights()
	local w = {}
	for i=1,#Balance.RarityWeights do w[i] = Balance.RarityWeights[i] end
	return w
end

local function applyStageScale(w, stage)
	if not stage or not stage.stageScale then return w end
	for i=1,#w do
		w[i] = (w[i] or 0) * (stage.stageScale[i] or 0)
	end
	return w
end

local function applyRarityCap(w, stage)
	if not stage or not stage.rarityCap then return w end
	for i=stage.rarityCap+1, #w do w[i] = 0 end
	return w
end

local function applyPity(p, w)
	local st = ensure(p)
	for tier, cfg in pairs(Tun.Pity) do
		local miss = (st.pityMiss[tier] or 0)
		if miss > 0 then
			local mul = Curves.expoBoost(miss, cfg.threshold, cfg.step, cfg.maxMul)
			w[tier] = (w[tier] or 0) * mul
		end
	end
	return w
end

local function rollRarity(p)
	local stage = currentStage(p)
	local w = baseRarityWeights()
	w = applyStageScale(w, stage)
	w = applyRarityCap(w, stage)
	w = applyPity(p, w)
	w = Curves.normalize(w)

	local idx = Curves.weightedPick(w)

	local st = ensure(p)
	for tier,_ in pairs(Tun.Pity) do
		if tier == idx then st.pityMiss[tier] = 0 else st.pityMiss[tier] = (st.pityMiss[tier] or 0) + 1 end
	end
	st.rolls += 1

	return idx
end

local function pickSize(p)
	local stage = currentStage(p)
	local bag = stage.sizeWeights or { Micro=30, Petit=35, Moyen=30, Grand=4, Titan=1 }
	local list, weights = {}, {}
	for i, name in ipairs(Tun.SIZES) do
		local w = bag[name] or 0
		if w > 0 then
			table.insert(list, name)
			table.insert(weights, w)
		end
	end
	if #list == 0 then return "Moyen" end
	local k = Curves.weightedPick(weights)
	return list[k]
end

local function pickMood()
	local list = SlimesFolder:GetChildren()
	if #list == 0 then return "Neutre" end
	return list[ math.random(1, #list) ].Name
end

local function computeStageBasePrice(p)
	local stage = currentStage(p)
	if not stage then return 70 end
	-- Moyen Commun de reference = 70, multiply by stage scaling
	return 70 * Tun.ComputeStageBasePrice(stage)
end

local function clampPriceToStage(p, price)
	local stage = currentStage(p)
	local lo, hi = stage.priceFloor or 1, stage.priceCeil or 1e9
	return math.max(lo, math.min(hi, price))
end

-- ==== API ====
function M.BuildOffer(p)
	local mood       = pickMood()
	local sizeName   = pickSize(p)
	local rarityIdx  = rollRarity(p)
	local stateIdx   = nil

	-- Compute avec stage scaling appliqué
	local basePrice = computeStageBasePrice(p)
	Balance.BasePrice = basePrice
	local price = Balance.ComputePrice(mood, sizeName, rarityIdx, stateIdx)
	price = clampPriceToStage(p, price)

	local prod  = Balance.ComputeProd(mood, sizeName, rarityIdx, stateIdx)

	return {
		mood = mood,
		sizeName = sizeName,
		rarityIndex = rarityIdx,
		stateIndex = stateIdx,
		price = price,
		prodPerSec = prod
	}
end

function M.RecordPurchase(p, offerOrTier)
	local st = ensure(p)
	st.purchases += 1
	local tier = tonumber(offerOrTier) or (offerOrTier and offerOrTier.rarityIndex) or nil
	if tier and Tun.Pity[tier] then
		st.pityMiss[tier] = 0
	end
end

function M.ResetPlayer(p) State[p] = nil end

Players.PlayerRemoving:Connect(function(p) State[p] = nil end)

return M
