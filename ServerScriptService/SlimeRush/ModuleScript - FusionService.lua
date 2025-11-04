-- from: ServerScriptService.SlimeRush.FusionService

-- ServerScriptService/SlimeRush/FusionService
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local M = {}

-- Types de fusions
-- Type 1: 2 slimes identiques → upgrade rareté (50% chance)
-- Type 2: 3 slimes quelconques + catalyseur → état garanti
-- Type 3: 5+ slimes rares → Omega (% chance)

function M.AttemptFusion(player, slimeIds, fusionType, catalyseur)
	if not slimeIds or #slimeIds < 2 then
		return false, "Au moins 2 slimes requis"
	end

	-- Type 1: Upgrade rareté
	if fusionType == 1 and #slimeIds == 2 then
		local roll = math.random(100)
		if roll <= 50 then
			-- Succès
			return true, {
				type = "success",
				rarity = "upgraded",
				essence = 10,
			}
		else
			-- Échec
			return false, {
				type = "fail",
				essence = 5, -- Consolation
			}
		end
	end

	-- Type 2: État (3 slimes + catalyseur)
	if fusionType == 2 and #slimeIds == 3 and catalyseur then
		-- Toujours réussi avec catalyseur
		return true, {
			type = "state_change",
			state = catalyseur,
			essence = 15,
		}
	end

	-- Type 3: Omega
	if fusionType == 3 and #slimeIds >= 5 then
		local roll = math.random(100)
		if roll <= 10 then
			return true, {
				type = "omega",
				essence = 100,
			}
		else
			return false, {
				type = "fail",
				essence = 25,
			}
		end
	end

	return false, "Type de fusion invalide"
end

-- Remotes
local remotes = RS:WaitForChild("Remotes")
local fusionRemote = remotes:WaitForChild("AttemptFusion")

fusionRemote.OnServerInvoke = function(player, slimeIds, fusionType, catalyseur)
	return M.AttemptFusion(player, slimeIds, fusionType, catalyseur)
end

return M
