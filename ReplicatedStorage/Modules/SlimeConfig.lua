-- ========================================
-- SLIME RUSH - SLIME CONFIGURATION
-- ModuleScript
-- Localisation: ReplicatedStorage/Modules/SlimeConfig
-- ========================================

local SlimeConfig = {}

-- ========================================
-- MOODS (Familles)
-- ========================================
SlimeConfig.Moods = {
    {Name = "Joyeux", Color = Color3.fromHex("#73C83C"), Icon = "😊"},
    {Name = "Amoureux", Color = Color3.fromHex("#FF64A0"), Icon = "😍"},
    {Name = "Calme", Color = Color3.fromHex("#46C8FF"), Icon = "😌"},
    {Name = "Timide", Color = Color3.fromHex("#A078DC"), Icon = "😳"},
    {Name = "Colérique", Color = Color3.fromHex("#FF4A3A"), Icon = "😠"},
    {Name = "Endormi", Color = Color3.fromHex("#FF8C32"), Icon = "😴"},
    {Name = "Énergique", Color = Color3.fromHex("#FFD23C"), Icon = "⚡"},
    {Name = "Triste", Color = Color3.fromHex("#3050C8"), Icon = "😢"},
    {Name = "Sérieux", Color = Color3.fromHex("#3CA858"), Icon = "😐"},
    {Name = "Rêveur", Color = Color3.fromHex("#2BC7B8"), Icon = "💭"},
    {Name = "Fier", Color = Color3.fromHex("#D4AF37"), Icon = "😎"},
    {Name = "Neutre", Color = Color3.fromHex("#C8C8D0"), Icon = "😑"}
}

-- ========================================
-- RARETÉS
-- ========================================
SlimeConfig.Rarities = {
    {Name = "Commun", Color = Color3.fromHex("#BDBDBD"), Multiplier = 1},
    {Name = "Vibrant", Color = Color3.fromHex("#3CB371"), Multiplier = 2.5},
    {Name = "Rare", Color = Color3.fromHex("#1E90FF"), Multiplier = 7},
    {Name = "Arcane", Color = Color3.fromHex("#6A5ACD"), Multiplier = 18},
    {Name = "Épique", Color = Color3.fromHex("#8A2BE2"), Multiplier = 50},
    {Name = "Légendaire", Color = Color3.fromHex("#FFD700"), Multiplier = 140},
    {Name = "Mythique", Color = Color3.fromHex("#FF4500"), Multiplier = 400},
    {Name = "Occulte", Color = Color3.fromHex("#2F4F4F"), Multiplier = 1100},
    {Name = "Céleste", Color = Color3.fromHex("#87CEFA"), Multiplier = 3000},
    {Name = "Abyssal", Color = Color3.fromHex("#4B0082"), Multiplier = 8500},
    {Name = "Prismatique", Color = Color3.fromHex("#FF00FF"), Multiplier = 25000},
    {Name = "Oméga", Color = Color3.fromHex("#FFFFFF"), Multiplier = 75000}
}

-- ========================================
-- TAILLES
-- ========================================
SlimeConfig.Sizes = {
    {Name = "Micro", Scale = 0.5, Multiplier = 1},
    {Name = "Petit", Scale = 0.8, Multiplier = 3.5},
    {Name = "Moyen", Scale = 1.2, Multiplier = 12},
    {Name = "Grand", Scale = 1.8, Multiplier = 45},
    {Name = "Titan", Scale = 2.5, Multiplier = 180}
}

-- ========================================
-- ÉTATS (Uniquement par fusion)
-- ========================================
SlimeConfig.States = {
    {Name = "Aucun", Icon = "", FusionMultiplier = 1},
    {Name = "Pur", Icon = "✨", FusionMultiplier = 3},
    {Name = "Muté", Icon = "🧬", FusionMultiplier = 5},
    {Name = "Fusionné", Icon = "⚡", FusionMultiplier = 8},
    {Name = "Cristallisé", Icon = "💎", FusionMultiplier = 12},
    {Name = "Corrompu", Icon = "☠️", FusionMultiplier = 20}
}

