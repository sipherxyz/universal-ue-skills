---
name: ue-vfx-niagara-profiler
description: Profile Niagara particle systems for performance including particle counts, GPU vs CPU simulation costs, overdraw estimation, and memory usage. Use when optimizing VFX, debugging particle performance, or preparing for console certification. Triggers on "Niagara profiling", "particle performance", "VFX optimization", "particle count", "overdraw", "GPU particles".
---

# UE VFX Niagara Profiler

Profile and optimize Niagara particle systems for AAA performance targets.

## Quick Start

1. Identify Niagara systems to profile
2. Capture performance metrics
3. Get optimization recommendations

## Performance Budgets

### Per-System Limits (60 FPS Target)

| Category | Budget | Notes |
|----------|--------|-------|
| Particle Count (screen) | <10,000 | Total visible |
| GPU Sim Systems | <20 active | Concurrent |
| CPU Sim Systems | <10 active | Per frame |
| Overdraw Factor | <4x | Screen pixels |
| Memory per System | <50 MB | VRAM |

### Platform Budgets

| Platform | Max Particles | Max GPU Systems |
|----------|---------------|-----------------|
| PC (High) | 50,000 | 50 |
| PC (Medium) | 25,000 | 25 |
| PS5 | 30,000 | 30 |
| Xbox Series X | 30,000 | 30 |
| Xbox Series S | 15,000 | 15 |

## Profiling Workflow

### Step 1: Capture Metrics

```
# Console commands
stat Niagara                    # Niagara overview
stat NiagaraDetailed            # Detailed breakdown
stat GPU                        # GPU particle costs
stat Particles                  # Legacy + Niagara combined
Niagara.DebugHUD 1              # On-screen debug
```

### Step 2: Analyze System Configuration

For each Niagara System, extract:

```markdown
## System: NS_{SystemName}

### Emitter Configuration
| Emitter | Sim Target | Max Count | Spawn Rate | Lifetime |
|---------|------------|-----------|------------|----------|
| {Name} | {GPU/CPU} | {N} | {N}/s | {N}s |

### Module Costs
| Module | Type | Estimated Cost |
|--------|------|----------------|
| {Module} | Spawn/Update/Render | {Low/Med/High} |

### Renderer Configuration
| Renderer | Material | Overdraw Risk |
|----------|----------|---------------|
| {Type} | {Material} | {Low/Med/High} |
```

### Step 3: Identify Issues

#### High Particle Count

```
Issue: Emitter "{Name}" spawns {N} particles
Impact: {CPU/GPU} pressure, potential frame drop
Current: SpawnRate={N}, Lifetime={N}s → {MaxCount} particles

Recommendations:
1. Reduce spawn rate: {N} → {Suggested}
2. Reduce lifetime: {N}s → {Suggested}s
3. Add LOD: Cull at {Distance}
```

#### Expensive Modules

| Module | Cost | Alternative |
|--------|------|-------------|
| `Collision` | High | `Depth Buffer Collision` |
| `Curl Noise Force` | High | Pre-baked noise texture |
| `Point Attraction Force` | Medium | Simplified gravity |
| `Mesh Renderer` | High | Sprite with normal map |

#### Overdraw Problems

```
Issue: System has high overdraw factor
Analysis:
- Particle size: {N} units average
- Particle count: {N} at peak
- Screen coverage: {N}% estimated
- Overdraw factor: {N}x

Recommendations:
1. Reduce particle size by {N}%
2. Use cutout opacity instead of translucent
3. Add depth fade to reduce overlap visibility
4. Implement screen-space particle limit
```

### Step 4: LOD Analysis

```markdown
### LOD Configuration

| LOD Level | Distance | Scale Factor | Spawn Multiplier |
|-----------|----------|--------------|------------------|
| LOD0 | 0-1000 | 1.0 | 1.0 |
| LOD1 | 1000-3000 | 0.75 | 0.5 |
| LOD2 | 3000-5000 | 0.5 | 0.25 |
| Cull | 5000+ | N/A | 0 |

### Missing LOD Issues
- {SystemName}: No LOD configured
- {SystemName}: LOD distances too aggressive
```

## Optimization Techniques

### 1. GPU vs CPU Selection

```
Use GPU Simulation when:
- High particle counts (>1000)
- Simple update logic
- No collision required
- No events/ribbons

Use CPU Simulation when:
- Complex logic branching
- Collision required
- Event-driven spawning
- Ribbon renderers
- Low particle count (<500)
```

### 2. Material Optimization

| Issue | Fix |
|-------|-----|
| Complex material | Simplify shader |
| No LOD materials | Add simplified LOD material |
| Translucent sorting | Use masked when possible |
| Many texture samples | Combine textures, reduce samples |

