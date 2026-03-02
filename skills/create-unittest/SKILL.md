---
name: create-unittest
description: Generate comprehensive C++ unit tests with ultrathink analysis for edge cases and integration errors
---

# Create Unit Test Skill

**Role:** Senior Test Engineer with deep UE5 and GAS expertise
**Input:** C++ class/file path OR PRD/TechDoc specification
**Output:** Comprehensive C++ automation test files
**Platform:** Unreal Engine 5.7

## Objective

Generate production-quality unit tests using **ultrathink analysis**:
1. **Exhaustive edge cases** - boundary, null/empty, overflow, race conditions
2. **Mutation-based thinking** - "What if off-by-one? Null? Wrong type?"
3. **Coverage matrix** - systematic input combinations and state transitions

Tests catch both **logic errors** (unit tests) and **integration errors** (functional tests).

---

## Usage

### Mode 1: Code-First (Analyze Existing Code)

```
/s2:create-unittest <class-name-or-file-path>

Examples:
/s2:create-unittest FSipherAsyncLoader
/s2:create-unittest Source/S2/Private/Combat/SipherParryComponent.cpp
/s2:create-unittest Plugins/SipherCore/Source/SipherCore/Public/Utils/SipherAsyncLoader.h
```

### Mode 2: Spec-First (From PRD/TechDoc)

```
/s2:create-unittest
> [Paste PRD or reference file path]

Examples:
/s2:create-unittest docs/features/charged-attack.md
/s2:create-unittest
> Feature: Parry Window
> - Player can parry attacks within 200ms window
> - Perfect parry (first 50ms) triggers counter-attack
```

### Options

```
--dry-run              Preview test cases without writing files
--depth=basic|full     Control test exhaustiveness (default: full)
--output <path>        Override output directory
--no-integration       Skip functional/integration tests
--fixture <name>       Force specific fixture (GAS, Combat, AI, UI, AnimNotify)
```

---

## Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. INPUT ANALYSIS                                               │
├─────────────────────────────────────────────────────────────────┤
│ • Identify target class/system                                  │
│ • Read source code or PRD specification                         │
│ • Extract public API, state transitions, dependencies           │
│ • Determine output location and fixture type                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│ 2. ULTRATHINK: COVERAGE MATRIX                                  │
├─────────────────────────────────────────────────────────────────┤
│ For each public method, create matrix:                          │
│                                                                 │
│ ┌─────────────────┬───────────────────────────────────────────┐ │
│ │ Input Parameter │ Test Values                               │ │
│ ├─────────────────┼───────────────────────────────────────────┤ │
│ │ Pointer/Ref     │ nullptr, valid, dangling                  │ │
│ │ Integer         │ 0, 1, -1, MAX, MIN, typical               │ │
│ │ Float           │ 0.0, 1.0, -1.0, NaN, Inf, epsilon         │ │
│ │ String          │ empty, whitespace, unicode, very long     │ │
│ │ Array           │ empty, single, typical, max capacity      │ │
│ │ Enum            │ each value, invalid cast                  │ │
│ │ Handle/ID       │ invalid, valid, stale/expired             │ │
│ │ Soft/Weak Ptr   │ null, valid, unloaded, loaded             │ │
│ └─────────────────┴───────────────────────────────────────────┘ │
│                                                                 │
│ State combinations:                                             │
│ • Pre-initialization, initialized, active, destroyed            │
│ • Component registered vs unregistered                          │
│ • World valid vs nullptr                                        │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│ 3. ULTRATHINK: MUTATION ANALYSIS                                │
├─────────────────────────────────────────────────────────────────┤
│ For each test case, ask:                                        │
│                                                                 │
│ • What if this value is off-by-one?                             │
│ • What if this pointer is null?                                 │
│ • What if this is called twice?                                 │
│ • What if this is called before initialization?                 │
│ • What if this is called from wrong thread?                     │
│ • What if the callback is null?                                 │
│ • What if the async operation fails mid-way?                    │
│ • What if the object is destroyed during operation?             │
│ • What if GC runs between operations?                           │
│ • What if this modifies shared state?                           │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│ 4. GENERATE TEST STRUCTURE                                      │
├─────────────────────────────────────────────────────────────────┤
│ Single file per class with sections:                            │
│                                                                 │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ {ClassName}Tests.cpp                                        │ │
│ ├─────────────────────────────────────────────────────────────┤ │
│ │ // Test Assets / Constants                                  │ │
│ │ // SECTION: Basic Functionality (Unit Tests)                │ │
│ │ // SECTION: Edge Cases                                      │ │
│ │ // SECTION: Error Handling                                  │ │
│ │ // SECTION: State Transitions                               │ │
│ │ // SECTION: Integration / Functional Tests                  │ │
│ │ // SECTION: Async / Latent Tests (if applicable)            │ │
│ └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│ 5. WRITE & REPORT                                               │
├─────────────────────────────────────────────────────────────────┤
│ • Write test file to appropriate location                       │
│ • Generate summary with test count by category                  │
│ • Provide run command for immediate verification                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Fixture Auto-Detection

