# AnimMontage (AMT_) Analysis Patterns

Reference for S2 project-specific patterns used in montage analysis.

## Notify Class Patterns

### Audio Notifies (S2 Project)

| Class Name | Purpose | Detection Pattern |
|------------|---------|-------------------|
| `AN_S2_Foley_Base` | Base foley event | `AN_S2_Foley_*` |
| `AN_S2_Foley_Walk_L` | Left foot walk | `*Foley*Walk*` |
| `AN_S2_Foley_Walk_R` | Right foot walk | `*Foley*Walk*` |
| `AN_S2_Foley_Run_L` | Left foot run | `*Foley*Run*` |
| `AN_S2_Foley_Run_R` | Right foot run | `*Foley*Run*` |
| `AN_S2_Foley_Sprint_L` | Left foot sprint | `*Foley*Sprint*` |
| `AN_S2_Foley_Sprint_R` | Right foot sprint | `*Foley*Sprint*` |
| `AN_S2_Foley_Jump` | Jump takeoff | `*Foley*Jump*` |
| `AN_S2_Foley_Land` | Landing | `*Foley*Land*` |
| `AN_S2_Foley_Fall` | Falling loop | `*Foley*Fall*` |
| `AN_S2_Foley_Scuff_L` | Left scuff | `*Foley*Scuff*` |
| `AN_S2_Foley_Scuff_R` | Right scuff | `*Foley*Scuff*` |
| `AN_S2_Foley_Handplant_L` | Left hand plant | `*Foley*Hand*` |
| `AN_S2_Foley_Handplant_R` | Right hand plant | `*Foley*Hand*` |
| `AN_S2_Foley_DetectGround` | Ground type detection | `*DetectGround*` |
| `AN_S2_Voice_Attack` | Attack vocalization | `*Voice*Attack*` |
| `AN_S2_Voice_GetHit` | Hit reaction voice | `*Voice*Hit*` |
| `AN_S2_Voice` | Generic voice event | `AN_S2_Voice` |

### VFX Notifies (Engine + Project)

| Class Name | Purpose | Detection Pattern |
|------------|---------|-------------------|
| `AnimNotify_PlayNiagaraEffect` | One-shot Niagara | `*Niagara*` |
| `AnimNotifyState_TimedNiagaraEffect` | Duration Niagara | `*TimedNiagara*` |
| `AnimNotify_PlayParticleEffect` | Legacy Cascade | `*Particle*` |

### Combat Notifies (S2 Project)

| Class Name | Purpose | Detection Pattern |
|------------|---------|-------------------|
| `SipherAbilityNotifyData_Hitbox` | Hitbox window | `*Hitbox*` |
| `DamageShape_Sphere` | Spherical damage | `DamageShape_*` |
| `DamageShape_Box` | Box damage | `DamageShape_*` |
| `DamageShape_Capsule` | Capsule damage | `DamageShape_*` |
| `EDamageImpact::Light` | Light hit impact | `EDamageImpact*` |
| `EDamageImpact::Heavy` | Heavy hit impact | `EDamageImpact*` |
| `EDamageImpact::Launch` | Launch impact | `EDamageImpact*` |

### Movement Notifies

| Class Name | Purpose | Detection Pattern |
|------------|---------|-------------------|
| `BP_NotifyState_MotionWarping` | Motion warping window | `*MotionWarp*` |
| `RootMotionModifier_*` | Root motion adjustment | `RootMotion*` |

### Camera Notifies

| Class Name | Purpose | Detection Pattern |
|------------|---------|-------------------|
| `BP_CameraShake_*` | Project camera shake | `*CameraShake*` |
| `AnimNotify_CameraShake` | Engine camera shake | `*CameraShake*` |

---

## Slot Names

Common slot names in montages:

| Slot Name | Layer | Description |
|-----------|-------|-------------|
| `DefaultSlot` | Full body | Default montage slot |
| `DefaultGroup.DefaultSlot` | Full body | Qualified default |
| `UpperBody` | Upper | Upper body only |
| `Additive` | Additive | Layered additive |
| `Face` | Face | Facial animations |
| `Weapon` | Weapon | Weapon-specific |

---

## Naming Conventions (S2 Project)

### Attack Montages
```
AMT_{Character}_Attack{N}              # Basic numbered attacks
AMT_{Character}_Combo{N}               # Combo sequences
AMT_{Character}_Special_{Name}         # Special moves
AMT_{Character}_ChargeAttack           # Charged attacks
AMT_{Character}_Heavy_{N}              # Heavy attacks
AMT_{Character}_Light_{N}              # Light attacks
```

### Defensive Montages
```
AMT_{Character}_HitReact_{Dir}_{Weight}  # Hit reactions
AMT_{Character}_Dodge_{Dir}              # Dodges (F/B/L/R)
AMT_{Character}_Block                    # Blocking
AMT_{Character}_Parry                    # Parrying
AMT_{Character}_Defense{N}               # Defensive actions
```

### State Montages
```
AMT_{Character}_Death                   # Death animation
AMT_{Character}_Stun                    # Stunned state
AMT_{Character}_GetUp_{Dir}             # Recovery from knockdown
AMT_{Character}_Stunned                 # Alternative stun naming
```

### Boss Phase Variants
```
AMT_{Character}_Attack01_Fire_Phase3    # Phase-specific variant
AMT_{Character}_Phase2_ComboToGrab      # Phase transition combo
```

### Suffixes
| Suffix | Meaning |
|--------|---------|
| `_RM` | Root Motion enabled |
| `_IP` | In-Place (no root motion) |
| `_Quick` / `_quick` | Faster variant |
| `_Slow` | Slower variant |
| `_quickrecovery` | Fast recovery |
| `_no_anticipate` | Reduced anticipation |
| `_Fire_Phase3` | Phase 3 fire variant |
| `_DoubleHit` | Double hit variant |

---

## Quality Checklist by Montage Type

### Attack Montages
- [ ] Has at least one hitbox notify
- [ ] Has attack SFX (whoosh/swing sound)
- [ ] Has impact VFX setup
- [ ] Has motion warping (for gap-closing attacks)
- [ ] Has camera shake (for heavy attacks)
- [ ] No TEMP references

### Hit Reaction Montages
- [ ] Has voice notify (pain grunt)
- [ ] Appropriate duration for weight
- [ ] Root motion or proper blend settings
- [ ] Direction-appropriate (F/B/L/R)

### Death Montages
- [ ] Has voice notify (death sound)
- [ ] Has VFX (if special death type)
- [ ] Appropriate blend out time
- [ ] No loop sections

### Dodge Montages
- [ ] Has foley notifies
- [ ] Has motion warping for distance
- [ ] I-frames marked (if applicable)
- [ ] Direction-appropriate movement

---

## Expected Skeleton References

| Character Type | Expected Skeleton |
|---------------|-------------------|
| Player (Daji) | `SK_Daji` or `SK_Female_*` |
| Tiger Boss | `SK_Tiger` or `SK_S2_Tiger` |
| Generic Male | `SK_Male_*` or `SK_Mannequin` |
| Generic Female | `SK_Female_*` |
| Creature | Per-creature skeleton |

---

## Common Issues

### Missing Notifies
- Attack without hitbox → Combat broken
- Movement without foley → Silent footsteps
- Heavy attack without camera shake → Reduced impact

### Naming Issues
- Typo: `Bawuchang` → Should be `Baiwuchang`
- TEMP prefixes in production assets
- Inconsistent naming (Attack01 vs Attack_01)

### Reference Issues
- TEMP_* dependencies
- Missing animation sequences
- Wrong skeleton references
