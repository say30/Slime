-- from: ServerScriptService.CollectService

-- ServerScriptService/CollectService
-- Agrège la production des slimes POSÉS SUR PODS d'une base,
-- ajoute un ENTIER par seconde (ex. 6/s -> +6, +12, +18...),
-- met à jour SR_CollectLabel / SR_RateLabel,
-- collecte via Hitbox (owner only),
-- et laisse les CollectorGui désactivés côté serveur (le client du proprio les active).

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local WS      = game:GetService("Workspace")

local Balance = require(RS:WaitForChild("Modules"):WaitForChild("GameBalance"))
local Economy = require(script.Parent:WaitForChild("EconomyService"))

local BasesFolder = WS:WaitForChild("Base")
local OwnedFolder = WS:FindFirstChild("OwnedSlimes") or Instance.new("Folder", WS)
OwnedFolder.Name  = "OwnedSlimes"

-- ------- utils -------
local function short(n:number): string
	if n >= 1e12 then return string.format("%.2fT", n/1e12)
	elseif n >= 1e9 then return string.format("%.2fB", n/1e9)
	elseif n >= 1e6 then return string.format("%.2fM", n/1e6)
	elseif n >= 1e3 then return string.format("%.2fK", n/1e3)
	else return tostring(math.floor(n+0.5)) end
end
local function ownerIdOf(base: Instance) return tonumber(base:GetAttribute("OwnerUserId")) or 0 end

local function findCollectorGui(baseModel: Instance)
	local rec  = baseModel:FindFirstChild("Recolte")
	local main = rec and rec:FindFirstChild("Main")
	local gui  = main and main:FindFirstChild("CollectorGui")
	local lblC = gui and gui:FindFirstChild("SR_CollectLabel")
	local lblR = gui and gui:FindFirstChild("SR_RateLabel")
	return gui, lblC, lblR
end

-- Masquer tous les CollectorGui côté serveur
for _, b in ipairs(BasesFolder:GetChildren()) do
	local gui = select(1, findCollectorGui(b))
	if gui and gui:IsA("SurfaceGui") then gui.Enabled = false end
end
BasesFolder.ChildAdded:Connect(function(ch)
	task.defer(function()
		local gui = select(1, findCollectorGui(ch))
		if gui and gui:IsA("SurfaceGui") then gui.Enabled = false end
	end)
end)

-- Somme ENTIER des prods/s des slimes GARÉS sur les pods de cette base
-- (on ARRONDIT chaque slime individuellement puis on additionne)
local function rateIntForBase(baseModel: Model): number
	local basePath = baseModel:GetFullName()
	local ownerId  = ownerIdOf(baseModel)
	if ownerId == 0 then return 0 end

	local totalInt = 0
	for _, m in ipairs(OwnedFolder:GetChildren()) do
		if m:IsA("Model") and (tonumber(m:GetAttribute("OwnerUserId")) or 0) == ownerId then
			local slotPath = m:GetAttribute("SlotPath")
			if type(slotPath) == "string"
				and string.find(slotPath, basePath, 1, true)
				and string.find(slotPath, "PodsSlime", 1, true) then

				local p = tonumber(m:GetAttribute("ProdPerSec"))
				if not p then
					local mood        = m:GetAttribute("Mood")
					local sizeName    = m:GetAttribute("SizeName")
					local rarityIndex = tonumber(m:GetAttribute("RarityIndex")) or 1
					local stateIndex  = tonumber(m:GetAttribute("StateIndex")) or 1
					if mood and sizeName then
						p = Balance.ComputeProd(mood, sizeName, rarityIndex, stateIndex)
					end
				end
				p = p or 0
				totalInt = totalInt + math.floor(p + 0.5) -- ✅ pas de "+="
			end
		end
	end
	return totalInt
end

-- État par base
local stateByBase: {[Model]: {bank:number}} = {}
local function st(base: Model)
	stateByBase[base] = stateByBase[base] or { bank = 0 }
	return stateByBase[base]
end

local function pushUi(base: Model, bank: number, rateInt: number)
	local _, lblC, lblR = findCollectorGui(base)
	if lblC and lblC:IsA("TextLabel") then lblC.Text = short(bank) end
	if lblR and lblR:IsA("TextLabel") then lblR.Text = string.format("%s/s", short(rateInt)) end
end

local function resetBase(base: Model)
	local S = st(base); S.bank = 0
	pushUi(base, 0, 0)
end

for _, b in ipairs(BasesFolder:GetChildren()) do
	resetBase(b)
	b:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		resetBase(b)
	end)
end
BasesFolder.ChildAdded:Connect(function(ch)
	if ch:IsA("Model") then
		resetBase(ch)
		ch:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
			resetBase(ch)
		end)
	end
end)

-- Tick : + rate ENTIER chaque seconde
task.spawn(function()
	while true do
		for _, base in ipairs(BasesFolder:GetChildren()) do
			if base:IsA("Model") then
				local ownerId = ownerIdOf(base)
				local S = st(base)
				if ownerId == 0 then
					if S.bank ~= 0 then resetBase(base) end
				else
					local rInt = rateIntForBase(base)
					S.bank = S.bank + rInt
					pushUi(base, S.bank, rInt)
				end
			end
		end
		task.wait(1)
	end
end)

-- Collecte via Hitbox (owner only)
local function hookHitbox(base: Model)
	local rec  = base:FindFirstChild("Recolte")
	local hit  = rec and rec:FindFirstChild("Hitbox")
	if not (hit and hit:IsA("BasePart")) then return end

	hit.Touched:Connect(function(part)
		local char = part.Parent
		local hum  = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		local plr = Players:GetPlayerFromCharacter(char)
		if not plr or plr.UserId ~= ownerIdOf(base) then return end

		local S = st(base)
		if S.bank <= 0 then return end
		local add = S.bank
		S.bank = 0

		Economy.AddWallet(plr, add)
		Economy.AddCollected(plr, add)
		pushUi(base, 0, rateIntForBase(base))
	end)
end

for _, b in ipairs(BasesFolder:GetChildren()) do
	hookHitbox(b)
end
BasesFolder.ChildAdded:Connect(function(ch)
	if ch:IsA("Model") then
		task.defer(function()
			hookHitbox(ch)
		end)
	end
end)