-- ========================================
-- PROBABILITÉS DE SPAWN LOCAL
-- ========================================
SlimeConfig.SpawnProbabilities = {
    Rarities = {
        35,    -- Commun 35%
        25,    -- Vibrant 25%
        18,    -- Rare 18%
        10,    -- Arcane 10%
        6,     -- Épique 6%
        3.5,   -- Légendaire 3.5%
        1.5,   -- Mythique 1.5%
        0.6,   -- Occulte 0.6%
        0.25,  -- Céleste 0.25%
        0.1,   -- Abyssal 0.1%
        0.04,  -- Prismatique 0.04%
        0.01   -- Oméga 0.01%
    },

    Sizes = {
        45,  -- Micro 45%
        30,  -- Petit 30%
        17,  -- Moyen 17%
        6,   -- Grand 6%
        2    -- Titan 2%
    },

    -- Moods : Équiprobabilité (8.33% chacun)
}

-- ========================================
-- CALCUL PRODUCTION & COÛT
-- ========================================
function SlimeConfig.GetProduction(sizeIndex, rarityIndex)
    local sizeMult = SlimeConfig.Sizes[sizeIndex].Multiplier
    local rarityMult = SlimeConfig.Rarities[rarityIndex].Multiplier
    return sizeMult * rarityMult -- gélatine/seconde
end

function SlimeConfig.GetCost(sizeIndex, rarityIndex)
    local production = SlimeConfig.GetProduction(sizeIndex, rarityIndex)
    return math.floor(production * 80) -- Coût = Production × 80
end

-- ========================================
-- SPAWN SETTINGS
-- ========================================
SlimeConfig.SpawnSettings = {
    SpawnInterval = 8, -- 1 slime toutes les 8 secondes
    MaxSlimesOnPlate = 15, -- Max 15 slimes sur le plateau en même temps
    SpawnRadius = 130, -- Rayon autour de MapCenter
    DropHeight = 50, -- Hauteur de spawn au-dessus de DropPlate
    FallSpeed = 2, -- Vitesse de descente (studs/s)
}

-- ========================================
-- BILLBOARDS
-- ========================================
SlimeConfig.BillboardSettings = {
    Size = UDim2.new(0, 200, 0, 150),
    StudsOffset = Vector3.new(0, 3, 0),
    MaxDistance = 50,
    AlwaysOnTop = true
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Obtenir mood aléatoire
function SlimeConfig.GetRandomMood()
    return math.random(1, #SlimeConfig.Moods)
end

-- Obtenir rareté aléatoire avec probabilités
function SlimeConfig.GetRandomRarity()
    local rand = math.random() * 100
    local cumulative = 0

    for i, prob in ipairs(SlimeConfig.SpawnProbabilities.Rarities) do
        cumulative = cumulative + prob
        if rand <= cumulative then
            return i
        end
    end

    return 1 -- Fallback Commun
end

-- Obtenir taille aléatoire avec probabilités
function SlimeConfig.GetRandomSize()
    local rand = math.random() * 100
    local cumulative = 0

    for i, prob in ipairs(SlimeConfig.SpawnProbabilities.Sizes) do
        cumulative = cumulative + prob
        if rand <= cumulative then
            return i
        end
    end

    return 1 -- Fallback Micro
end

-- Générer slime aléatoire complet
function SlimeConfig.GenerateRandomSlime()
    return {
        Mood = SlimeConfig.GetRandomMood(),
        Rarity = SlimeConfig.GetRandomRarity(),
        Size = SlimeConfig.GetRandomSize(),
        State = 1, -- Aucun état au spawn
        UniqueID = game:GetService("HttpService"):GenerateGUID(false)
    }
end

-- Obtenir SlimeDex Key (pour tracking collection)
function SlimeConfig.GetSlimeDexKey(mood, rarity, size, state)
    return string.format("%d_%d_%d_%d", mood, rarity, size, state)
end

-- Calculer total variétés
function SlimeConfig.GetTotalVarieties()
    return #SlimeConfig.Moods * #SlimeConfig.Rarities * #SlimeConfig.Sizes * #SlimeConfig.States
end

return SlimeConfig
