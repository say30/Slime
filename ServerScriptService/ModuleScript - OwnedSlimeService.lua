-- from: ServerScriptService.OwnedSlimeService

-- ServerScriptService/OwnedSlimeService (ModuleScript)
-- Clone serveur fidèle + billboard + marche au sol (ralentie) depuis la position du slime local

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")

local GameBalance = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameBalance"))

-- vitesses (plus lent vers la base)
local SPEED_HOME  = 6    -- studs/s vers structure base home
local SPEED_PARK  = 8    -- studs/s vers Pod
local MIN_DUR     = 1.2
local MAX_DUR     = 8.0
local EPS         = 0.05

local OwnedFolder = Workspace:FindFirstChild("OwnedSlimes") or Instance.new("Folder", Workspace)
OwnedFolder.Name = "OwnedSlimes"

local Plateau = Workspace:WaitForChild("Part")
local function plateauTopY(): number
	if Plateau:IsA("BasePart") then
		return Plateau.Position.Y + Plateau.Size.Y * 0.5
	end
	return Plateau.Position.Y
end

local function anchorGhost(model: Model, anchored: boolean)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored   = anchored
			d.CanCollide = false
			d.CanTouch   = false
			d.CanQuery   = false
		end
	end
end

local function getSize(model: Model)
	local _, size = model:GetBoundingBox()
	return size
end

local function topOf(part: BasePart)
	return part.Position.Y + part.Size.Y * 0.5
end

local function yawOnly(cf: CFrame, yawRadians: number?)
	local pos = cf.Position
	if not yawRadians then
		local look = cf.LookVector
		yawRadians = math.atan2(-look.X, -look.Z)
	end
	return CFrame.new(pos) * CFrame.Angles(0, yawRadians, 0)
end

local function tweenPivot(model: Model, fromCF: CFrame, toCF: CFrame, duration: number, style, dir)
	style = style or Enum.EasingStyle.Sine
	dir   = dir   or Enum.EasingDirection.InOut
	local nv = Instance.new("NumberValue")
	nv.Value = 0
	local tw = TweenService:Create(nv, TweenInfo.new(duration, style, dir), {Value = 1})
	nv.Changed:Connect(function(v)
		model:PivotTo(fromCF:Lerp(toCF, v))
	end)
	tw.Completed:Connect(function() nv:Destroy() end)
	tw:Play(); tw.Completed:Wait()
end

local function clampDuration(dist: number, speed: number)
	return math.clamp(dist / math.max(1e-3, speed), MIN_DUR, MAX_DUR)
end

-- -------- Billboard serveur (identique au style client) --------
local VIEW_DIST = 60

local function makePurpleJellyIcon(parent: Instance, sizePx: number?)
	sizePx = sizePx or 14
	local wrap = Instance.new("Frame"); wrap.Name="IconJelly"; wrap.BackgroundTransparency=1; wrap.Size=UDim2.fromOffset(sizePx,sizePx); wrap.Parent=parent
	local base = Instance.new("Frame"); base.Size=UDim2.fromScale(1,1); base.BackgroundColor3=Color3.fromRGB(160,120,255); base.Parent=wrap
	Instance.new("UICorner",base).CornerRadius=UDim.new(1,0)
	local s=Instance.new("UIStroke",base); s.Thickness=1.5; s.Color=Color3.fromRGB(90,60,150); s.Transparency=0.25
	local hi=Instance.new("Frame"); hi.Size=UDim2.fromScale(0.6,0.6); hi.Position=UDim2.fromScale(0.15,0.12); hi.BackgroundColor3=Color3.fromRGB(220,210,255); hi.BackgroundTransparency=0.2; hi.Parent=wrap
	Instance.new("UICorner",hi).CornerRadius=UDim.new(1,0)
	local shade=Instance.new("Frame"); shade.Size=UDim2.fromScale(0.9,0.9); shade.Position=UDim2.fromScale(0.05,0.05); shade.BackgroundColor3=Color3.fromRGB(120,85,200); shade.BackgroundTransparency=0.6; shade.Parent=wrap
	Instance.new("UICorner",shade).CornerRadius=UDim.new(1,0)
end

local function removeAnyBillboards(model: Model)
	for _, c in ipairs(model:GetChildren()) do
		if c:IsA("BillboardGui") then c:Destroy() end
	end
end

