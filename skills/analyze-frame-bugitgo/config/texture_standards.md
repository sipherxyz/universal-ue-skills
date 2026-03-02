# Texture Standards & Validation Rules

Defines texture requirements and validation checks for material scanning.

---

## Deprecated Material Nodes (UE 5.6 → 5.7)

Nodes deprecated in UE 5.7 that should be flagged during material validation.

| Node | Replacement | Severity | Notes |
|------|-------------|----------|-------|
| WorldAlignedTexture | Manual replacement with TriPlanar setup | ⚠️ Warning | Deprecated in 5.7 |
| DepthFade | SceneDepth + custom math | ⚠️ Warning | Deprecated in 5.7 |
| SphereMask | Manual sphere distance calculation | ⚠️ Warning | Limited functionality |
| AntialiasedTextureMask | Alternative sampling methods | ⚠️ Warning | Performance concerns |

---

## Section 1: Validation Rules (Used by Skill)

### Resolution Limits

| Texture Type (Prefix) | Max Resolution | Condition |
|-----------------------|----------------|-----------|
| `T_mc_`, `T_npc_`, `T_boss_`, `T_eboss_` | >0, ≤4096 | If Texture Group = None AND imported size > 2048 |
| `T_env_`, `T_ene_`, `T_eli_` | >0, ≤4096 | ⚠ Warning if = 4096 |
| Others | >0, ≤2048 | If Texture Group = None |
| Any (with Texture Group) | =0 OK | Max Resolution of Texture Group must be >0, <4096 |

**Notes**:
- **Max Resolution = 0** means "use default" in UE, not zero pixels
- When Texture Group is set, Max Resolution = 0 is valid (inherits from group)
- When Texture Group = None and Imported size > 2048, Max Resolution must be explicitly set (>0)
- All textures must be Power of 2 (except UI and _VAT)

---

### Texture Group Suggestion

Recommended Texture Group based on Type and SubType in texture name. Type takes priority over SubType.

| Pattern | Location | Recommended Texture Group |
|---------|----------|---------------------------|
| `_mc_` | Type or SubType | Character |
| `_npc_` | Type or SubType | Character |
| `_ene_` | Type or SubType | Character |
| `_eli_` | Type or SubType | Character |
| `_boss_` | Type or SubType | Character |
| `_eboss_` | Type or SubType | Character |
| `_env_` | Type or SubType | World |
| `_proto_` | Type or SubType | World |
| `_UI_` | Type | UI |

**Priority Rules**:
- **Type** (first segment after `T_`) takes precedence over SubType
- Example: `T_env_ene_beast_D` → Type is `env_`, so Texture Group = **World** (not Character)
- Example: `T_ene_wea_sword_D` → Type is `ene_`, so Texture Group = **Character**

---

### Virtual Texture (VT) Rules

| Condition | VT Setting | Notes |
|-----------|------------|-------|
| `MI_` = Translucent/Additive | VT OFF | Required |
| NOT `T_VFX_`, NOT `T_UI_` | Streamable/Allow Mips | Required |
| Textures have suffix `_DpR`, `_DpRA` | VT ON | Required |

---

### sRGB Settings by Suffix

| sRGB ON ✅ | sRGB OFF ⬜ |
|-----------|------------|
| `_D` | `_N` |
| `_BC` , `_B`, `_C` | `_T` |
| `_E` | `_DpR` |
| `_CO` | `_DpRA` |
| | `_CTAC` |
| | `_MRO` |
| | `_Velocity` |
| | `_ORM` |
| | `_Mask` |
| | `_TSx` |
| | `_VAT` |

---

### Scan Priority by Folder

| Priority | Folder | Action |
|----------|--------|--------|
| 🔴 HIGH | `\Content\S2` | Full validation |
| 🟡 LOW | `\Content\Megascans` | Basic checks only |
| 🟡 LOW | `\Content\ArtRef` | Basic checks only |
| ⬜ SKIP | `\Content\S2\Temp` | Skip if NOT ref in build |

---

### Material Validation Checks (Automated)

1. **Power of 2**: All textures (except UI and Data textures) must have Po2 dimensions
2. **Max Resolution**: Check against type limits above
3. **VT Status**: Verify VT on/off based on material blend mode
4. **sRGB Setting**: Verify sRGB matches suffix rules
5. **Allow Mips**: Verify enabled for non-VFX/UI/Data textures

---

### Issue Severity Levels

| Severity | Color | Action |
|----------|-------|--------|
| Critical | 🔴 Red | Must fix before shipping |
| Warning | 🟡 Yellow | Should fix, may impact performance or cause hidden issues |
| Info | 🔵 Blue | Suggestion, optional fix |

#### Severity Mapping by Violation

| Violation | Severity | Reason |
|-----------|----------|--------|
| `T_boss_`, `T_eboss_` with imported size ≥4096, Max Resolution = 0 | ⚠️ Warning | Large textures should have explicit resolution limit |
| `T_env_`, `T_ene_`, `T_eli_` with imported size = 4096 | ⚠️ Warning | At upper limit, consider if necessary |
| `_MRO` suffix with sRGB = ON | ⚠️ Warning | Data texture should not have sRGB |
| `_N` suffix with sRGB = ON | ⚠️ Warning | Normal maps must not have sRGB |
| VT = ON when material is Translucent/Additive | ⚠️ Warning | VT incompatible with these blend modes |
| Non-Power of 2 dimensions (except UI/Data) | 🔴 Critical | Required for mip streaming |
| Missing Allow Mips on streamable texture | 🔴 Critical | Breaks texture streaming |

