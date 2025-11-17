-- ReplicatedStorage/Modules/Shared/AdminConfig.lua
-- ============================================
-- 🔧 CONFIGURATION DU SYSTÈME ADMIN
-- ============================================

local AdminConfig = {}

-- ============================================
-- 👑 LISTE DES ADMINISTRATEURS
-- ============================================
AdminConfig.Admins = {
	[9588755428] = true, -- gos_v1 (TOI)
	-- Ajoute d'autres admins ici si besoin :
	-- [123456789] = true,
}

-- ============================================
-- 🎯 COMMANDES PAR ONGLET
-- ============================================

AdminConfig.Commands = {

	-- 📂 ONGLET 1 : JOUEURS
	Joueurs = {
		{
			Name = "Give Gélatine",
			Description = "Donner de la gélatine à un joueur",
			Icon = "💰",
			Inputs = {
				{Type = "Player", Label = "Joueur"},
				{Type = "Number", Label = "Montant", Default = 1000000}
			},
			Command = "GiveGelatine"
		},
		{
			Name = "Give Essence",
			Description = "Donner de l'essence fusion",
			Icon = "✨",
			Inputs = {
				{Type = "Player", Label = "Joueur"},
				{Type = "Number", Label = "Montant", Default = 10000}
			},
			Command = "GiveEssence"
		},
		{
			Name = "Téléporter vers Base",
			Description = "TP un joueur vers une base",
			Icon = "🚀",
			Inputs = {
				{Type = "Player", Label = "Joueur"},
				{Type = "Number", Label = "Base (1-8)", Default = 1}
			},
			Command = "TeleportToBase"
		},
		{
			Name = "TP vers Moi",
			Description = "Téléporter un joueur vers toi",
			Icon = "👤",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "TeleportToMe"
		},
		{
			Name = "Me TP vers Joueur",
			Description = "Te téléporter vers un joueur",
			Icon = "🎯",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "TeleportMeTo"
		},
		{
			Name = "View Stats",
			Description = "Voir les stats d'un joueur",
			Icon = "📊",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "ViewStats"
		},
		{
			Name = "Reset Data",
			Description = "Effacer les données d'un joueur",
			Icon = "🗑️",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "ResetData"
		},
		{
			Name = "Kick Player",
			Description = "Éjecter un joueur du serveur",
			Icon = "⛔",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "KickPlayer"
		}
	},

	-- 📂 ONGLET 2 : SLIMES
	Slimes = {
		{
			Name = "Spawn Slime Custom",
			Description = "Créer un slime spécifique",
			Icon = "🎨",
			Inputs = {
				{Type = "Player", Label = "Joueur"},
				{Type = "Text", Label = "Mood", Default = "Joyeux"},
				{Type = "Text", Label = "Rareté", Default = "Commun"},
				{Type = "Text", Label = "Taille", Default = "Petit"},
				{Type = "Text", Label = "État", Default = "Normal"}
			},
			Command = "SpawnCustomSlime"
		},
		{
			Name = "Spawn Random Slime",
			Description = "Créer un slime aléatoire",
			Icon = "🎲",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "SpawnRandomSlime"
		},
		{
			Name = "Clear Slimes (Joueur)",
			Description = "Supprimer tous les slimes d'un joueur",
			Icon = "🧹",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "ClearPlayerSlimes"
		},
		{
			Name = "Clear All Slimes",
			Description = "Supprimer TOUS les slimes du serveur",
			Icon = "💥",
			Inputs = {},
			Command = "ClearAllSlimes"
		},
		{
			Name = "List Player Slimes",
			Description = "Afficher la liste des slimes",
			Icon = "📋",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "ListPlayerSlimes"
		},
		{
			Name = "Fill All Pods",
			Description = "Remplir tous les pods avec slimes aléatoires",
			Icon = "🎁",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "FillAllPods"
		}
	},

	-- 📂 ONGLET 3 : ÉCONOMIE
	["Économie"] = {
		{
			Name = "Unlock Pods",
			Description = "Débloquer des pods",
			Icon = "🔓",
			Inputs = {
				{Type = "Player", Label = "Joueur"},
				{Type = "Number", Label = "Nombre (1-22)", Default = 22}
			},
			Command = "UnlockPods"
		},
		{
			Name = "Set Production",
			Description = "Modifier le multiplicateur de production",
			Icon = "⚡",
			Inputs = {
				{Type = "Player", Label = "Joueur"},
				{Type = "Number", Label = "Multiplicateur", Default = 10}
			},
			Command = "SetProduction"
		},
		{
			Name = "Give Catalyseur Mineur",
			Description = "Donner des catalyseurs mineurs",
			Icon = "💎",
			Inputs = {
				{Type = "Player", Label = "Joueur"},
				{Type = "Number", Label = "Quantité", Default = 10}
			},
			Command = "GiveCatalyseurMineur"
		},
		{
			Name = "Give Catalyseur Stable",
			Description = "Donner des catalyseurs stables",
			Icon = "💠",
			Inputs = {
				{Type = "Player", Label = "Joueur"},
				{Type = "Number", Label = "Quantité", Default = 5}
			},
			Command = "GiveCatalyseurStable"
		},
		{
			Name = "Give Catalyseur Parfait",
			Description = "Donner des catalyseurs parfaits",
			Icon = "💫",
			Inputs = {
				{Type = "Player", Label = "Joueur"},
				{Type = "Number", Label = "Quantité", Default = 1}
			},
			Command = "GiveCatalyseurParfait"
		},
		{
			Name = "Set Rebirth Level",
			Description = "Changer le niveau de rebirth",
			Icon = "🔄",
			Inputs = {
				{Type = "Player", Label = "Joueur"},
				{Type = "Number", Label = "Niveau", Default = 10}
			},
			Command = "SetRebirthLevel"
		},
		{
			Name = "Max Inventory",
			Description = "Donner le maximum de slots d'inventaire",
			Icon = "📦",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "MaxInventory"
		},
		{
			Name = "Max All Resources",
			Description = "Maximiser toutes les ressources",
			Icon = "🌟",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "MaxAllResources"
		}
	},

	-- 📂 ONGLET 4 : DEBUG
	Debug = {
		{
			Name = "Print Player Data",
			Description = "Afficher les données dans la console",
			Icon = "🖨️",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "PrintPlayerData"
		},
		{
			Name = "Print Server Stats",
			Description = "Afficher les stats du serveur",
			Icon = "📈",
			Inputs = {},
			Command = "PrintServerStats"
		},
		{
			Name = "List All Bases",
			Description = "Afficher l'attribution des bases",
			Icon = "🏠",
			Inputs = {},
			Command = "ListAllBases"
		},
		{
			Name = "Check DataStore",
			Description = "Vérifier l'intégrité des données",
			Icon = "🔍",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "CheckDataStore"
		},
		{
			Name = "Force Save",
			Description = "Forcer la sauvegarde immédiate",
			Icon = "💾",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "ForceSave"
		},
		{
			Name = "Reload Data",
			Description = "Recharger les données depuis le DataStore",
			Icon = "🔄",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "ReloadData"
		},
		{
			Name = "Clear Server Cache",
			Description = "Vider le cache du serveur",
			Icon = "🗑️",
			Inputs = {},
			Command = "ClearCache"
		},
		{
			Name = "Test Notification",
			Description = "Tester le système de notifications",
			Icon = "🔔",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "TestNotification"
		}
	},

	-- 📂 ONGLET 5 : UTILITAIRES
	Utilitaires = {
		{
			Name = "God Mode",
			Description = "Activer/désactiver l'invincibilité",
			Icon = "🛡️",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "ToggleGodMode"
		},
		{
			Name = "Walkspeed",
			Description = "Modifier la vitesse de marche",
			Icon = "🏃",
			Inputs = {
				{Type = "Player", Label = "Joueur"},
				{Type = "Number", Label = "Vitesse", Default = 100}
			},
			Command = "SetWalkspeed"
		},
		{
			Name = "Jump Power",
			Description = "Modifier la puissance de saut",
			Icon = "🦘",
			Inputs = {
				{Type = "Player", Label = "Joueur"},
				{Type = "Number", Label = "Puissance", Default = 100}
			},
			Command = "SetJumpPower"
		},
		{
			Name = "Noclip",
			Description = "Activer/désactiver le noclip",
			Icon = "👻",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "ToggleNoclip"
		},
		{
			Name = "Fly Mode",
			Description = "Activer/désactiver le mode vol",
			Icon = "✈️",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "ToggleFly"
		},
		{
			Name = "Reset Character",
			Description = "Réinitialiser le personnage",
			Icon = "♻️",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "ResetCharacter"
		},
		{
			Name = "Heal",
			Description = "Soigner un joueur",
			Icon = "❤️",
			Inputs = {
				{Type = "Player", Label = "Joueur"}
			},
			Command = "HealPlayer"
		},
		{
			Name = "Respawn All Players",
			Description = "Respawn tous les joueurs",
			Icon = "🔄",
			Inputs = {},
			Command = "RespawnAll"
		}
	}
}

-- ============================================
-- ✅ VÉRIFICATION DES PERMISSIONS
-- ============================================
function AdminConfig:IsAdmin(userId)
	return self.Admins[userId] == true
end

return AdminConfig
