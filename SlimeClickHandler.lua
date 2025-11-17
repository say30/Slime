--[[
    SlimeClickHandler.lua
    VERSION SÉCURISÉE avec vérifications
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local PurchaseSlimeEvent = RemoteEvents:WaitForChild("PurchaseSlimeEvent")

print("[SlimeClick] ✅ Service chargé - Achat direct activé")

ProximityPromptService.PromptTriggered:Connect(function(promptObject, playerWhoTriggered)
	if playerWhoTriggered ~= player then return end

	local basePart = promptObject.Parent
	local slimeModel = basePart and basePart.Parent

	if not slimeModel or not slimeModel:IsA("Model") then return end
	if not slimeModel.Name:match("^LocalSlime_") then return end

	local mood = slimeModel:GetAttribute("Mood")
	local rarity = slimeModel:GetAttribute("Rarity")
	local size = slimeModel:GetAttribute("Size")
	local production = slimeModel:GetAttribute("Production")
	local cost = slimeModel:GetAttribute("Cost")

	if not mood or not rarity or not size or not production or not cost then
		warn("[SlimeClick] ❌ Attributs manquants")
		return
	end

	-- Récupérer la position avec vérifications
	local slimePosition

	-- Méthode 1 : GetPivot
	local success1, pivot = pcall(function()
		return slimeModel:GetPivot()
	end)

	if success1 and pivot then
		slimePosition = pivot.Position
		print("[SlimeClick] 📍 Position (GetPivot):", slimePosition)
	else
		-- Méthode 2 : PrimaryPart
		local primaryPart = slimeModel.PrimaryPart
		if primaryPart then
			slimePosition = primaryPart.Position
			print("[SlimeClick] 📍 Position (PrimaryPart):", slimePosition)
		else
			-- Méthode 3 : Première BasePart
			local firstPart = slimeModel:FindFirstChildWhichIsA("BasePart")
			if firstPart then
				slimePosition = firstPart.Position
				print("[SlimeClick] 📍 Position (FirstPart):", slimePosition)
			else
				warn("[SlimeClick] ❌ Impossible de trouver la position du slime")
				return
			end
		end
	end

	if not slimePosition then
		warn("[SlimeClick] ❌ Position est nil")
		return
	end

	print("[SlimeClick] 🛒 Achat:", mood, size, rarity, "-", cost, "gélatines")

	-- Envoyer au serveur
	PurchaseSlimeEvent:FireServer({
		mood = mood,
		rarity = rarity,
		size = size,
		production = production,
		cost = cost,
		position = slimePosition
	})

	-- Détruire le slime local
	slimeModel:Destroy()

	print("[SlimeClick] ✅ Demande envoyée avec position:", slimePosition)
end)

print("[SlimeClickHandler] ✅ Gestionnaire activé")
