--[[
    EconomyConfig.lua
    Configuration économique basée sur temps de farm
]]

local EconomyConfig = {}

-- ============================================
-- 💰 TABLE DE PRIX PAR RARETÉ ET TAILLE
-- ============================================

-- FORMULE DE BASE : Prix = Temps_Farm_Minutes × Production_Moyenne_Par_Minute
-- Philosophie : Plus c'est rare, plus ça nécessite de temps de farm

local PRICE_TABLE = {
	-- COMMUNS (accessibles, 70% spawn)
	Commun = {
		[1] = 50,        -- Micro
		[3.5] = 80,      -- Petit
		[12] = 960,      -- Moyen (×80 formule)
		[45] = 3600,     -- Grand (×80 formule)
		[180] = 14400    -- Titan (×80 formule)
	},

	-- VIBRANTS (nécessitent 20-60 min de farm, 20% spawn)
	Vibrant = {
		[2.5] = 12000,      -- Micro (20 min avec 10 Communs à 10/s)
		[8.75] = 36000,     -- Petit (30 min avec setup moyen)
		[30] = 120000,      -- Moyen (1h de farm)
		[112.5] = 450000,   -- Grand (2-3h de farm)
		[450] = 1800000     -- Titan (4-5h de farm)
	},

	-- RARES (nécessitent plusieurs heures, 7% spawn)
	Rare = {
		[7] = 50000,        -- Micro
		[24.5] = 175000,    -- Petit
		[84] = 600000,      -- Moyen
		[315] = 2250000,    -- Grand
		[1260] = 9000000    -- Titan
	},

	-- ARCANE (mid-game, 2% spawn)
	Arcane = {
		[18] = 150000,
		[63] = 525000,
		[216] = 1800000,
		[810] = 6750000,
		[3240] = 27000000
	},

	-- ÉPIQUE (late-game début, 0.7% spawn)
	["Épique"] = {
		[50] = 500000,
		[175] = 1750000,
		[600] = 6000000,
		[2250] = 22500000,
		[9000] = 90000000
	},

	-- LÉGENDAIRE (late-game, 0.2% spawn)
	["Légendaire"] = {
		[140] = 2000000,
		[490] = 7000000,
		[1680] = 24000000,
		[6300] = 90000000,
		[25200] = 360000000
	},

	-- MYTHIQUE (end-game, 0.07% spawn)
	Mythique = {
		[400] = 8000000,
		[1400] = 28000000,
		[4800] = 96000000,
		[18000] = 360000000,
		[72000] = 1440000000
	},

	-- OCCULTE (ultra rare, 0.02% spawn)
	Occulte = {
		[1100] = 30000000,
		[3850] = 105000000,
		[13200] = 360000000,
		[49500] = 1350000000,
		[198000] = 5400000000
	},

	-- CÉLESTE (quasi impossible, 0.008% spawn)
	["Céleste"] = {
		[3000] = 100000000,
		[10500] = 350000000,
		[36000] = 1200000000,
		[135000] = 4500000000,
		[540000] = 18000000000
	},

	-- ABYSSAL (extrême, 0.002% spawn)
	Abyssal = {
		[8500] = 350000000,
		[29750] = 1225000000,
		[102000] = 4200000000,
		[382500] = 15750000000,
		[1530000] = 63000000000
	},

	-- PRISMATIQUE (légendaire, 0.0008% spawn)
	Prismatique = {
		[25000] = 1250000000,
		[87500] = 4375000000,
		[300000] = 15000000000,
		[1125000] = 56250000000,
		[4500000] = 225000000000
	},

	-- OMÉGA (ultime, 0.0002% spawn)
	["Oméga"] = {
		[75000] = 5000000000,
		[262500] = 17500000000,
		[900000] = 60000000000,
		[3375000] = 225000000000,
		[13500000] = 900000000000
	}
}

-- ============================================
-- 📈 CALCUL DU PRIX D'ACHAT D'UN SLIME
-- ============================================
function EconomyConfig:CalculateCost(production, rarityMultiplier, sizeMultiplier)
	-- Récupérer le nom de la rareté
	local rarityName = self:GetRarityNameFromMultiplier(rarityMultiplier)

	if not rarityName or not PRICE_TABLE[rarityName] then
		-- Fallback : formule ×80
		return math.ceil(production * 80)
	end

	-- Chercher le prix exact dans la table
	local priceForRarity = PRICE_TABLE[rarityName]

	-- Trouver le prix correspondant à la production exacte
	if priceForRarity[production] then
		return priceForRarity[production]
	end

	-- Fallback si production non trouvée
	return math.ceil(production * 80)
end

-- ============================================
-- 🔍 HELPER - Trouver rareté par multiplicateur
-- ============================================
function EconomyConfig:GetRarityNameFromMultiplier(multiplier)
	local rarityMap = {
		[1] = "Commun",
		[2.5] = "Vibrant",
		[7] = "Rare",
		[18] = "Arcane",
		[50] = "Épique",
		[140] = "Légendaire",
		[400] = "Mythique",
		[1100] = "Occulte",
		[3000] = "Céleste",
		[8500] = "Abyssal",
		[25000] = "Prismatique",
		[75000] = "Oméga"
	}

	return rarityMap[multiplier]
end

-- ============================================
-- 💎 CALCUL DE LA VALEUR DE REVENTE (50% du prix)
-- ============================================
function EconomyConfig:CalculateSellValue(production, rarityMultiplier, sizeMultiplier)
	local buyCost = self:CalculateCost(production, rarityMultiplier, sizeMultiplier)
	return math.floor(buyCost * 0.5)
end

