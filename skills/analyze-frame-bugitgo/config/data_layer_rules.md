# Data Layer Configuration Rules

Defines which World Partition Data Layers to enable for each realm set.

---

## Main Data Layers (Realms)

| Data Layer | Realm | Description | Play in Default | Play in Limbo | Cinematic | Status |
|------------|-------|-------------|-----------------|---------------|-----------|--------|
| DL_Cinematic | Cinematic | Cutscene-specific content | ⬜ | ⬜ | ✅ | In use |
| DL_Default | Default | Standard gameplay environment | ✅ | ⬜ | ⬜ | In use |
| DL_Domain | Domain | BVT phase 2, Tiger phase 2, etc. | ⬜ | ⬜ | ⬜ | `Removed` |
| DL_Dream | Dream (old: Mirror) | Mirror world / alternate dimension | ⬜ | ⬜ | ⬜ | In use |
| DL_Fixed_Collision | Shared | Collision shared across all realms | ✅ | ✅ | ⬜ | In use |
| DL_Limbo | Limbo/Fast Travel | Mặc Hải | ⬜ | ✅ | ⬜ | In use |

---

## Data Layer Sets

### Default Set

Standard gameplay environment. DL_Default is a group containing multiple child Data Layers.

| Child Data Layer | Default State | Description |
|------------------|---------------|-------------|
| DL_Default_Audio | ✅ Enabled | Audio volumes and emitters |
| DL_Default_BVT_phase1_light | ⬜ Disabled | BVT phase 1 lighting (legacy) (only available in L_Location_03_PlayTest) |
| DL_Default_Collision | ✅ Enabled | Collision volumes |
| DL_Default_Decor-static | ✅ Enabled | Static decoration props |
| DL_Default_ene | ✅ Enabled | Enemies, bosses, minibosses, traps |
| DL_Default_IO | ✅ Enabled | Interactive objects, quest objects, chests, teleports |
| DL_Default_LD-proto | ⬜ Disabled | Level design prototype (WIP) |
| DL_Default_Light | ✅ Enabled | Main lighting (group) |
| DL_Default_Script-E | ✅ Enabled | Scripted events |
| DL_Default_Temp | ⬜ Disabled | Temporary/WIP content |
| DL_Default_Tiger_phase1_light | ✅ Disabled | Tiger phase 1 lighting (legacy) (only available in L_Location_03_PlayTest) |
| DL_Default_WIP | ⬜ Disabled | Work in progress content |

**Note**: Items marked ⬜ Disabled are OFF by default when playing. Tool should respect these defaults unless user specifies otherwise.

---

### Dream Set

Dream world / alternate dimension (tên cũ: Mirror).

| Child Data Layer | Default State | Description |
|------------------|---------------|-------------|
| DL_Dream_Decor-static | ✅ Enabled | Static decoration props |
| DL_Dream_Enemies | ✅ Enabled | Enemies in Dream realm |
| DL_Dream_Light | ✅ Enabled | Dream realm lighting |

---

### Cinematic Set

For cutscene captures.

| Data Layer | Status | Description |
|------------|--------|-------------|
| DL_Cinematic | ✅ Enabled | Cinematic-specific content |

---

### Limbo Set

Limbo / Fast Travel realm (Mặc Hải).

| Data Layer | Default State | Description |
|------------|---------------|-------------|
| DL_Limbo | ✅ Enabled | Limbo realm (flat, no children) |

---

## Level Instance Streaming Folders (NOT impact Data layer structure)

When loading Level Instances, tool should load content from these folders based on camera distance:

| Folder | Loading Range | Content |
|--------|---------------|---------|
| OUT_ENV | 200m+ | Outdoor environment: mountains, houses, towers, far lights |
| OUT_DECOR_Far | 50-100m | Medium decor: rocks, trees, big plants |
| OUT_DECOR_Near | ~50m | Small decor: small rocks, lamp posts, bone piles |
| INDOOR | 32m | Interior objects: closed spaces, houses, dungeons |
| DYNAMIC | 50m | Dynamic objects: VFX, enemies, destructibles |
| WPO_LARGE | 150m | Large WPO objects: trees with wind animation |
| WPO_SMALL | 50m | Small WPO objects: grass, flowers |

**Note**: For bug screenshot tool, all folders within camera frustum should be loaded.

---

## Naming Convention Reference

### Data Layers
```
DL_{Realm}_{Type}
```

**Realm**:
| Value | Description |
|-------|-------------|
| Default | Standard/Default gameplay |
| Domain | BVT phase 2, Tiger phase 2, etc. (`Removed`) |
| Dream | Dream world (old: Mirror) |
| Cinematic | Not a realm but same structure, to control cutscene/cinematic |
| Limbo | Limbo/Fast Travel/Mặc Hải |

**Type**:
| Value | Description |
|-------|-------------|
| col | Collision |
| dec | Decor-static |
| light | Light, including weathering, VFX, SFX |
| ene | Enemies, including bosses, minibosses, traps |
| IO | Interactive objects, quest objects, chests, teleports |
| LD | Level design prototype |
| Temp/WIP | Temporary (consider merged with WIP) |

### Level Instances
```
L_{Realm}_{Type}_{Location}_{Zone}
```

**Locations**: Loc1, Loc2, Loc3, Loc4

**Zones**: 1, 3b, 2_M, etc.

---

## Notes

- Tool should enable the appropriate realm Data Layer based on user selection
- All sub-types (col, dec, light, etc.) within that realm are auto-included
- Cinematic is not a realm but follows same structure
- Edit this file when new Data Layers are added to the project
