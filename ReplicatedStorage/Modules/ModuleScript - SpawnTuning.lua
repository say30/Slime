-- from: ReplicatedStorage.Modules.SpawnTuning

-- ReplicatedStorage/Modules/SpawnTuning.lua
-- CALIBRÉ POUR 10h AVANT 1ER LEGENDARY + ÉCONOMIE PROGRESSIVE→EXPLOSIVE
local T = {}

T.TIER = {
	COMMON=1, VIBRANT=2, RARE=3, ARCANE=4, EPIC=5, LEGEND=6,
	MYTHIC=7, SECRET=8, CELESTIAL=9, ABYSSAL=10, PRISMATIC=11, OMEGA=12
}

T.SIZES = {"Micro","Petit","Moyen","Grand","Titan"}

-- ====================================================================
-- STAGES : Calibrés pour 10 heures avant 1er Legendary
-- ====================================================================
T.Stages = {
	-- STARTER (0-5 purchased) : Easy ramp, Legendary impossible
	-- First 30 min ≈ 450 slimes, Legendary weight ÷ 500
	{
		name = "Starter",
		isStage = function(m) return (m.totalPurchases or 0) < 5 end,
		rarityCap = T.TIER.RARE,                      -- Commun/Vibrant/Rare max
		priceFloor = 10, priceCeil = 100,             -- Easy afford
		baseScaling = 1.0,                            -- 1x base price
		sizeWeights = { Micro=50, Petit=35, Moyen=15, Grand=0, Titan=0 },
		-- Legendary weight: 120 ÷ 500 = 0.24 (vs vanilla 120)
		stageScale = { 1.00,0.95,0.80,0.60,0.30,0.06,0.03,0.01,0.005,0.002,0.001,0.0003 },
	},

	-- EARLY (5-25 purchased) : Accelerating, Legendary ultra-rare
	-- 5-25 purchased ≈ 1-3 hours, Legendary weight ÷ 200
	{
		name = "Early",
		isStage = function(m)
			return (m.totalPurchases or 0) >= 5 and (m.totalPurchases or 0) < 25
		end,
		rarityCap = T.TIER.EPIC,                      -- Epic max (no Legendary yet)
		priceFloor = 20, priceCeil = 300,
		baseScaling = 1.5,                            -- Prices start rising
		sizeWeights = { Micro=40, Petit=35, Moyen=20, Grand=5, Titan=0 },
		-- Legendary weight: 120 ÷ 200 = 0.6
		stageScale = { 1.00,0.90,0.75,0.50,0.25,0.10,0.04,0.015,0.008,0.003,0.001,0.0005 },
	},

	-- MID (25-80 purchased) : Legendary becomes possible (rare)
	-- 25-80 purchased ≈ 3-8 hours, Legendary weight ÷ 80
	{
		name = "Mid",
		isStage = function(m)
			return (m.totalPurchases or 0) >= 25 and (m.totalPurchases or 0) < 80
		end,
		rarityCap = nil,                              -- All rarities OK
		priceFloor = 50, priceCeil = 5000,
		baseScaling = 3.0,                            -- Prices accelerate
		sizeWeights = { Micro=30, Petit=32, Moyen=28, Grand=8, Titan=2 },
		-- Legendary weight: 120 ÷ 80 = 1.5
		stageScale = { 1.00,0.85,0.65,0.40,0.18,0.20,0.08,0.03,0.012,0.005,0.002,0.0008 },
	},

	-- LATE (80+ purchased) : Legendary grindable, prices EXPLOSIVE
	-- 80+ purchased ≈ 8-15 hours, Legendary weight ÷ 40 (+ pity boost helps)
	{
		name = "Late",
		isStage = function(m)
			return (m.totalPurchases or 0) >= 80
		end,
		rarityCap = nil,
		priceFloor = 200, priceCeil = 100000,         -- BRUTAL JUMP
		baseScaling = 10.0,                           -- 10x prices = explosive
		sizeWeights = { Micro=20, Petit=25, Moyen=35, Grand=15, Titan=5 },
		-- Legendary weight: 120 ÷ 40 = 3.0 (+ pity can 3x this = 9.0 max)
		stageScale = { 1.00,0.75,0.50,0.30,0.12,0.30,0.12,0.05,0.02,0.008,0.003,0.001 },
	},

	-- ENDGAME (200+ purchased) : Farming legendaries, Mythics rare, prices in MILLIONS
	{
		name = "Endgame",
		isStage = function(m)
			return (m.totalPurchases or 0) >= 200
		end,
		rarityCap = nil,
		priceFloor = 1000000, priceCeil = 1000000000,  -- Millions to billions
		baseScaling = 100.0,                           -- 100x = trillions territory
		sizeWeights = { Micro=10, Petit=15, Moyen=40, Grand=25, Titan=10 },
		stageScale = { 1.00,0.60,0.35,0.15,0.05,0.40,0.20,0.10,0.05,0.02,0.008,0.003 },
	},
}

-- ====================================================================
-- PITY : Après N rolls sans voir ce tier, boost temporairement le weight
-- ====================================================================
T.Pity = {
	-- [tierIndex] = { threshold, step, maxMul }
	[ T.TIER.LEGEND    ] = { threshold = 80,  step = 0.08, maxMul = 4.0 },  -- Aggresif
	[ T.TIER.MYTHIC    ] = { threshold = 160, step = 0.10, maxMul = 5.0 },
	[ T.TIER.SECRET    ] = { threshold = 240, step = 0.12, maxMul = 6.0 },
	[ T.TIER.CELESTIAL ] = { threshold = 320, step = 0.15, maxMul = 7.0 },
	[ T.TIER.ABYSSAL   ] = { threshold = 400, step = 0.18, maxMul = 8.0 },
	[ T.TIER.PRISMATIC ] = { threshold = 500, step = 0.20, maxMul = 10.0 },
	[ T.TIER.OMEGA     ] = { threshold = 800, step = 0.25, maxMul = 15.0 },
}

-- ====================================================================
-- BASE PRICE CALCULATION FORMULA
-- ====================================================================
-- Price = StageBasePrice * MoodMul * SizeMul * RarityMul * StateMul * UserWalletCurve

function T.ComputeStageBasePrice(stage)
	-- Prend le stage et retourne le base price
	if not stage then return 1 end
	return stage.baseScaling or 1.0
end

function T.GetStageByCriteria(metrics)
	for _, stage in ipairs(T.Stages) do
		if stage.isStage(metrics) then
			return stage
		end
	end
	return T.Stages[#T.Stages]
end

return T
