---
name: generate-tests
description: Generate C++ unit and functional tests from PRD/TechDoc specifications
---

# Test Generation Skill

**Role:** Test Engineer
**Input:** PRD/TechDoc (pasted or file reference)
**Output:** C++ automation test files
**Platform:** Unreal Engine 5.7

## Objective

Generate comprehensive C++ test cases from feature specifications (PRD/TechDocs). Produces unit tests and functional tests by default, with optional integration and performance tests.

## When to Use This Skill

- When implementing a new feature that needs test coverage
- When QA provides test scenarios for a feature
- When reviewing a PRD and want to define test cases
- Before creating a PR that requires tests for critical systems

---

## Usage

### Basic Usage

```
/qa-testing:generate-tests
```

Then provide the PRD by either:
1. **Pasting directly** into the chat
2. **Referencing a file**: `docs/features/charged-attack.md`

### With Options

```
/qa-testing:generate-tests <file-or-paste> [options]

Options:
  --include-integration    Generate integration tests
  --include-perf          Generate performance tests
  --output <path>         Override output directory
  --dry-run               Preview without writing files
```

### Examples

```
# Paste PRD directly
/qa-testing:generate-tests
> Here's the Charged Attack PRD: [paste content]

# Reference a file
/qa-testing:generate-tests docs/features/parry-system.md

# With performance tests
/qa-testing:generate-tests docs/features/50-enemy-combat.md --include-perf

# Override output location
/qa-testing:generate-tests docs/features/combo.md --output Plugins/SipherComboGraph/Private/Tests/
```

---

## Workflow

```
1. RECEIVE PRD/TechDoc
   ↓
2. ANALYZE content:
   - Identify target system (Combat, AI, GAS, UI)
   - Extract testable requirements
   - Determine test file location
   ↓
3. GENERATE test cases:
   - Unit tests (logic, calculations)
   - Functional tests (behavior with world/actors)
   - Integration/Performance (if requested)
   ↓
4. WRITE test files to appropriate location
   ↓
5. REPORT summary of generated tests
```

---

## System Detection

Analyze PRD content to determine target system and output location:

| Keywords Found | System | Default Output Location |
|----------------|--------|-------------------------|
| combo, attack, damage, hit, parry, dodge, hitstop | Combat | `Plugins/SipherComboGraph/Private/Tests/` |
| parry, deflect, block, counter | Parry | `Plugins/SipherParryV2/Private/Tests/` |
| AI, behavior, patrol, aggro, coordinator, slot | AI | `Plugins/SipherAIScalableFramework/Private/Tests/` |
| ability, effect, attribute, GAS, gameplay tag | GAS | `Source/S2/Private/Core/ASC/Tests/` |
| UI, widget, viewmodel, HUD, menu, MVVM | UI | `Source/S2/Private/UI/Tests/` |
| hit reaction, stagger, knockback | HitReaction | `Plugins/SipherHitReaction/Private/Tests/` |
| QTE, quick time, prompt | QTE | `Plugins/SipherQTE/Private/Tests/` |
| Multiple systems mentioned | Integration | `Source/S2/Private/Tests/Integration/` |

---

## Test Naming Convention

Follow project standard: `Sipher.{TestType}.{Domain}.{Category}.{TestName}`

```cpp
// Unit test
"Sipher.Unit.Combat.ChargedAttack.DamageScalingMinCharge"

// Functional test
"Sipher.Functional.Combat.ChargedAttack.FullChargeAppliesStagger"

// Integration test
"Sipher.Integration.Combat.ChargedAttackWithParryCounter"

// Performance test
"Sipher.Perf.Combat.ChargedAttack50Enemies"
```

---

## Test Extraction Rules

Extract test cases from PRD by identifying these patterns:

| PRD Pattern | Test Type | Example |
|-------------|-----------|---------|
| Specific numbers/thresholds | Unit | "damage scales from 100% to 300%" → test min/mid/max |
| "When X, then Y" | Functional | "When fully charged, adds stagger" → test stagger applied |
| "Can/Cannot" | Both + Negative | "Can cancel with dodge" → test cancel works |
| "If...else" conditions | Branch coverage | Each branch gets a test |
| State transitions | State tests | Test each transition |
| Time-based behavior | Timing tests | Test at boundary times |
| Edge cases mentioned | Edge case tests | Test boundary conditions |

---

## Generated Test Structure

### Unit Test Template

