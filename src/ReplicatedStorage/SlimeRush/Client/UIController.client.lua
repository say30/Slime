local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("SlimeRushRemotes")

local buttons = {}
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SlimeRushHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local buttonNames = {"Fusion", "Inventaire", "SlimeDex", "Shop", "Contrat"}

local function createButton(index, name)
    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Text = name
    button.Font = Enum.Font.GothamBold
    button.TextScaled = true
    button.Size = UDim2.new(0, 150, 0, 42)
    button.Position = UDim2.new(0, 16 + ((index - 1) * 160), 1, -56)
    button.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    button.TextColor3 = Color3.fromRGB(255, 225, 160)
    button.AutoButtonColor = true
    button.Parent = screenGui
    return button
end

for index, name in ipairs(buttonNames) do
    buttons[name] = createButton(index, name)
end

local panelStates = {}

local function togglePanel(panelName)
    panelStates[panelName] = not panelStates[panelName]
    -- Hook up with actual UI panels when implemented.
end

for name, button in pairs(buttons) do
    button.MouseButton1Click:Connect(function()
        togglePanel(name)
        if name == "Inventaire" then
            local inventory = Remotes.RequestInventory:InvokeServer()
            -- Display inventory contents when UI exists.
        elseif name == "Shop" then
            local shop = Remotes.RequestShopStock:InvokeServer()
        elseif name == "Contrat" then
            local contracts = Remotes.RequestContracts:InvokeServer()
        end
    end)
end

return {
    Buttons = buttons,
    TogglePanel = togglePanel,
}
