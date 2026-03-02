---
name: ue-shader-complexity-report
description: Profile material shader complexity including instruction counts, texture samples, and GPU cost estimation. Identify expensive shaders and suggest LOD variants. Use when optimizing rendering, debugging GPU bottlenecks, or auditing material performance. Triggers on "shader complexity", "material performance", "GPU optimization", "instruction count", "shader profiling", "material cost".
---

# UE Shader Complexity Report

Profile material shader complexity and identify optimization targets.

## Quick Start

1. Specify scope (material, folder, or scene)
2. Run complexity analysis
3. Get cost estimates and optimization suggestions

## Complexity Metrics

### Instruction Budgets

| Platform | VS Budget | PS Budget | Notes |
|----------|-----------|-----------|-------|
| PC High | 500 | 500 | Desktop GPUs |
| PC Medium | 300 | 300 | Mid-range |
| PS5 | 400 | 400 | Fixed hardware |
| Xbox Series X | 400 | 400 | Fixed hardware |
| Xbox Series S | 250 | 250 | Lower power |

### Texture Sample Budgets

| Quality Level | Max Samples | Notes |
|---------------|-------------|-------|
| High | 16 | Desktop/Next-gen |
| Medium | 12 | Consoles |
| Low | 8 | Performance mode |

## Analysis Workflow

### Step 1: Capture Shader Stats

```
# Console commands
stat ShaderComplexity          # Enable complexity view
r.ShaderComplexityColors 1     # Color-coded visualization
ProfileGPU                     # GPU profiler
stat GPU                       # GPU frame stats
```

### Step 2: Analyze Materials

```markdown
## Material Analysis: M_{MaterialName}

### Shader Statistics
| Metric | Base Pass | Depth | Velocity |
|--------|-----------|-------|----------|
| VS Instructions | {N} | {N} | {N} |
| PS Instructions | {N} | {N} | {N} |
| Texture Samples | {N} | {N} | {N} |
| Interpolators | {N} | {N} | {N} |

### Compilation Info
| Variant | Compiled | Instructions |
|---------|----------|--------------|
| Default | Yes | {N} |
| Static Lighting | Yes | {N} |
| Dynamic Lighting | Yes | {N} |
| Masked | Yes | {N} |
```

### Step 3: Identify Expensive Operations

```markdown
### Expensive Operations Detected

#### Texture Samples
| Sample | Type | Cost | Suggestion |
|--------|------|------|------------|
| Diffuse | Texture2D | Low | OK |
| Normal | Texture2D | Low | OK |
| DetailNormal | Texture2D | Medium | Consider merging |
| Noise1 | Texture2D | Medium | Use world-space tiling |
| Noise2 | Texture2D | Medium | Combine with Noise1 |

#### Math Operations
| Operation | Count | Cost | Suggestion |
|-----------|-------|------|------------|
| Sine | 5 | High | Use LUT or approximate |
| Power | 8 | Medium | Reduce or precompute |
| Normalize | 12 | Low | OK |
| Dot | 15 | Low | OK |

#### Special Features
| Feature | Cost | Impact |
|---------|------|--------|
| Subsurface Scattering | High | +100 instructions |
| Refraction | High | Extra pass |
| Masked | Medium | Early-Z rejection |
```

### Step 4: LOD Recommendations

```markdown
### LOD Material Strategy

| LOD Level | Distance | Recommendations |
|-----------|----------|-----------------|
| LOD0 | 0-1000 | Full material (current) |
| LOD1 | 1000-3000 | Remove detail normal, reduce samples |
| LOD2 | 3000-5000 | Simplified shader, 4 samples max |
| LOD3 | 5000+ | Flat color or impostor |

### Simplified Material Variants

#### M_{MaterialName}_LOD1
- Remove: Detail normal, noise
- Keep: Diffuse, main normal
- Savings: ~30% instructions

#### M_{MaterialName}_LOD2
- Remove: All secondary textures
- Keep: Diffuse only
- Savings: ~60% instructions
```

## Common Optimization Patterns

### Reduce Texture Samples

```
Before: 12 samples
- Diffuse (1)
- Normal (1)
- Roughness (1)
- Metallic (1)
- AO (1)
- Detail Diffuse (1)
- Detail Normal (1)
- Noise x3 (3)
- Mask x2 (2)

After: 6 samples
- Diffuse (1)
- Normal (1)
- ORM packed (1) - Occlusion/Roughness/Metallic
- Detail Normal (1) - Merged detail
- Noise (1) - Single 4-channel noise
- Mask (1) - Combined masks

Savings: 50% texture samples
```

### Expensive Math Replacement

```cpp
// EXPENSIVE: Sine wave animation
float Wave = sin(Time * Frequency);

// CHEAPER: Triangle wave approximation
float Wave = abs(frac(Time * Frequency) * 2 - 1) * 2 - 1;

// CHEAPEST: LUT texture
float Wave = Texture2DSample(WaveLUT, Time * Frequency).r;
```

### Material Instance Optimization

```markdown
### Material Instance Strategy

Base Material: M_Character_Master
├── Exposes all parameters
├── Static switches for features
└── Compiles all variants

Instances for common cases:
├── MI_Character_Simple (no subsurface)
├── MI_Character_Full (all features)
└── MI_Character_Background (LOD2 equivalent)

Benefit: Pre-compiled permutations, no runtime branching
```

## Report Template

```markdown
# Shader Complexity Report

## Executive Summary
- **Scope**: {Scope}
- **Materials Analyzed**: {N}
- **Over Budget**: {N}
- **Critical**: {N}

## Top Offenders
| Material | PS Instructions | Samples | Status |
|----------|-----------------|---------|--------|
| M_{Name} | {N} | {N} | Over |
| M_{Name} | {N} | {N} | Over |

## Budget Compliance
| Budget | Pass | Warning | Fail |
|--------|------|---------|------|
| Instructions | {N} | {N} | {N} |
| Samples | {N} | {N} | {N} |

## Optimization Opportunities
| Material | Current | Target | Savings |
|----------|---------|--------|---------|
| M_{Name} | {N} inst | {N} inst | {N}% |

## Recommendations
1. {Recommendation with expected GPU time savings}

## Scene Impact
- Current GPU material cost: {N}ms
- After optimization: {N}ms estimated
- Savings: {N}%
```

## Console Commands

| Command | Purpose |
|---------|---------|
| `viewmode ShaderComplexity` | Complexity visualization |
| `r.ShaderComplexityColors` | Toggle color coding |
| `stat Material` | Material statistics |
| `DumpShaderStats` | Export shader stats |
| `r.DumpShaderDebugInfo` | Debug shader compilation |
