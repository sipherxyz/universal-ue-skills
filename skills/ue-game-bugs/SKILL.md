---
name: ue-game-bugs
description: Autonomous bug fixing system for UE5 - accepts GitHub issues, screenshots, logs, or text
---

# Autonomous Bug Fix Skill

**Role:** Bug Fix Engineer
**Scope:** Full codebase analysis and C++ bug fixing
**Engine Version:** UE 5.7.1-huli
**Platform:** Windows

## Objective

Autonomously analyze and fix bugs from multiple input sources:
- GitHub issue URLs or numbers
- Screenshots (multimodal vision analysis)
- Log files and stack traces
- Text descriptions

Routes fixes through BMGD workflows with adversarial code review.

## When to Use This Skill

- Bug reports from QA with screenshots
- GitHub issues requiring C++ fixes
- Crash logs needing investigation
- Player-reported issues with reproduction steps

## Input Types

### GitHub Issues
```
/game-bugs 123
/game-bugs https://github.com/sipherxyz/s2/issues/123
```

### Screenshots
```
/game-bugs screenshot.png
/game-bugs 123 evidence1.png evidence2.png
```

### Log Files
```
/game-bugs crash.log
/game-bugs S2-backup-2024.01.15-12.30.45.log
```

### Text Descriptions
```
/game-bugs --describe "Player takes damage twice per hit"
/game-bugs bug_description.txt
```

### Combined Inputs
```
/game-bugs 123 screenshot.png crash.log
```

## Workflow

### Phase 1: Input Parsing
- Parse all input sources (GitHub, images, logs, text)
- Extract bug details, reproduction steps, error messages
- Merge into unified BugReport

### Phase 2: Classification
- Classify bug type: C++, Blueprint, Asset, Config
- Identify affected systems: Combat, AI, UI, Animation, etc.
- Calculate complexity score
- Determine if auto-fixable (C++ only)

### Phase 3: Codebase Analysis
- Search codebase for relevant files
- Identify primary location
- Analyze related components
- Build dependency graph

### Phase 4: Root Cause Diagnosis
- Analyze evidence against codebase
- Identify root cause with confidence score
- Generate suggested fix approach

### Phase 5: Fix Implementation (C++ Only)
- Create feature branch: `fix/{issue}-{slug}`
- Route to specialized agent if needed:
  - `combat-engineer` for GAS/combo/damage bugs
  - `principal-gameplay-engineer` for StateTree bugs
  - `crash-investigator` for crashes
- Apply fix using `/bmad:bmgd:agents:game-dev`

### Phase 6: Build Verification
- Compile using `/dev-workflow:ue-cpp-build`
- Analyze and fix any build errors
- Re-verify compilation

### Phase 7: Code Review (3x Adversarial)
- Run `/bmad:bmgd:workflows:code-review`
- Auto-fix issues found
- Repeat up to 3 rounds

### Phase 8: Delivery
- Commit changes with proper message
- Push branch to remote
- Create pull request

## Model Configuration

| Task | Default Model | Complex Override |
|------|---------------|------------------|
| Classification | claude-sonnet-4-5 | - |
| Analysis | claude-sonnet-4-5 | - |
| Diagnosis | claude-sonnet-4-5 | claude-opus-4-5 |
| Fix Implementation | claude-sonnet-4-5 | claude-opus-4-5 |
| Code Review | claude-sonnet-4-5 | - |

**Complexity Threshold:** 0.8 (auto-upgrade to Opus for complex bugs)

### CLI Model Override
```bash
# Use Opus for everything
/game-bugs 123 --model opus

# Use Haiku for simple bugs
/game-bugs 123 --model haiku
```

## Options

| Flag | Description |
|------|-------------|
| `--model {sonnet\|opus\|haiku}` | Override model selection |
| `--dry-run` | Don't commit or create PR |
| `--skip-tests` | Skip test execution |
| `--verbose` | Enable verbose logging |
| `--resume {checkpoint}` | Resume from checkpoint |

## Output Modes

### C++ Bugs (Auto-Fixable)
- Creates branch
- Implements fix
- Runs code review
- Creates PR
- Returns PR URL

