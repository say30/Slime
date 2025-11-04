-- from: ServerScriptService.BaseUpgradeUnlockPods

-- ServerScriptService/BaseUpgradeUnlockPods
-- Script à placer dans ServerScriptService
-- Déverrouille 2 pods lors d'un upgrade de base et informe le client

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local PodLockStatusChanged = ReplicatedStorage:FindFirstChild("PodLockStatusChanged")

local function unlockNextLockedPods(player)
    -- Trouver la base du joueur
    local basesFolder = Workspace:FindFirstChild("Base")
    if not basesFolder then return end

    for _, base in basesFolder:GetChildren() do
        if base:IsA("Model") then
            local panneau = base:FindFirstChild("Panneau")
            local part = panneau and panneau:FindFirstChild("Part", true)
            local sg = part and part:FindFirstChildOfClass("SurfaceGui")
            local tl = sg and sg:FindFirstChild("MainFrame") and sg.MainFrame:FindFirstChild("TitleLabel")

            if tl and tl:IsA("TextLabel") then
                local title = tl.Text or ""
                if title == "Base de " .. player.DisplayName or title == "Base de " .. player.Name then
                    local podsFolder = base:FindFirstChild("PodsSlime")
                    if podsFolder then
                        local unlocked = 0
                        for i = 11, 22 do
                            local pod = podsFolder:FindFirstChild("PodsSlime" .. i)
                            if pod and pod:GetAttribute("Locked") == true then
                                pod:SetAttribute("Locked", false)
                                unlocked = unlocked + 1
                                -- Informer le client pour mettre à jour l'affichage
                                if PodLockStatusChanged then
                                    PodLockStatusChanged:FireClient(player, pod.Name, false)
                                end
                                if unlocked >= 2 then
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Exemple d'intégration : à appeler lors d'un upgrade de base
-- unlockNextLockedPods(player)

-- Pour tester, vous pouvez temporairement déverrouiller 2 pods à la connexion du joueur :
Players.PlayerAdded:Connect(function(player)
    -- task.wait(5)
    -- unlockNextLockedPods(player)
end)

-- Ce script doit être appelé lors de l'upgrade de la base du joueur.
-- Il déverrouille 2 pods et informe le client pour mettre à jour l'affichage.
