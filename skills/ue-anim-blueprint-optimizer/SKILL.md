---
name: ue-anim-blueprint-optimizer
description: Analyze and optimize Animation Blueprint graphs for performance. Detects expensive nodes, missing fast path compliance, unnecessary blending, and ABP bottlenecks. Use when optimizing character animation, investigating animation hitches, or scaling to 50+ animated characters. Triggers on "animation blueprint", "ABP optimization", "anim graph", "animation performance", "fast path", "anim blueprint profiling".
---

# UE Animation Blueprint Optimizer

Analyze Animation Blueprint graphs for performance optimization and fast path compliance.

## Quick Start

1. Specify ABP asset to analyze
2. Run optimization analysis
3. Get fast path compliance report and fixes

## Performance Targets

### Budget per Character (60 FPS with 50+ AI)

| Metric | Budget | Notes |
|--------|--------|-------|
| ABP Evaluation | <0.3ms | Per character |
| Blend Operations | <5 | Per frame |
| Bone Transforms | <100 | Modified per frame |
| State Machine Transitions | <3 | Active per frame |

### Fast Path Requirements

Fast Path allows animation evaluation on worker threads. Requirements:
1. No Blueprint VM calls in animation graph
2. Only fast-path-compatible nodes
3. No custom Blueprint events in graph

## Analysis Workflow

### Step 1: Profile ABP

```
# Console commands
stat Anim                       # Animation overview
stat AnimDetail                 # Per-character breakdown
anim.DebugSelectedGraph 1       # Debug selected character's ABP
anim.ShowFastPath 1             # Highlight fast path violations
```

### Step 2: Node Analysis

#### Fast Path Compatible Nodes

| Node Type | Fast Path | Notes |
|-----------|-----------|-------|
| Blend Poses by bool | Yes | Use over Select |
| Blend Poses by int | Yes | Limited options |
| Two Bone IK | Yes | Built-in |
| FABRIK | Yes | Built-in |
| Layered blend per bone | Yes | With fixed bones |
| Blend Space | Yes | Direct reference |
| State Machine | Yes | If all states compliant |

#### Fast Path Violations

| Node Type | Issue | Alternative |
|-----------|-------|-------------|
| Custom Blueprint Event | VM call | Use Notify or C++ |
| Get Actor Location | Blueprint call | Use bone location |
| Any Blueprint function | VM call | Move to C++ |
| Dynamic Blend Space | Runtime lookup | Cache reference |
| Modify Bone (BP) | Script execution | Use C++ AnimNode |

### Step 3: State Machine Analysis

```markdown
## State Machine: {Name}

### States
| State | Entry Condition | Exit Count | Issue |
|-------|-----------------|------------|-------|
| {State} | {Condition} | {N} | {Issue or OK} |

### Transition Issues
| From → To | Condition | Duration | Issue |
|-----------|-----------|----------|-------|
| {A} → {B} | {Cond} | {N}s | {Issue or OK} |

### Problems Found
1. **Excessive transitions**: {State} has {N} outgoing transitions
2. **Long blend time**: {Transition} blend is {N}s (recommend <0.3s)
3. **Blueprint condition**: {Transition} uses BP function call
```

### Step 4: Blend Analysis

```markdown
## Blend Operations

### Active Blends
| Blend Node | Inputs | Weight Source | Cost |
|------------|--------|---------------|------|
| {Node} | {N} | {Source} | {Low/Med/High} |

### Optimization Opportunities
1. **Reduce blend inputs**: {Node} blends {N} poses, consider {Suggested}
2. **Bone masking**: {Node} affects all bones, mask to {SuggestedBones}
3. **Consolidate blends**: {Nodes} can be combined
```

## Common Issues & Fixes

### 1. Blueprint Function Calls in Graph

```
Issue: "Get Player Character" called every frame
Impact: Forces game thread, breaks fast path
Location: Locomotion State → Idle → Entry Logic

Fix Options:
A) Cache value in C++ AnimInstance:
   // In C++ AnimInstance
   UPROPERTY(Transient, BlueprintReadOnly)
   ACharacter* CachedOwner;

   void NativeUpdateAnimation(float DeltaSeconds)
   {
       CachedOwner = TryGetPawnOwner();
   }

B) Use AnimNotify instead of per-frame check
```

### 2. Excessive State Machine Complexity

```
Issue: State machine "{Name}" has {N} states, {M} transitions
Impact: Evaluation cost scales with complexity

Recommendations:
1. Split into sub-state machines by category
2. Use linked anim layers for modular behavior
3. Consider anim node state machine in C++
```

### 3. Non-Fast-Path Blend Space

```
Issue: Blend Space uses dynamic asset reference
Impact: Requires game thread lookup every frame

Fix:
// Cache blend space reference
UPROPERTY(EditDefaultsOnly)
UBlendSpace* CachedBlendSpace;

// In ABP, use direct reference instead of GetBlendSpace()
```

### 4. Unnecessary Pose Snapshots

```
Issue: Pose snapshot taken every frame
Impact: Memory allocation, bone copy overhead

Fix:
- Take snapshot only on state change
- Use bone caching instead of full pose
- Consider partial pose (relevant bones only)
```

## Report Template

```markdown
# Animation Blueprint Analysis: {ABPName}

## Executive Summary
- **Fast Path Compliant**: {Yes/No/Partial}
- **Estimated Cost**: {N}ms per character
- **Scalability**: {Good/Fair/Poor} for 50+ characters
- **Critical Issues**: {N}

## Fast Path Compliance

### Violations
| Node | Location | Violation Type | Fix |
|------|----------|----------------|-----|
| {Node} | {State/Graph} | {Type} | {Fix} |

### Compliant Sections
- {Section}: Fast path OK
- {Section}: Fast path OK

## State Machine Analysis

| Machine | States | Transitions | Status |
|---------|--------|-------------|--------|
| {Name} | {N} | {N} | {OK/WARN} |

## Performance Metrics

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Evaluation Time | {N}ms | 0.3ms | {OK/OVER} |
| Blend Count | {N} | 5 | {OK/OVER} |
| Modified Bones | {N} | 100 | {OK/OVER} |

## Optimization Priority

| Priority | Change | Expected Savings |
|----------|--------|------------------|
| 1 | {Change} | {N}ms |
| 2 | {Change} | {N}ms |

## Code Changes Required

### C++ AnimInstance Updates
{Code snippets for required changes}

### Blueprint Graph Updates
{Node replacement instructions}
```

## Console Commands

| Command | Purpose |
|---------|---------|
| `a.AnimNode.StateMachine.Debug` | State machine debug |
| `a.URO.Enable` | Update rate optimization |
| `a.DebugSkeletalMeshComponent` | Mesh debug overlay |
| `anim.ShowFastPath` | Fast path violation highlight |

## Huli/S2 Integration

Priority ABPs to optimize:
1. **Player ABP**: Highest frame count, most complex
2. **Enemy Base ABP**: Instanced 50+ times
3. **Boss ABP**: Complex but low instance count
4. **NPC ABP**: Background characters, LOD important

Target: <0.2ms per enemy ABP for 50+ simultaneous AI
