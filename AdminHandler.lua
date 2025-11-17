-- StarterGui/AdminPanel/AdminHandler.lua
-- ============================================
-- 🎮 GESTION DU PANEL ADMIN (CLIENT) - VERSION CORRIGÉE
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local adminPanel = script.Parent
local adminFrame = adminPanel:WaitForChild("AdminFrame")
local topBar = adminFrame:WaitForChild("TopBar")
local closeBtn = topBar:WaitForChild("CloseButton")
local tabsContainer = adminFrame:WaitForChild("TabsContainer")
local contentFrame = adminFrame:WaitForChild("ContentFrame")
local logScroll = adminFrame:WaitForChild("LogFrame"):WaitForChild("LogScroll")

-- Attendre le chargement des modules
local AdminConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("AdminConfig"))
local adminCommand = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AdminCommand")

-- ============================================
-- 🔐 VÉRIFICATION DES PERMISSIONS
-- ============================================
local isAdmin = AdminConfig:IsAdmin(player.UserId)

if not isAdmin then
	warn("[AdminPanel] ❌ Tu n'es pas administrateur")
	adminPanel:Destroy()
	return
end

print("[AdminPanel] ✅ Accès admin autorisé pour", player.Name)

-- ============================================
-- 📋 VARIABLES GLOBALES
-- ============================================
local currentTab = "Joueurs"
local inputFields = {}
local dragging = false
local dragStart = nil
local startPos = nil

-- ============================================
-- 📝 FONCTION : AJOUTER UN LOG
-- ============================================
local function addLog(message, color)
	local logLabel = Instance.new("TextLabel")
	logLabel.Size = UDim2.new(1, -10, 0, 16)
	logLabel.BackgroundTransparency = 1
	logLabel.Text = "[" .. os.date("%H:%M:%S") .. "] " .. message
	logLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
	logLabel.TextSize = 11
	logLabel.Font = Enum.Font.Code
	logLabel.TextXAlignment = Enum.TextXAlignment.Left
	logLabel.TextWrapped = true
	logLabel.Parent = logScroll

	-- Auto-scroll vers le bas
	logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y)

	-- Limiter à 50 logs max
	if #logScroll:GetChildren() > 51 then -- +1 pour UIListLayout
		logScroll:GetChildren()[1]:Destroy()
	end
end

