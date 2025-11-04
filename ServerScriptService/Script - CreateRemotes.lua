-- from: ServerScriptService.CreateRemotes

-- ServerScriptService/CreateRemotes.lua - Crée les RemoteEvents manquants
-- Place: ServerScriptService
-- Type: Script

local RS = game:GetService("ReplicatedStorage")

-- Créer le dossier Remotes s'il n'existe pas
local remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder", RS)
remotes.Name = "Remotes"

-- Créer les RemoteEvents nécessaires
local getInvRemote = remotes:FindFirstChild("GetInventory") or Instance.new("RemoteFunction", remotes)
getInvRemote.Name = "GetInventory"

local moveRemote = remotes:FindFirstChild("MoveSlimeToInventory") or Instance.new("RemoteFunction", remotes)
moveRemote.Name = "MoveSlimeToInventory"

local sellRemote = remotes:FindFirstChild("SellSlime") or Instance.new("RemoteFunction", remotes)
sellRemote.Name = "SellSlime"

local placeRemote = remotes:FindFirstChild("PlaceSlimeFromInventory") or Instance.new("RemoteFunction", remotes)
placeRemote.Name = "PlaceSlimeFromInventory"

print("✅ Tous les RemoteEvents ont été créés")
