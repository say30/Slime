# 🎮 SLIME RUSH - Documentation Complète du Projet

## 📋 Vue d'Ensemble

Slime Rush est un jeu Roblox de collection et progression hardcore avec 3,600 variétés de slimes.

**Technologies :** Lua/Luau, Roblox Studio
**Architecture :** Client-Serveur avec DataStore persistence
**Branches :** `claude/slime-rush-game-design-01QFBRngpWuUay84mvEFyHQz`

---

## 📊 Économie du Jeu

### Ressources
- **Gélatine** : Monnaie principale
- **Essence de Fusion** : Monnaie de fusion

### Slimes
- **3,600 variétés** = 12 moods × 12 raretés × 5 tailles × 5 états
- **Production** : Multiplicateur Taille × Multiplicateur Rareté
- **Coût** : Production × 80

### Progression
- **10 PodsSlime** de base → **22 maximum** (6 upgrades)
- **Rebirth** avec sacrifice de slimes spécifiques
- **Contrats journaliers** (3-4/jour)
- **Événements** toutes les 3h

---

## 🗂️ Structure des Fichiers

### ✅ CRÉÉS - ReplicatedStorage/Modules/

| Fichier | Type | Fonction |
|---------|------|----------|
| `SlimeConfig.lua` | ModuleScript | Configuration slimes (moods, raretés, tailles, états) |
| `EconomyConfig.lua` | ModuleScript | Économie (upgrades, rebirth, coûts) |
| `FusionConfig.lua` | ModuleScript | Système de fusion (probabilités, catalyseurs) |
| `ContractConfig.lua` | ModuleScript | 40 contrats + rotation journalière |
| `ShopConfig.lua` | ModuleScript | Shop (boosts, catalyseurs, Robux) |
| `EventConfig.lua` | ModuleScript | Événements temporels |
| `DataManager.lua` | ModuleScript | Structure données joueur + helpers |

### ✅ CRÉÉS - ServerScriptService/

| Fichier | Type | Fonction |
|---------|------|----------|
| `MainServer.lua` | Script | Orchestration serveur principale |
| `DataStoreManager.lua` | Script | Sauvegarde/chargement DataStore |
| `BaseManager.lua` | Script | Attribution bases aux joueurs (8 max/serveur) |
| `SlimeSpawner.lua` | Script | Création slimes côté serveur |
| `ProductionManager.lua` | Script | Calcul production gélatine/s |
| `FusionHandler.lua` | Script | Validation et exécution fusions |
| `ContractManager.lua` | Script | Suivi progression contrats |
| `ShopManager.lua` | Script | Achats shop + gamepasses |
| `RebirthHandler.lua` | Script | Processus rebirth |
| `EventManager.lua` | Script | Gestion événements (spawn, notifications) |
| `ServerMatchmaking.lua` | Script | Téléportation serveurs pleins |

### ✅ CRÉÉS - StarterPlayer/StarterPlayerScripts/

| Fichier | Type | Fonction |
|---------|------|----------|
| `LocalSlimeSpawner.lua` | LocalScript | Spawn slimes locaux (client uniquement) |

### ⚠️ À CRÉER - StarterPlayer/StarterPlayerScripts/

| Fichier | Type | Fonction |
|---------|------|----------|
| `ClientMain.lua` | LocalScript | Initialisation client |
| `UIController.lua` | LocalScript | Gestion ouverture/fermeture menus |
| `PurchaseHandler.lua` | LocalScript | Validation achat avant envoi serveur |
| `BillboardManager.lua` | LocalScript | Mise à jour billboards dynamiques |
| `NotificationManager.lua` | LocalScript | Affichage notifications |

### ⚠️ À CRÉER - StarterGui/

#### MainHUD/
- `HUD.lua` (LocalScript) - Affichage ressources + boutons principaux

#### FusionUI/
- `FusionController.lua` (LocalScript) - Logique fusion à 2 et 3

