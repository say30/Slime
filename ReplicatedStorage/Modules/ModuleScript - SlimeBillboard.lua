-- from: ReplicatedStorage.Modules.SlimeBillboard

-- ReplicatedStorage/Modules/SlimeBillboard.lua
-- Construit un BillboardGui centré, 4 lignes, avec icône jelly violette, distance gérée côté client.

local M = {}

local function purpleJelly(parent, px)
	px = px or 14
	local wrap = Instance.new("Frame")
	wrap.BackgroundTransparency = 1
	wrap.Size = UDim2.fromOffset(px, px); wrap.Parent = parent

	local base = Instance.new("Frame")
	base.BackgroundColor3 = Color3.fromRGB(160,120,255)
	base.Size = UDim2.fromScale(1,1); base.Parent = wrap
	Instance.new("UICorner", base).CornerRadius = UDim.new(1,0)
	local s = Instance.new("UIStroke", base); s.Thickness=1.5; s.Color=Color3.fromRGB(90,60,150); s.Transparency=0.25

	local hi = Instance.new("Frame")
	hi.BackgroundColor3 = Color3.fromRGB(220,210,255); hi.BackgroundTransparency=0.2
	hi.Size = UDim2.fromScale(0.6,0.6); hi.Position = UDim2.fromScale(0.15,0.12); hi.Parent = wrap
	Instance.new("UICorner", hi).CornerRadius = UDim.new(1,0)

	local shade = Instance.new("Frame")
	shade.BackgroundColor3 = Color3.fromRGB(120,85,200); shade.BackgroundTransparency=0.6
	shade.Size = UDim2.fromScale(0.9,0.9); shade.Position = UDim2.fromScale(0.05,0.05); shade.Parent = wrap
	Instance.new("UICorner", shade).CornerRadius = UDim.new(1,0)
	return wrap
end

local function rowText(parent, txt, sizePx, bold, order, color)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Text = txt or ""
	t.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	t.TextSize = sizePx
	t.TextColor3 = color or Color3.fromRGB(235,240,255)
	t.TextXAlignment = Enum.TextXAlignment.Center
	t.Size = UDim2.new(1,-10,0,sizePx+2)
	t.LayoutOrder = order or 1
	t.Parent = parent
	return t
end

function M.Build(model: Model, data: table)
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not root then return end

	for _, c in ipairs(model:GetChildren()) do
		if c:IsA("BillboardGui") and c.Name == "SR_BB" then c:Destroy() end
	end

	local bb = Instance.new("BillboardGui")
	bb.Name = "SR_BB"
	bb.Adornee = root
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Size = UDim2.fromOffset(360, 140)
	bb.Parent = model

	local _, size = model:GetBoundingBox()
	bb.StudsOffset = Vector3.new(0, size.Y + 3.5, 0)

	local stack = Instance.new("Frame", bb)
	stack.BackgroundTransparency = 1
	stack.Size = UDim2.fromScale(1,1)

	local list = Instance.new("UIListLayout", stack)
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 2)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment   = Enum.VerticalAlignment.Top

	local rarityName = data.rarityName or ""
	local stateName  = (data.stateName and #data.stateName>0) and data.stateName or nil

	rowText(stack, string.format("%s %s", data.mood or "?", data.sizeName or "?"), 24, true, 1, Color3.new(1,1,1))
	if stateName then
		rowText(stack, string.format("%s  |  %s", rarityName, stateName), 18, false, 2, Color3.fromRGB(195,220,255))
	else
		rowText(stack, string.format("%s", rarityName), 18, false, 2, Color3.fromRGB(195,220,255))
	end

	local function centeredLine(order, labelText)
		local row = Instance.new("Frame"); row.BackgroundTransparency=1; row.Size=UDim2.new(1,-10,0,22); row.LayoutOrder=order; row.Parent=stack
		local line = Instance.new("Frame"); line.BackgroundTransparency=1; line.AutomaticSize=Enum.AutomaticSize.X; line.Size=UDim2.new(0,0,1,0)
		line.AnchorPoint=Vector2.new(0.5,0.5); line.Position=UDim2.fromScale(0.5,0.5); line.Parent=row
		local h = Instance.new("UIListLayout", line)
		h.FillDirection=Enum.FillDirection.Horizontal; h.Padding=UDim.new(0,6)
		h.HorizontalAlignment=Enum.HorizontalAlignment.Center; h.VerticalAlignment=Enum.VerticalAlignment.Center
		purpleJelly(line, 14)
		local lbl = Instance.new("TextLabel"); lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=18
		lbl.TextColor3 = Color3.fromRGB(200,230,255); lbl.AutomaticSize=Enum.AutomaticSize.X; lbl.Size=UDim2.new(0,0,1,0)
		lbl.Text = labelText; lbl.Parent = line
	end

	centeredLine(3, ("Prod : %s"):format(data.prodText or "?"))
	centeredLine(4, ("Coût : %s"):format(data.priceText or "?"))
	return bb
end

return M
