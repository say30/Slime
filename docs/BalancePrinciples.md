# Slime Rush Progression & Balance Notes

This document outlines the guiding principles used to keep Slime Rush engaging over long play sessions. The values exposed in the Lua modules are derived from these goals and can be tuned as the experience evolves.

## Currency Flow
- **Starting Gelatin:** 100 for a quick first purchase.
- **Low Rarity Costs:** The first three rarity tiers cost between 100 and 480 gelatin, allowing new players to secure a small roster quickly.
- **Steep Scaling:** Each rarity tier doubles or more in cost so late-game purchases require contracts, fusion, and base upgrades.
- **Fusion Essence:** Earned primarily from failed fusions and contract completions. Essence is the primary limiter for catalysts, high-tier upgrades, and late base expansions.

## Base Upgrades
| Level | Pods Unlocked | Gelatin Cost | Essence Cost | Notes |
| ----- | ------------- | ------------ | ------------ | ----- |
| 0     | 10 (free)     | -            | -            | Starter footprint. |
| 1     | +2            | 1,500        | 10           | Encourages early saving. |
| 2     | +4            | 6,000        | 40           | Requires contract engagement. |
| 3     | +6            | 24,000       | 120          | Late-game milestone before future floors. |

Pods 23-24 are reserved for the upcoming second floor. Their requirements should exceed level 3 costs and may include unique questlines.

## Inventory Upgrades
- **Base Capacity:** 25 slots.
- **Upgrade Scaling:** 20%, 30%, 50%, 80%, and 100% multipliers respectively.
- **Robux Gate:** The final upgrade is monetized and should only be offered once the player engages with the long-term systems.

## Fusion System
### Two-Slime Fusion
- Baseline 18% success chance to raise rarity.
- Each rarity tier applies a penalty, so attempting to push beyond rarity 8 requires catalysts or repeated attempts.
- Failure has a 65% chance to destroy the slime, refunding 115% of the rarity-based essence payout.

### Three-Slime Fusion
- Supports intents: mutate, corrupt, purify, crystallize.
- Success odds range from 5% to 12% before modifiers.
- Catalysts provide up to +20% success chance depending on type.
- Failure converts all three slimes into essence, making attempts a meaningful sacrifice.

## Contracts
- Three contracts generated per day (easy, medium, hard).
- Each contract targets a mood/rarity pair to encourage collection diversity.
- Rewards always include gelatin and sometimes essence, with higher tiers leaning heavily on essence.

## Catalysts & Shop
- Daily restock limits prevent market flooding.
- Rarity catalysts discount slime purchases when used, creating strategic decisions between buying catalysts or saving for slimes directly.
- Catalysts expire after 24 hours to motivate regular play.

## Slimedex Completion
- 3,600 combinations encourage long-term goals.
- The Slimedex should highlight owned combinations and provide hints for uncollected states to guide fusion experimentation.

These guidelines should evolve with telemetry. Adjust cost curves, success chances, and contract rewards as you observe real player progression.
