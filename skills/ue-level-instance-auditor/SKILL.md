---
name: ue-level-instance-auditor
description: Audit Level Instances including loading priority, streaming distance, actor count, and data layer configuration. Use when optimizing level streaming, debugging level instance issues, or validating world partition setup. Triggers on "level instance", "level audit", "streaming audit", "level instance check", "level loading", "sublevel".
---

# UE Level Instance Auditor

Audit Level Instance configurations for streaming and performance.

## Quick Start

1. Specify level or world to audit
2. Run instance analysis
3. Get optimization recommendations

## Audit Categories

### 1. Instance Configuration

| Check | Severity | Description |
|-------|----------|-------------|
| Instance Valid | Error | Level Instance exists |
| Streaming Distance | Warning | Appropriate for content |
| Loading Priority | Info | Priority relative to others |
| Data Layer | Warning | Correct layer assignment |

### 2. Content Analysis

| Check | Severity | Description |
|-------|----------|-------------|
| Actor Count | Warning | Not overloaded |
| Component Count | Warning | Performance impact |
| Asset Size | Warning | Memory budget |
| Bounds Size | Info | Streaming cell coverage |

### 3. Dependency Analysis

| Check | Severity | Description |
|-------|----------|-------------|
| Hard References | Warning | Minimize hard refs |
| Soft References | Info | Track for loading |
| Cross-Instance Refs | Error | Avoid cross-level hard refs |

## Audit Workflow

### Step 1: Enumerate Level Instances

```markdown
## Level Instance Audit: {WorldName}

### Instance Inventory
| Instance | Type | Status |
|----------|------|--------|
| LI_{Name}_01 | Blueprint | {Loaded/Unloaded} |
| LI_{Name}_02 | Level | {Loaded/Unloaded} |

### Summary
- **Total Instances**: {N}
- **Loaded**: {N}
- **Unloaded**: {N}
- **Estimated Memory**: {N} MB
```

### Step 2: Analyze Each Instance

```markdown
## Instance Analysis: LI_{InstanceName}

### Configuration
| Property | Value | Assessment |
|----------|-------|------------|
| World Asset | {Path} | {Valid/Missing} |
| Streaming Distance | {N} | {OK/TooFar/TooClose} |
| Loading Priority | {N} | {High/Medium/Low} |
| Data Layer | {Layer} | {Correct/Wrong/None} |
| Always Loaded | {Yes/No} | {Expected/Unexpected} |

### Content Stats
| Metric | Value | Budget | Status |
|--------|-------|--------|--------|
| Actors | {N} | 500 | {OK/Over} |
| Components | {N} | 2000 | {OK/Over} |
| Static Meshes | {N} | 200 | {OK/Over} |
| Estimated Memory | {N} MB | 100 MB | {OK/Over} |

### Bounds
- **Origin**: {X, Y, Z}
- **Extent**: {X, Y, Z}
- **Cells Covered**: {N}
```

### Step 3: Identify Issues

```markdown
### Issues Found

#### [WARNING] Excessive Actor Count
- **Instance**: LI_{Name}
- **Actors**: 750
- **Budget**: 500
- **Impact**: Slow streaming, memory pressure
- **Fix**: Split into smaller instances or optimize actors

#### [ERROR] Cross-Instance Hard Reference
- **From**: LI_{Name}_01
- **To**: LI_{Name}_02
- **Reference**: BP_Door → BP_Switch
- **Impact**: Forces both instances to load together
- **Fix**: Use soft reference or event system

#### [WARNING] Streaming Distance Too Large
- **Instance**: LI_Interior_Room
- **Current**: 50000 (500m)
- **Recommended**: 10000 (100m)
- **Impact**: Loads small interior from too far away
- **Fix**: Reduce streaming distance to match visibility
```

### Step 4: Dependency Report

```markdown
### Dependency Analysis

#### Hard References (Load Together)
| From Instance | To Instance | Reference Type |
|---------------|-------------|----------------|
| LI_{A} | LI_{B} | Actor Reference |

#### Soft References (Load On Demand)
| Instance | External Assets | Size |
|----------|-----------------|------|
| LI_{Name} | {N} assets | {N} MB |

#### Circular Dependencies
{None found / List of cycles}
```

## Optimization Recommendations

### Streaming Distance Guidelines

| Content Type | Recommended Distance | Reason |
|--------------|---------------------|--------|
| Large Exterior | 20000-50000 | Visible from far |
| Building Exterior | 10000-20000 | Medium visibility |
| Interior Room | 5000-10000 | Only when close |
| Detail Props | 2000-5000 | Fine detail |
| Interactive | 3000-8000 | Need for gameplay |

### Actor Count Guidelines

| Instance Type | Max Actors | Max Components |
|---------------|------------|----------------|
| Small Interior | 100 | 500 |
| Large Interior | 250 | 1000 |
| Exterior Chunk | 500 | 2000 |
| Combat Arena | 200 | 800 |
| Boss Room | 300 | 1200 |

### Data Layer Assignment

| Content Type | Recommended Layer | Streaming |
|--------------|-------------------|-----------|
| Structural | Base | Always |
| Gameplay | Gameplay | On demand |
| Visual Detail | Detail | Distance-based |
| Combat | Combat | Event-triggered |

## Batch Audit

```markdown
## World Audit: {WorldName}

### Summary
| Metric | Value |
|--------|-------|
| Total Instances | {N} |
| Total Actors | {N} |
| Estimated Memory | {N} MB |
| Issues Found | {N} |

### Instance Overview
| Instance | Actors | Memory | Status |
|----------|--------|--------|--------|
| LI_{Name} | {N} | {N} MB | {OK/WARN} |

### Top Issues
1. {Most common issue} ({N} occurrences)

### Optimization Potential
- Memory savings if optimized: ~{N} MB
- Loading time improvement: ~{N}%
```

## Output Report

```markdown
# Level Instance Audit Report

## Executive Summary
- **World**: {WorldName}
- **Total Instances**: {N}
- **Status**: {HEALTHY / NEEDS_OPTIMIZATION / CRITICAL}
- **Estimated Savings**: {N} MB

## Critical Issues
1. {Issue requiring immediate fix}

## Optimization Queue
| Priority | Instance | Action | Impact |
|----------|----------|--------|--------|
| 1 | {Instance} | {Action} | {Impact} |

## Recommendations
1. {Recommendation}

## Streaming Performance Estimate
- Current peak memory: {N} MB
- After optimization: {N} MB
- Loading time reduction: {N}%
```
