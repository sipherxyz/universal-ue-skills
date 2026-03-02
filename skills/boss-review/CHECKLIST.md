# Boss Implementation Checklist

Quick reference for boss readiness assessment.

---

## Mandatory Assets (P0 if missing)

### Blueprints
- [ ] `BP_S2_boss_{Name}_Phase_01.uasset` - Main character BP
- [ ] `BP_S2_boss_{Name}_Phase_02.uasset` - If multi-phase
- [ ] Clone BPs - If clone mechanic exists

### Animation Montages
- [ ] **Attack Montages** - Minimum 3 per phase
- [ ] **HitReact** - Boss-specific (NOT borrowed from other characters)
  - [ ] Front Light
  - [ ] Front Heavy
  - [ ] Back Light
  - [ ] Back Heavy
  - [ ] Left (Light or Heavy)
  - [ ] Right (Light or Heavy)
  - [ ] Stun/Stagger
  - [ ] Knockdown/Bounce
- [ ] **Dodge** - Boss-specific (NOT borrowed)
  - [ ] Back
  - [ ] Left
  - [ ] Right
  - [ ] Forward (optional)
- [ ] **Death** - At least 1 death animation
- [ ] **Block/Parry** - If boss can block

### Audio (SFX)
- [ ] Weapon whoosh on ALL attack montages
- [ ] Impact sounds on ALL attack montages
- [ ] Footstep/foley on locomotion

### Audio (Voice)
- [ ] Attack grunts (3-5 variants)
- [ ] Pain/HitReact vocals (3-5 variants)
- [ ] Death cry (1-2 variants)
- [ ] Phase transition vocal (if multi-phase)
- [ ] Special move callouts

### VFX
- [ ] Weapon trail on melee attacks
- [ ] Hit impact sparks
- [ ] Special attack effects
- [ ] Death effect (recommended)

---

## High Priority (P1)

### Montage Polish
- [ ] Camera shake on heavy attacks
- [ ] Motion warping for target tracking
- [ ] Hitbox shapes properly sized
- [ ] Damage impact levels set correctly

### GCN (Gameplay Cue Notifies)
- [ ] Phase transition feedback
- [ ] Enrage state visual
- [ ] Special ability charge indicator

### Consistency
- [ ] All montages use correct skeleton
- [ ] Naming conventions followed
- [ ] No placeholder assets in Montage/ folders

---

## Red Flags (Auto-Fail)

| Issue | Description |
|-------|-------------|
| 🔴 Borrowed HitReacts | Using another character's HitReact montages |
| 🔴 Borrowed Dodges | Using another boss's dodge montages |
| 🔴 No Death Animation | Boss cannot die properly |
| 🔴 Wrong Skeleton | Montages reference different character's skeleton |
| 🔴 Silent Attacks | Attack montages with no SFX |

---

## Scoring Guide

| Score | Status | Meaning |
|-------|--------|---------|
| 90-100% | ✅ EP Ready | Can present to Executive Producer |
| 75-89% | 🟡 Playtest Ready | Can schedule internal playtest |
| 50-74% | 🟠 Needs Work | Fix P0/P1 issues before playtest |
| <50% | 🔴 Not Ready | Significant work required |

---

## Quick Commands

```bash
# Count assets
find "Content/S2/Core_Boss/{boss}" -name "*.uasset" | wc -l

# Find montages
find "Content/S2/Core_Boss/{boss}" -name "*Montage*.uasset" -o -name "*AMT*.uasset"

# Check for borrowed assets in BP
powershell ... | grep -E "Core_Boss/(?!{this_boss})|Core_Ene"

# Find missing death
find "Content/S2/Core_Boss/{boss}" -iname "*death*"
```

---

## Common Issues by Boss Type

### Humanoid Female (e.g., Gao Lan Ying)
- Often borrows from male/creature HitReacts
- Needs feminine attack grunts and pain vocals
- Dual weapon trails if dual-wielding

### Large Creature (e.g., Tiger, Giant)
- Camera shake critical for impact feel
- Ground slam VFX often missing
- Needs heavy footstep foley

### Multi-Phase Boss
- Phase transition VFX/SFX often forgotten
- Phase 2 often less polished than Phase 1
- Clone mechanics need spawn/despawn feedback
