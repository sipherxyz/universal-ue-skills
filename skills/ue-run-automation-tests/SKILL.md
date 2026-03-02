---
name: ue-run-automation-tests
description: Run Unreal Engine automation tests including unit tests, integration tests, and stress tests. Use when running tests, validating code changes, or setting up CI/CD pipelines. Triggers on "run tests", "automation test", "unit test", "test suite", "CI tests", "validate tests".
---

# UE Run Automation Tests

Run Unreal Engine automation tests with headless support for CI/CD pipelines.

## Quick Start

1. Detect engine path
2. Select test category or specific tests
3. Run tests (headless or with editor)
4. Parse results and report failures

## Test Categories

| Category | Path | Description |
|----------|------|-------------|
| All Sipher | `Sipher` | All project tests (144+) |
| GAS | `Sipher.GAS` | Ability system tests (~61) |
| AI | `Sipher.AI` | AI behavior tests (~56) |
| UI | `Sipher.UI` | ViewModel tests (~10) |
| AnimNotify | `Sipher.AnimNotify` | Animation notify tests (~17) |
| Combat | `Sipher.Combat` | Combat system tests |
| Audio | `Sipher.Audio` | Audio subsystem tests (~50) |

## Test Execution

### Headless Mode (CI/CD)

```bash
# Run all Sipher tests
"{EnginePath}/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "{ProjectPath}/S2.uproject" ^
  -ExecCmds="Automation RunTests Sipher;Quit" ^
  -unattended -NullRHI -NoSound -NoSplash -log

# Run specific category
"{EnginePath}/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "{ProjectPath}/S2.uproject" ^
  -ExecCmds="Automation RunTests Sipher.GAS;Quit" ^
  -unattended -NullRHI -NoSound -NoSplash -log

# Run single test
"{EnginePath}/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "{ProjectPath}/S2.uproject" ^
  -ExecCmds="Automation RunTests Sipher.GAS.AbilityDataQueue.Default.ValidDefaultState;Quit" ^
  -unattended -NullRHI -NoSound -NoSplash -log
```

### Command Line Flags

| Flag | Purpose |
|------|---------|
| `-unattended` | No user prompts, auto-accept dialogs |
| `-NullRHI` | Headless rendering (no GPU required) |
| `-NoSound` | Disable audio subsystem |
| `-NoSplash` | Skip splash screen |
| `-log` | Enable logging to file |
| `-LogCmds="global Verbose"` | Verbose logging |
| `-ReportOutputPath="{Path}"` | Custom report location |

### With Editor (Interactive)

```bash
# Open editor with automation window
"{EnginePath}/Engine/Binaries/Win64/UnrealEditor.exe" "{ProjectPath}/S2.uproject"

# In editor: Window > Developer Tools > Session Frontend > Automation
```

## Test Result Parsing

### Log File Location

```
{ProjectPath}/Saved/Logs/S2.log
```

### Parse Results

```powershell
# Find test results in log
$LogFile = Join-Path $ProjectPath "Saved/Logs/S2.log"

# Count successes
$Successes = (Select-String -Path $LogFile -Pattern "Test Completed.*Success").Count

# Count failures
$Failures = (Select-String -Path $LogFile -Pattern "Test Completed.*Fail").Count

# Extract failed test names
$FailedTests = Select-String -Path $LogFile -Pattern "Test Completed. Result={Fail}" -Context 0,1 |
    ForEach-Object { $_.Context.PostContext }
```

### Automation Report Format

```json
{
  "Tests": [
    {
      "TestDisplayName": "Sipher.GAS.AbilityDataQueue.Default.ValidDefaultState",
      "State": "Success",
      "Duration": 0.015
    },
    {
      "TestDisplayName": "Sipher.AI.Coordinator.Handle.TargetHandle.DefaultInvalid",
      "State": "Fail",
      "Duration": 0.008,
      "Errors": ["Expected false but got true"]
    }
  ],
  "Succeeded": 143,
  "Failed": 1,
  "TotalDuration": 45.2
}
```

## Test Fixtures

### Core Fixtures (SipherTestFixtures.h)

| Fixture | Purpose | Setup |
|---------|---------|-------|
| `FWorldFixture` | Test world creation | Spawns actors, controls ticks |
| `FGASFixture` | GAS testing | Manages abilities, effects, attributes |
| `FCombatFixture` | Combat scenarios | Attacker/defender pairing |
| `FUIFixture` | ViewModel testing | Property change tracking |
| `FAnimNotifyFixture` | Animation testing | Mock animation context |
| `FAIFixture` | AI testing | Blackboard access |

### Using Fixtures in Tests

