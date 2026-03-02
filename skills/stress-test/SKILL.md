---
name: stress-test
description: Run automated stress tests using SipherStressTest plugin to find random crashes
---

# Stress Test Skill

**Role:** QA Automation Engineer
**Scope:** Automated stress testing and crash detection
**Plugin:** SipherStressTest
**Platform:** Windows (Win64)

## Objective

Help users record gameplay sessions and run automated stress tests to find random/intermittent crashes and bugs.

## Prerequisites

1. SipherStressTest plugin is enabled (located in `Plugins/Frameworks/SipherStressTest/`)
2. Project compiles successfully
3. Unreal Engine registered in Windows Registry

## Dynamic Path Resolution

```
{CWD} = Current Working Directory (D:\s2)
{ProjectFile} = S2.uproject
{RecordingsDir} = {CWD}/Saved/StressTest/Recordings
{ResultsDir} = {CWD}/Saved/StressTestResults
{RunScript} = {CWD}/RunStressTest.bat
```

## Core Operations

### 1. Record a Gameplay Session

Guide user through recording:

1. **Instruct user to start PIE** (Play in Editor)
2. **Open console** (`~` key)
3. **Execute recording commands:**

```
Sipher.Recording.Start [optional-session-name]
```

4. **User plays the level**
5. **Add checkpoints at key moments:**

```
Sipher.Recording.AddCheckpoint
```

6. **Stop recording:**

```
Sipher.Recording.Stop
```

**Output Location:** `{RecordingsDir}/<session-id>.json`

### 2. Run Stress Test (Batch Script)

**Most common operation** - Run stress test via batch script:

```bash
"{CWD}/RunStressTest.bat" -spec "{RecordingsDir}/<session-id>.json" -iterations 10
```

**Full options:**

```bash
RunStressTest.bat -spec <path> [-iterations N] [-timeout S] [-nocrashrecovery] [-output <path>] [-verbose]
```

| Option | Default | Description |
|--------|---------|-------------|
| `-spec` | Required | Path to session JSON |
| `-iterations` | 10 | Number of replay iterations |
| `-timeout` | 600 | Seconds per iteration |
| `-nocrashrecovery` | false | Stop on first failure |
| `-output` | Saved/StressTestResults | Report directory |
| `-verbose` | false | Enable detailed logging |

### 3. Run Stress Test (PowerShell)

Alternative method with more control:

```powershell
& "{CWD}/Scripts/StressTest/RunLocalStressTest.ps1" -Spec "<session>.json" -Iterations 10 -Verbose
```

### 4. Run Stress Test (Direct Commandlet)

For CI/CD or custom integration:

```bash
"{EnginePath}/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "{CWD}/S2.uproject" -run=SipherStressTest -spec="<session>.json" -iterations=10 -crashrecovery=true -unattended -nopause -NullRHI
```

### 5. Check Recording Status (In-Editor)

```
Sipher.Recording.Status
```

Expected output:
```
Recording Status:
  Session ID: <guid>
  Current Frame: 1234
  Events Recorded: 567
  Checkpoints: 3
  Duration: 20.57 seconds
```

### 6. Replay a Session (In-Editor)

For testing recordings before stress test:

```
Sipher.Replay.Start "{RecordingsDir}/<session-id>.json"
```

Check progress:
```
Sipher.Replay.Status
```

Stop replay:
```
Sipher.Replay.Stop
```

### 7. List Available Recordings

```bash
ls "{CWD}/Saved/StressTest/Recordings/"
```

### 8. View Test Results

Results are in `{ResultsDir}/`:
- `stress-test_<session>_<timestamp>.json` - Machine-readable
- `stress-test_<session>_<timestamp>.md` - Human-readable report

```bash
cat "{ResultsDir}/stress-test_<session>_<timestamp>.md"
```

## Console Commands Reference

### Recording

| Command | Description |
|---------|-------------|
| `Sipher.Recording.Start [ID]` | Start recording with optional session ID |
| `Sipher.Recording.Stop` | Stop and save recording |
| `Sipher.Recording.AddCheckpoint` | Add state verification checkpoint |
| `Sipher.Recording.Status` | Show recording status |

### Replay

| Command | Description |
|---------|-------------|
| `Sipher.Replay.Start <path>` | Start replay from file |
| `Sipher.Replay.Stop` | Stop current replay |
| `Sipher.Replay.Status` | Show replay progress |

## Example Workflows

### Workflow A: Quick Stress Test

```bash
# 1. User records session in editor (manual step)
# 2. Find the recording
ls "Saved/StressTest/Recordings/"

# 3. Run stress test
./RunStressTest.bat -spec "Saved/StressTest/Recordings/<session>.json" -iterations 20

# 4. Check results
cat "Saved/StressTestResults/stress-test_<session>_*.md"
```

### Workflow B: Extended Overnight Test

```bash
./RunStressTest.bat -spec "combat-test.json" -iterations 500 -timeout 1200 -output "OvernightResults"
```

### Workflow C: CI/CD Integration

```yaml
# In GitHub Actions or similar
- name: Stress Test
  run: |
    .\RunStressTest.bat -spec "TestSpecs/regression-combat.json" -iterations 100
  shell: cmd
```

## Interpreting Results

### Success Rate

| Rate | Interpretation |
|------|----------------|
| 100% | No crashes detected |
| 95-99% | Rare intermittent issue |
| 80-95% | Reproducible bug exists |
| <80% | Critical stability issue |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All iterations passed |
| 1 | One or more crashes/failures |

## Troubleshooting

### "Could not find Unreal Engine"

Engine not registered. Check registry:
```bash
reg query "HKCU\SOFTWARE\Epic Games\Unreal Engine\Builds"
```

### "Spec file not found"

Verify path is correct:
```bash
ls "{RecordingsDir}/"
```

### "All iterations timeout"

Increase timeout or check if game loads properly:
```bash
./RunStressTest.bat -spec "session.json" -iterations 5 -timeout 1200 -verbose
```

## File Locations

| Path | Purpose |
|------|---------|
| `Plugins/Frameworks/SipherStressTest/` | Plugin source |
| `Plugins/Frameworks/SipherStressTest/Docs/` | Documentation |
| `Saved/StressTest/Recordings/` | Recorded sessions |
| `Saved/StressTestResults/` | Test reports |
| `RunStressTest.bat` | Quick launcher |
| `Scripts/StressTest/` | PowerShell scripts |

## Related Documentation

- Design Document: `Plugins/Frameworks/SipherStressTest/Docs/DESIGN.md`
- User Guide: `Plugins/Frameworks/SipherStressTest/Docs/USER_GUIDE.md`
- Example Spec: `Plugins/Frameworks/SipherStressTest/Content/TestSpecs/example-combat-session.json`

## Legacy Metadata

```yaml
skill: stress-test
type: testing
category: qa-automation
scope: project-root
```
