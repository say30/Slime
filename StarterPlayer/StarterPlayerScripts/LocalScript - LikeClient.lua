-- from: StarterPlayer.StarterPlayerScripts.LikeClient

-- StarterPlayer/StarterPlayerScripts/LikeClient.lua
-- Relie chaque bouton "LikeButton" des panneaux et envoie LikeRequest(baseId)

local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")

local LikeRequest = RS:WaitForChild("Remotes"):WaitForChild("Bases"):WaitForChild("LikeRequest")
local BasesFolder = WS:WaitForChild("Base")

local function baseIdFrom(inst: Instance)
	local m = inst
	while m and m ~= BasesFolder do
		if m:IsA("Model") and string.match(m.Name, "^Base%s*%d+") then
			return tonumber(string.match(m.Name, "%d+"))
		end
		m = m.Parent
	end
	return nil
end

local function hook(btn: Instance)
	if not btn or not btn:IsA("TextButton") then return end
	if btn:GetAttribute("Hooked") then return end
	btn:SetAttribute("Hooked", true)
	btn.MouseButton1Click:Connect(function()
		local id = baseIdFrom(btn)
		if id then
			LikeRequest:FireServer(id)
		end
	end)
end

local function scanOneBase(baseModel: Instance)
	local panneau = baseModel:FindFirstChild("Panneau")
	if not panneau then return end
	local part = panneau:FindFirstChild("Contour") and panneau.Contour:FindFirstChild("Part")
	if not part then part = panneau:FindFirstChild("Part", true) end
	if not part then return end
	local surface = part:FindFirstChildOfClass("SurfaceGui")
	if not surface then return end
	local likeBtn = surface:FindFirstChild("LikeButton", true)
	if likeBtn then hook(likeBtn) end
end

for _, b in ipairs(BasesFolder:GetChildren()) do
	if b:IsA("Model") and string.match(b.Name, "^Base%s*%d+") then
		scanOneBase(b)
	end
end

BasesFolder.ChildAdded:Connect(function(child)
	task.wait()
	if child:IsA("Model") then scanOneBase(child) end
end)
