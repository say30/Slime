--[[
    ContractConfig.lua
    40 contrats avec objectifs fixes et récompenses dynamiques
]]

local ContractConfig = {}

-- ============================================
-- 📊 CONFIGURATION DES CONTRATS (40 TOTAL)
-- ============================================

ContractConfig.Contracts = {
	-- ============================================
	-- 🟢 FACILES (16 contrats) - 2-3% target
	-- ============================================
	{
		id = "buy_slimes_easy_1",
		tier = "Easy",
		type = "BuySlimes",
		objective = {
			target = 5,
			description = "Acheter {target} slimes"
		},
		rewards = {
			gelatinPercent = 0.02,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "buy_slimes_easy_2",
		tier = "Easy",
		type = "BuySlimes",
		objective = {
			target = 10,
			description = "Acheter {target} slimes"
		},
		rewards = {
			gelatinPercent = 0.03,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "collect_gelatin_easy_1",
		tier = "Easy",
		type = "CollectGelatin",
		objective = {
			target = 0.5, -- 0.5h de production
			description = "Collecter de la gélatine (30 min de production)"
		},
		rewards = {
			gelatinPercent = 0.025,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "collect_gelatin_easy_2",
		tier = "Easy",
		type = "CollectGelatin",
		objective = {
			target = 1, -- 1h de production
			description = "Collecter de la gélatine (1h de production)"
		},
		rewards = {
			gelatinPercent = 0.03,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "sell_slimes_easy_1",
		tier = "Easy",
		type = "SellSlimes",
		objective = {
			target = 3,
			description = "Vendre {target} slimes"
		},
		rewards = {
			gelatinPercent = 0.02,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "sell_slimes_easy_2",
		tier = "Easy",
		type = "SellSlimes",
		objective = {
			target = 5,
			description = "Vendre {target} slimes"
		},
		rewards = {
			gelatinPercent = 0.025,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "like_bases_easy",
		tier = "Easy",
		type = "LikeBases",
		objective = {
			target = 3,
			description = "Liker {target} bases d'autres joueurs"
		},
		rewards = {
			gelatinPercent = 0.02,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "pods_slimes_easy_1",
		tier = "Easy",
		type = "PodsSlimes",
		objective = {
			target = 5,
			description = "Avoir {target} slimes sur les pods"
		},
		rewards = {
			gelatinPercent = 0.025,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "pods_slimes_easy_2",
		tier = "Easy",
		type = "PodsSlimes",
		objective = {
			target = 10,
			description = "Avoir {target} slimes sur les pods"
		},
		rewards = {
			gelatinPercent = 0.03,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "playtime_easy",
		tier = "Easy",
		type = "PlayTime",
		objective = {
			target = 10, -- 10 minutes
			description = "Jouer pendant {target} minutes"
		},
		rewards = {
			gelatinPercent = 0.02,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "buy_common_easy",
		tier = "Easy",
		type = "BuyRarity",
		objective = {
			target = "Commun",
			count = 5,
			description = "Acheter {count} slimes {target}"
		},
		rewards = {
			gelatinPercent = 0.02,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "buy_vibrant_easy",
		tier = "Easy",
		type = "BuyRarity",
		objective = {
			target = "Vibrant",
			count = 3,
			description = "Acheter {count} slimes {target}"
		},
		rewards = {
			gelatinPercent = 0.025,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "mood_collection_easy_1",
		tier = "Easy",
		type = "SameMood",
		objective = {
			target = 3,
			description = "Avoir {target} slimes du même Mood sur pods"
		},
		rewards = {
			gelatinPercent = 0.025,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "mood_collection_easy_2",
		tier = "Easy",
		type = "SameMood",
		objective = {
			target = 5,
			description = "Avoir {target} slimes du même Mood sur pods"
		},
		rewards = {
			gelatinPercent = 0.03,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "buy_micro_easy",
		tier = "Easy",
		type = "BuySize",
		objective = {
			target = "Micro",
			count = 5,
			description = "Acheter {count} slimes {target}"
		},
		rewards = {
			gelatinPercent = 0.02,
			essencePercent = 0,
			catalysts = {}
		}
	},
	{
		id = "buy_petit_easy",
		tier = "Easy",
		type = "BuySize",
		objective = {
			target = "Petit",
			count = 3,
			description = "Acheter {count} slimes {target}"
		},
		rewards = {
			gelatinPercent = 0.025,
			essencePercent = 0,
			catalysts = {}
		}
	},

	-- ============================================
	-- 🟡 MOYENS (16 contrats) - 6-8% target
	-- ============================================
	{
		id = "fuse_2_medium_1",
		tier = "Medium",
		type = "Fuse2",
		objective = {
			target = 2,
			description = "Réussir {target} fusions à 2"
		},
		rewards = {
			gelatinPercent = 0.06,
			essencePercent = 0.01,
			catalysts = {}
		}
	},
	{
		id = "fuse_2_medium_2",
		tier = "Medium",
		type = "Fuse2",
		objective = {
			target = 3,
			description = "Réussir {target} fusions à 2"
		},
		rewards = {
			gelatinPercent = 0.07,
			essencePercent = 0.015,
			catalysts = {
				{type = "Minor", quantity = 1}
			}
		}
	},
	{
		id = "fuse_3_medium_1",
		tier = "Medium",
		type = "Fuse3",
		objective = {
			target = 1,
			description = "Réussir {target} fusion à 3"
		},
		rewards = {
			gelatinPercent = 0.065,
			essencePercent = 0.012,
			catalysts = {}
		}
	},
	{
		id = "fuse_3_medium_2",
		tier = "Medium",
		type = "Fuse3",
		objective = {
			target = 2,
			description = "Réussir {target} fusions à 3"
		},
		rewards = {
			gelatinPercent = 0.075,
			essencePercent = 0.018,
			catalysts = {
				{type = "Minor", quantity = 1}
			}
		}
	},
	{
		id = "collect_gelatin_medium_1",
		tier = "Medium",
		type = "CollectGelatin",
		objective = {
			target = 2, -- 2h de production
			description = "Collecter de la gélatine (2h de production)"
		},
		rewards = {
			gelatinPercent = 0.07,
			essencePercent = 0.01,
			catalysts = {}
		}
	},
	{
		id = "collect_gelatin_medium_2",
		tier = "Medium",
		type = "CollectGelatin",
		objective = {
			target = 3, -- 3h de production
			description = "Collecter de la gélatine (3h de production)"
		},
		rewards = {
			gelatinPercent = 0.08,
			essencePercent = 0.015,
			catalysts = {}
		}
	},
	{
		id = "buy_upgrades_medium",
		tier = "Medium",
		type = "BuyUpgrades",
		objective = {
			target = 1,
			description = "Acheter {target} upgrade (Base/Production/Inventaire)"
		},
		rewards = {
			gelatinPercent = 0.06,
			essencePercent = 0.02,
			catalysts = {}
		}
	},
	{
		id = "buy_rare_medium",
		tier = "Medium",
		type = "BuyRarity",
		objective = {
			target = "Rare",
			count = 1,
			description = "Acheter {count} slime {target}"
		},
		rewards = {
			gelatinPercent = 0.07,
			essencePercent = 0.015,
			catalysts = {
				{type = "Minor", quantity = 1}
			}
		}
	},
	{
		id = "buy_arcane_medium",
		tier = "Medium",
		type = "BuyRarity",
		objective = {
			target = "Arcane",
			count = 1,
			description = "Acheter {count} slime {target}"
		},
		rewards = {
			gelatinPercent = 0.075,
			essencePercent = 0.018,
			catalysts = {}
		}
	},
	{
		id = "production_medium_1",
		tier = "Medium",
		type = "ReachProduction",
		objective = {
			target = 0.05, -- 5% de la prod actuelle en plus
			description = "Atteindre une production +5% supérieure"
		},
		rewards = {
			gelatinPercent = 0.065,
			essencePercent = 0.012,
			catalysts = {}
		}
	},
	{
		id = "production_medium_2",
		tier = "Medium",
		type = "ReachProduction",
		objective = {
			target = 0.1, -- 10% de la prod actuelle en plus
			description = "Atteindre une production +10% supérieure"
		},
		rewards = {
			gelatinPercent = 0.08,
			essencePercent = 0.02,
			catalysts = {}
		}
	},
	{
		id = "playtime_medium",
		tier = "Medium",
		type = "PlayTime",
		objective = {
			target = 30, -- 30 minutes
			description = "Jouer pendant {target} minutes"
		},
		rewards = {
			gelatinPercent = 0.06,
			essencePercent = 0.01,
			catalysts = {}
		}
	},
	{
		id = "like_bases_medium",
		tier = "Medium",
		type = "LikeBases",
		objective = {
			target = 5,
			description = "Liker {target} bases d'autres joueurs"
		},
		rewards = {
			gelatinPercent = 0.065,
			essencePercent = 0.01,
			catalysts = {}
		}
	},
	{
		id = "sell_slimes_medium",
		tier = "Medium",
		type = "SellSlimes",
		objective = {
			target = 10,
			description = "Vendre {target} slimes"
		},
		rewards = {
			gelatinPercent = 0.07,
			essencePercent = 0.015,
			catalysts = {}
		}
	},
	{
		id = "buy_moyen_medium",
		tier = "Medium",
		type = "BuySize",
		objective = {
			target = "Moyen",
			count = 2,
			description = "Acheter {count} slimes {target}"
		},
		rewards = {
			gelatinPercent = 0.065,
			essencePercent = 0.012,
			catalysts = {}
		}
	},
	{
		id = "pods_slimes_medium",
		tier = "Medium",
		type = "PodsSlimes",
		objective = {
			target = 15,
			description = "Avoir {target} slimes sur les pods"
		},
		rewards = {
			gelatinPercent = 0.07,
			essencePercent = 0.01,
			catalysts = {}
		}
	},

	-- ============================================
	-- 🔴 DIFFICILES (8 contrats) - 12-18% target
	-- ============================================
	{
		id = "buy_epique_hard",
		tier = "Hard",
		type = "BuyRarity",
		objective = {
			target = "Épique",
			count = 1,
			description = "Acheter {count} slime {target}"
		},
		rewards = {
			gelatinPercent = 0.12,
			essencePercent = 0.03,
			catalysts = {
				{type = "Minor", quantity = 1}
			}
		}
	},
	{
		id = "buy_legendaire_hard",
		tier = "Hard",
		type = "BuyRarity",
		objective = {
			target = "Légendaire",
			count = 1,
			description = "Acheter {count} slime {target}"
		},
		rewards = {
			gelatinPercent = 0.15,
			essencePercent = 0.04,
			catalysts = {
				{type = "Stable", quantity = 1}
			}
		}
	},
	{
		id = "fuse_state_hard_1",
		tier = "Hard",
		type = "FuseState",
		objective = {
			targetState = "Fusionné",
			description = "Réussir une fusion donnant l'état {targetState}"
		},
		rewards = {
			gelatinPercent = 0.13,
			essencePercent = 0.035,
			catalysts = {
				{type = "Minor", quantity = 2}
			}
		}
	},
	{
		id = "fuse_state_hard_2",
		tier = "Hard",
		type = "FuseState",
		objective = {
			targetState = "Cristallisé",
			description = "Réussir une fusion donnant l'état {targetState}"
		},
		rewards = {
			gelatinPercent = 0.16,
			essencePercent = 0.045,
			catalysts = {
				{type = "Stable", quantity = 1}
			}
		}
	},
	{
		id = "production_hard",
		tier = "Hard",
		type = "ReachProduction",
		objective = {
			target = 0.25, -- 25% de la prod actuelle en plus
			description = "Atteindre une production +25% supérieure"
		},
		rewards = {
			gelatinPercent = 0.14,
			essencePercent = 0.04,
			catalysts = {
				{type = "Minor", quantity = 1}
			}
		}
	},
	{
		id = "sell_value_hard",
		tier = "Hard",
		type = "SellValue",
		objective = {
			target = 0.5, -- 50% du target
			description = "Vendre pour une valeur totale importante"
		},
		rewards = {
			gelatinPercent = 0.15,
			essencePercent = 0.038,
			catalysts = {}
		}
	},
	{
		id = "mood_collection_hard",
		tier = "Hard",
		type = "SameMood",
		objective = {
			target = 10,
			description = "Avoir {target} slimes du même Mood sur pods"
		},
		rewards = {
			gelatinPercent = 0.17,
			essencePercent = 0.042,
			catalysts = {
				{type = "Minor", quantity = 1}
			}
		}
	},
	{
		id = "playtime_hard",
		tier = "Hard",
		type = "PlayTime",
		objective = {
			target = 60, -- 1h
			description = "Jouer pendant {target} minutes"
		},
		rewards = {
			gelatinPercent = 0.18,
			essencePercent = 0.05,
			catalysts = {
				{type = "Minor", quantity = 2}
			}
		}
	}
}

-- ============================================
-- 🔧 HELPERS
-- ============================================

-- Obtenir tous les contrats d'un tier
function ContractConfig:GetContractsByTier(tier)
	local contracts = {}
	for _, contract in ipairs(self.Contracts) do
		if contract.tier == tier then
			table.insert(contracts, contract)
		end
	end
	return contracts
end

-- Obtenir un contrat par ID
function ContractConfig:GetContractById(id)
	for _, contract in ipairs(self.Contracts) do
		if contract.id == id then
			return contract
		end
	end
	return nil
end

-- Obtenir un contrat aléatoire d'un tier
function ContractConfig:GetRandomContract(tier)
	local tierContracts = self:GetContractsByTier(tier)
	if #tierContracts == 0 then return nil end
	return tierContracts[math.random(1, #tierContracts)]
end

print("[ContractConfig] ✅ Module chargé - 40 contrats disponibles")

return ContractConfig