-- ============================================
-- 🎯 FONCTION : GÉNÉRER LES BOUTONS DE COMMANDE
-- ============================================
local function generateCommandButtons(tabName)
	-- Nettoyer le contenu actuel
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	inputFields = {}

	local commands = AdminConfig.Commands[tabName]
	if not commands then
		warn("[AdminPanel] ❌ Onglet inconnu:", tabName)
		return
	end

	-- Créer un bouton pour chaque commande
	for _, cmd in ipairs(commands) do
		local cmdFrame = Instance.new("Frame")
		cmdFrame.Name = cmd.Name
		cmdFrame.Size = UDim2.new(1, -10, 0, 0) -- Hauteur auto
		cmdFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		cmdFrame.BorderSizePixel = 0
		cmdFrame.Parent = contentFrame

		local cmdCorner = Instance.new("UICorner")
		cmdCorner.CornerRadius = UDim.new(0, 6)
		cmdCorner.Parent = cmdFrame

		local cmdLayout = Instance.new("UIListLayout")
		cmdLayout.Padding = UDim.new(0, 5)
		cmdLayout.Parent = cmdFrame

		local cmdPadding = Instance.new("UIPadding")
		cmdPadding.PaddingTop = UDim.new(0, 10)
		cmdPadding.PaddingBottom = UDim.new(0, 10)
		cmdPadding.PaddingLeft = UDim.new(0, 10)
		cmdPadding.PaddingRight = UDim.new(0, 10)
		cmdPadding.Parent = cmdFrame

		-- Titre de la commande
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, 0, 0, 20)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = cmd.Icon .. " " .. cmd.Name
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.TextSize = 14
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Parent = cmdFrame

		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, 0, 0, 16)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = cmd.Description
		descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		descLabel.TextSize = 11
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = cmdFrame

		local totalHeight = 46 -- Titre + Description + padding

		-- Créer les inputs
		local inputs = {}
		for i, input in ipairs(cmd.Inputs) do
			local inputContainer = Instance.new("Frame")
			inputContainer.Size = UDim2.new(1, 0, 0, 50)
			inputContainer.BackgroundTransparency = 1
			inputContainer.Parent = cmdFrame

			local inputLabel = Instance.new("TextLabel")
			inputLabel.Size = UDim2.new(1, 0, 0, 16)
			inputLabel.BackgroundTransparency = 1
			inputLabel.Text = input.Label .. ":"
			inputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			inputLabel.TextSize = 12
			inputLabel.Font = Enum.Font.Gotham
			inputLabel.TextXAlignment = Enum.TextXAlignment.Left
			inputLabel.Parent = inputContainer

			if input.Type == "Player" then
				-- Dropdown pour sélectionner un joueur
				local dropdown = Instance.new("TextButton")
				dropdown.Size = UDim2.new(1, 0, 0, 30)
				dropdown.Position = UDim2.new(0, 0, 0, 18)
				dropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				dropdown.Text = "Sélectionner un joueur"
				dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
				dropdown.TextSize = 12
				dropdown.Font = Enum.Font.Gotham
				dropdown.Parent = inputContainer

				local dropCorner = Instance.new("UICorner")
				dropCorner.CornerRadius = UDim.new(0, 4)
				dropCorner.Parent = dropdown

				-- Stocker la référence avec le joueur sélectionné
				local inputData = {
					Type = "Player",
					Element = dropdown,
					SelectedPlayer = player -- Par défaut = joueur local
				}
				table.insert(inputs, inputData)

				-- Click handler - Sélectionner le joueur local (simplifié)
				dropdown.MouseButton1Click:Connect(function()
					inputData.SelectedPlayer = player
					dropdown.Text = player.Name
				end)

			elseif input.Type == "Number" then
				-- TextBox pour les nombres
				local textbox = Instance.new("TextBox")
				textbox.Size = UDim2.new(1, 0, 0, 30)
				textbox.Position = UDim2.new(0, 0, 0, 18)
				textbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				textbox.Text = tostring(input.Default or 0)
				textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
				textbox.TextSize = 12
				textbox.Font = Enum.Font.Gotham
				textbox.PlaceholderText = "Entrer un nombre..."
				textbox.ClearTextOnFocus = false
				textbox.Parent = inputContainer

				local boxCorner = Instance.new("UICorner")
				boxCorner.CornerRadius = UDim.new(0, 4)
				boxCorner.Parent = textbox

				table.insert(inputs, {Type = "Number", Element = textbox})

			elseif input.Type == "Text" then
				-- TextBox pour le texte
				local textbox = Instance.new("TextBox")
				textbox.Size = UDim2.new(1, 0, 0, 30)
				textbox.Position = UDim2.new(0, 0, 0, 18)
				textbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				textbox.Text = input.Default or ""
				textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
				textbox.TextSize = 12
				textbox.Font = Enum.Font.Gotham
				textbox.PlaceholderText = "Entrer du texte..."
				textbox.ClearTextOnFocus = false
				textbox.Parent = inputContainer

				local boxCorner = Instance.new("UICorner")
				boxCorner.CornerRadius = UDim.new(0, 4)
				boxCorner.Parent = textbox

				table.insert(inputs, {Type = "Text", Element = textbox})
			end

			totalHeight = totalHeight + 55
		end

		-- Bouton d'exécution
		local executeBtn = Instance.new("TextButton")
		executeBtn.Size = UDim2.new(1, 0, 0, 35)
		executeBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		executeBtn.Text = "✓ EXÉCUTER"
		executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		executeBtn.TextSize = 13
		executeBtn.Font = Enum.Font.GothamBold
		executeBtn.Parent = cmdFrame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = executeBtn

		totalHeight = totalHeight + 40

		-- Définir la hauteur finale
		cmdFrame.Size = UDim2.new(1, -10, 0, totalHeight)

		-- Click handler pour exécuter la commande
		executeBtn.MouseButton1Click:Connect(function()
			local args = {}

			-- Collecter les valeurs des inputs
			for _, input in ipairs(inputs) do
				if input.Type == "Player" then
					-- ✅ CORRECTION : Utiliser SelectedPlayer stocké dans inputData
					if input.SelectedPlayer then
						table.insert(args, input.SelectedPlayer.Name)
					else
						table.insert(args, player.Name) -- Par défaut, le joueur local
					end
				elseif input.Type == "Number" then
					table.insert(args, tonumber(input.Element.Text) or 0)
				elseif input.Type == "Text" then
					table.insert(args, input.Element.Text)
				end
			end

			-- Envoyer la commande au serveur
			addLog("▶ Exécution: " .. cmd.Command, Color3.fromRGB(100, 200, 255))
			adminCommand:FireServer(cmd.Command, args)
		end)
	end
