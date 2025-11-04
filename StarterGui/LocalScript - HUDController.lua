-- from: StarterGui.SlimeHUD.HUDController

-- StarterGui/SlimeHUD/HUDController.lua
-- Affiche (dans l'ordre) : [🟣 Gélatine] / [Récolté] / [🔵 EssenceF]
-- Icône + texte alignés à gauche sur chaque ligne. Idempotent (pas de doublons).

local Players = game:GetService("Players")
local LP      = Players.LocalPlayer
local pg      = LP:WaitForChild("PlayerGui")

-- Robustesse : si le script est sous SlimeHUD, on prend son parent direct
local hud = script.Parent
if not hud or not hud:IsA("ScreenGui") then
	hud = pg:WaitForChild("SlimeHUD")
end

local function short(n:number)
	if n>=1e12 then return string.format("%.2fT",n/1e12)
	elseif n>=1e9 then return string.format("%.2fB",n/1e9)
	elseif n>=1e6 then return string.format("%.2fM",n/1e6)
	elseif n>=1e3 then return string.format("%.2fK",n/1e3)
	else return tostring(math.floor(n+0.5)) end
end

local function makeIcon(parent: Instance, color: Color3, sizePx: number?)
	sizePx = sizePx or 28
	local wrap = Instance.new("Frame")
	wrap.BackgroundTransparency = 1
	wrap.Size = UDim2.fromOffset(sizePx, sizePx)
	wrap.Parent = parent

	local base = Instance.new("Frame")
	base.Size = UDim2.fromScale(1,1)
	base.BackgroundColor3 = color
	base.Parent = wrap
	Instance.new("UICorner", base).CornerRadius = UDim.new(1,0)
	local s = Instance.new("UIStroke", base); s.Thickness = 1.5; s.Color = Color3.fromRGB(255,255,255); s.Transparency = 0.25

	local hi = Instance.new("Frame")
	hi.Size = UDim2.fromScale(0.6,0.6)
	hi.Position = UDim2.fromScale(0.15,0.12)
	hi.BackgroundColor3 = Color3.fromRGB(255,255,255)
	hi.BackgroundTransparency = 0.3
	hi.Parent = wrap
	Instance.new("UICorner", hi).CornerRadius = UDim.new(1,0)
	return wrap
end

-- ===== CONTENEUR ============================================================
local frame = hud:FindFirstChild("MainFrame") or Instance.new("Frame")
frame.Name = "MainFrame"
frame.Parent = hud
frame.BackgroundColor3 = Color3.fromRGB(25,28,36)
frame.BackgroundTransparency = 0.15
frame.Size = UDim2.fromOffset(280, 580)
frame.AnchorPoint = Vector2.new(1, 0.5)
frame.Position = UDim2.new(1, -40, 0.5, 0)
frame.BorderSizePixel = 0
if not frame:FindFirstChildOfClass("UICorner") then
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
end

-- ===== SECTION MONNAIES =====================================================
local currencySection = frame:FindFirstChild("CurrencySection") or Instance.new("Frame")
currencySection.Name = "CurrencySection"
currencySection.BackgroundTransparency = 1
currencySection.Size = UDim2.new(1, -20, 0, 150)
currencySection.Position = UDim2.fromOffset(10, 10)
currencySection.Parent = frame

local currencyLayout = currencySection:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout", currencySection)
currencyLayout.FillDirection = Enum.FillDirection.Vertical
currencyLayout.Padding = UDim.new(0, 12)
currencyLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function makeRow(name: string, color: Color3, order: number)
	local row = Instance.new("Frame", currencySection)
	row.Name = name
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 40)
	row.LayoutOrder = order

	local h = Instance.new("UIListLayout", row)
	h.FillDirection = Enum.FillDirection.Horizontal
	h.Padding = UDim.new(0, 10)
	h.VerticalAlignment = Enum.VerticalAlignment.Center
	h.HorizontalAlignment = Enum.HorizontalAlignment.Left

	local icon = makeIcon(row, color, 28); icon.LayoutOrder = 1

	local label = Instance.new("TextLabel", row)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 26
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.new(0, 0, 1, 0)
	label.LayoutOrder = 2

	return row, label
