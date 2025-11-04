-- from: StarterPlayer.StarterPlayerScripts.PodsSlimeLockedLabel

-- Script local à placer dans StarterPlayerScripts
-- Affiche "verrouillé" en rouge au-dessus des PodsSlime 11 à 22 verrouillés
-- UNIQUEMENT sur la base du joueur

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function getPlayerBase()
    local basesFolder = Workspace:FindFirstChild("Base")
    if not basesFolder then return nil end

    for _, base in basesFolder:GetChildren() do
        if base:IsA("Model") then
            local panneau = base:FindFirstChild("Panneau")
            local part = panneau and panneau:FindFirstChild("Part", true)
            local sg = part and part:FindFirstChildOfClass("SurfaceGui")
            local tl = sg and sg:FindFirstChild("MainFrame") and sg.MainFrame:FindFirstChild("TitleLabel")

            if tl and tl:IsA("TextLabel") then
                local title = tl.Text or ""
                if title == "Base de " .. LocalPlayer.DisplayName or title == "Base de " .. LocalPlayer.Name then
                    return base
                end
            end
        end
    end
    return nil
end

local function showLockedLabels()
    local playerBase = getPlayerBase()
    if not playerBase then return end

    local podsFolder = playerBase:FindFirstChild("PodsSlime")
    if podsFolder then
        for i = 11, 22 do
            local pod = podsFolder:FindFirstChild("PodsSlime" .. i)
            if pod then
                local locked = pod:GetAttribute("Locked")
                if locked == true then
                    if not pod:FindFirstChild("LockedLabel") then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = "LockedLabel"
                        billboard.Size = UDim2.new(0, 100, 0, 30)
                        billboard.Adornee = pod
                        billboard.AlwaysOnTop = true
                        billboard.StudsOffset = Vector3.new(0, 2, 0)
                        billboard.Parent = pod

                        local textLabel = Instance.new("TextLabel")
                        textLabel.Size = UDim2.new(1, 0, 1, 0)
                        textLabel.BackgroundTransparency = 1
                        textLabel.Text = "verrouillé"
                        textLabel.TextColor3 = Color3.new(1, 0, 0)
                        textLabel.TextStrokeTransparency = 0.5
                        textLabel.Font = Enum.Font.SourceSansBold
                        textLabel.TextScaled = true
                        textLabel.Parent = billboard
                    end
                else
                    local label = pod:FindFirstChild("LockedLabel")
                    if label then
                        label:Destroy()
                    end
                end
            end
        end
    end
end

-- Rafraîchir à l'ouverture et toutes les 2 secondes
showLockedLabels()
while true do
    task.wait(2)
    showLockedLabels()
end

-- Ce script affiche "verrouillé" uniquement sur les pods 11 à 22 de la base du joueur.
-- Lorsqu'un pod est déverrouillé (Locked = false), le message disparaît.
