-- from: ServerScriptService.EconomyBootstrap

-- ServerScriptService/EconomyBootstrap.server.lua
-- Assure 100 gélatines mini au premier spawn + expose Wallet/TotalCollected en Attributes.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ECON = DataStoreService:GetDataStore("SR_Economy_v1")

local DEFAULT_WALLET = 100
local DEFAULT_TOTAL  = 0

local function load(p)
	local key = "U_"..p.UserId
	local ok, data = pcall(function() return ECON:GetAsync(key) end)
	if not ok then data = nil end
	data = data or { Wallet = DEFAULT_WALLET, Total = DEFAULT_TOTAL }
	-- garantit 100 mini
	data.Wallet = math.max(tonumber(data.Wallet) or 0, DEFAULT_WALLET)
	p:SetAttribute("Wallet", data.Wallet)
	p:SetAttribute("TotalCollected", tonumber(data.Total) or DEFAULT_TOTAL)
end

local function save(p)
	local key = "U_"..p.UserId
	local payload = {
		Wallet = p:GetAttribute("Wallet") or DEFAULT_WALLET,
		Total  = p:GetAttribute("TotalCollected") or DEFAULT_TOTAL,
	}
	pcall(function() ECON:SetAsync(key, payload) end)
end

Players.PlayerAdded:Connect(load)
Players.PlayerRemoving:Connect(save)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		save(p)
	end
end)