end

-- L1 : Gélatine
local gelRow, gelWallet = makeRow("GelRow", Color3.fromRGB(160,120,255), 1)
gelWallet.TextColor3 = Color3.fromRGB(235,240,255)
gelWallet.Text = "0 Gélatine"

-- L2 : Récolté
local totalRow = Instance.new("Frame", currencySection)
totalRow.Name = "TotalRow"
totalRow.BackgroundTransparency = 1
totalRow.Size = UDim2.new(1, 0, 0, 40)
totalRow.LayoutOrder = 2
do
	local h = Instance.new("UIListLayout", totalRow)
	h.FillDirection = Enum.FillDirection.Horizontal
	h.Padding = UDim.new(0, 10)
	h.VerticalAlignment = Enum.VerticalAlignment.Center
	h.HorizontalAlignment = Enum.HorizontalAlignment.Left
end
local totalLabel = Instance.new("TextLabel", totalRow)
totalLabel.BackgroundTransparency = 1
totalLabel.Font = Enum.Font.GothamBold
totalLabel.TextSize = 26
totalLabel.TextColor3 = Color3.fromRGB(150,170,200)
totalLabel.TextXAlignment = Enum.TextXAlignment.Left
totalLabel.Size = UDim2.new(1, -40, 1, 0)
totalLabel.Text = "Récolté : 0"

-- L3 : EssenceF
local essRow, essWallet = makeRow("EssRow", Color3.fromRGB(100,200,255), 3)
essWallet.TextColor3 = Color3.fromRGB(100,200,255)
essWallet.Text = "0 EssenceF"

-- ===== SECTION BOUTONS (laisse en place si déjà présent) ====================
local buttonsPanel = frame:FindFirstChild("ButtonsPanel") or Instance.new("Frame")
buttonsPanel.Name = "ButtonsPanel"
buttonsPanel.BackgroundTransparency = 1
buttonsPanel.Size = UDim2.new(1, -20, 1, -210)
buttonsPanel.Position = UDim2.fromOffset(10, 170)
buttonsPanel.Parent = frame

local buttonsLayout = buttonsPanel:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout", buttonsPanel)
buttonsLayout.FillDirection = Enum.FillDirection.Vertical
buttonsLayout.Padding = UDim.new(0, 8)

local function createButton(name, text, order)
	if buttonsPanel:FindFirstChild(name) then return end
	local btn = Instance.new("TextButton", buttonsPanel)
	btn.Name = name
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.BackgroundColor3 = Color3.fromRGB(60,100,160)
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.BorderSizePixel = 0
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.LayoutOrder = order
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(80,130,200) end)
	btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(60,100,160) end)
end

createButton("ContractBtn",  "📋 CONTRATS",    1)
createButton("FusionBtn",    "🧬 FUSION",      2)
createButton("InventoryBtn", "📦 INVENTAIRE",  3)
createButton("ShopBtn",      "🛍️ SHOP",        4)
createButton("SlimedexBtn",  "📚 SLIMEDEX",     5)
createButton("UpgradeBtn",   "⬆️ UPGRADE",     6)

-- ===== UPDATE ===============================================================
local function refresh()
	local w = LP:GetAttribute("Wallet") or 0
	local e = LP:GetAttribute("Essence") or 0
	local t = LP:GetAttribute("TotalCollected") or 0
	gelWallet.Text  = short(w) .. " Gélatine"
	totalLabel.Text = "Récolté : " .. short(t)
	essWallet.Text  = short(e) .. " EssenceF"
end
refresh()
LP:GetAttributeChangedSignal("Wallet"):Connect(refresh)
LP:GetAttributeChangedSignal("Essence"):Connect(refresh)
LP:GetAttributeChangedSignal("TotalCollected"):Connect(refresh)

print("✅ HUD : Gélatine / Récolté / EssenceF prêt")
