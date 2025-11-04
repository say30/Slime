-- from: ReplicatedStorage.Modules.GameBalance

-- ReplicatedStorage/Modules/GameBalance.lua
-- REBALANCÉ EXPLOSIF : Économie longue avec trillions en endgame
local Balance = {}

-- ===========================
-- SIZES (prix ↑ fort; prod ↑ modérée)
-- ===========================
Balance.Sizes = {"Micro","Petit","Moyen","Grand","Titan"}
Balance.SizePrice = { Micro=0.65, Petit=0.85, Moyen=1.00, Grand=1.40, Titan=2.00 }
Balance.SizeProd  = { Micro=0.60, Petit=0.80, Moyen=1.00, Grand=1.45, Titan=2.10 }

-- ===========================
-- RARETES (12 tiers)
-- ===========================
Balance.Rarities = {
	"Commun","Vibrant","Rare","Arcane","Épique","Légendaire",
	"Mythique","Occulte","Céleste","Abyssal","Prismatique","Oméga"
}
Balance.RarityHex = {
	"#BDBDBD","#3CB371","#1E90FF","#6A5ACD","#8A2BE2","#FFD700",
	"#FF4500","#2F4F4F","#87CEFA","#4B0082","#FF00FF","#FFFFFF"
}

-- VANILLA WEIGHTS (pour référence baseline)
Balance.RarityWeights = {10000,4200,2200,1000,420,120,60,30,15,8,4,1}

-- MULTIPLICATEURS PRIX par rareté (explosion exponentielle)
Balance.RarityPrice = {1.00,1.15,1.35,1.60,1.95,2.50,3.50,5.00,7.50,11.00,16.00,25.00}

-- MULTIPLICATEURS PROD par rareté (moins agressif que prix)
Balance.RarityProd  = {1.00,1.05,1.12,1.20,1.32,1.48,1.68,1.90,2.15,2.45,2.80,3.20}

-- ===========================
-- STATES (Fusion uniquement)
-- ===========================
Balance.States = {"Corrompu","Cristallisé","Fusionné","Muté","Pur"}
Balance.StatePrice = {1.15,1.35,1.60,1.90,2.30}
Balance.StateProd  = {1.12,1.28,1.50,1.80,2.20}

-- ===========================
-- MOODS
-- ===========================
Balance.MoodPrice = setmetatable({}, { __index = function() return 1.0 end })
Balance.MoodProd  = setmetatable({}, { __index = function() return 1.0 end })

-- ===========================
-- RÉFÉRENCES DE BASE (CRITIQUES)
-- ===========================
Balance.BasePrice = 1
Balance.BaseProd  = 1.0

-- ===== Utils =====
local function weightedPick(weights)
	local sum = 0
	for _,w in ipairs(weights) do sum += w end
	local r = math.random() * sum
	for i,w in ipairs(weights) do
		if r <= w then return i end
		r -= w
	end
	return #weights
end

function Balance.RollRarityIndex()
	return weightedPick(Balance.RarityWeights)
end

function Balance.NoStateIndex() return nil end

-- ===========================
-- CALCULS DE PRIX
-- ===========================
function Balance.ComputePrice(mood, sizeName, rarityIndex, stateIndex)
	local price = Balance.BasePrice
	price *= (Balance.MoodPrice[mood] or 1)
	price *= (Balance.SizePrice[sizeName] or 1)
	price *= (Balance.RarityPrice[rarityIndex or 1] or 1)
	if stateIndex then price *= (Balance.StatePrice[stateIndex] or 1) end
	return math.max(1, math.floor(price + 0.5))
end

-- ===========================
-- CALCULS DE PRODUCTION
-- ===========================
function Balance.ComputeProd(mood, sizeName, rarityIndex, stateIndex)
	local p = Balance.BaseProd
	p *= (Balance.MoodProd[mood] or 1)
	p *= (Balance.SizeProd[sizeName] or 1)
	p *= (Balance.RarityProd[rarityIndex or 1] or 1)
	if stateIndex then p *= (Balance.StateProd[stateIndex] or 1) end
	return p
end

-- ===========================
-- FORMATAGE NOMBRES
-- ===========================
function Balance.FormatNumber(n)
	if n >= 1e15 then return string.format("%.2fQ", n/1e15)
	elseif n >= 1e12 then return string.format("%.2fT", n/1e12)
	elseif n >= 1e9 then return string.format("%.2fB", n/1e9)
	elseif n >= 1e6 then return string.format("%.2fM", n/1e6)
	elseif n >= 1e3 then return string.format("%.2fK", n/1e3)
	else return tostring(math.floor(n+0.5)) end
end

-- ===========================
-- ESSENCE REWARDS
-- ===========================
Balance.EssenceRewards = {
	FusionSuccess = 1,
	FusionFail = 5,
	ContractBase = 2,
	FusionLegendaries = 50,
	DailyBonus = 3,
}

return Balance