### 3. Memory Optimization

```cpp
// Set fixed bounds to avoid recalculation
NiagaraComponent->SetForceSolo(false);
NiagaraComponent->SetRenderCustomDepth(false);
NiagaraComponent->SetRandomSeedOffset(0); // Deterministic for pooling

// Pre-warm and pool
NiagaraComponent->SetWarmupTime(0.5f);
ObjectPool->ReturnToPool(NiagaraComponent);
```

## Report Template

```markdown
# Niagara Performance Report: {Context}

## Executive Summary
- **Total Systems Analyzed**: {N}
- **Critical Issues**: {N}
- **Estimated Budget Usage**: {N}%
- **Recommendation**: {OK/OPTIMIZE/CRITICAL}

## Systems Overview

| System | Particles | Sim Type | GPU Cost | CPU Cost | Status |
|--------|-----------|----------|----------|----------|--------|
| {Name} | {N} | {Type} | {ms} | {ms} | {OK/WARN} |

## Critical Issues

### 1. {System Name}
**Issue**: {Description}
**Impact**: {Frame time impact}
**Fix**: {Specific recommendation}

## Optimization Priority

| Priority | System | Change | Expected Savings |
|----------|--------|--------|------------------|
| 1 | {System} | {Change} | {N}ms |

## Budget Compliance

| Metric | Current | Budget | Status |
|--------|---------|--------|--------|
| Total Particles | {N} | 30,000 | {OK/OVER} |
| GPU Systems | {N} | 30 | {OK/OVER} |
| Peak VRAM | {N} MB | 500 MB | {OK/OVER} |
```

## Console Commands Reference

| Command | Purpose |
|---------|---------|
| `Niagara.WarmupDeltaTime` | Control warmup speed |
| `fx.Niagara.AllowGPUParticles` | Toggle GPU particles |
| `fx.Niagara.MaxGPUParticlesSpawnPerFrame` | Limit spawn rate |
| `fx.Niagara.Debug.ShowGlobalBudgetInfo` | Budget overlay |

## Huli/S2 Integration

### VFX Content Location

**Primary Path**: `/Content/S2/Core_VFX/`

| Folder | Purpose | Priority |
|--------|---------|----------|
| `1_COMBAT_EFFECTS/` | Hit impacts, buffs, AOE, character-specific | **HIGH** |
| `2_ENVIRONMENTAL_EFFECTS/` | Weather, ambient, level VFX | MEDIUM |
| `4_UI_AND_CINEMATICS/` | Screen effects, cutscene VFX | MEDIUM |
| `5_LIGHTING/` | Light-based particle effects | LOW |
| `_CORE_ASSETS/` | Shared modules, materials, meshes | Reference |
| `_VFX_WORKSPACE/` | WIP effects (exclude from audit) | Skip |

**Total Niagara Systems**: ~1,197

### Combat VFX Subcategories

```
1_COMBAT_EFFECTS/
├── Area_Of_Effect_AOE/     # Ground slams, explosions, zones
├── Buffs_And_Debuffs/      # Auras, weapon enchants, status
├── Character_Specific/     # Player/enemy unique effects
│   └── Player_Protagonist/
│       └── Fox_Transform/  # Nine-tails transformation VFX
├── Melee_Impact/           # Hit reactions, slashes
├── Projectiles/            # Ranged attacks, thrown objects
└── Trails/                 # Weapon trails, dash effects
```

### Priority Systems to Profile

1. **Combat AOE** (`Area_Of_Effect_AOE/`): Explosions, ground effects (high particle count risk)
2. **Buff Auras** (`Buffs_And_Debuffs/`): Always-on effects (per-character cost)
3. **Fox Transform** (`Fox_Transform/`): Signature ability (spike potential)
4. **Boss VFX** (`Character_Specific/`): Phase transitions (budget spikes)
5. **Environmental** (`2_ENVIRONMENTAL_EFFECTS/`): Weather, ambient (always active)

### Editor Tool Access

```
Window → Developer Tools → Niagara Review
```

Or analyze via C++:
```cpp
TArray<FNiagaraAnalysisResult> Results = FNiagaraAnalyzer::AnalyzeFolder(TEXT("/Game/S2/Core_VFX"));
```

### Naming Convention

| Prefix | Type |
|--------|------|
| `NS_Combat_AOE_*` | Area of effect |
| `NS_Combat_Buff_*` | Buff/aura effects |
| `NS_Combat_Debuff_*` | Debuff/status effects |
| `NS_Combat_Melee_*` | Melee impact/trail |
| `NS_Combat_Range_*` | Ranged/projectile |
| `NS_Env_*` | Environmental |
| `NS_UI_*` | UI/screen effects |
