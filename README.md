# 🎮 Slime Rush

Un jeu Roblox de collection hardcore avec **3,600 variétés** de slimes à collecter.

## 🚀 Quick Start

### 1. Setup Initial (Roblox Studio)

Dans **Command Bar**, exécuter :

```lua
-- Charger le script de setup
dofile("setup_structure.lua")
```

Cela créera automatiquement :
- ✅ Tous les dossiers (ReplicatedStorage, ServerScriptService, etc.)
- ✅ Tous les RemoteEvents/RemoteFunctions
- ✅ Structure Workspace validation

### 2. Workspace Requis

Créer manuellement dans Workspace :
- `Base/` avec Base 1 à Base 8 (structure détaillée dans `PROJECT_DOCUMENTATION.md`)
- `DropPlate` (Part)
- `MapCenter` (Part)

### 3. Slimes Models

Dans `ReplicatedStorage/Slimes/`, organiser vos models :

```
Slimes/
├── Joyeux/
│   ├── Micro/ (Model ici)
│   ├── Petit/ (Model ici)
│   ├── Moyen/ (Model ici)
│   ├── Grand/ (Model ici)
│   └── Titan/ (Model ici)
├── Amoureux/
│   └── ... (même structure)
└── ... (12 moods au total)
```

## 📊 Système

- **Moods** : 12 (Joyeux, Amoureux, Calme, etc.)
- **Raretés** : 12 (Commun → Oméga)
- **Tailles** : 5 (Micro → Titan)
- **États** : 5 (Aucun, Pur, Muté, Fusionné, Cristallisé, Corrompu)

**Total variétés** : 12 × 12 × 5 × 5 = **3,600 slimes**

## ✅ Ce qui est FAIT

### Backend Complet (Serveur)
- ✅ **Système de sauvegarde** (DataStore avec retry + validation)
- ✅ **Matchmaking** (8 bases/serveur, téléportation auto si plein)
- ✅ **Production** (calcul/s avec upgrades + rebirth + boosts)
- ✅ **Fusion** (2 types, probabilités, catalyseurs, timer)
- ✅ **Contrats** (40 contrats, rotation journalière, progression)
- ✅ **Shop** (boosts temporaires, catalyseurs, permanent upgrades, Robux)
- ✅ **Rebirth** (sacrifice de slimes, multiplicateurs cumulatifs)
- ✅ **Événements** (toutes les 3h, 10 types d'événements)
- ✅ **Économie hardcore** (équilibrée pour mois/années de jeu)

### Frontend (Client)
- ✅ **Spawn local slimes** (visible uniquement par joueur, anti-snipe)
- ✅ **Billboards dynamiques** (mood, taille, rareté, production, coût)
- ✅ **Système d'achat** (ClickDetector → validation serveur)

## ⚠️ À IMPLÉMENTER

### Scripts Client
- `ClientMain.lua` - Initialisation client
- `UIController.lua` - Gestion menus
- Tous les controllers UI (Fusion, Inventory, Shop, etc.)

### Interfaces UI
- MainHUD (ressources + boutons)
- FusionUI (2 onglets)
- InventoryUI (slimes + catalyseurs)
- ShopUI (items rotation)
- ContractUI (progression)
- UpgradeUI (base/production/inventaire)
- SlimeDexUI (codex 3600 variétés)
- NotificationUI (popups)

### Gameplay
- Mouvement slime acheté → structure base home → PodsSlime
- Système de Likes (panneau bases)
- Animations/effets visuels
- Sons

## 📝 Documentation

- **Détails complets** : `PROJECT_DOCUMENTATION.md`
- **Économie** : Voir section "Économie du Jeu" dans la doc
- **DataStore structure** : Voir section "DataStore Structure"

## 🔧 Configuration

### IDs à remplacer (ShopManager.lua)
```lua
local GAMEPASS_IDS = {
    VIPPremium = 0, -- Remplacer par vrai ID
    AutoFusion = 0,
    MegaInventory = 0,
    DoubleRebirth = 0
}
```

### DataStore
- **Nom** : `SlimeRushData_V1`
- **Auto-save** : Toutes les 5 minutes
- **Retry** : 3 tentatives avec backoff

## 🎯 Prochaines Étapes

1. Créer les models de slimes dans ReplicatedStorage/Slimes/
2. Tester le spawn local (devrait fonctionner immédiatement)
3. Créer les UI controllers (templates fournis dans doc)
4. Configurer les gamepasses Robux
5. Tester en multiplayer (8 joueurs max/serveur)

## 📊 Économie Highlights

| Item | Coût | Gain |
|------|------|------|
| Slime Micro Commun | 80 gélatine | 1 gélatine/s |
| Upgrade Base 1 | 3.5M gélatine | +2 PodsSlime |
| Fusion à 2 (base) | 1K gélatine + 150 essence | 35% succès |
| Rebirth 1 | 100B gélatine + 50M essence | ×1.25 production |

## 🐛 Debug

### Logs importants
- `[DataStore]` - Sauvegarde/chargement
- `[BaseManager]` - Attribution bases
- `[Production]` - Calcul production
- `[FusionHandler]` - Résultats fusions
- `[LocalSlimeSpawner]` - Spawn client

## 📞 Support

Issues/bugs : [GitHub Issues](https://github.com/say30/Slime/issues)

---

**Version** : 1.0.0-alpha
**Branche** : `claude/slime-rush-game-design-01QFBRngpWuUay84mvEFyHQz`
**Status** : Backend complet ✅ | Frontend en cours ⚠️
