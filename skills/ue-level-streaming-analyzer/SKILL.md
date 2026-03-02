---
name: ue-level-streaming-analyzer
description: Analyze World Partition, HLOD, Data Layers, and level streaming configuration for performance and correctness. Use when debugging streaming issues, optimizing level loading, auditing world partition setup, or investigating pop-in/hitches. Triggers on "world partition", "level streaming", "HLOD", "data layers", "streaming distance", "level loading", "pop-in".
---

# UE Level Streaming Analyzer

Analyze World Partition configuration, HLODs, Data Layers, and streaming settings for AAA performance.

## Quick Start

1. Specify level/map to analyze
2. Review streaming configuration
3. Get optimization recommendations

## Analysis Workflow

### Step 1: Identify Level Assets

Locate world partition assets:
```
Content/{ProjectName}/Maps/{LevelName}/
├── {LevelName}.umap                    # Main level
├── {LevelName}_HLOD/                   # HLOD actors
├── __ExternalActors__/                 # External actor storage
└── __ExternalObjects__/                # External object storage
```

### Step 2: World Partition Configuration

Analyze `WorldSettings` for:

| Setting | Recommended | Impact |
|---------|-------------|--------|
| `RuntimeGrid` | 12800 (128m cells) | Memory vs granularity |
| `LoadingRange` | Based on view distance | Pop-in timing |
| `DataLayersInitiallyActive` | Minimal set | Initial load time |
| `bEnableStreaming` | true | Required for WP |

### Step 3: Data Layer Analysis

Check Data Layer configuration:

```markdown
## Data Layer Report

### Active by Default
| Layer | Actor Count | Estimated Memory |
|-------|-------------|------------------|
| {LayerName} | {count} | {size} |

### Streaming Layers
| Layer | Streaming Policy | Distance |
|-------|------------------|----------|
| {LayerName} | {policy} | {dist} |

### Issues Found
- {Layer} has no streaming distance set
- {Layer} overlaps with {OtherLayer}
```

### Step 4: HLOD Configuration

Analyze HLOD setup:

| HLOD Level | Cell Size | Simplification | Purpose |
|------------|-----------|----------------|---------|
| HLOD0 | 12800 | Merged Static Meshes | Near LOD |
| HLOD1 | 25600 | Simplified Meshes | Mid LOD |
| HLOD2 | 51200 | Imposters | Far LOD |

**Quality Checks:**
- HLOD build status (stale/current)
- Proxy mesh triangle counts
- Material complexity in HLODs
- Missing HLOD coverage

### Step 5: Streaming Distance Audit

Per-actor streaming settings:

```markdown
## Streaming Distance Analysis

### Oversized Streaming Distances
Actors loading from too far away (causes memory pressure):

| Actor | Current Distance | Recommended | Reason |
|-------|------------------|-------------|--------|
| {Actor} | 50000 | 25000 | Small prop, not visible at distance |

### Undersized Streaming Distances
Actors loading too late (causes pop-in):

| Actor | Current Distance | Recommended | Reason |
|-------|------------------|-------------|--------|
| {Actor} | 5000 | 15000 | Large landmark, visible from far |
```

## Common Issues

### 1. Excessive Always-Loaded Content

```
Issue: Data Layer "Gameplay" has 500+ actors always loaded
Impact: High base memory, long initial load
Fix: Split into streaming sub-layers by area
```

### 2. Grid Cell Imbalance

```
Issue: Cell (12,5) has 200 actors, cell (12,6) has 5 actors
Impact: Inconsistent streaming hitches
Fix: Redistribute actors or adjust grid size
```

### 3. Missing HLOD Builds

```
Issue: HLOD actors are stale or missing
Impact: No LOD transitions, high draw calls at distance
Fix: Build HLODs: World Partition → Build → Build HLODs
```

### 4. Streaming Priority Conflicts

```
Issue: Multiple actors competing for same streaming slot
Impact: Random pop-in, inconsistent loading
Fix: Assign explicit priorities based on gameplay importance
```

## Report Template

```markdown
# Level Streaming Analysis: {LevelName}

## Executive Summary
- **Status**: {OK/WARNING/CRITICAL}
- **Estimated Memory Budget**: {GB}
- **Streaming Cell Count**: {N}
- **HLOD Status**: {Current/Stale/Missing}

## World Partition Configuration
| Setting | Value | Assessment |
|---------|-------|------------|
| Grid Size | {N} | {OK/Adjust} |
| Loading Range | {N} | {OK/Adjust} |

## Data Layer Summary
| Layer | Actors | Memory | Always Loaded |
|-------|--------|--------|---------------|
| {Layer} | {N} | {MB} | {Yes/No} |

## HLOD Summary
| Level | Cells | Status | Triangle Budget |
|-------|-------|--------|-----------------|
| HLOD0 | {N} | {status} | {triangles} |

## Critical Issues
1. {Issue with fix}

## Optimization Recommendations
1. {Recommendation with expected improvement}
```

## Console Commands

| Command | Purpose |
|---------|---------|
| `wp.Runtime.ToggleDrawRuntimeHash2D` | Visualize streaming grid |
| `wp.Runtime.ToggleDrawRuntimeHash3D` | 3D streaming visualization |
| `wp.EnableStreaming 1` | Enable WP streaming |
| `stat LevelStreaming` | Streaming statistics |
| `obj list class=WorldPartitionRuntimeCell` | List loaded cells |

## Huli/S2 Integration

Project-specific considerations:
1. **Realm System**: Verify realm-specific Data Layers load correctly
2. **Combat Encounters**: Ensure encounter actors stream with their triggers
3. **Boss Arenas**: Check boss areas have isolated streaming cells
4. **NPC Spawns**: Validate spawn points stream before trigger volumes
5. **VFX Heavy Areas**: Flag cells with high Niagara system counts