---

### Validation Workflow

The automated validation follows this flow:

```
1. Parse texture name → Extract prefix (T_mc_, T_env_, etc.) and suffix (_D, _N, _MRO, etc.)

2. Check basic properties:
   ├─ Power of 2? (except T_UI_ and _VAT suffix)
   ├─ Import size vs Max Resolution limits
   └─ sRGB setting matches suffix rules?

3. If VT is ON → Find all Material Instances using this texture:
   ├─ For each MI, check Blend Mode (Opaque, Masked, Translucent, Additive)
   ├─ If ANY MI is Translucent or Additive → VT should be OFF
   └─ Report warning with list of affected MIs

4. Check Allow Mips:
   └─ Must be ON unless T_VFX_, T_UI_, or _VAT suffix
```

---

### Validation Examples

#### Example 1: `T_ene_fear_03_D`
| Check | Value | Result |
|-------|-------|--------|
| Import size | 4096x4096 | ✅ Po2 = Checked |
| Max resolution | 0 | ⚠️ Warning (Texture Group = None AND imported > 2048) |
| VT | On | → Check material instances |
| Check blending mode of materials using this texture | MI_ene_fear_03: Opaque | |
| | MI_ene_fear_03_v2: Opaque | |
| | | ✅ VT = On is OK (all opaque) |
| Allow mips | ON | ✅ OK |
| Suffix `_D` + sRGB | ON | ✅ OK |

#### Example 2: `T_env_dec_redtree_MRO`
| Check | Value | Result |
|-------|-------|--------|
| Import size | 2048x256 | ✅ Po2 = Checked |
| Max resolution | 0 | ✅ OK (Texture Group = None AND imported < 4096) |
| VT | On | → Check material instances |
| Check blending mode of materials using this texture | MI_env_gianttree_01: Opaque | |
| | MI_ene_redbeast_cloth: Masked | |
| | | ✅ VT = On is OK |
| Allow mips | ON | ✅ OK |
| Suffix `_MRO` + sRGB | ON | ⚠️ Warning (should be OFF) |

#### Example 3: `T_boss_Lion_cloth_N`
| Check | Value | Result |
|-------|-------|--------|
| Import size | 8192x8192 | ✅ Po2 = Checked |
| Max resolution | 0 | ⚠️ Warning (Texture Group = None AND imported ≥ 4096) |
| VT | On | → Check material instances |
| Check blending mode of materials using this texture | MI_boss_Lion_cloth_01: Masked | |
| | MI_boss_Lion_cloth_v3: Additive | |
| | | ⚠️ Warning (VT = On is NOT OK, Additive material found) |
| Allow mips | ON | ✅ OK |
| Suffix `_N` + sRGB | OFF | ✅ OK |

---

## Section 2: Reference Information (Naming Convention)

> This section is for reference only - not directly used by validation.

### Texture Naming Pattern

```
T_Type_SubType_..._suffix
```

### Type Prefixes

| Prefix | Description |
|--------|-------------|
| `template_` | Template |
| `wea_` | Weapons |
| `mc_` | Main character |
| `npc_` | Non-playable character |
| `ene_` | Enemies |
| `eli_` | Elite enemies (miniboss) |
| `boss_` | Boss |
| `eboss_` | Epic boss |
| `env_` | Environment |
| `proto_` | Prototype |
| `VFX_` | VFX |
| `UI_` | UI element |

### SubType - Characters (`mc_`, `npc_`)

| SubType | Description |
|---------|-------------|
| `cos_` | Costumes |

### SubType - Weapons (`wea_`)

| SubType | Description |
|---------|-------------|
| `ene_` | Weapon for enemies |
| `mc_` | Weapon for main character |

### SubType - Environment Realm (`Default_`, `Domain_`, `Dream_`, `Cinematic_`)

| SubType | Description |
|---------|-------------|
| `col_` | Collision |
| `dec_` | Decor-static |
| `light_` | Light (including weathering, vfx, sfx) |
| `ene_` | Enemies (including bosses, minibosses, traps) |
| `IO_` | Interactive objects (quest objects, chests, teleports) |
| `LD_` | Level design prototype |
| `Temp_` | Temporary (consider merged with WIP) |

### SubType - Environment Asset (`env_`)

| SubType | Description |
|---------|-------------|
| `prop_` | General props |
| `hprop_` | Hero props |
| `do_` | Destroyable objects |
| `LightObj_` | Lighting objects |
| `io_` | Interactive objects |

### Suffixes

| Suffix | Description |
|--------|-------------|
| `_D` | Diffuse |
| `_N` | Normal |
| `_T` | (unspecified) |
| `_BC`, `_B`, `_C` | Base Color |
| `_CO` | Color/Opacity |
| `_E` | Emissive |
| `_DpR` | Displacement/Roughness |
| `_DpRA` | Displacement/Roughness/Ambient Occlusion |
| `_CTAC` | Concave/Thickness/Ambient Occlusion/Convex |
| `_MRO` | Metallic/Roughness/Occlusion |
| `_Velocity` | Velocity map |
| `_ORM` | Opacity/Roughness/Metalic |
| `_Mask` | Multi masks for Micro details |
| `_TSx` (for example `_TS0`, `_TS1`, `_TS2.`..) | Hair Card |
| `_VAT` | Vertex Animation Texture (non-Po2 allowed)(not allow Mip) |

---

## Notes

- Resolution limits based on texture type prefix
- sRGB settings must match suffix for correct rendering
- VT must be OFF for translucent/additive materials
- Edit this file when standards change
