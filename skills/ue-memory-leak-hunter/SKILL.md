---
name: ue-memory-leak-hunter
description: Analyze UE5 memory reports to detect memory leaks, growth patterns, and optimization opportunities. Use when investigating memory issues, analyzing memreport output, tracking UObject growth, or debugging memory pressure on consoles. Triggers on "memory leak", "memreport", "memory growth", "OOM", "out of memory", "memory budget".
---

# UE Memory Leak Hunter

Analyze Unreal Engine memory reports to identify leaks, growth patterns, and optimization targets.

## Quick Start

1. Generate memory report in editor/game: `memreport -full`
2. Provide the memreport file path
3. Get categorized analysis with actionable fixes

## Workflow

### Step 1: Collect Memory Data

Instruct user to generate memreport:

```
# In UE console
memreport -full

# Or for specific categories
memreport -class
memreport -obj
```

Default output: `{Project}/Saved/Profiling/MemReports/`

### Step 2: Parse Memory Report

Read the memreport file and extract:

**Object Count Section:**
```
Class                          Count   NumBytes  MaxBytes  ResExcBytes  ResExcBytesMax
----------------------------------------------------------------------------------------------
Texture2D                      1523    892.45 MB ...
StaticMesh                     3421    456.78 MB ...
SkeletalMesh                   89      234.56 MB ...
```

**Memory Pool Section:**
```
FMalloc
    Used: 2.34 GB
    Peak: 2.89 GB
    Waste: 156 MB
```

### Step 3: Analyze Patterns

#### Leak Indicators

| Pattern | Severity | Indicator |
|---------|----------|-----------|
| Object count growing over time | Critical | Compare sequential memreports |
| Orphan UObjects without outer | High | Objects with `Outer=None` |
| Pending kill objects not collected | High | Large `PendingKill` count |
| Texture/Mesh duplicates | Medium | Same asset loaded multiple times |
| Delegate binding growth | Medium | Multicast delegate arrays growing |

#### Memory Budget Violations

| Platform | Memory Budget | Alert Threshold |
|----------|---------------|-----------------|
| PS5 | 12 GB usable | >10 GB |
| Xbox Series X | 13.5 GB usable | >11 GB |
| PC (min spec) | 8 GB | >6 GB |

### Step 4: Generate Report

Output format:

```markdown
## Memory Analysis Report

### Executive Summary
- **Total Used**: {size}
- **Peak**: {peak}
- **Status**: {OK/WARNING/CRITICAL}

### Top Memory Consumers
| Rank | Class | Count | Size | % of Total |
|------|-------|-------|------|------------|
| 1 | {class} | {count} | {size} | {pct} |

### Leak Suspects
1. **{ClassName}** - {count} objects, {size}
   - Growth rate: +{n} per minute
   - Likely cause: {analysis}
   - Fix: {recommendation}

### Recommendations
1. {Priority 1 fix}
2. {Priority 2 fix}
```

## Common Leak Patterns

### 1. Delegate Binding Leaks
```cpp
// WRONG - Never unbound
BeginPlay() { SomeDelegate.AddDynamic(this, &MyClass::Handler); }

// CORRECT - Unbound in EndPlay
EndPlay() { SomeDelegate.RemoveDynamic(this, &MyClass::Handler); }
```

### 2. Timer Handle Leaks
```cpp
// WRONG - Timer keeps reference
GetWorld()->GetTimerManager().SetTimer(Handle, this, &MyClass::Tick, 1.0f, true);

// CORRECT - Clear in EndPlay
EndPlay() { GetWorld()->GetTimerManager().ClearTimer(Handle); }
```

### 3. Async Load Leaks
```cpp
// WRONG - Handle not stored
StreamableManager.RequestAsyncLoad(Path, Callback);

// CORRECT - Store and cancel
TSharedPtr<FStreamableHandle> Handle = StreamableManager.RequestAsyncLoad(Path, Callback);
// Cancel in destructor if still loading
```

### 4. Widget Leaks
```cpp
// WRONG - Widget created but never removed
UUserWidget* W = CreateWidget<UUserWidget>(this, WidgetClass);
W->AddToViewport();

// CORRECT - Track and remove
if (ActiveWidget) { ActiveWidget->RemoveFromParent(); }
ActiveWidget = CreateWidget<UUserWidget>(this, WidgetClass);
```

## Console Commands Reference

| Command | Purpose |
|---------|---------|
| `memreport -full` | Complete memory dump |
| `obj list class=Texture2D` | List specific class |
| `obj gc` | Force garbage collection |
| `gc.CollectGarbageEveryFrame 1` | Debug GC |
| `obj refs class=MyClass` | Show references |

## Integration with Project

For Huli/S2 project, check these common sources:

1. **GAS Abilities**: `USipherGameplayAbility` instances not ending properly
2. **AI Characters**: `ASipherAICharacter` pooling issues
3. **VFX**: Niagara systems not deactivating
4. **Combo Graph**: `SipherComboGraph` state accumulation
5. **Hit Reactions**: `USipherHitReaction` delegate leaks
