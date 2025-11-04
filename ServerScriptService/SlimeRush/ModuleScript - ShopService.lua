-- from: ServerScriptService.SlimeRush.ShopService

-- ServerScriptService/SlimeRush/ShopService
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local M = {}

-- Catalyseurs
local shopItems = {
	{id=1, name="Cristal Sombre", price=200, essence=20, state="Corrompu"},
	{id=2, name="Sérum Instable", price=200, essence=20, state="Muté"},
	{id=3, name="Gemme Glaciale", price=200, essence=20, state="Cristallisé"},
	{id=4, name="Orbe Éthéré", price=300, essence=30, state="Fusionné"},
	{id=5, name="Noyau Essence", price=500, essence=50, boostRarity=0.3},
	{id=6, name="Pierre de Chance", price=1000, essence=100, doubleProd=true},
}

function M.GetShop()
	return shopItems
end

function M.GetItemById(itemId)
	for _, item in ipairs(shopItems) do
		if item.id == itemId then
			return item
		end
	end
	return nil
end

function M.BuyItem(player, itemId)
	local item = M.GetItemById(itemId)
	if not item then
		return false, "Item introuvable"
	end
	-- Economy va check les ressources
	return true, item
end

-- Remotes
local remotes = RS:WaitForChild("Remotes")
local shopRemote = remotes:WaitForChild("GetShop")
local buyRemote = remotes:WaitForChild("BuyShopItem")

shopRemote.OnServerInvoke = function(player)
	return M.GetShop()
end

buyRemote.OnServerInvoke = function(player, itemId)
	return M.BuyItem(player, itemId)
end

return M
