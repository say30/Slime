-- from: ServerScriptService.EconomyService

-- ServerScriptService/EconomyService.lua
local DSS = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Store = DSS:GetDataStore("SR_Economy_v1")

local Economy = {}
local DEFAULT_WALLET = 100
local DEFAULT_TOTAL  = 0

local function key(uid) return ("U_%d"):format(uid) end

function Economy.Load(player)
	local ok, data = pcall(function() return Store:GetAsync(key(player.UserId)) end)
	local wallet, total = DEFAULT_WALLET, DEFAULT_TOTAL
	if ok and type(data)=="table" then
		wallet = tonumber(data.Wallet) or wallet
		total  = tonumber(data.Total) or total
	end
	if (wallet or 0) < DEFAULT_WALLET and (total or 0) == 0 then
		wallet = DEFAULT_WALLET
	end
	player:SetAttribute("Wallet", wallet)
	player:SetAttribute("TotalCollected", total)
end

function Economy.Save(player)
	local payload = {
		Wallet = player:GetAttribute("Wallet") or DEFAULT_WALLET,
		Total  = player:GetAttribute("TotalCollected") or DEFAULT_TOTAL,
	}
	pcall(function() Store:SetAsync(key(player.UserId), payload) end)
end

function Economy.AddWallet(player, amount)
	if not player then return end
	local w = (tonumber(player:GetAttribute("Wallet")) or 0) + (tonumber(amount) or 0)
	player:SetAttribute("Wallet", math.max(0, math.floor(w + 0.5)))
end

function Economy.AddCollected(player, amount)
	if not player then return end
	local t = (tonumber(player:GetAttribute("TotalCollected")) or 0) + (tonumber(amount) or 0)
	player:SetAttribute("TotalCollected", math.max(0, t))
end

function Economy.TryPurchase(player, price)
	price = math.max(0, math.floor((tonumber(price) or 0) + 0.5))
	local w = tonumber(player:GetAttribute("Wallet")) or 0
	if w + 1e-6 >= price then
		player:SetAttribute("Wallet", math.max(0, math.floor(w - price + 0.5)))
		return true
	end
	return false
end

Players.PlayerAdded:Connect(function(p) Economy.Load(p) end)
Players.PlayerRemoving:Connect(function(p) Economy.Save(p) end)

return Economy