#### InventoryUI/
- `InventoryController.lua` (LocalScript) - Affichage slimes + catalyseurs

#### ShopUI/
- `ShopController.lua` (LocalScript) - Affichage items + achats

#### ContractUI/
- `ContractController.lua` (LocalScript) - Affichage contrats + progression

#### UpgradeUI/
- `UpgradeController.lua` (LocalScript) - Upgrades base/production/inventaire

#### SlimeDexUI/
- `SlimeDexController.lua` (LocalScript) - Affichage codex (3600 variétés)

#### NotificationUI/
- `NotificationDisplay.lua` (LocalScript) - Popups temporaires

---

## 🔧 Setup Initial (Command Bar)

Exécuter dans **Studio Command Bar** :

```lua
-- Charger et exécuter le script de setup
local setupScript = game:GetService("ReplicatedStorage").setup_structure
loadstring(setupScript.Source)()
```

**Ou** copier le contenu de `setup_structure.lua` directement dans Command Bar.

---

## 🎯 RemoteEvents Créés

**Localisation :** `ReplicatedStorage/RemoteEvents/`

### RemoteEvents
- `PurchaseSlime` - Achat slime local → serveur
- `CollectGelatin` - Collection manuelle gélatine
- `FuseSlimes` - Demande fusion
- `PlaceSlime` - Placer slime inventaire → pod
- `SellSlime` - Vendre slime
- `BuyShopItem` - Achat shop
- `ClaimContract` - Réclamer récompense contrat
- `LikeBase` - Liker base d'un joueur
- `BuyUpgrade` - Acheter upgrade
- `ActivateBoost` - Activer boost temporaire
- `UpdateSlimeDex` - Mise à jour codex
- `DoRebirth` - Effectuer rebirth
- `SkipFusionTimer` - Skip cooldown fusion
- `RequestSlimeList` - Liste slimes plateau (amélioration Robux)
- `UpdateContractProgress` - Serveur → Client mise à jour contrats

### RemoteFunctions
- `GetPlayerData` - Client demande données joueur
- `GetShopItems` - Récupérer items shop du jour
- `GetContracts` - Récupérer contrats actifs
- `GetSlimeDex` - Récupérer progression SlimeDex

---

## 📐 Workspace Structure Requise

```
Workspace/
├── Base/
│   ├── Base 1/
│   │   ├── PodsSlime/
│   │   │   ├── PodsSlime1 à PodsSlime22
│   │   ├── Panneau/
│   │   │   └── Part/SurfaceGui/MainFrame/
│   │   │       ├── TitleLabel
│   │   │       └── LikeContainer/LikeCount
│   │   ├── Recolte/
│   │   │   ├── Hitbox (Part avec Touched event)
│   │   │   └── Main/CollectorGui/
│   │   │       ├── SR_CollectLabel
│   │   │       └── SR_RateLabel
│   │   └── structure base home (Part/Model)
│   ├── Base 2/ ... Base 8/ (même structure)
├── DropPlate (Part où slimes locaux atterrissent)
├── MapCenter (Part, centre de spawn)
├── LocalSlimes/ (Créé dynamiquement)
│   └── [PlayerName]/ (Dossier par joueur)
└── PlayerBases/ (Créé dynamiquement)
    └── Player_[UserId]/ (Slimes serveur)
```

---

## 🎨 Système de Couleurs

### Raretés
| Rareté | Couleur HEX | RGB |
|--------|-------------|-----|
| Commun | #BDBDBD | 189,189,189 |
| Vibrant | #3CB371 | 60,179,113 |
| Rare | #1E90FF | 30,144,255 |
| Arcane | #6A5ACD | 106,90,205 |
| Épique | #8A2BE2 | 138,43,226 |
| Légendaire | #FFD700 | 255,215,0 |
| Mythique | #FF4500 | 255,69,0 |
| Occulte | #2F4F4F | 47,79,79 |
| Céleste | #87CEFA | 135,206,250 |
| Abyssal | #4B0082 | 75,0,130 |
| Prismatique | #FF00FF | 255,0,255 |
| Oméga | #FFFFFF | 255,255,255 |

