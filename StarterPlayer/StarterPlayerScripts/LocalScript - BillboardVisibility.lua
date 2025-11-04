-- from: StarterPlayer.StarterPlayerScripts.BillboardVisibility

-- BillboardVisibility.client.lua
-- Masque/affiche tout BillboardGui "SR_BB" selon distance (<= 60) du joueur.

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local WS = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local VIEW = 60

local function hrp() local c=LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end

RunService.Heartbeat:Connect(function()
	local p = hrp(); if not p then return end
	for _, inst in ipairs(WS:GetDescendants()) do
		if inst:IsA("BillboardGui") and inst.Name=="SR_BB" then
			local ad = inst.Adornee
			if ad and ad.Parent then
				inst.Enabled = (p.Position - ad.Position).Magnitude <= VIEW
			end
		end
	end
end)