-- ============================================
-- 🏠 UPGRADES DE BASE
-- ============================================
EconomyConfig.BaseUpgrades = {
	{Level = 1, GelatinCost = 3500000, UnlocksPods = {11, 12}},
	{Level = 2, GelatinCost = 25000000, UnlocksPods = {13, 14}},
	{Level = 3, GelatinCost = 180000000, UnlocksPods = {15, 16}},
	{Level = 4, GelatinCost = 1300000000, UnlocksPods = {17, 18}},
	{Level = 5, GelatinCost = 9500000000, UnlocksPods = {19, 20}},
	{Level = 6, GelatinCost = 70000000000, UnlocksPods = {21, 22}}
}

-- ============================================
-- ⚙️ UPGRADES DE PRODUCTION
-- ============================================
EconomyConfig.ProductionUpgrades = {
	{Level = 1, GelatinCost = 500000, EssenceCost = 50000, Bonus = 0.10},
	{Level = 2, GelatinCost = 5000000, EssenceCost = 500000, Bonus = 0.15},
	{Level = 3, GelatinCost = 50000000, EssenceCost = 5000000, Bonus = 0.20},
	{Level = 4, GelatinCost = 500000000, EssenceCost = 50000000, Bonus = 0.25},
	{Level = 5, GelatinCost = 5000000000, EssenceCost = 500000000, Bonus = 0.30},
	{Level = 6, GelatinCost = 50000000000, EssenceCost = 5000000000, Bonus = 0.35},
	{Level = 7, GelatinCost = 500000000000, EssenceCost = 50000000000, Bonus = 0.40},
	{Level = 8, GelatinCost = 5000000000000, EssenceCost = 500000000000, Bonus = 0.50},
	{Level = 9, GelatinCost = 50000000000000, EssenceCost = 5000000000000, Bonus = 0.70},
	{Level = 10, GelatinCost = 500000000000000, EssenceCost = 50000000000000, Bonus = 1.00}
}

-- ============================================
-- 🎒 UPGRADES D'INVENTAIRE
-- ============================================
EconomyConfig.InventoryUpgrades = {
	{Level = 1, GelatinCost = 2000000, EssenceCost = 300000, SlotsAdded = 25},
	{Level = 2, GelatinCost = 15000000, EssenceCost = 2000000, SlotsAdded = 25},
	{Level = 3, GelatinCost = 100000000, EssenceCost = 15000000, SlotsAdded = 30},
	{Level = 4, GelatinCost = 750000000, EssenceCost = 100000000, SlotsAdded = 30},
	{Level = 5, GelatinCost = 5000000000, EssenceCost = 750000000, SlotsAdded = 40},
	{Level = 6, GelatinCost = 35000000000, EssenceCost = 5000000000, SlotsAdded = 40},
	{Level = 7, GelatinCost = 250000000000, EssenceCost = 35000000000, SlotsAdded = 50},
	{Level = 8, GelatinCost = 1750000000000, EssenceCost = 250000000000, SlotsAdded = 50},
	{Level = 9, GelatinCost = 12000000000000, EssenceCost = 1750000000000, SlotsAdded = 60},
	{Level = 10, GelatinCost = 85000000000000, EssenceCost = 12000000000000, SlotsAdded = 80}
}

-- ============================================
-- 🧬 FUSION À 2 (États)
-- ============================================
EconomyConfig.Fusion2 = {
	BaseCost = {Gelatin = 1000, Essence = 150},
	BaseSuccessRate = 35,
	BaseTimerSeconds = 30,

	TimerMultiplierByRarity = {
		Commun = 1.0,
		Vibrant = 1.2,
		Rare = 1.5,
		Arcane = 2.0,
		["Épique"] = 2.5,
		["Légendaire"] = 3.0,
		Mythique = 4.0,
		Occulte = 5.0,
		["Céleste"] = 6.5,
		Abyssal = 8.0,
		Prismatique = 10.0,
		["Oméga"] = 15.0
	},

	TimerMultiplierBySize = {
		Micro = 1.0,
		Petit = 1.3,
		Moyen = 1.7,
		Grand = 2.2,
		Titan = 3.0
	},

	TimerMultiplierByState = {
		Aucun = 1.0,
		Pur = 1.4,
		["Muté"] = 1.8,
		["Fusionné"] = 2.3,
		["Cristallisé"] = 3.0,
		Corrompu = 4.0
	},

	FailureCompensation = {
		GelatinRefund = 0.10,
		EssenceBonus = 0.10
	}
}

-- ============================================
-- 🔀 FUSION À 3 (Mood/Rareté/Taille)
-- ============================================
EconomyConfig.Fusion3 = {
	BaseCost = {Gelatin = 5000, Essence = 750},
	BaseTimerSeconds = 60,

	SuccessRates = {
		Mood = 30,
		Rarity = 35,
		Size = 40
	},

	FailureCompensation = {
		GelatinRefund = 0.10,
		EssenceBonus = 0.10
	}
}

-- ============================================
-- 🛍️ CATALYSEURS
-- ============================================
EconomyConfig.Catalysts = {
	Minor = {Name = "Catalyseur Mineur", BonusChance = 5, EssenceCost = 100000},
	Stable = {Name = "Catalyseur Stable", BonusChance = 10, EssenceCost = 500000},
	Powerful = {Name = "Catalyseur Puissant", BonusChance = 15, EssenceCost = 2000000},
	Perfect = {Name = "Catalyseur Parfait", BonusChance = 20, EssenceCost = 10000000},
	Guaranteed = {Name = "Catalyseur Garanti", BonusChance = 100, EssenceCost = 100000000},
	Stability = {Name = "Catalyseur de Stabilité", EssenceCost = 50000000}
}

-- ============================================
-- 🎁 VENTE DE SLIMES
-- ============================================
EconomyConfig.SellRewards = {
	GelatinRefund = 1.10,
	EssenceBonus = 0.01
}

return EconomyConfig
