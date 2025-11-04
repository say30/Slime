-- from: ServerScriptService.InitPodsSlimeLocked

-- ServerScriptService/InitPodsSlimeLocked.lua
-- Script à placer dans ServerScriptService pour initialiser l'attribut Locked sur PodsSlime 11 à 22
-- Cela permet au script local d'afficher le message "verrouillé" correctement

local Workspace = game:GetService("Workspace")

local basesFolder = Workspace:FindFirstChild("Base")
if basesFolder then
    for _, base in basesFolder:GetChildren() do
        local podsFolder = base:FindFirstChild("PodsSlime")
        if podsFolder then
            for i = 11, 22 do
                local pod = podsFolder:FindFirstChild("PodsSlime" .. i)
                if pod then
                    pod:SetAttribute("Locked", true)
                end
            end
        end
    end
end

-- Ce script s'exécute au démarrage du serveur et marque les pods 11 à 22 comme verrouillés.
-- Cela permet au script local d'afficher le message "verrouillé" en rouge au-dessus de chaque pod concerné.
