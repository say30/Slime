--[[
    FusionConfig.lua
    Configuration et formules pour le système de fusion hardcore
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SlimeConfig = require(script.Parent:WaitForChild("SlimeConfig"))

local FusionConfig = {}

-- ============================================
-- 📊 MULTIPLICATEURS (depuis SlimeConfig)
-- ============================================

-- Fonction pour récupérer le multiplicateur de rareté
local function getRarityMultiplier(rarityName)
	local rarityData = SlimeConfig:GetRarityByName(rarityName)
	return rarityData and rarityData.Multiplier or 1
end

-- Fonction pour récupérer le multiplicateur de taille
local function getSizeMultiplier(sizeName)
	local sizeData = SlimeConfig:GetSizeByName(sizeName)
	return sizeData and sizeData.Multiplier or 1
end

-- Multiplicateurs d'état
local STATE_MULTIPLIERS = {
	["Aucun"] = 1,
	["Pur"] = 3,
	["Muté"] = 5,
	["Fusionné"] = 8,
	["Cristallisé"] = 12,
	["Corrompu"] = 20
}

local function getStateMultiplier(stateName)
	return STATE_MULTIPLIERS[stateName] or 1
end

-- ============================================
-- ⚡ FUSION À 2 (ÉTATS) - FORMULES
-- ============================================

function FusionConfig:CalculateFusion2Cost(rarityName, sizeName, stateName)
	local baseGelatinCost = 1000
	local baseEssenceCost = 150

	local rarityMult = getRarityMultiplier(rarityName)
	local sizeMult = getSizeMultiplier(sizeName)
	local stateMult = getStateMultiplier(stateName)

	-- Coût en gélatine
	local gelatinCost = baseGelatinCost * rarityMult * sizeMult * stateMult

	-- Coût en essence
	local essenceCost = baseEssenceCost * rarityMult * (sizeMult / 2)

	return {
		gelatin = math.floor(gelatinCost),
		essence = math.floor(essenceCost)
	}
end

function FusionConfig:CalculateFusion2Timer(rarityName, sizeName, stateName)
	local baseTime = 30  -- 30 secondes de base

	local rarityMult = getRarityMultiplier(rarityName)
	local sizeMult = getSizeMultiplier(sizeName)
	local stateMult = getStateMultiplier(stateName)

	local duration = baseTime * math.sqrt(rarityMult) * math.sqrt(sizeMult) * math.log(stateMult + 2)

	return math.floor(duration)
end

function FusionConfig:CalculateFusion2Chance(rarityName, sizeName, catalystBonus)
	local baseChance = 35
	catalystBonus = catalystBonus or 0

	local rarityMult = getRarityMultiplier(rarityName)
	local sizeMult = getSizeMultiplier(sizeName)

	-- Pénalités
	local rarityPenalty = math.log10(rarityMult + 1) * 3
	local sizePenalty = math.log10(sizeMult + 1) * 2

	local finalChance = math.max(baseChance - rarityPenalty - sizePenalty + catalystBonus, 5)

	return math.floor(finalChance * 10) / 10  -- Arrondi à 1 décimale
end

-- ============================================
-- 🔥 FUSION À 3 (AMÉLIORATION) - FORMULES
-- ============================================

function FusionConfig:CalculateFusion3Cost(rarityName, sizeName)
	local baseGelatinCost = 5000
	local baseEssenceCost = 750

	local rarityMult = getRarityMultiplier(rarityName)
	local sizeMult = getSizeMultiplier(sizeName)

	-- Coût en gélatine
	local gelatinCost = baseGelatinCost * rarityMult * sizeMult

	-- Coût en essence
	local essenceCost = baseEssenceCost * rarityMult * (sizeMult / 3)

	return {
		gelatin = math.floor(gelatinCost),
		essence = math.floor(essenceCost)
	}
end

function FusionConfig:CalculateFusion3Timer(rarityName, sizeName)
	local baseTime = 60  -- 60 secondes de base

	local rarityMult = getRarityMultiplier(rarityName)
	local sizeMult = getSizeMultiplier(sizeName)

	local duration = baseTime * math.sqrt(rarityMult * 1.5) * math.sqrt(sizeMult * 1.5)

	return math.floor(duration)
end

function FusionConfig:CalculateFusion3Chance(fusionType, rarityName, sizeName, catalystBonus)
	catalystBonus = catalystBonus or 0

	-- Probabilités de base
	local baseChances = {
		Mood = 30,
		Rarity = 35,
		Size = 40
	}

	local baseChance = baseChances[fusionType] or 30

	local rarityMult = getRarityMultiplier(rarityName)
	local sizeMult = getSizeMultiplier(sizeName)

	-- Pénalités
	local rarityPenalty = math.log10(rarityMult + 1) * 4
	local sizePenalty = math.log10(sizeMult + 1) * 2.5

	-- Chances minimales selon le type
	local minChances = {
		Mood = 3,
		Rarity = 5,
		Size = 8
	}

	local minChance = minChances[fusionType] or 3

	local finalChance = math.max(baseChance - rarityPenalty - sizePenalty + catalystBonus, minChance)

	return math.floor(finalChance * 10) / 10
end

-- ============================================
-- 💎 CATALYSEURS
-- ============================================

FusionConfig.Catalysts = {
	Minor = {
		name = "Mineur",
		bonus = 5,
		icon = "⚡"
	},
	Stable = {
		name = "Stable",
		bonus = 10,
		icon = "⚡⚡"
	},
	Powerful = {
		name = "Puissant",
		bonus = 15,
		icon = "⚡⚡⚡"
	},
	Perfect = {
		name = "Parfait",
		bonus = 20,
		icon = "⚡⚡⚡⚡"
	}
}

function FusionConfig:GetCatalystBonus(catalystType)
	local catalyst = self.Catalysts[catalystType]
	return catalyst and catalyst.bonus or 0
end

-- ============================================
-- 📈 PROGRESSION DES ÉTATS
-- ============================================

FusionConfig.StateProgression = {
	"Aucun",
	"Pur",
	"Muté",
	"Fusionné",
	"Cristallisé",
	"Corrompu"
}

function FusionConfig:GetNextState(currentState)
	for i, state in ipairs(self.StateProgression) do
		if state == currentState then
			return self.StateProgression[i + 1]
		end
	end
	return nil  -- État maximal
end

function FusionConfig:CanUpgradeState(currentState)
	return self:GetNextState(currentState) ~= nil
end

-- ============================================
-- 💰 SKIP TIMER (ROBUX)
-- ============================================

function FusionConfig:CalculateSkipCost(timerDuration)
	-- 1 Robux par minute (arrondi au supérieur)
	return math.ceil(timerDuration / 60)
end

-- ============================================
-- 💔 COMPENSATION D'ÉCHEC
-- ============================================

function FusionConfig:CalculateFailCompensation(slimesValue)
	return {
		gelatin = math.floor(slimesValue * 0.5),  -- 50% remboursement
		essence = math.floor(slimesValue * 0.001) -- 0.1% en essence
	}
end

-- ============================================
-- 🔍 VALIDATION
-- ============================================

function FusionConfig:ValidateFusion2(slime1, slime2)
	if slime1.mood ~= slime2.mood then
		return false, "Les Moods doivent être identiques"
	end

	if slime1.rarity ~= slime2.rarity then
		return false, "Les Raretés doivent être identiques"
	end

	if slime1.sizeName ~= slime2.sizeName then
		return false, "Les Tailles doivent être identiques"
	end

	-- Vérifier si l'état peut être amélioré
	if not self:CanUpgradeState(slime1.state or "Aucun") then
		return false, "État maximal atteint (Corrompu)"
	end

	return true
end

function FusionConfig:ValidateFusion3(slime1, slime2, slime3)
	-- Détecter le type de fusion
	local fusionType = nil

	if slime1.mood == slime2.mood and slime2.mood == slime3.mood then
		fusionType = "Mood"
	elseif slime1.rarity == slime2.rarity and slime2.rarity == slime3.rarity then
		fusionType = "Rarity"
	elseif slime1.sizeName == slime2.sizeName and slime2.sizeName == slime3.sizeName then
		fusionType = "Size"
	else
		return false, "Aucune correspondance trouvée (Mood, Rareté ou Taille)"
	end

	-- Vérifier si on peut améliorer
	if fusionType == "Rarity" then
		local rarities = SlimeConfig.Rarities
		local currentIndex = nil
		for i, r in ipairs(rarities) do
			if r.Name == slime1.rarity then
				currentIndex = i
				break
			end
		end
		if currentIndex >= #rarities then
			return false, "Rareté maximale atteinte (Oméga)"
		end
	elseif fusionType == "Size" then
		local sizes = SlimeConfig.Sizes
		local currentIndex = nil
		for i, s in ipairs(sizes) do
			if s.Name == slime1.sizeName then
				currentIndex = i
				break
			end
		end
		if currentIndex >= #sizes then
			return false, "Taille maximale atteinte (Titan)"
		end
	end

	return true, fusionType
end

print("[FusionConfig] ✅ Module chargé (Formules hardcore)")

return FusionConfig
