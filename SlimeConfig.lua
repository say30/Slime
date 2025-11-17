--[[
    SlimeConfig.lua
    Configuration complète des Moods, Raretés, Tailles, États
]]

local SlimeConfig = {}

-- ============================================
-- 🎨 MOODS (12 Familles)
-- ============================================
SlimeConfig.Moods = {
	{Name = "Joyeux", Color = Color3.fromHex("73C83C"), Probability = 8.33},
	{Name = "Amoureux", Color = Color3.fromHex("FF64A0"), Probability = 8.33},
	{Name = "Calme", Color = Color3.fromHex("46C8FF"), Probability = 8.33},
	{Name = "Timide", Color = Color3.fromHex("A078DC"), Probability = 8.33},
	{Name = "Colérique", Color = Color3.fromHex("FF4A3A"), Probability = 8.33},
	{Name = "Endormi", Color = Color3.fromHex("FF8C32"), Probability = 8.33},
	{Name = "Énergétique", Color = Color3.fromHex("FFD23C"), Probability = 8.33},
	{Name = "Triste", Color = Color3.fromHex("3050C8"), Probability = 8.33},
	{Name = "Sérieux", Color = Color3.fromHex("3CA858"), Probability = 8.33},
	{Name = "Rêveur", Color = Color3.fromHex("2BC7B8"), Probability = 8.33},
	{Name = "Fier", Color = Color3.fromHex("D4AF37"), Probability = 8.33},
	{Name = "Neutre", Color = Color3.fromHex("C8C8D0"), Probability = 8.34}
}

-- ============================================
-- 💎 RARETÉS (12 Niveaux) - STRICTEMENT AJUSTÉ
-- ============================================
SlimeConfig.Rarities = {
	{Name = "Commun", Color = Color3.fromHex("BDBDBD"), Multiplier = 1, Probability = 70},           -- 70% ⬆️⬆️
	{Name = "Vibrant", Color = Color3.fromHex("3CB371"), Multiplier = 3, Probability = 20},        -- 20%
	{Name = "Rare", Color = Color3.fromHex("1E90FF"), Multiplier = 7, Probability = 7},              -- 7% ⬇️
	{Name = "Arcane", Color = Color3.fromHex("6A5ACD"), Multiplier = 18, Probability = 2},           -- 2% ⬇️
	{Name = "Épique", Color = Color3.fromHex("8A2BE2"), Multiplier = 50, Probability = 0.7},         -- 0.7% ⬇️
	{Name = "Légendaire", Color = Color3.fromHex("FFD700"), Multiplier = 140, Probability = 0.2},    -- 0.2% ⬇️
	{Name = "Mythique", Color = Color3.fromHex("FF4500"), Multiplier = 400, Probability = 0.07},     -- 0.07% ⬇️
	{Name = "Occulte", Color = Color3.fromHex("2F4F4F"), Multiplier = 1100, Probability = 0.02},     -- 0.02% ⬇️
	{Name = "Céleste", Color = Color3.fromHex("87CEFA"), Multiplier = 3000, Probability = 0.008},    -- 0.008% ⬇️
	{Name = "Abyssal", Color = Color3.fromHex("4B0082"), Multiplier = 8500, Probability = 0.002},    -- 0.002% ⬇️
	{Name = "Prismatique", Color = Color3.fromHex("FF00FF"), Multiplier = 25000, Probability = 0.0008}, -- 0.0008% ⬇️
	{Name = "Oméga", Color = Color3.fromHex("FFFFFF"), Multiplier = 75000, Probability = 0.0002}     -- 0.0002% ⬇️
}

-- ============================================
-- 📏 TAILLES (5 Niveaux)
-- ============================================
SlimeConfig.Sizes = {
	{Name = "Micro", Scale = 0.5, Multiplier = 1, Probability = 45},
	{Name = "Petit", Scale = 0.8, Multiplier = 3, Probability = 30},
	{Name = "Moyen", Scale = 1.2, Multiplier = 12, Probability = 17},
	{Name = "Grand", Scale = 1.8, Multiplier = 45, Probability = 6},
	{Name = "Titan", Scale = 2.5, Multiplier = 180, Probability = 2}
}

-- ============================================
-- ⚡ ÉTATS (6 Niveaux)
-- ============================================
SlimeConfig.States = {
	{Name = "Aucun", Icon = "", Multiplier = 1},
	{Name = "Pur", Icon = "✨", Multiplier = 3},
	{Name = "Muté", Icon = "🧬", Multiplier = 5},
	{Name = "Fusionné", Icon = "⚡", Multiplier = 8},
	{Name = "Cristallisé", Icon = "💎", Multiplier = 12},
	{Name = "Corrompu", Icon = "☠️", Multiplier = 20}
}

-- ============================================
-- 🔢 HELPERS
-- ============================================
function SlimeConfig:GetMoodByName(name)
	for _, mood in ipairs(self.Moods) do
		if mood.Name == name then
			return mood
		end
	end
	return nil
end

function SlimeConfig:GetRarityByName(name)
	for _, rarity in ipairs(self.Rarities) do
		if rarity.Name == name then
			return rarity
		end
	end
	return nil
end

function SlimeConfig:GetSizeByName(name)
	for _, size in ipairs(self.Sizes) do
		if size.Name == name then
			return size
		end
	end
	return nil
end

function SlimeConfig:GetStateByName(name)
	for _, state in ipairs(self.States) do
		if state.Name == name then
			return state
		end
	end
	return nil
end

-- ============================================
-- 🎲 SÉLECTION ALÉATOIRE
-- ============================================
function SlimeConfig:GetRandomMood()
	local rand = math.random() * 100
	local cumulative = 0

	for _, mood in ipairs(self.Moods) do
		cumulative = cumulative + mood.Probability
		if rand <= cumulative then
			return mood
		end
	end

	return self.Moods[1]
end

function SlimeConfig:GetRandomRarity()
	local rand = math.random() * 100
	local cumulative = 0

	for _, rarity in ipairs(self.Rarities) do
		cumulative = cumulative + rarity.Probability
		if rand <= cumulative then
			return rarity
		end
	end

	return self.Rarities[1]
end

function SlimeConfig:GetRandomSize()
	local rand = math.random() * 100
	local cumulative = 0

	for _, size in ipairs(self.Sizes) do
		cumulative = cumulative + size.Probability
		if rand <= cumulative then
			return size
		end
	end

	return self.Sizes[1]
end

return SlimeConfig