### Blueprint/Asset Bugs (Report-Only)
- Generates analysis report
- Identifies affected assets
- Provides manual fix instructions
- Saves to `claude-agents/reports/game-bugs/`

## Dynamic Path Resolution

```
{CWD} = Current Working Directory
{ProjectRoot} = H:\Jenkins\workspace\source\s2
{GameBugsDir} = agentic-systems/game-bugs
{ReportsDir} = claude-agents/reports/game-bugs
{CheckpointsDir} = {GameBugsDir}/checkpoints
```

## Integration with Other Skills

### Required Skills
- `/dev-workflow:ue-cpp-build` - Compile verification
- `/bmad:bmgd:agents:game-dev` - Fix implementation
- `/bmad:bmgd:workflows:code-review` - Adversarial review

### Specialized Routing
- `/combat-engineer` - Combat system bugs
- `/principal-gameplay-engineer` - Gameplay system bugs
- `/crash-investigator` - Crash analysis

## Coding Rules (Auto-Checked)

Enforces project coding standards from CODING_PITFALLS.md:

- No `LoadSynchronous()` → `RequestAsyncLoad()`
- No `new FGameplayEffectSpec()` → `MakeOutgoingSpec()`
- Cache `GetComponentByClass()` in `PostInitializeComponents()`
- No `NativeTick` in widgets → use timers
- Use `nullptr` not `NULL`
- Max 2-3 nested ifs → extract to helper functions

## Example Sessions

### Simple Bug Fix
```
User: /game-bugs 456

Agent:
1. Fetching GitHub issue #456...
2. Bug: "Combat damage applied twice per hit"
3. Type: C++ | Systems: Combat, GAS
4. Searching codebase...
5. Found: Source/S2/Private/Combat/SipherDamageExecution.cpp:234
6. Root Cause: Missing guard for duplicate damage application
7. Creating branch: fix/456-double-damage
8. Implementing fix...
9. Building... SUCCESS
10. Code review round 1... 0 issues
11. Committing...
12. Creating PR...

PR Created: https://github.com/sipherxyz/s2/pull/789
```

### Multi-Input Bug
```
User: /game-bugs 789 crash_screenshot.png S2.log

Agent:
1. Parsing inputs...
   - GitHub #789: "Game crashes during boss transition"
   - Screenshot: Shows crash dialog with access violation
   - Log: Stack trace pointing to SipherBossStateTree.cpp:156
2. Type: C++ | Systems: AI, StateTree
3. Routing to: crash-investigator
4. Root Cause: Null pointer access in state transition
5. Fix: Add null check before state access
...
```

### Blueprint Bug (Report-Only)
```
User: /game-bugs --describe "Boss animation not playing"

Agent:
1. Analyzing description...
2. Type: Blueprint | Systems: Animation
3. NOT AUTO-FIXABLE (Blueprint change required)
4. Generating report...

Report saved: claude-agents/reports/game-bugs/boss-animation-report.md

Recommended manual fixes:
- Check Animation Blueprint event graph
- Verify montage slot configuration
- Check State Tree animation triggers
```

## Checkpoint Recovery

If the workflow fails mid-execution:

```bash
# Resume from last checkpoint
/game-bugs --resume chk_20240115_123045
```

Checkpoints saved after each phase with full state.

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `GitHub fetch failed` | Invalid issue or auth | Check GITHUB_TOKEN |
| `Image analysis failed` | Unsupported format | Use PNG/JPG |
| `Build failed` | Code error | Auto-retry with fix |
| `No root cause found` | Insufficient info | Request more evidence |

### Recovery
- All state saved to checkpoints
- Resume from any phase
- Manual override available

## Success Criteria

- Bug properly classified
- Root cause identified with >70% confidence
- Fix compiles successfully
- Code review passes (3 rounds)
- PR created (for C++ bugs)
- Report generated (for non-C++ bugs)

## Notes

- Does NOT auto-run builds after initial fixes (per CLAUDE.md)
- Requires explicit user confirmation for destructive git operations
- All paths resolved dynamically
- Model selection can be customized per-task in config.yaml

## Legacy Metadata

```yaml
skill: ue-game-bugs
invoke: /qa-testing:ue-game-bugs
type: development
category: bug-fixing
scope: project-root
```
