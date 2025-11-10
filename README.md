# Slime Rush Prototype

This repository contains a Roblox server-side prototype for the **Slime Rush** experience, a game inspired by *Steal a Brainrot*. The focus of this prototype is to provide a well structured foundation covering:

- Player base management and pod unlock flow.
- Slime purchasing pipeline using personal preview spawns before finalizing a purchase.
- Inventory, fusion, and slime state mutation systems with meaningful economic pressure.
- Daily contracts, catalysts, and shop offerings that extend long-term progression.
- Data-driven configuration that supports the 3,600 slime varieties derived from mood, rarity, size, and state.

The project is organized to make it easy to expand individual systems while keeping the overall balance tunable through central configuration tables.

## Directory Layout

```
src/
  ReplicatedStorage/
    SlimeRush/
      Client/
  ServerScriptService/
    SlimeRush/
      Core/
```

- `Core/` modules run on the server. Each module encapsulates a gameplay system (economy, base, inventory, shop, etc.).
- `ReplicatedStorage/SlimeRush/Client/` contains LocalScripts responsible for client interactions such as personal slime previews and UI toggles.

## Key Systems

### Base Manager
Assigns a persistent base to each player as they join, reserves pods, and exposes upgrade hooks. Pods 1-10 are free, 11-22 require upgrades, and pods 23-24 are reserved for future content.

### Slime Catalog & Economy
Defines the 3,600 slime variants programmatically and maps rarity/mood tiers to gelatin prices. Scales cost aggressively so that early slimes are accessible while higher tiers demand late-game resources.

### Fusion
Supports both 2-way (rarity upgrade attempts) and 3-way (state mutation archetypes: corrupt, purify, crystallize, etc.) fusions with configurable success chances, failure penalties, and fusion essence payouts.

### Contracts
Generates three contracts per day (easy/medium/hard) with escalating requirements and rewards. Contracts serve as long-term goals that pressure players to diversify slime collections.

### Inventory & Upgrades
Starts with 25 slots and offers progressive capacity upgrades (20%, 30%, 50%, 80%, 100%) tied to gelatin and fusion essence costs. Base upgrades expand pod availability.

## Getting Started

1. Place the `src/ServerScriptService/SlimeRush` folder inside your Roblox place's `ServerScriptService`.
2. Place the `src/ReplicatedStorage/SlimeRush` folder inside your place's `ReplicatedStorage`.
3. Wire the `init.server.lua` script to your datastore and teleport handlers according to your backend setup.
4. Expand the provided configuration tables to tune drop rates, pricing, and upgrade pacing.

This prototype intentionally focuses on systems and balance scaffolding. You can iterate on art, UI, and content cadence on top of this foundation.
