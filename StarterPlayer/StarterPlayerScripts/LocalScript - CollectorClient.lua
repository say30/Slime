-- from: StarterPlayer.StarterPlayerScripts.CollectorClient

-- Affiche CollectorGui/labels UNIQUEMENT pour la base du joueur local
-- et cache agressivement les autres (Enabled/Visible/Transparence).

local Players = game:GetService("Players")
local LP      = Players.LocalPlayer
local WS      = game:GetService("Workspace")

local Bases = WS:WaitForChild("Base")

local function myBase(base: Instance)
	return (tonumber(base:GetAttribute("OwnerUserId")) or 0) == LP.UserId
end

local function collectorStuff(base: Instance)
	local guis, labels = {}, {}
	for _, d in ipairs(base:GetDescendants()) do
		if d:IsA("SurfaceGui") and (d.Name == "CollectorGui"
			or d:FindFirstChild("SR_CollectLabel", true)
			or d:FindFirstChild("SR_RateLabel", true)) then
			table.insert(guis, d)
		elseif d:IsA("TextLabel") and (d.Name == "SR_CollectLabel" or d.Name == "SR_RateLabel") then
			table.insert(labels, d)
		end
	end
	return guis, labels
end

local function apply(base: Instance)
	local mine = myBase(base)
	local guis, labels = collectorStuff(base)

	for _, g in ipairs(guis) do
		g.Enabled = mine
	end
	for _, l in ipairs(labels) do
		l.Visible = mine
		if mine then
			l.TextTransparency = 0
			l.TextStrokeTransparency = 0.2
		else
			l.TextTransparency = 1
			l.TextStrokeTransparency = 1
		end
	end
end

local function hook(base: Instance)
	apply(base)
	base:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		apply(base)
	end)
	base.DescendantAdded:Connect(function()
		task.defer(function()
			apply(base)
		end)
	end)
	base.DescendantRemoving:Connect(function()
		task.defer(function()
			apply(base)
		end)
	end)
end

for _, b in ipairs(Bases:GetChildren()) do
	if b:IsA("Model") then hook(b) end
end

Bases.ChildAdded:Connect(function(ch)
	if ch:IsA("Model") then
		task.defer(function()
			hook(ch)
		end)
	end
end)

-- garde-fou périodique
task.spawn(function()
	while true do
		for _, b in ipairs(Bases:GetChildren()) do
			if b:IsA("Model") then apply(b) end
		end
		task.wait(1.5)
	end
end)
