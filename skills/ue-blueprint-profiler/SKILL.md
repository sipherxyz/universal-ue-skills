---
name: ue-blueprint-profiler
description: Profile and optimize Blueprint graphs for performance. Detects expensive nodes, Tick abuse, latent action chains, and BP bottlenecks. Use when investigating frame drops, optimizing BP-heavy systems, or reviewing Blueprint performance. Triggers on "blueprint performance", "BP optimization", "blueprint tick", "blueprint profiling", "expensive blueprint", "BP lag".
---

# UE Blueprint Profiler

Analyze Blueprint graphs for performance issues and optimization opportunities.

## Quick Start

1. Enable Blueprint profiling: `stat BlueprintProfiler`
2. Identify slow Blueprints from profiler
3. Analyze specific BP graphs for optimization

## Profiling Workflow

### Step 1: Capture Performance Data

```
# Console commands
stat BlueprintProfiler          # Enable BP profiler overlay
stat ScriptTimePerActor         # Per-actor script cost
stat Game                       # Overall game thread timing
```

### Step 2: Identify Hot Spots

From profiler output, identify:
- Functions > 0.1ms average
- Tick functions called every frame
- Event dispatchers with many bindings

### Step 3: Analyze Blueprint Asset

When given a Blueprint path, analyze for these patterns:

## Anti-Patterns to Detect

### 1. Expensive Tick Operations

**Red Flags:**
- `Event Tick` → `Get All Actors of Class`
- `Event Tick` → `Line Trace`
- `Event Tick` → `Get Overlapping Actors`
- `Event Tick` → Any `ForEachLoop`

**Fix:** Move to timer-based updates or event-driven

```
Expensive Tick Pattern Detected:
  BP: {BlueprintName}
  Node: Get All Actors of Class (X)
  Called: Every frame
  Cost: ~{N}ms per call

  Recommendation:
  - Cache results in BeginPlay
  - Use timer (0.1-0.5s interval) instead of Tick
  - Consider C++ implementation
```

### 2. Unnecessary Casts

**Red Flags:**
- Cast → Same result discarded
- Cast in loop body
- Chain of casts to same type

**Fix:** Cache cast result, use interfaces

### 3. String Operations in Hot Paths

**Red Flags:**
- `Append` / `Format Text` in Tick
- String comparison in loops
- `Print String` left in shipping builds

### 4. Array Operations

**Red Flags:**
- `Find` on large arrays (O(n))
- `Contains` in nested loops (O(n²))
- `Add Unique` repeatedly

**Fix:** Use Set/Map, cache lookups

### 5. Latent Action Abuse

**Red Flags:**
- Multiple overlapping `Delay` chains
- `Move Component To` without cancellation
- Nested latent actions without tracking

## Analysis Report Format

```markdown
## Blueprint Performance Report: {BlueprintName}

### Summary
- **Risk Level**: {Low/Medium/High/Critical}
- **Tick Cost**: {Estimated ms per frame}
- **Node Count**: {Total nodes}
- **Complexity Score**: {1-100}

### Critical Issues
1. **{Issue Type}** - Line {N}
   - Node: {NodeName}
   - Impact: {High/Medium/Low}
   - Current: {What it does}
   - Fix: {How to fix}

### Tick Analysis
- Uses Event Tick: {Yes/No}
- Tick-dependent nodes: {count}
- Estimated tick cost: {ms}

### Optimization Opportunities
| Priority | Change | Expected Savings |
|----------|--------|------------------|
| 1 | {change} | {savings} |
| 2 | {change} | {savings} |

### C++ Conversion Candidates
Functions that would benefit from C++ implementation:
1. {FunctionName} - {reason}
```

## Blueprint Complexity Metrics

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| Nodes per function | <50 | 50-100 | >100 |
| Tick node count | 0-5 | 5-15 | >15 |
| Cast operations | <10 | 10-25 | >25 |
| Get All Actors calls | 0 | 1-2 | >2 |
| Nested loops | 0 | 1 | >1 |

## Common Fixes

### Replace Get All Actors with Caching

```
Before (Tick):
  Get All Actors of Class → ForEach → Process

After (BeginPlay + Timer):
  BeginPlay: Get All Actors → Store in Array
  Timer (0.5s): ForEach cached array → Process
  Handle spawns via delegate
```

### Replace Tick with Timer

```
Before:
  Event Tick → Check Condition → Do Action

After:
  BeginPlay → Set Timer by Function Name (0.1s, looping)
  Timer Function → Check Condition → Do Action
```

### Interface Instead of Cast

```
Before:
  Cast to PlayerCharacter → Get Health
  Cast to EnemyCharacter → Get Health

After:
  Does Implement Interface (Damageable) → Get Health (message)
```

## Huli/S2 Project Specifics

Priority optimization targets:
1. **Enemy AI Blueprints**: Check AI behavior tick costs
2. **UI Widgets**: Widget Tick and binding updates
3. **Ability Blueprints**: GAS ability graph efficiency
4. **Environmental Actors**: Interactive object polling
5. **VFX Blueprints**: Niagara parameter updates

Performance budget per Blueprint Tick: **< 0.05ms** for 60 FPS with 50+ AI
