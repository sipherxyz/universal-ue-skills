---
name: ue-texture-budget-enforcer
description: Enforce texture resolution and format budgets by asset type, flag violations, and suggest optimizations. Use when auditing texture memory, optimizing for consoles, or enforcing art standards. Triggers on "texture budget", "texture audit", "texture memory", "texture optimization", "texture resolution", "mipmap".
---

# UE Texture Budget Enforcer

Enforce texture resolution and format standards with violation detection.

## Quick Start

1. Specify scope (folder, asset type, or full project)
2. Run budget check against standards
3. Get violations and optimization suggestions

## Budget Standards

### Resolution by Asset Type

| Asset Type | Max Resolution | Typical | Notes |
|------------|---------------|---------|-------|
| Character Diffuse | 4096 | 2048 | Main characters only |
| Character Normal | 2048 | 1024 | |
| Weapon | 2048 | 1024 | |
| Environment Tileable | 2048 | 1024 | |
| Environment Unique | 4096 | 2048 | Hero assets |
| Props | 1024 | 512 | |
| UI | 1024 | 512 | No mipmaps |
| VFX | 512 | 256 | Often animated |
| Lightmaps | 1024 | 512 | Per-object |

### Format Standards

| Usage | Format | Compression |
|-------|--------|-------------|
| Diffuse/Albedo | BC1/DXT1 | Standard |
| Normal Map | BC5/3Dc | Two-channel |
| Masks (RGBA) | BC3/DXT5 | With alpha |
| Masks (RGB) | BC1/DXT1 | No alpha |
| HDR | BC6H | HDR environments |
| UI (transparent) | BC3/DXT5 | Crisp alpha |
| UI (opaque) | BC1/DXT1 | Smallest |

### Platform Budgets

| Platform | Texture Memory Budget |
|----------|----------------------|
| PC High | 4 GB |
| PC Medium | 2 GB |
| PS5 | 3 GB |
| Xbox Series X | 3 GB |
| Xbox Series S | 1.5 GB |

## Audit Workflow

### Step 1: Scan Textures

```markdown
## Texture Audit: {Scope}

### Summary
| Metric | Value |
|--------|-------|
| Total Textures | {N} |
| Total Size (Disk) | {N} GB |
| Total Size (Memory) | {N} GB |
| Violations | {N} |
```

### Step 2: Analyze by Category

```markdown
### By Asset Type
| Type | Count | Avg Size | Total Memory | Status |
|------|-------|----------|--------------|--------|
| Character | {N} | {N} MB | {N} MB | {OK/OVER} |
| Environment | {N} | {N} MB | {N} MB | {OK/OVER} |
| Props | {N} | {N} MB | {N} MB | {OK/OVER} |
| VFX | {N} | {N} MB | {N} MB | {OK/OVER} |
| UI | {N} | {N} MB | {N} MB | {OK/OVER} |

### By Resolution
| Resolution | Count | % of Total |
|------------|-------|------------|
| 4096+ | {N} | {N}% |
| 2048 | {N} | {N}% |
| 1024 | {N} | {N}% |
| 512 | {N} | {N}% |
| <512 | {N} | {N}% |
```

### Step 3: Identify Violations

```markdown
### Resolution Violations

#### [ERROR] Oversized Texture
- **Asset**: T_{AssetName}_D
- **Type**: Environment Prop
- **Current**: 4096x4096
- **Budget**: 1024x1024
- **Memory Impact**: +12 MB over budget
- **Fix**: Resize to 1024 or justify as hero asset

#### [WARNING] Non-Power-of-Two
- **Asset**: T_{AssetName}_UI
- **Resolution**: 1920x1080
- **Impact**: Cannot use block compression
- **Fix**: Resize to 2048x1024 or use uncompressed

---

### Format Violations

#### [ERROR] Wrong Compression
- **Asset**: T_{AssetName}_N
- **Type**: Normal Map
- **Current**: BC1 (DXT1)
- **Expected**: BC5 (3Dc)
- **Impact**: Quality loss on normal mapping
- **Fix**: Re-import with BC5 compression

#### [WARNING] Missing Mipmaps
- **Asset**: T_{AssetName}_D
- **Type**: Environment
- **Impact**: Aliasing at distance, no streaming
- **Fix**: Enable mipmap generation
```

### Step 4: Memory Analysis

```markdown
### Memory Breakdown

#### By Mip Level
| Mip Level | Size | Cumulative |
|-----------|------|------------|
| 0 (Full) | {N} MB | {N} MB |
| 1 | {N} MB | {N} MB |
| 2 | {N} MB | {N} MB |
| ... | ... | ... |

#### Streaming Impact
- **With Streaming**: {N} MB resident
- **Without Streaming**: {N} MB required
- **Savings**: {N}%
```

## Optimization Recommendations

### Automatic Fixes

| Issue | Auto-Fix | Command |
|-------|----------|---------|
| Missing mipmaps | Yes | Reimport with mips |
| Wrong compression | Yes | Change format setting |
| No LOD bias | Yes | Set streaming LOD |

### Manual Review Required

| Issue | Reason |
|-------|--------|
| Oversized resolution | May be intentional hero asset |
| Non-POT | May be UI specific requirement |
| Uncompressed | May need quality preservation |

### Compression Savings Estimate

| Current | Recommended | Savings |
|---------|-------------|---------|
| BC3 → BC1 (no alpha) | 50% | If alpha unused |
| RGBA8 → BC3 | 75% | Standard assets |
| R8G8B8A8 → BC1 | 87.5% | Opaque textures |

## Batch Enforcement

```markdown
## Batch Enforcement Run

### Settings Applied
| Setting | Value |
|---------|-------|
| Max Character | 2048 |
| Max Environment | 2048 |
| Max Props | 1024 |
| Max VFX | 512 |
| Force Compression | Yes |
| Generate Mipmaps | Yes |

### Results
| Action | Count | Memory Freed |
|--------|-------|--------------|
| Resized | {N} | {N} MB |
| Recompressed | {N} | {N} MB |
| Mipmapped | {N} | N/A |
| Skipped (manual) | {N} | - |

### Total Savings: {N} MB ({N}%)
```

## Output Report

```markdown
# Texture Budget Report

## Executive Summary
- **Scope**: {Scope}
- **Status**: {COMPLIANT / VIOLATIONS / CRITICAL}
- **Total Memory**: {N} MB
- **Budget**: {N} MB
- **Overhead**: {N}%

## Violations by Severity
| Severity | Count |
|----------|-------|
| Error | {N} |
| Warning | {N} |
| Info | {N} |

## Top Offenders
| Asset | Size | Over Budget |
|-------|------|-------------|
| {Asset} | {N} MB | +{N} MB |

## Recommendations
1. {Recommendation with expected savings}

## Compliance Checklist
- [ ] All character textures ≤ 2048
- [ ] All props ≤ 1024
- [ ] Normal maps use BC5
- [ ] All textures have mipmaps
- [ ] Streaming LOD configured
```
