-- from: ServerScriptService.SlimePromptHandler

-- ServerScriptService/SlimePromptHandler.lua
-- Place: ServerScriptService (Script)
-- Prend les slimes sur PodsSlime et les met dans l'inventaire

local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local InventoryService = require(script.Parent:WaitForChild("SlimeRush"):WaitForChild("InventoryService"))

print("🔍 SlimePromptHandler: Démarrage...")

local function setupSlime(slime)
	if not slime:IsA("Model") then return end

	local primaryPart = slime.PrimaryPart or slime:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then return end

	local existingPrompt = primaryPart:FindFirstChild("ProximityPrompt")
	if existingPrompt then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Prendre"
	prompt.ObjectText = "Slime"
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 15
	prompt.RequiresLineOfSight = false
	prompt.Parent = primaryPart

	print("✅ ProximityPrompt ajouté au slime: " .. slime.Name)

	prompt.Triggered:Connect(function(player)
		print("🎯 Prompt triggered par " .. player.Name)

		local ownerId = slime:GetAttribute("OwnerUserId")
		if not ownerId or ownerId ~= player.UserId then
			print("❌ Ce slime n'appartient pas à " .. player.Name)
			return
		end

		local podNumber = slime:GetAttribute("PodNumber")
		local baseName = slime:GetAttribute("BaseName")

		local slimeData = {
			mood = slime:GetAttribute("Mood") or "?",
			sizeName = slime:GetAttribute("SizeName") or "?",
			rarityIndex = slime:GetAttribute("RarityIndex") or 1,
			stateIndex = slime:GetAttribute("StateIndex") or 0,  -- ✅ FIX: or 0, pas or 1
			prodPerSec = slime:GetAttribute("ProdPerSec") or 1,
			price = slime:GetAttribute("Price") or 0,
			podNumber = podNumber,
			baseName = baseName,
		}

		print("📍 Slime pris depuis pod " .. (podNumber or "?") .. " base " .. (baseName or "?"))

		local ok, msg = InventoryService.AddSlimeToInventory(player, slimeData)
		if ok then
			print("✅ Slime dans l'inventaire!")
			slime:Destroy()
		else
			print("❌ Erreur: " .. msg)
		end
	end)
end

local ownedSlimes = Workspace:FindFirstChild("OwnedSlimes")
if ownedSlimes then
	for _, slime in ipairs(ownedSlimes:GetChildren()) do
		setupSlime(slime)
	end
end

if ownedSlimes then
	ownedSlimes.ChildAdded:Connect(function(slime)
		task.wait(0.1)
		setupSlime(slime)
	end)
end

print("✅ SlimePromptHandler démarré!")
