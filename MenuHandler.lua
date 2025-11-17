--[[
    MenuHandler.lua
    Menu vertical en grille 2x3
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Attendre que CurrencyUI existe
local currencyUI = playerGui:WaitForChild("CurrencyUI")
local currencyFrame = currencyUI:WaitForChild("MainFrame")

-- ============================================
-- 🎨 CRÉATION DU MENU UI
-- ============================================

local screenGui = playerGui:FindFirstChild("MenuUI")
if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MenuUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 11
	screenGui.Parent = playerGui
end

-- ============================================
-- 📐 CONSTANTES DE POSITION
-- ============================================

local BUTTON_SIZE = 70
local SPACING = 8
local ARROW_SIZE = 30
local MENU_WIDTH = (BUTTON_SIZE * 2) + SPACING + 20 -- 2 colonnes + espaces
local MENU_HEIGHT = (BUTTON_SIZE * 3) + (SPACING * 2) + 10 -- 3 rangées + espaces

-- ============================================
-- 🔽 BOUTON FLÈCHE (TOGGLE)
-- ============================================

local toggleButton = Instance.new("ImageButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, ARROW_SIZE, 0, ARROW_SIZE)
toggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
toggleButton.BackgroundTransparency = 0.15
toggleButton.BorderSizePixel = 0
toggleButton.Parent = screenGui

-- Position : juste en dessous de CurrencyUI
toggleButton.Position = UDim2.new(
	currencyFrame.Position.X.Scale,
	currencyFrame.Position.X.Offset,
	currencyFrame.Position.Y.Scale,
	currencyFrame.Position.Y.Offset + currencyFrame.Size.Y.Offset + 5
)

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleButton

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(100, 100, 150)
toggleStroke.Thickness = 2
toggleStroke.Transparency = 0.5
toggleStroke.Parent = toggleButton

-- Icône flèche
local arrowIcon = Instance.new("TextLabel")
arrowIcon.Name = "ArrowIcon"
arrowIcon.Size = UDim2.new(1, 0, 1, 0)
arrowIcon.BackgroundTransparency = 1
arrowIcon.Text = "▼"
arrowIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
arrowIcon.TextSize = 16
arrowIcon.Font = Enum.Font.GothamBold
arrowIcon.Parent = toggleButton

-- ============================================
-- 📦 MAIN FRAME (MENU) - GRILLE 2x3
-- ============================================

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, MENU_WIDTH, 0, MENU_HEIGHT)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Position : juste en dessous du bouton toggle
mainFrame.Position = UDim2.new(
	toggleButton.Position.X.Scale,
	toggleButton.Position.X.Offset,
	toggleButton.Position.Y.Scale,
	toggleButton.Position.Y.Offset + ARROW_SIZE + 5
)

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 100, 150)
mainStroke.Thickness = 2
mainStroke.Transparency = 0.5
mainStroke.Parent = mainFrame

-- ✅ GRILLE 2x3 au lieu de liste horizontale
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
gridLayout.CellPadding = UDim2.new(0, SPACING, 0, SPACING)
gridLayout.FillDirectionMaxCells = 2 -- 2 colonnes
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = mainFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 5)
padding.PaddingBottom = UDim.new(0, 5)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = mainFrame

-- ============================================
-- 🎯 FONCTION : CRÉER UN BOUTON
-- ============================================

