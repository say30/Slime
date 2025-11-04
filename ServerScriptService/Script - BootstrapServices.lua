-- from: ServerScriptService.BootstrapServices

-- ServerScriptService/BootstrapServices.lua - Charge tous les services au démarrage
-- Place: ServerScriptService
-- Type: Script

local SS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")

print("\n" .. string.rep("=", 50))
print("🚀 BOOTSTRAP SLIME RUSH")
print(string.rep("=", 50) .. "\n")

-- Attendre que les modules existent
local slimeRushFolder = SS:WaitForChild("SlimeRush")

-- Charger les services dans l'ordre
local services = {
	"InventoryService",
	"CollectionService",
	"FusionService",
	"ContractService",
	"ShopService",
	"BaseUpgradeService",
}

for i, serviceName in ipairs(services) do
	local serviceModule = slimeRushFolder:FindFirstChild(serviceName)
	if serviceModule then
		local service = require(serviceModule)
		print("[" .. i .. "/" .. #services .. "] ✅ " .. serviceName .. " chargé")
	else
		warn("[" .. i .. "/" .. #services .. "] ❌ " .. serviceName .. " introuvable!")
	end
end

print("\n" .. string.rep("=", 50))
print("✅ BOOTSTRAP COMPLET!")
print(string.rep("=", 50) .. "\n")
