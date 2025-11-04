-- from: ServerScriptService.CollectorVisibility

-- ServerScriptService/CollectorVisibility.server.lua
-- Force tous les CollectorGui à OFF par défaut côté serveur.
-- (Le client du propriétaire l’activera uniquement pour SA base.)

local WS = game:GetService("Workspace")
local Bases = WS:WaitForChild("Base")

local function hideGui(baseModel: Instance)
	local rec   = baseModel:FindFirstChild("Recolte")
	local main  = rec and rec:FindFirstChild("Main")
	local gui   = main and main:FindFirstChild("CollectorGui")
	if gui and gui:IsA("SurfaceGui") then
		gui.Enabled = false
	end
end

for _, b in ipairs(Bases:GetChildren()) do
	if b:IsA("Model") then hideGui(b) end
end

Bases.ChildAdded:Connect(function(ch)
	if ch:IsA("Model") then
		-- petit délai au cas où la hiérarchie se construit
		task.defer(function() hideGui(ch) end)
	end
end)