Analyze the target class to select the appropriate test fixture:

| Class Pattern | Detected System | Fixture | Include |
|---------------|-----------------|---------|---------|
| `*AbilitySystemComponent*`, `*ASC*`, `UGameplayAbility*`, `UGameplayEffect*`, `*Attribute*` | GAS | `FGASFixture` | `SipherTestFixtures.h` |
| `*Combat*`, `*Damage*`, `*Attack*`, `*Parry*`, `*HitReaction*` | Combat | `FCombatFixture` | `SipherTestFixtures.h` |
| `*AI*`, `*BehaviorTree*`, `*StateTree*`, `*Blackboard*`, `*Coordinator*` | AI | `FAIFixture` | `SipherTestFixtures.h` |
| `*Widget*`, `*ViewModel*`, `*UI*`, `*HUD*` | UI | `FUIFixture` | `SipherTestFixtures.h` |
| `*AnimNotify*`, `*Montage*` | Animation | `FAnimNotifyFixture` | `SipherTestFixtures.h` |
| `*AsyncLoad*`, `*Streamable*` | Async | `FWorldFixture` + Latent | `SipherTestFixtures.h` |
| Other | Generic | `FWorldFixture` | `SipherTestFixtures.h` |

---

## Output Location Rules

| Source Location | Test Output Location |
|-----------------|---------------------|
| `Source/S2/Private/Combat/*` | `Source/S2/Private/Tests/Combat/` |
| `Source/S2/Private/Core/ASC/*` | `Source/S2/Private/Tests/GAS/` |
| `Source/S2/Private/AI/*` | `Source/S2/Private/Tests/AI/` |
| `Source/S2/Private/UI/*` | `Source/S2/Private/Tests/UI/` |
| `Plugins/{Plugin}/Source/{Module}/Private/*` | `Plugins/{Plugin}/Source/{Module}/Private/Tests/` |
| `Plugins/{Plugin}/Source/{Module}/Public/*` | `Plugins/{Plugin}/Source/{Module}/Private/Tests/` |

---

## Test Naming Convention

```
Sipher.{Domain}.{ClassName}.{TestCategory}.{TestName}

Examples:
Sipher.Core.AsyncLoader.EmptyPaths
Sipher.Core.AsyncLoader.HandleDefaultState
Sipher.Core.AsyncLoader.NullCallback.NoFailed
Sipher.GAS.AbilityDataQueue.QueueItemConstruction
Sipher.GAS.AbilityDataQueue.InstancedStructCopyMove
Sipher.Combat.ParryComponent.ParryWindow.PerfectParry
Sipher.Combat.ParryComponent.EdgeCase.NullInstigator
```

---

## Edge Case Checklist

**MANDATORY for every test file - verify each applies:**

### Null/Invalid Input
- [ ] `nullptr` passed for each pointer parameter
- [ ] Invalid handle/ID passed
- [ ] Empty array/string passed
- [ ] Uninitialized struct passed

