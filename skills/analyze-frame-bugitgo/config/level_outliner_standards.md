# Level Outliner Standards

Rules for organizing actors and folders inside a level's World Outliner.

## World Partition Setup

All Level Instances (LI) and Actors in a level must have **Runtime Grid = None** (empty).

This is set in the World Partition > Advanced section of each actor/level instance.

## Level Instance Folder Structure (for both Human and CICD tool)

Each Level Instance (e.g., `L_Default_dec_Loc3_8a`) must contain these folders:

| Folder | Loading Range | Purpose | Examples |
|--------|--------------|---------|----------|
| **OUT_ENV** | 200m+ | Outdoor terrain and large visible objects | Mountains, houses, towers, far lights |
| **OUT_DECOR_Far** | 50-100m | Medium-range decorative details | Medium rocks, trees, big plants |
| **OUT_DECOR_Near** | ~50m | Close-range decorative details | Small rocks, small houses, lamp posts, bone piles |
| **INDOOR** | 32m | Objects inside closed spaces | Interior props, dungeon elements |
| **DYNAMIC** | 50m | Runtime-spawned or interactive objects | VFX, enemies, destructibles |
| **WPO_LARGE** | 150m | Large objects with World Position Offset | Trees visible from distance |
| **WPO_SMALL** | 50m | Small objects with World Position Offset | Grass, flowers |
| **WorldDataLayers** | - | Data layer configuration | Data layer actors |

---

## Workflow States (for Human)

### WIP Deco (Work In Progress)
- Not packed yet
- Apply this folder structure
- Must apply Critical Points
- Must add correct Data Layers

### Done Deco
- Pack objects based on folder structure
- Put BP in correct folder
- Must apply Critical Points
- Must add correct Data Layers

### Edge Cases
- Hero props with multiple parts → keep in 1 BP
- Dynamic objects that are epic/important AND far → put in OUT_ENV

## Data Layer Assignment

Every actor must have the correct Data Layer assigned based on its folder location. The Data Layer determines streaming behavior at runtime.

## Critical Points

All level instances must have Critical Points applied for proper streaming priority.