### Moods
| Mood | Couleur HEX |
|------|-------------|
| Joyeux | #73C83C |
| Amoureux | #FF64A0 |
| Calme | #46C8FF |
| Timide | #A078DC |
| Colérique | #FF4A3A |
| Endormi | #FF8C32 |
| Énergique | #FFD23C |
| Triste | #3050C8 |
| Sérieux | #3CA858 |
| Rêveur | #2BC7B8 |
| Fier | #D4AF37 |
| Neutre | #C8C8D0 |

---

## 🔐 DataStore Structure

**DataStore Name :** `SlimeRushData_V1`

```lua
PlayerData = {
    -- Ressources
    Gelatin = 100,
    Essence = 0,
    GelatinLifetime = 0,

    -- Progression
    BaseLevel = 0, -- 0-6
    ProductionUpgradeLevel = 0, -- 0-10
    InventoryUpgradeLevel = 0, -- 0-8
    RebirthLevel = 0, -- 0-5

    -- Inventaire
    Inventory = {{Mood, Rarity, Size, State, UniqueID}, ...},
    Catalysts = {Stability=0, Chance10=0, ...},

    -- Base
    PlacedSlimes = {[1]={...}, [2]=nil, ...}, -- Index = PodIndex
    AccumulatedProduction = {[1]=amount, ...},

    -- Contrats
    DailyContracts = {{ID, Progress, Claimed}, ...},
    LastContractReset = timestamp,
    ContractProgress = {TotalPurchased, ...},

    -- SlimeDex
    SlimeDex = {["1_1_1_1"]=true, ...},

    -- Shop
    ShopCooldowns = {["ItemID"]=timestamp, ...},
    LastShopReset = timestamp,
    PermanentUpgrades = {ShopDiscount25=false, ...},

    -- Robux
    RobuxUpgrades = {TeleportFast=false, ...},
    Gamepasses = {VIPPremium=false, ...},

    -- Boosts
    ActiveBoosts = {{Type, EndTime}, ...},

    -- Fusion
    LastFusionTime = timestamp,
    FusionSkipsAvailable = 0,
    LastFusionSkipReset = timestamp,

    -- Matchmaking
    AssignedBaseIndex = 1-8,

    -- Stats
    LastJoinTime = timestamp,
    TotalPlayTime = seconds
}
```

---

## 🚀 Ordre d'Initialisation

### Serveur (MainServer.lua)
1. ✅ **DataStoreManager** : Chargement données
2. ✅ **BaseManager** : Attribution base (1-8)
3. ✅ **ProductionManager** : Démarrage loop production
4. ✅ **ContractManager** : Vérification reset journalier
5. ✅ **ShopManager** : Vérification reset shop
6. ✅ **EventManager** : Initialisation loop événements

### Client (ClientMain.lua - À CRÉER)
1. ⚠️ Demande données joueur via `GetPlayerData`
2. ⚠️ **UIController** : Initialisation HUD
3. ⚠️ **LocalSlimeSpawner** : Démarrage spawn local ✅
4. ⚠️ **NotificationManager** : Prêt à recevoir notifications

---

## 🎮 Gameplay Flow

### Achat Slime
1. **Client** : Slime spawn localement (LocalSlimeSpawner) ✅
2. **Client** : Joueur clique (ClickDetector) ✅
3. **Client → Serveur** : `PurchaseSlime:FireServer(slimeData)` ✅
4. **Serveur** : Validation ressources + pod disponible ✅
5. **Serveur** : Création slime serveur (SlimeSpawner) ✅
6. **Serveur** : Mise à jour DataStore ✅
7. **Serveur → Client** : Confirmation achat ✅