### Boundary Values
- [ ] Zero value for numeric parameters
- [ ] Negative values where typically positive
- [ ] Maximum value (INT_MAX, FLT_MAX)
- [ ] Epsilon/tiny values for floats
- [ ] Off-by-one at array bounds

### State Errors
- [ ] Called before initialization
- [ ] Called after destruction
- [ ] Called twice in succession
- [ ] Called with wrong object state
- [ ] Component not registered

### Async/Timing
- [ ] Callback is nullptr
- [ ] Operation cancelled mid-way
- [ ] Object destroyed during async operation
- [ ] Multiple concurrent operations
- [ ] Zero timeout/duration

### UE-Specific
- [ ] World is nullptr
- [ ] GC during operation
- [ ] Component not initialized (PostInitializeComponents not called)
- [ ] Invalid asset path for TSoftObjectPtr
- [ ] Ability/Effect CDO access

---

## Template: Unit Test File

```cpp
// Copyright Ather Labs, Inc. All Rights Reserved.

/**
 * Unit tests for {ClassName}.
 * Tests {brief description of what class does}.
 *
 * Test Path: Sipher.{Domain}.{ClassName}.*
 */

#include "CoreMinimal.h"
#include "Misc/AutomationTest.h"
#include "Tests/AutomationCommon.h"

#if WITH_AUTOMATION_TESTS

#include "Tests/Fixtures/SipherTestFixtures.h"
#include "{PathToClassHeader}"

using namespace SipherTestFixtures;

//////////////////////////////////////////////////////////////////////////
// Test Constants
//////////////////////////////////////////////////////////////////////////

namespace {ClassName}TestConstants
{
    // Define test values here
    constexpr float TestDuration = 1.0f;
    const FName TestName = TEXT("TestValue");
}

//////////////////////////////////////////////////////////////////////////
// SECTION: Basic Functionality
//////////////////////////////////////////////////////////////////////////

IMPLEMENT_SIMPLE_AUTOMATION_TEST(F{ClassName}_BasicConstruction,
    "Sipher.{Domain}.{ClassName}.BasicConstruction",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool F{ClassName}_BasicConstruction::RunTest(const FString& Parameters)
{
    // Arrange
    {Fixture} Fixture;
    if (!Fixture.IsValid())
    {
        AddError(TEXT("Fixture creation failed"));
        return false;
    }

    // Act
    // {Create/call the thing being tested}

    // Assert
    TestNotNull(TEXT("Object should be created"), /* pointer */);

    return true;
}

//////////////////////////////////////////////////////////////////////////
// SECTION: Edge Cases - Null/Invalid Input
//////////////////////////////////////////////////////////////////////////

IMPLEMENT_SIMPLE_AUTOMATION_TEST(F{ClassName}_NullInput_{ParameterName},
    "Sipher.{Domain}.{ClassName}.EdgeCase.NullInput.{ParameterName}",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool F{ClassName}_NullInput_{ParameterName}::RunTest(const FString& Parameters)
{
    // Arrange
    {Fixture} Fixture;
    if (!Fixture.IsValid())
    {
        AddError(TEXT("Fixture creation failed"));
        return false;
    }

    // Act - pass nullptr where valid pointer expected
    // {Call method with nullptr}

    // Assert - should handle gracefully (no crash, return error/invalid)
    // TestFalse(TEXT("Should return false for null input"), Result);

    return true;
}

//////////////////////////////////////////////////////////////////////////
// SECTION: Edge Cases - Boundary Values
//////////////////////////////////////////////////////////////////////////

IMPLEMENT_SIMPLE_AUTOMATION_TEST(F{ClassName}_BoundaryValue_Zero,
    "Sipher.{Domain}.{ClassName}.EdgeCase.BoundaryValue.Zero",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool F{ClassName}_BoundaryValue_Zero::RunTest(const FString& Parameters)
{
    // Test with zero value
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(F{ClassName}_BoundaryValue_Negative,
    "Sipher.{Domain}.{ClassName}.EdgeCase.BoundaryValue.Negative",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool F{ClassName}_BoundaryValue_Negative::RunTest(const FString& Parameters)
{
    // Test with negative value where positive expected
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(F{ClassName}_BoundaryValue_Max,
    "Sipher.{Domain}.{ClassName}.EdgeCase.BoundaryValue.Max",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool F{ClassName}_BoundaryValue_Max::RunTest(const FString& Parameters)
{
    // Test with maximum value
    return true;
}

//////////////////////////////////////////////////////////////////////////
// SECTION: State Transitions
//////////////////////////////////////////////////////////////////////////

IMPLEMENT_SIMPLE_AUTOMATION_TEST(F{ClassName}_State_CalledBeforeInit,
    "Sipher.{Domain}.{ClassName}.State.CalledBeforeInit",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool F{ClassName}_State_CalledBeforeInit::RunTest(const FString& Parameters)
{
    // Test calling method before proper initialization
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(F{ClassName}_State_CalledTwice,
    "Sipher.{Domain}.{ClassName}.State.CalledTwice",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool F{ClassName}_State_CalledTwice::RunTest(const FString& Parameters)
{
    // Test calling method twice - should be idempotent or handle correctly
    return true;
}

//////////////////////////////////////////////////////////////////////////
// SECTION: Integration Tests (with World/Components)
//////////////////////////////////////////////////////////////////////////

IMPLEMENT_SIMPLE_AUTOMATION_TEST(F{ClassName}_Integration_WithWorld,
    "Sipher.{Domain}.{ClassName}.Integration.WithWorld",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool F{ClassName}_Integration_WithWorld::RunTest(const FString& Parameters)
{
    // Test with full world and component setup
    FWorldFixture WorldFixture;
    if (!WorldFixture.IsValid())
    {
        AddError(TEXT("World fixture creation failed"));
        return false;
    }

    // Spawn actors, set up scenario
    // AActor* TestActor = WorldFixture.SpawnActor<AActor>();

    // Run scenario
    // WorldFixture.Tick(0.016f);

    // Verify results
    return true;
}

#endif // WITH_AUTOMATION_TESTS
```