```cpp
IMPLEMENT_SIMPLE_AUTOMATION_TEST(FMyTest, "Sipher.Category.TestName",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMyTest::RunTest(const FString& Parameters)
{
    // Create fixture
    FWorldFixture World;

    // Spawn test actor
    AActor* TestActor = World.SpawnActor<AMyActor>();

    // Run assertions
    TestNotNull(TEXT("Actor should exist"), TestActor);
    TestEqual(TEXT("Health should be 100"), TestActor->Health, 100.f);

    return true;
}
```

## Specialized Test Frameworks

### Stress Testing

```bash
# Run stress test commandlet
"{EnginePath}/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "{ProjectPath}/S2.uproject" ^
  -run=SipherStressTest ^
  -spec="{SpecPath}" ^
  -iterations=100 ^
  -timeout=300
```

### VFX Lifecycle Tests

```bash
# Run via editor console
SipherVFX.RunLifecycleTests
SipherVFX.ExportResults "{OutputPath}/vfx_results.csv"
```

### Performance Testing (APT)

```bash
# Start screenshot capture
SipherAPT.StartScreenshot Interval=1.0 OutputDir="{Path}"

# Start video recording
SipherAPT.StartVideo OutputPath="{Path}/video.mp4" UseHardwareEncoding=true

# Start heatmap collection
SipherAPT.StartHeatmap
```

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Run Automation Tests
  shell: pwsh
  run: |
    $Engine = "G:/UnrealEngine"
    $Project = "${{ github.workspace }}/S2.uproject"

    & "$Engine/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" $Project `
      -ExecCmds="Automation RunTests Sipher;Quit" `
      -unattended -NullRHI -NoSound -NoSplash -log

    # Check for failures
    $Log = Get-Content "Saved/Logs/S2.log" -Raw
    if ($Log -match "Test Completed.*Fail") {
      Write-Error "Tests failed!"
      exit 1
    }
```

### Jenkins Pipeline

```groovy
stage('Run Tests') {
    steps {
        bat """
            "${ENGINE_PATH}\\Engine\\Binaries\\Win64\\UnrealEditor-Cmd.exe" ^
            "${WORKSPACE}\\S2.uproject" ^
            -ExecCmds="Automation RunTests Sipher;Quit" ^
            -unattended -NullRHI -NoSound -NoSplash -log
        """
    }
    post {
        always {
            archiveArtifacts artifacts: 'Saved/Logs/*.log'
        }
    }
}
```

## Test Naming Convention

```
Sipher.<System>.<Component>.<Subcomponent>.<TestName>
```

Examples:
- `Sipher.GAS.AbilityDataQueue.Default.ValidDefaultState`
- `Sipher.AI.Coordinator.Handle.TargetHandle.DefaultInvalid`
- `Sipher.UI.ViewModel.BossState.DefaultValues`
- `Sipher.Combat.Damage.Pipeline.AppliesCorrectly`

## Report Template

```markdown
# Automation Test Report

## Summary
- **Total Tests**: {Count}
- **Passed**: {Passed} ({Percentage}%)
- **Failed**: {Failed}
- **Duration**: {Time}

## Failed Tests
| Test Name | Error | Duration |
|-----------|-------|----------|
| {TestPath} | {ErrorMessage} | {Time}ms |

## Test Categories
| Category | Passed | Failed | Duration |
|----------|--------|--------|----------|
| Sipher.GAS | {N} | {N} | {Time}s |
| Sipher.AI | {N} | {N} | {Time}s |
| Sipher.UI | {N} | {N} | {Time}s |

## Slow Tests (>1s)
| Test Name | Duration |
|-----------|----------|
| {TestPath} | {Time}s |

## Recommendations
1. {Fix suggestion for failed tests}
```

## Troubleshooting

### Tests Not Found
```bash
# List available tests
-ExecCmds="Automation List;Quit"
```

### Tests Timeout
```bash
# Increase timeout (default 60s)
-ExecCmds="Automation SetTimeout 300;Automation RunTests Sipher;Quit"
```

### GPU Required Tests
Some tests require GPU - remove `-NullRHI` flag for those.

### Audio Tests Failing
Audio tests need audio subsystem - remove `-NoSound` flag.

### Memory Issues
```bash
# Limit parallel test execution
-ExecCmds="Automation SetParallelism 1;Automation RunTests Sipher;Quit"
```

## Quick Reference

```bash
# All tests (headless)
UnrealEditor-Cmd.exe Project.uproject -ExecCmds="Automation RunTests Sipher;Quit" -unattended -NullRHI -NoSound -log

# GAS tests only
... -ExecCmds="Automation RunTests Sipher.GAS;Quit" ...

# AI tests only
... -ExecCmds="Automation RunTests Sipher.AI;Quit" ...

# List all tests
... -ExecCmds="Automation List;Quit" ...

# Check results
findstr "Test Completed" Saved\Logs\S2.log
```