end

-- ============================================
-- 🎨 FONCTION : CHANGER D'ONGLET
-- ============================================
local function switchTab(tabName)
	currentTab = tabName

	-- Mettre à jour l'apparence des onglets
	for _, tab in ipairs(tabsContainer:GetChildren()) do
		if tab:IsA("TextButton") then
			if tab.Name == tabName .. "Tab" then
				tab.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
				tab.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				tab.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				tab.TextColor3 = Color3.fromRGB(200, 200, 200)
			end
		end
	end

	-- Générer les boutons
	generateCommandButtons(tabName)
end

-- ============================================
-- 🖱️ SYSTÈME DE DRAG (DRAGGABLE)
-- ============================================
topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = adminFrame.Position
	end
end)

topBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		adminFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

-- ============================================
-- 🎮 DÉTECTION DE LA COMMANDE "/admin"
-- ============================================
player.Chatted:Connect(function(message)
	if message:lower() == "/admin" then
		adminFrame.Visible = not adminFrame.Visible

		if adminFrame.Visible then
			addLog("✅ Panel admin ouvert", Color3.fromRGB(100, 255, 100))
			switchTab(currentTab)
		else
			addLog("❌ Panel admin fermé", Color3.fromRGB(255, 100, 100))
		end
	end
end)

-- ============================================
-- 🔘 BOUTON FERMER
-- ============================================
closeBtn.MouseButton1Click:Connect(function()
	adminFrame.Visible = false
	addLog("❌ Panel admin fermé", Color3.fromRGB(255, 100, 100))
end)

-- ============================================
-- 📂 GESTION DES ONGLETS
-- ============================================
for _, tab in ipairs(tabsContainer:GetChildren()) do
	if tab:IsA("TextButton") then
		tab.MouseButton1Click:Connect(function()
			local tabName = tab.Name:gsub("Tab", "")
			switchTab(tabName)
		end)
	end
end

-- ============================================
-- 📡 RÉCEPTION DES RÉPONSES DU SERVEUR
-- ============================================
adminCommand.OnClientEvent:Connect(function(messageType, message, color)
	if messageType == "Log" then
		addLog(message, color)
	elseif messageType == "Error" then
		addLog("❌ " .. message, Color3.fromRGB(255, 100, 100))
	elseif messageType == "Success" then
		addLog("✅ " .. message, Color3.fromRGB(100, 255, 100))
	end
end)

-- ============================================
-- ✅ INITIALISATION
-- ============================================
addLog("✅ Panel admin initialisé", Color3.fromRGB(100, 255, 100))
addLog("💡 Tape /admin pour ouvrir/fermer", Color3.fromRGB(255, 255, 100))

print("[AdminPanel] ✅ Handler chargé pour", player.Name)