---

## Template: Latent/Async Tests

For classes with async operations:

```cpp
//////////////////////////////////////////////////////////////////////////
// Latent Commands for Async Testing
//////////////////////////////////////////////////////////////////////////

DEFINE_LATENT_AUTOMATION_COMMAND_TWO_PARAMETER(FWaitFor{ClassName}Complete,
    TSharedPtr<{HandleType}>, HandlePtr,
    TSharedPtr<bool>, bCompletePtr);

bool FWaitFor{ClassName}Complete::Update()
{
    if (!HandlePtr.IsValid() || !HandlePtr->IsValid())
    {
        return true; // Handle invalid or completed
    }

    if (HandlePtr->IsComplete() || !HandlePtr->IsLoading())
    {
        return true;
    }

    return false; // Still loading
}

//////////////////////////////////////////////////////////////////////////
// SECTION: Async Operations
//////////////////////////////////////////////////////////////////////////

IMPLEMENT_SIMPLE_AUTOMATION_TEST(F{ClassName}_Async_Completion,
    "Sipher.{Domain}.{ClassName}.Async.Completion",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool F{ClassName}_Async_Completion::RunTest(const FString& Parameters)
{
    TSharedPtr<bool> bCompleteCalled = MakeShared<bool>(false);
    TSharedPtr<bool> bFailedCalled = MakeShared<bool>(false);

    // Start async operation
    TSharedPtr<{HandleType}> HandlePtr = MakeShared<{HandleType}>();
    *HandlePtr = /* start async operation with callbacks */;

    // If already completed synchronously
    if (*bCompleteCalled || !HandlePtr->IsValid())
    {
        TestTrue(TEXT("OnComplete should have been called"), *bCompleteCalled);
        TestFalse(TEXT("OnFailed should NOT be called"), *bFailedCalled);
        return true;
    }

    // Add latent wait
    ADD_LATENT_AUTOMATION_COMMAND(FWaitFor{ClassName}Complete(HandlePtr, bCompleteCalled));

    // Final verification
    ADD_LATENT_AUTOMATION_COMMAND(FDelayedFunctionLatentCommand([this, bCompleteCalled, bFailedCalled]()
    {
        TestTrue(TEXT("OnComplete should have been called after async"), *bCompleteCalled);
        TestFalse(TEXT("OnFailed should NOT be called"), *bFailedCalled);
        return true;
    }, 0.1f));

    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(F{ClassName}_Async_Cancellation,
    "Sipher.{Domain}.{ClassName}.Async.Cancellation",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool F{ClassName}_Async_Cancellation::RunTest(const FString& Parameters)
{
    // Test that cancellation works correctly
    // Callback should NOT be called after cancel
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(F{ClassName}_Async_NullCallback,
    "Sipher.{Domain}.{ClassName}.Async.NullCallback",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool F{ClassName}_Async_NullCallback::RunTest(const FString& Parameters)
{
    // Test with nullptr callback - should not crash
    return true;
}
```