local function buildServerBillboard(model: Model)
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not root then return end
	removeAnyBillboards(model)

	local bb = Instance.new("BillboardGui")
	bb.Name="SR_BB"; bb.Adornee=root; bb.Parent=model
	bb.AlwaysOnTop=true; bb.LightInfluence=0; bb.Size=UDim2.new(0,360,0,140); bb.MaxDistance=VIEW_DIST

	local _, size = model:GetBoundingBox()
	bb.StudsOffset = Vector3.new(0, size.Y + 3.5, 0)

	local stack = Instance.new("Frame", bb); stack.BackgroundTransparency=1; stack.Size=UDim2.fromScale(1,1)
	local list = Instance.new("UIListLayout", stack)
	list.FillDirection=Enum.FillDirection.Vertical; list.SortOrder=Enum.SortOrder.LayoutOrder
	list.Padding=UDim.new(0,2); list.HorizontalAlignment=Enum.HorizontalAlignment.Center; list.VerticalAlignment=Enum.VerticalAlignment.Top

	local function row(text, sizePx, color, bold, order)
		local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Text=text
		t.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
		t.TextSize=sizePx; t.TextColor3=color; t.TextXAlignment=Enum.TextXAlignment.Center
		t.Size=UDim2.new(1,-10,0,sizePx+2); t.LayoutOrder=order; t.Parent=stack
	end

	local mood     = model:GetAttribute("Mood") or "Joyeux"
	local sizeName = model:GetAttribute("SizeName") or "Moyen"
	local rIdx     = model:GetAttribute("RarityIndex") or 1
	local sIdx     = model:GetAttribute("StateIndex")  -- ✅ FIX: Pas de "or 1", garder nil si pas d'état
	local prod     = tonumber(model:GetAttribute("ProdPerSec")) or 1
	local price    = tonumber(model:GetAttribute("Price")) or 0

	local rarName   = GameBalance.Rarities[rIdx] or ("R"..tostring(rIdx))
	local stateName = sIdx and GameBalance.States[sIdx]  -- ✅ FIX: N'afficher l'état que s'il existe

	row(("%s %s"):format(mood, sizeName), 24, Color3.new(1,1,1), true, 1)
	if stateName then  -- ✅ FIX: N'afficher la ligne d'état que si le slime a un état
		row(("%s  |  %s"):format(rarName, stateName), 18, Color3.fromRGB(195,220,255), false, 2)
	else
		row(rarName, 18, Color3.fromRGB(195,220,255), false, 2)  -- ✅ FIX: Afficher seulement la rareté si pas d'état
	end

	local function centeredLine(order, text)
		local rowFrame=Instance.new("Frame"); rowFrame.BackgroundTransparency=1; rowFrame.Size=UDim2.new(1,-10,0,22); rowFrame.LayoutOrder=order; rowFrame.Parent=stack
		local line=Instance.new("Frame"); line.BackgroundTransparency=1; line.AutomaticSize=Enum.AutomaticSize.X
		line.Size=UDim2.new(0,0,1,0); line.AnchorPoint=Vector2.new(0.5,0.5); line.Position=UDim2.fromScale(0.5,0.5); line.Parent=rowFrame
		local h=Instance.new("UIListLayout",line); h.FillDirection=Enum.FillDirection.Horizontal; h.Padding=UDim.new(0,6)
		h.HorizontalAlignment=Enum.HorizontalAlignment.Center; h.VerticalAlignment=Enum.VerticalAlignment.Center
		makePurpleJellyIcon(line,14)
		local lbl=Instance.new("TextLabel"); lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=18
		lbl.TextColor3=Color3.fromRGB(200,230,255); lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.AutomaticSize=Enum.AutomaticSize.X
		lbl.Size=UDim2.new(0,0,1,0); lbl.Text=text; lbl.Parent=line
	end

	centeredLine(3, ("Prod : %s gél/s"):format(GameBalance.FormatNumber(prod)))
	centeredLine(4, ("Coût : %s"):format(GameBalance.FormatNumber(price)))
end

-- -------- Base & Pods --------
local function findPlayerBase(player: Player): Model?
	local basesFolder = Workspace:FindFirstChild("Base"); if not basesFolder then return nil end
	local A="Base de "..player.DisplayName; local B="Base de "..player.Name
	for _, base in ipairs(basesFolder:GetChildren()) do
		if base:IsA("Model") then
			local panneau = base:FindFirstChild("Panneau")
			local part = panneau and panneau:FindFirstChild("Part", true)
			local sg = part and part:FindFirstChildOfClass("SurfaceGui")
			local tl = sg and sg:FindFirstChild("MainFrame") and sg.MainFrame:FindFirstChild("TitleLabel")
			if tl and tl:IsA("TextLabel") then
				local t = tl.Text or ""
				if t==A or t==B then return base end
			end
		end
	end
	return nil