```cpp
// {Feature}Tests.cpp

#include "Misc/AutomationTest.h"
#include "{RelevantHeaders}.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    F{Feature}_{TestCategory}_{TestName},
    "Sipher.Unit.{Domain}.{Feature}.{TestName}",
    EAutomationTestFlags::ApplicationContextMask | EAutomationTestFlags::ProductFilter)

bool F{Feature}_{TestCategory}_{TestName}::RunTest(const FString& Parameters)
{
    // Arrange
    // Set up test data

    // Act
    // Call the function being tested

    // Assert
    // Verify expected outcomes
    TestEqual("Description", Actual, Expected);

    return true;
}
```

### Functional Test Template

```cpp
// {Feature}FunctionalTests.cpp

#include "Misc/AutomationTest.h"
#include "Tests/Fixtures/SipherTestFixtures.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    F{Feature}_{Scenario},
    "Sipher.Functional.{Domain}.{Feature}.{Scenario}",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter)

bool F{Feature}_{Scenario}::RunTest(const FString& Parameters)
{
    // Arrange
    FSipherCombatTestFixture Fixture(1);  // Or appropriate fixture
    // Grant abilities, set up state

    // Act
    // Perform the action being tested
    Fixture.TickCombat(Duration);

    // Assert
    TestTrue("Expected outcome", Condition);

    return true;
}
```

### Performance Test Template (when --include-perf)

```cpp
// {Feature}PerfTests.cpp

#include "Misc/AutomationTest.h"
#include "Tests/Fixtures/SipherTestFixtures.h"
#include "Tests/Performance/PerformanceTestHelpers.h"

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FPerf_{Feature}_{Scenario},
    "Sipher.Perf.{Domain}.{Feature}.{Scenario}",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::PerfFilter)

bool FPerf_{Feature}_{Scenario}::RunTest(const FString& Parameters)
{
    // Arrange
    FSipherCombatTestFixture Fixture(EnemyCount);
    FSipherPerfMetrics Metrics;
    FSipherPerfBaseline Baseline = FSipherPerfBaseline::Load(TestName);

    // Act - Run scenario
    Metrics.StartCapture();
    for (float Time = 0; Time < TestDuration; Time += DeltaTime)
    {
        Metrics.BeginFrame();
        Fixture.TickCombat(DeltaTime);
        Metrics.EndFrame();
    }
    Metrics.StopCapture();

    // Assert
    float Regression = Metrics.CompareToBaseline(Baseline);
    TestTrue("Frame time regression under threshold",
        Regression < SipherPerfConfig::FrameTimeRegressionThreshold);

    return true;
}
```

---

## Fixtures Reference

Use shared fixtures from `Source/S2/Private/Tests/Fixtures/`:

| Fixture | Purpose | Usage |
|---------|---------|-------|
| `FSipherTestWorld` | Creates test world | Basic world setup |
| `FSipherTestPlayer` | Player with ASC | `FSipherTestPlayer Player(World)` |
| `FSipherTestEnemy` | Enemy with AI | `FSipherTestEnemy Enemy(World, Class, Location)` |
| `FSipherCombatTestFixture` | Full combat setup | `FSipherCombatTestFixture Fixture(EnemyCount)` |

---

## Output Summary

After generation, report:

```markdown
## Generated Tests for: {Feature Name}

**Target System:** {Detected System}
**Output Location:** {Path}

### Unit Tests (X tests)
- Sipher.Unit.{Domain}.{Feature}.{Test1}
- Sipher.Unit.{Domain}.{Feature}.{Test2}
...

### Functional Tests (Y tests)
- Sipher.Functional.{Domain}.{Feature}.{Test1}
- Sipher.Functional.{Domain}.{Feature}.{Test2}
...

### Files Created
- `{Path}/{Feature}Tests.cpp` (X tests)
- `{Path}/{Feature}FunctionalTests.cpp` (Y tests)

**Next Steps:**
1. Review generated tests for accuracy
2. Implement any missing fixture methods used
3. Run tests locally: `UnrealEditor-Cmd S2.uproject -ExecCmds="Automation RunTests Sipher.*.{Feature}; Quit"`
4. Create PR with test files
```

---

## Critical Systems Requiring Tests

Tests are mandatory for these systems (enforced by CI):

- **Combat**: ComboGraph, Parry, HitReaction, UniversalDamage, QTE
- **AI**: SipherAIScalableFramework, StateTree, BehaviorTree
- **GAS**: SipherAbilitySystemComponent, GameplayEffects
- **UI**: MVVM ViewModels, Core Widgets

Editor tools and non-runtime utilities are exempt.

---

## Related Documentation

- [Testing Framework Design](claude-agents/qa/2026-01-01-testing-framework-design.md)
- [Test Generation Workflow](claude-agents/qa/test-generation-workflow.md)

## Legacy Metadata

```yaml
skill: generate-tests
invoke: /qa-testing:generate-tests
type: code-generation
category: testing
scope: Source/**/Tests/, Plugins/**/Tests/
```