---

## Output Report Format

After generating tests, output:

```markdown
## Generated Tests for: {ClassName}

**Source:** `{SourceFilePath}`
**Output:** `{TestFilePath}`
**Fixture:** {DetectedFixture}
**Domain:** {Domain}

### Coverage Matrix Applied

| Parameter | Test Values |
|-----------|-------------|
| {Param1} | nullptr, valid |
| {Param2} | 0, -1, MAX, typical |
| ... | ... |

### Generated Tests

**Basic Functionality ({N} tests)**
- Sipher.{Domain}.{ClassName}.BasicConstruction
- Sipher.{Domain}.{ClassName}.{MethodName}
...

**Edge Cases ({N} tests)**
- Sipher.{Domain}.{ClassName}.EdgeCase.NullInput.{Param}
- Sipher.{Domain}.{ClassName}.EdgeCase.BoundaryValue.Zero
...

**State Transitions ({N} tests)**
- Sipher.{Domain}.{ClassName}.State.CalledBeforeInit
- Sipher.{Domain}.{ClassName}.State.CalledTwice
...

**Integration ({N} tests)**
- Sipher.{Domain}.{ClassName}.Integration.WithWorld
...

**Async ({N} tests)** (if applicable)
- Sipher.{Domain}.{ClassName}.Async.Completion
- Sipher.{Domain}.{ClassName}.Async.Cancellation
...

### Run Command

```bash
UnrealEditor-Cmd.exe "{CWD}/{ProjectFile}" ^
    -nullrhi -nosplash -unattended -nopause ^
    -ExecCmds="Automation RunTests Sipher.{Domain}.{ClassName}; Quit"
```

### Edge Case Checklist Status

- [x] Null input for pointer parameters
- [x] Invalid handle/ID
- [x] Empty array/string
- [x] Zero/negative boundary values
- [x] Called before initialization
- [x] Called twice in succession
- [ ] Async cancellation (if applicable)
- [ ] Concurrent operations (if applicable)
```

---

## Critical Reminders

1. **ALWAYS use `#if WITH_AUTOMATION_TESTS` guard**
2. **ALWAYS include fixture validity check at test start**
3. **NEVER use `LoadSynchronous()` in tests** - use test assets or mock data
4. **ALWAYS verify no memory leaks** - clean up spawned actors and allocated memory
5. **ALWAYS use `TEXT()` macro for string literals in assertions**
6. **Test names must be unique** - include full context in test path

---

## Related Documentation

- Test Fixtures: `Source/S2/Private/Tests/Fixtures/SipherTestFixtures.h`
- Testing Proposal: `claude-agents/reports/ue-automation-testing/Huli-Test-Architecture-Proposal.md`
- UE Automation Overview: `claude-agents/reports/ue-automation-testing/UE-Automation-Testing-Overview.md`

## Legacy Metadata

```yaml
skill: create-unittest
invoke: /qa-testing:create-unittest
alias: /s2:create-unittest
type: code-generation
category: testing
scope: Source/**/Tests/, Plugins/**/Tests/
```