end

local function getStructureHome(baseModel: Model): BasePart?
	return baseModel:FindFirstChild("structure base home", true)
end

local function getPodsFolder(baseModel: Model): Folder?
	return baseModel:FindFirstChild("PodsSlime", true)
end

local Occupied: {[Model]: {[string]: boolean}} = {}
local function findFreePod(baseModel: Model): BasePart?
	local pods = getPodsFolder(baseModel); if not pods then return nil end
	Occupied[baseModel] = Occupied[baseModel] or {}
	for i=1,22 do
		local slot = pods:FindFirstChild("PodsSlime"..i)
		if slot then
			local key = slot:GetFullName()
			if not Occupied[baseModel][key] then
				local pad = slot:IsA("BasePart") and slot or slot:FindFirstChildWhichIsA("BasePart", true)
				if pad then Occupied[baseModel][key]=true; return pad end
			end
		end
	end
	return nil
end
local function freePod(baseModel: Model, slot: Instance?)
	if not slot then return end
	Occupied[baseModel] = Occupied[baseModel] or {}
	Occupied[baseModel][slot:GetFullName()] = nil
end

-- -------- Attributs + trajet --------
local function applyOfferAttributes(model: Model, offer)
	model:SetAttribute("Mood",         offer.mood)
	model:SetAttribute("SizeName",     offer.sizeName)
	model:SetAttribute("RarityIndex",  offer.rarityIndex)
	model:SetAttribute("StateIndex", nil)
	model:SetAttribute("ProdPerSec",   offer.prodPerSec)
	model:SetAttribute("Price",        offer.price)
end

local function moveToBaseAndPark(player: Player, model: Model)
	local base = findPlayerBase(player); if not base then return end
	local home = getStructureHome(base); if not home then return end

	local size   = getSize(model)
	local start  = model:GetPivot()

	local groundY = plateauTopY() + size.Y*0.5 + EPS

	-- 1) marche au sol -> home
	local tgt1 = CFrame.new(home.Position.X, groundY, home.Position.Z)
	local d1   = (start.Position - tgt1.Position).Magnitude
	local t1   = clampDuration(d1, SPEED_HOME)
	tweenPivot(model, yawOnly(start), yawOnly(tgt1), t1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	-- 2) home -> Pod (réglage Y sur le pod)
	local pad = findFreePod(base); if not pad then return end
	local tgt2 = CFrame.new(pad.Position.X, topOf(pad)+size.Y*0.5+EPS, pad.Position.Z)
	local d2   = (tgt1.Position - tgt2.Position).Magnitude
	local t2   = clampDuration(d2, SPEED_PARK)
	tweenPivot(model, yawOnly(tgt1), yawOnly(tgt2), t2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	anchorGhost(model, true)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("SlotPath", pad:GetFullName())
	model.AncestryChanged:Connect(function(_, parent) if not parent then freePod(base, pad) end end)
end

-- ===== API =====
local M = {}

-- CreateOwned(player, data, startCF?)
-- startCF (CFrame) : position/orientation du slime LOCAL au moment de l’achat.
function M.CreateOwned(player: Player, data: table, startCF: CFrame?): Model?
	-- clone fidèle
	local moodFolder = ReplicatedStorage:WaitForChild("Slimes"):FindFirstChild(data.mood)
	if not moodFolder then return nil end
	local prefab = moodFolder:FindFirstChild(data.mood .. " " .. data.sizeName)
	if not prefab then return nil end

	local model = prefab:Clone()
	model.Name  = data.mood .. " " .. data.sizeName
	model.Parent= OwnedFolder
	anchorGhost(model, true)
	applyOfferAttributes(model, data)
	buildServerBillboard(model)

	-- Point de départ = EXACTEMENT la position/orientation du slime local (si fournie),
	-- mais “posé” au sol (Y corrigée sur le plateau).
	local size = getSize(model)
	local pivot = startCF or CFrame.new(data.position)
	local pos   = pivot.Position
	local yaw   = math.atan2(-pivot.LookVector.X, -pivot.LookVector.Z)
	local groundY = plateauTopY() + size.Y*0.5 + EPS
	local startOnGround = CFrame.new(pos.X, groundY, pos.Z)
	model:PivotTo(yawOnly(startOnGround, yaw))

	task.spawn(function() moveToBaseAndPark(player, model) end)
	return model
end

return M
