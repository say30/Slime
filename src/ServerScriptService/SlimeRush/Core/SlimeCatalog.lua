local HttpService = game:GetService("HttpService")

local SlimeCatalog = {}

local Moods = {
    "Jovial", "Brooding", "Spunky", "Dreamy", "Icy", "Fiery", "Wistful", "Hyper", "Arcane", "Stoic", "Cosmic", "Mythic"
}

local States = {
    "Neutral",
    "Charged",
    "Radiant",
    "Chaotic",
    "Ethereal",
}

local Sizes = {"Mini", "Standard", "Chonky", "Grand", "Titan"}

local BaseStateTemplates = {
    Neutral = {State = 1, rarityOffset = 0},
    Charged = {State = 2, rarityOffset = 1},
    Radiant = {State = 3, rarityOffset = 2},
    Chaotic = {State = 4, rarityOffset = 3},
    Ethereal = {State = 5, rarityOffset = 4},
}

local function generateArchetype(overrides)
    local archetype = {
        Id = HttpService:GenerateGUID(false),
        Mood = overrides.Mood or math.random(1, #Moods),
        Rarity = overrides.Rarity or math.random(1, 3),
        Size = overrides.Size or math.random(1, #Sizes),
        State = overrides.State or 1,
        Traits = overrides.Traits or {},
    }

    return archetype
end

function SlimeCatalog.rollArchetype(profile)
    local rarityWeights = {60, 26, 10, 3, 1}
    local cumulative = {}
    local total = 0
    for _, weight in ipairs(rarityWeights) do
        total = total + weight
        table.insert(cumulative, total)
    end

    local roll = math.random(1, total)
    local rarity = 1
    for index, threshold in ipairs(cumulative) do
        if roll <= threshold then
            rarity = index
            break
        end
    end

    return generateArchetype({
        Rarity = rarity,
    })
end

function SlimeCatalog.mergeSlimes(slimes, template)
    local avgMood = 0
    local avgSize = 0
    local avgRarity = 0
    for _, slime in ipairs(slimes) do
        avgMood = avgMood + slime.Mood
        avgSize = avgSize + slime.Size
        avgRarity = avgRarity + slime.Rarity
    end

    avgMood = math.clamp(math.floor(avgMood / #slimes + 0.5), 1, #Moods)
    avgSize = math.clamp(math.floor(avgSize / #slimes + 0.5), 1, #Sizes)
    avgRarity = math.clamp(math.floor(avgRarity / #slimes + (template.rarityOffset or 0)), 1, 12)

    local newSlime = generateArchetype({
        Mood = avgMood,
        Size = avgSize,
        Rarity = avgRarity,
        State = template.State,
    })

    newSlime.SourceIds = {}
    for _, slime in ipairs(slimes) do
        table.insert(newSlime.SourceIds, slime.Id)
    end

    return newSlime
end

function SlimeCatalog.getStateTemplate(index)
    local stateName = States[index] or "Neutral"
    return BaseStateTemplates[stateName] or BaseStateTemplates.Neutral
end

function SlimeCatalog.buildSlimedex()
    local dex = {}
    for moodIndex = 1, #Moods do
        dex[moodIndex] = {}
        for rarity = 1, 12 do
            dex[moodIndex][rarity] = {}
            for size = 1, #Sizes do
                dex[moodIndex][rarity][size] = {}
                for state = 1, #States do
                    table.insert(dex[moodIndex][rarity][size], {
                        Mood = moodIndex,
                        Rarity = rarity,
                        Size = size,
                        State = state,
                    })
                end
            end
        end
    end
    return dex
end

SlimeCatalog.Slimedex = SlimeCatalog.buildSlimedex()
SlimeCatalog.Moods = Moods
SlimeCatalog.States = States
SlimeCatalog.Sizes = Sizes

return SlimeCatalog