local function createMenuButton(iconText, labelText, colorAccent, layoutOrder)
	local button = Instance.new("TextButton")
	button.Name = labelText .. "Button"
	button.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE) -- Géré par GridLayout
	button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	button.BackgroundTransparency = 0.3
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.LayoutOrder = layoutOrder
	button.Parent = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = button

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = colorAccent
	btnStroke.Thickness = 2
	btnStroke.Transparency = 0.7
	btnStroke.Parent = button

	-- Container pour l'icône et le texte
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = button

	local containerLayout = Instance.new("UIListLayout")
	containerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	containerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	containerLayout.Padding = UDim.new(0, 2)
	containerLayout.Parent = container

	-- Icône
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 30, 0, 30)
	icon.BackgroundTransparency = 1
	icon.Text = iconText
	icon.TextColor3 = colorAccent
	icon.TextSize = 24
	icon.Font = Enum.Font.GothamBold
	icon.Parent = container

	-- Label
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(200, 200, 220)
	label.TextSize = 9
	label.Font = Enum.Font.Gotham
	label.Parent = container

	-- ✨ EFFET HOVER
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.2), {Transparency = 0.3}):Play()
		TweenService:Create(icon, TweenInfo.new(0.2), {TextSize = 26}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.2), {Transparency = 0.7}):Play()
		TweenService:Create(icon, TweenInfo.new(0.2), {TextSize = 24}):Play()
	end)

	-- 🎯 FONCTION CLICK (À IMPLÉMENTER PLUS TARD)
	button.MouseButton1Click:Connect(function()
		print("[Menu] 🎯 Bouton cliqué:", labelText)
		-- TODO : Ouvrir le menu correspondant
	end)

	return button
end

-- ============================================
-- 🎨 CRÉER LES 6 BOUTONS (ORDRE 2x3)
-- ============================================

-- Rangée 1
local inventoryBtn = createMenuButton("🎒", "Inventaire", Color3.fromRGB(100, 200, 255), 1)
local shopBtn = createMenuButton("🛒", "Shop", Color3.fromRGB(255, 215, 0), 2)

-- Rangée 2
local fusionBtn = createMenuButton("⚡", "Fusion", Color3.fromRGB(255, 100, 255), 3)
local upgradeBtn = createMenuButton("⬆️", "Upgrade", Color3.fromRGB(100, 255, 150), 4)

-- Rangée 3
local slimeDexBtn = createMenuButton("📖", "SlimeDex", Color3.fromRGB(150, 150, 255), 5)
local contractBtn = createMenuButton("📋", "Contrat", Color3.fromRGB(255, 150, 100), 6)

-- ============================================
-- 🔄 SYSTÈME D'OUVERTURE/FERMETURE
-- ============================================

local isOpen = true -- Commence ouvert

local function toggleMenu()
	isOpen = not isOpen

	if isOpen then
		-- Ouvrir
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, MENU_WIDTH, 0, MENU_HEIGHT)
		}):Play()

		TweenService:Create(arrowIcon, TweenInfo.new(0.3), {
			Rotation = 0,
			Text = "▼"
		}):Play()

		print("[Menu] 📂 Menu ouvert")
	else
		-- Fermer
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, MENU_WIDTH, 0, 0)
		}):Play()

		TweenService:Create(arrowIcon, TweenInfo.new(0.3), {
			Rotation = 180,
			Text = "▲"
		}):Play()

		print("[Menu] 📁 Menu fermé")
	end
end

-- Connecter le bouton toggle
toggleButton.MouseButton1Click:Connect(toggleMenu)

-- ============================================
-- 📱 ADAPTATION MOBILE
-- ============================================

local function adjustForMobile()
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local isMobile = viewportSize.X < 600

	if isMobile then
		-- Réduire la taille des boutons sur mobile
		gridLayout.CellSize = UDim2.new(0, 60, 0, 60)

		local mobileWidth = (60 * 2) + SPACING + 20
		local mobileHeight = (60 * 3) + (SPACING * 2) + 10

		mainFrame.Size = UDim2.new(0, mobileWidth, 0, mobileHeight)
		print("[Menu] 📱 Mode mobile activé")
	else
		-- Desktop
		gridLayout.CellSize = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
		mainFrame.Size = UDim2.new(0, MENU_WIDTH, 0, MENU_HEIGHT)
	end
end

-- Vérifier au démarrage
adjustForMobile()

-- Vérifier quand la taille change
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adjustForMobile)

print("[MenuHandler] ✅ Menu en grille 2x3 chargé")
