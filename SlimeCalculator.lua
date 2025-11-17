--[[
    SlimeCalculator.lua
    Calculs de production, coût, timer de fusion
]]

local SlimeCalculator = {}

local SlimeConfig = require(script.Parent.SlimeConfig)
local EconomyConfig = require(script.Parent.EconomyConfig)

-- ============================================
-- 💧 CALCUL DE PRODUCTION
-- ============================================
function SlimeCalculator:CalculateProduction(mood, rarity, size, state)
	local rarityData = SlimeConfig:GetRarityByName(rarity)
	local sizeData = SlimeConfig:GetSizeByName(size)
	local stateData = SlimeConfig:GetStateByName(state or "Aucun")

	if not rarityData or not sizeData or not stateData then
		warn("[SlimeCalculator] Données invalides:", rarity, size, state)
		return 1
	end

	local production = rarityData.Multiplier * sizeData.Multiplier * stateData.Multiplier
	return production
end

-- ============================================
-- 💰 CALCUL DE COÛT
-- ============================================
function SlimeCalculator:CalculateCost(production, mood, rarity, size, state)
	-- Récupérer les multiplicateurs
	local rarityData = SlimeConfig:GetRarityByName(rarity)
	local sizeData = SlimeConfig:GetSizeByName(size)

	if not rarityData or not sizeData then
		-- Fallback : formule basique
		return EconomyConfig:CalculateCost(production)
	end

	-- Appeler EconomyConfig avec les multiplicateurs
	return EconomyConfig:CalculateCost(production, rarityData.Multiplier, sizeData.Multiplier)
end

-- ============================================
-- ⏱️ CALCUL TIMER FUSION
-- ============================================
function SlimeCalculator:CalculateFusionTimer(fusionType, rarity, size, state)
	local config = fusionType == 2 and EconomyConfig.Fusion2 or EconomyConfig.Fusion3
	local baseTimer = config.BaseTimerSeconds

	local rarityMult = config.TimerMultiplierByRarity[rarity] or 1
	local sizeMult = config.TimerMultiplierBySize[size] or 1
	local stateMult = config.TimerMultiplierByState[state or "Aucun"] or 1

	local finalTimer = baseTimer * rarityMult * sizeMult * stateMult
	return math.floor(finalTimer)
end

-- ============================================
-- 🎲 CHECK FUSION SUCCESS
-- ============================================
function SlimeCalculator:CheckFusionSuccess(baseRate, catalystBonus)
	local totalChance = math.min(95, baseRate + (catalystBonus or 0))
	local roll = math.random(1, 100)
	return roll <= totalChance
end

-- ============================================
-- 📊 CALCUL PRODUCTION GLOBALE
-- ============================================
function SlimeCalculator:CalculateTotalProduction(baseProduction, playerData)
	local total = baseProduction

	if playerData.ProductionUpgradeLevel > 0 then
		local upgrade = EconomyConfig.ProductionUpgrades[playerData.ProductionUpgradeLevel]
		if upgrade then
			total = total * (1 + upgrade.Bonus)
		end
	end

	total = total * (playerData.RebirthMultiplier or 1)

	if playerData.ActiveBoosts then
		for _, boost in ipairs(playerData.ActiveBoosts) do
			if boost.BoostType == "ProductionX2" and os.time() < boost.Expiration then
				total = total * 2
			elseif boost.BoostType == "ProductionX5" and os.time() < boost.Expiration then
				total = total * 5
			end
		end
	end

	return math.floor(total)
end

return SlimeCalculator