### Fusion
1. **Client** : Sélection 2-3 slimes (FusionUI - À CRÉER)
2. **Client** : Vérification timer local
3. **Client → Serveur** : `FuseSlimes:FireServer(type, slimes, catalysts)`
4. **Serveur** : Validation + calcul probabilités (FusionHandler) ✅
5. **Serveur** : Succès → nouveau slime inventaire ✅
6. **Serveur** : Échec → récupération essence ✅
7. **Serveur → Client** : Résultat + animation ✅

### Production
1. **Serveur** : Loop 1s calcul production par pod ✅
2. **Serveur** : Accumulation dans `AccumulatedProduction[podIndex]` ✅
3. **Client** : Affichage temps réel (SR_CollectLabel via ProductionManager) ✅
4. **Client/Serveur** : Collection via Hitbox.Touched ou ProximityPrompt ✅

---

## 🐛 Anti-Exploit Measures

✅ **Validations Serveur :**
- Tous les achats validés côté serveur
- Fusions validées (inventaire, ressources, timer)
- Ownership des slimes vérifiée
- Production calculée côté serveur uniquement

✅ **Protections :**
- RemoteEvents avec checks UserId
- DataStore avec retry + validation
- Cooldowns serveur (fusion, shop)

---

## 📝 TODO Liste

### Priorité HAUTE
- [ ] Créer `ClientMain.lua`
- [ ] Créer `UIController.lua` + tous les controllers UI
- [ ] Créer interfaces UI (ScreenGuis) dans StarterGui
- [ ] Implémenter système de Likes (panneau bases)
- [ ] Implémenter téléportation vers structure base home après achat
- [ ] Implémenter mouvement slime vers PodsSlime disponible
- [ ] Tester DataStore save/load
- [ ] Configurer DevProducts/Gamepasses IDs dans ShopManager

### Priorité MOYENNE
- [ ] Système de quêtes narratives (optionnel)
- [ ] Trading system (Phase 2)
- [ ] Leaderboards (serveur-wide)
- [ ] Tutoriel interactif FTUE

### Priorité BASSE
- [ ] Customisation base cosmétique
- [ ] Système de visites (VIP feature)
- [ ] 7e upgrade base (étages + PodsSlime supplémentaires)

---

## 🎨 UI Layout (Mobile-First)

### HUD Principal (Toujours visible)
```
┌─────────────────────────────────────────┐
│ 💧 Gélatine  ✨ Essence  📊 Lifetime  │ Haut
├─────────────────────────────────────────┤
│ [🔀] Fusion                             │ Gauche
│ [🎒] Inventaire                         │
│ [📖] SlimeDex                           │
│ [📋] Contrats                           │
│ [🛒] Shop                               │
│ [⬆️] Upgrade                            │
├─────────────────────────────────────────┤
│                                         │
│        (Zone de jeu)                    │
│                                         │
├─────────────────────────────────────────┤
│ 🚀 Prod +100%  ⏱️ 12:34               │ Bas droit
│ 🤖 Auto-Collect ⏱️ 45:12              │
└─────────────────────────────────────────┘
```

### Tailles Minimales (Mobile)
- Boutons : `60×60 pixels`
- Texte : `UDim2.new(0, ..., 0, ...)` + TextScaled
- Marges : `8-12 pixels`

---

## 💡 Suggestions d'Optimisation

### Performance
- **Limite particules** : Max 50 ParticleEmitters actifs
- **Billboard MaxDistance** : 50 studs
- **Despawn slimes locaux** : Si > 15 sur plateau
- **Throttle updates UI** : 0.5s au lieu de temps réel

### UX
- **Feedback visuel** : Tweens pour achats/fusions
- **Sons** : Achat, fusion succès/échec, collection
- **Vibration mobile** : Pour événements importants

---

## 📞 Support

Pour bugs/suggestions, créer une issue sur le repository GitHub.

**Version :** 1.0.0-alpha
**Date :** 2025-01-13
**Auteur :** Développé par Claude pour say30/Slime
