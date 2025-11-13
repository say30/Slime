-- ========================================
-- SLIME RUSH - EVENT MANAGER
-- Script (Serveur)
-- Localisation: ServerScriptService/EventManager
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local EventConfig = require(ReplicatedStorage.Modules.EventConfig)

local EventManager = {}

-- État événement actuel
local CurrentEvent = nil
local EventStartTime = nil
local NextEventTime = tick() + EventConfig.Settings.Frequency

-- ========================================
-- INITIALISATION
-- ========================================

function EventManager.Initialize()
    print("[EventManager] 🎯 Système d'événements initialisé")

    -- Boucle événements
    spawn(function()
        while true do
            wait(1)

            local now = tick()

            -- Notification 2 min avant
            if not CurrentEvent and now >= NextEventTime - EventConfig.Settings.WarningTime and now < NextEventTime then
                -- Envoyer notification warning
                EventManager.NotifyPlayers("⚠️ Événement dans 2 minutes !")
                wait(EventConfig.Settings.WarningTime)
            end

            -- Démarrer événement
            if now >= NextEventTime and not CurrentEvent then
                CurrentEvent = EventConfig.SelectRandomEvent(now)
                EventStartTime = now

                print(string.format("[EventManager] 🎉 Événement démarré: %s", CurrentEvent.Name))

                EventManager.NotifyPlayers(string.format("🌟 ÉVÉNEMENT: %s", CurrentEvent.Name), CurrentEvent.Description)

                -- TODO: Appliquer effets événement sur spawn local client via RemoteEvent
            end

            -- Terminer événement
            if CurrentEvent and now >= EventStartTime + EventConfig.Settings.Duration then
                print(string.format("[EventManager] ⏱️ Événement terminé: %s", CurrentEvent.Name))

                EventManager.NotifyPlayers("✅ Événement terminé !")

                CurrentEvent = nil
                EventStartTime = nil
                NextEventTime = now + EventConfig.Settings.Frequency
            end
        end
    end)
end

-- ========================================
-- NOTIFIER JOUEURS
-- ========================================

function EventManager.NotifyPlayers(title, description)
    for _, player in ipairs(Players:GetPlayers()) do
        -- Envoyer notification client
        local notifEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("EventNotification")
        if notifEvent then
            notifEvent:FireClient(player, title, description or "")
        end
    end
end

-- ========================================
-- OBTENIR ÉVÉNEMENT ACTUEL
-- ========================================

function EventManager.GetCurrentEvent()
    if CurrentEvent and EventConfig.IsEventActive(EventStartTime) then
        return CurrentEvent, EventConfig.GetTimeRemaining(EventStartTime)
    end
    return nil, 0
end

return EventManager
