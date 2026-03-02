---
name: combat-ai-review
description: Multi-agent Combat AI review with parallel analysis and consensus debate (supports Behavior Trees and State Trees)
---

# Combat AI Multi-Agent Review Skill

**Role:** Multi-Agent Review Coordinator
**Scope:** Combat AI dumps (`$env:TEMP/SipherAIBPTools/**/*BT*.md`, `$env:TEMP/SipherAIBPTools/**/*ST*.md`, or `.blueprints/**/*BT*.md`, `.blueprints/**/*ST*.md`) - **excluding** `*_vis.md` files
**Platform Focus:** PC, PS5, Xbox Series X, Next-gen consoles
**Performance Target:** 60 FPS with 50+ AI enemies

> This skill supports both **Behavior Trees (BT)** and **State Trees (ST)** for combat AI.

> **Important:** Only read `BT_{name}.md` or `ST_{name}.md` files for AI analysis. Do NOT read `_vis.md` files - those are Mermaid visualizations for designers, not structured data for machine parsing.

## Overview

This skill orchestrates a comprehensive Combat AI review using three specialized agents who independently analyze the BT/ST, then engage in a structured debate to reach consensus on prioritized issues.

## Workflow

### Phase 0: Locate or Generate Combat AI Markdown

Before parsing the Combat AI, ensure the markdown file exists for AI analysis.

**Step 0.1: Search for Existing Markdown**

Search for the Combat AI markdown file in the temp folder first, then `.blueprints/`:

```
Search Pattern (BT): $env:TEMP/SipherAIBPTools/**/BT_{name}.md
Search Pattern (ST): $env:TEMP/SipherAIBPTools/**/ST_{name}.md
Fallback Pattern: .blueprints/**/BT_{name}.md or .blueprints/**/ST_{name}.md
Example: $env:TEMP/SipherAIBPTools/S2/Core_Boss/s2_boss_gaolanying/BT_Boss_GaoLanYing_Phase2.md
```

**If found:** Proceed to Phase 1.

**If NOT found:** Continue to Step 0.2.

---

**Step 0.2: Verify Combat AI Asset Exists**

Check if the `.uasset` file exists in the Content folder:

```
Search Pattern (BT): Content/**/BT_{name}.uasset
Search Pattern (ST): Content/**/ST_{name}.uasset
Example: Content/S2/Core_Boss/s2_boss_gaolanying/BT_Boss_GaoLanYing_Phase2.uasset
```

**If NOT found:** Report error - Combat AI asset does not exist. Cannot proceed with review.

**If found:** Continue to Step 0.3.

---

**Step 0.3: Generate Combat AI Markdown**

Two cases based on Unreal Editor state:

#### Case 1: Editor NOT Running

Use the SipherAIBPTools commandlet to generate the markdown files.

**Find Engine Path:**
1. Read `S2.uproject` to get `EngineAssociation` GUID
2. Look up registry: `HKEY_CURRENT_USER\SOFTWARE\Epic Games\Unreal Engine\Builds`
3. Match GUID to find engine installation path

**Run Commandlet (Behavior Tree):**
```powershell
# Windows PowerShell command
$EnginePath = "F:/S2UE"  # From registry lookup
$ProjectPath = "D:/s2/S2.uproject"
$BTPath = "/Game/S2/Core_Boss/s2_boss_gaolanying/BT_Boss_GaoLanYing_Phase2"

# By default, outputs to $env:TEMP/SipherAIBPTools/ (outside repository)
& "$EnginePath/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" `
    $ProjectPath `
    -run=SipherAIBPTools `
    -bt="$BTPath" `
    -preservepath `
    -verbose
```

**Run Commandlet (State Tree):**
```powershell
# Windows PowerShell command
$EnginePath = "F:/S2UE"  # From registry lookup
$ProjectPath = "D:/s2/S2.uproject"
$STPath = "/Game/S2/Core_Ene/s2_ene_swordshield_01A_prototype/ST_ene_swordshield_combat"

# By default, outputs to $env:TEMP/SipherAIBPTools/ (outside repository)
& "$EnginePath/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" `
    $ProjectPath `
    -run=SipherAIBPTools `
    -st="$STPath" `
    -preservepath `
    -verbose
```

**Output Location:**
- Default: `$env:TEMP/SipherAIBPTools/{preserved-path}/{AssetName}.md` (outside repository)
- Use `-output=".blueprints"` to write to `.blueprints/` in the project directory

**Output Files Generated:**
- `BT_{name}.md` or `ST_{name}.md` - Raw structured data for AI analysis (**USE THIS FOR REVIEW**)
- `BT_{name}_vis.md` or `ST_{name}_vis.md` - Mermaid diagram visualization (for designers only, DO NOT use for AI review)

#### Case 2: Editor IS Running

When the S2.uproject is open in Unreal Editor, use one of these methods:

**Method A: Editor Toolbar Button**
1. Open the BehaviorTree or StateTree asset in the editor
2. Click the "Export to Markdown" button in the toolbar
3. Files are generated to `.blueprints/` with preserved path

**Method B: Console Command**
```
# In Unreal Editor console (` key)
SipherAIBPTools.ExportBT /Game/S2/Core_Boss/s2_boss_gaolanying/BT_Boss_GaoLanYing_Phase2
SipherAIBPTools.ExportST /Game/S2/Core_Ene/s2_ene_swordshield_01A_prototype/ST_ene_swordshield_combat
```

---

**Phase 0 Completion Checklist:**
- [ ] Combat AI markdown file located or generated at `$env:TEMP/SipherAIBPTools/.../BT_{name}.md` or `$env:TEMP/SipherAIBPTools/.../ST_{name}.md` (or `.blueprints/...` as fallback)
- [ ] Ready to proceed to Phase 1 (use only `.md` file, NOT `_vis.md`)

---

### Phase 1: Parse Combat AI Structure

Before dispatching to agents, extract and clean the tree representation:

**Input Parsing Checklist:**
1. Extract asset path and blackboard/schema reference
2. Parse blackboard keys table (name, type, sync status)
3. Extract tree structure (nodes, decorators, tasks, selectors, sequences, states)
4. Identify all asset dependencies (abilities, montages, EQS queries)
5. Note any services attached to nodes

**Cleaned Structure Output:**
```markdown
## Parsed Combat AI Summary

**Asset:** [Asset Name]
**Type:** [Behavior Tree / State Tree]
**Blackboard/Schema:** [Reference]

### Key Metrics
- Total Nodes: X
- Selector Count: X (parallel decision points)
- Sequence Count: X (linear execution chains)
- State Count: X (for State Trees)
- Task Count: X
- Decorator/Condition Count: X
- Max Tree Depth: X

### Blackboard/Parameter Usage
| Key | Type | Used By Nodes | Potential Issues |
|-----|------|---------------|------------------|
| [Key] | [Type] | [Node List] | [Unused/Orphaned/etc] |

### Tree Hierarchy (Simplified)
[Cleaned ASCII tree showing major decision points]

### Critical Paths
1. Combat Path: [Description]
2. Wandering Path: [Description]
3. Special Ability Path: [Description]
```

---

### Phase 2: Parallel Agent Analysis

Spawn three agents simultaneously for independent review:

#### Agent 1: Combat Engineer (@combat-engineer-agent)

**Focus Areas:**
- GAS ability integration (BTT_ActivateAbility nodes, State Tree tasks)
- Performance concerns (nested selectors, expensive decorators/conditions)
- Memory safety (ability activation patterns)
- Scalability with 50+ AI instances
- Component lookup patterns in custom tasks
- Async loading compliance

**Review Template:**
```markdown
## Combat Engineer Analysis

### Performance Assessment
Critical | High | Medium | Low

### GAS Integration Review
- [ ] Ability activation uses proper ASC patterns
- [ ] No synchronous asset loading in tasks
- [ ] GameplayTags used consistently
- [ ] Ability data queue pattern followed (if applicable)

### Scalability Concerns
[List concerns for 50+ AI scenario]

### Top 5 Technical Concerns
1. [Issue with severity and location]
2. ...
```

#### Agent 2: Combat Designer (@combat-designer-agent)

**Focus Areas:**
- Attack pattern readability and fairness
- Timing windows and player reaction time
- Range-based behavior transitions
- Combo flow and variety
- Threat communication (telegraphs)
- Difficulty tuning opportunities

**Review Template:**
```markdown
## Combat Designer Analysis

### Player Experience Assessment
Feel Score: [1-10]
Threat Clarity: [1-10]
Fairness Rating: [1-10]

### Attack Pattern Analysis
- Close Range Attacks: [List with timing analysis]
- Mid Range Attacks: [List with gap-close patterns]
- Long Range Attacks: [List with approach strategies]

### Readability Issues
[Attack telegraphs, timing windows, player reaction feasibility]

### Balance Concerns
[Damage windows, recovery frames, cooldown usage]

### Top 5 Design Concerns
1. [Issue with player impact]
2. ...
```

#### Agent 3: QA Manager (@qa-manager-agent)

**Focus Areas:**
- Edge case handling (null targets, invalid states)
- State transition completeness
- Blackboard key initialization
- Error recovery paths
- Test scenario identification
- Regression risk assessment

**Review Template:**
```markdown
## QA Manager Analysis

### Test Coverage Assessment
Testability Score: [1-10]
Bug Risk: [Low/Medium/High/Critical]

### State Machine Analysis
- [ ] All states have exit conditions
- [ ] No infinite loops possible
- [ ] Failure states handled gracefully
- [ ] Blackboard keys properly initialized

### Edge Cases Identified
| Scenario | Expected Behavior | Potential Bug |
|----------|------------------|---------------|
| [Case] | [Expected] | [Risk] |

### Test Scenarios Required
1. [Scenario description with steps]
2. ...

### Top 5 QA Concerns
1. [Issue with reproduction risk]
2. ...
```

---

### Phase 3: Debate Protocol

After collecting independent analyses, facilitate structured debate:

**Debate Format:**

```markdown
## Agent Debate Round

### Presentation Phase
Each agent presents their top 5 concerns in priority order.

### Response Matrix

| Issue | Combat Engineer | Combat Designer | QA Manager |
|-------|-----------------|-----------------|------------|
| [Issue 1] | AGREE/CHALLENGE/ADD | AGREE/CHALLENGE/ADD | AGREE/CHALLENGE/ADD |

### Challenge Details

#### Challenge 1: [Issue being challenged]
**Challenger:** [Agent Name]
**Original Claim:** [What was claimed]
**Challenge:** [Why they disagree]
**Resolution:** [Consensus reached OR "Flagged for Human Review"]

### Context Additions
[Additional context any agent added to another's findings]
```

**Debate Rules:**
1. Each agent presents their top 5 concerns
2. Other agents respond with: **AGREE**, **CHALLENGE**, or **ADD CONTEXT**
3. Challenges must include reasoning
4. If consensus not reached after one round, flag for human review
5. Context additions are incorporated into final report

---

### Phase 4: Consensus Report Synthesis

Generate final prioritized report:

```markdown
# Combat AI Review: [Asset Name]

| Field | Value |
|-------|-------|
| **Review Date** | YYYY-MM-DD HH:MM |
| **Reviewed By** | Combat Engineer, Combat Designer, QA Manager (Multi-Agent Consensus) |
| **Asset Path** | [Full path] |
| **Asset Type** | [Behavior Tree / State Tree] |
| **Blackboard/Schema** | [Reference name] |

## Executive Summary

| Severity | Count |
|----------|-------|
| Critical | X |
| High Priority | Y |
| Medium | Z |
| Low | W |

| Metric | Status |
|--------|--------|
| **Overall Combat AI Health** | 60% |
| **Combat Readiness** | 80% |
| **Testability** | 40% |
| **Console Cert Status** | PASS / FAIL (reason) |

> **Note on Effort Estimates:** All time estimates in this report are assumptions based on typical complexity. Actual effort may vary significantly.

---

## Combat Designer Feel Assessment

### Current State: [Excellent/Good/Functional/Needs Work/Poor]

**Player Experience Rating:** X/10

| Aspect | Score | Status |
|--------|-------|--------|
| Combat Feel | X/10 | [Status] |
| Threat Clarity | X/10 | [Status] |
| Fairness | X/10 | [Status] |
| Enemy Identity | X/10 | [Status] |

### What Works
- [Positive aspect 1]
- [Positive aspect 2]

### What Feels Wrong
- [Issue 1 - brief description]
- [Issue 2 - brief description]

---

## Consensus Findings

### Critical Issues (All Agents Agree)

#### Issue #1: [Title]
**Severity:** Critical
**Identified By:** [Agent(s)]
**Consensus Level:** Full Agreement

**Problem:**
[Description of the issue]

**Location in Tree:**
[Node path or reference]

**Impact:**
- Technical: [Performance/Memory/Stability]
- Design: [Player experience/Balance]
- QA: [Test coverage/Bug risk]

**Recommended Fix:**
[Specific action to take]

---

### High Priority Issues

[Continue with high priority items...]

---

### Medium Priority Issues

[Continue with medium priority items...]

---

## Action Items by Owner

### For AI Engineers
1. [ ] [Action item] - [Priority]
2. ...

### For Combat Designers
1. [ ] [Action item] - [Priority]
2. ...

### For QA Team
1. [ ] [Action item] - [Priority]
2. ...

---

## Test Plan

### Automated Tests Required
| Test Type | Description | Coverage |
|-----------|-------------|----------|
| Unit | [Description] | [Nodes covered] |
| Integration | [Description] | [Systems covered] |

### Manual Test Scenarios
1. **[Scenario Name]**
   - Setup: [How to set up the test]
   - Steps: [What to do]
   - Expected: [What should happen]
   - Covers: [Issues this validates]

---

**Report Generated:** [Timestamp]
**Next Review Due:** [Date based on severity]
**Save Location:** `claude-agents/reports/combat-ai-reviews/[asset-name]_review_[date].md`
```

---

## Example Invocation

**Example 1: Review Behavior Tree with existing markdown file**
```
/skill combat-ai-review

Please review the following Combat AI:
.blueprints/S2/Core_Ene/s2_eli_Dreadroot_01A_prototype/BT_EliteDreadroot_DualPunch.md

Focus areas:
- Combat balance for elite enemy encounter
- Performance at scale with multiple Dreadroots
- QA test coverage for phase transitions
```

**Example 2: Review State Tree**
```
/skill combat-ai-review

Please review this State Tree:
.blueprints/S2/Core_Ene/s2_ene_swordshield_01A_prototype/ST_ene_swordshield_combat.md

Focus areas:
- State transition logic
- Combat feel and fairness
- Performance at scale
```

**Example 3: Review by asset path (auto-generates markdown if needed)**
```
/skill combat-ai-review

Please review this Combat AI:
Content/S2/Core_Boss/s2_boss_gaolanying/BT_Boss_GaoLanYing_Phase2.uasset

Focus areas:
- Phase transition handling
- Clone spawning performance
- Combat feel and fairness
```

---

## Agent Spawning Instructions

When executing this skill, spawn agents using the Task tool:

```
0. Locate or generate the Combat AI markdown file (Phase 0):
   a. Search for existing .md in .blueprints/ folder
   b. If not found, check if .uasset exists in Content/
   c. If .uasset exists, generate markdown:
      - Editor NOT running: Run commandlet with -bt or -st parameter
      - Editor running: Use toolbar button, console command, or Python script
   d. Verify markdown file exists before proceeding

1. Parse the Combat AI file first (Phase 1)
2. Spawn all three agents in PARALLEL using a single message with multiple Task tool calls:
   - Task: combat-engineer analysis with parsed Combat AI context
   - Task: combat-designer analysis with parsed Combat AI context
   - Task: qa-manager analysis with parsed Combat AI context
3. Collect all three responses
4. Synthesize debate (Phase 3) based on their findings
5. Generate consensus report (Phase 4)
```

---

## Success Criteria

**Review Complete When:**
- Combat AI markdown file located or generated (Phase 0)
- Combat AI structure parsed and summarized (Phase 1)
- All three agents provided independent analysis (Phase 2)
- Debate round completed with responses captured (Phase 3)
- Unresolved issues flagged for human review
- Consensus report generated with prioritized issues (Phase 4)
- Action items assigned by role
- Test plan included
- Report saved to `claude-agents/reports/combat-ai-reviews/`

---

## Knowledge Base References

- `claude-agents/docs/combat-design/combat_philosophy.md` - Combat design standards (HIGHEST AUTHORITY)
- `claude-agents/docs/combat-design/enemy_archetypes.md` - Enemy tier complexity budgets
- `claude-agents/reports/combat-ai-reviews/` - Previous Combat AI reviews for pattern reference
- `CLAUDE.md` - Project standards and AI architecture context

---

## Performance Notes

- Parallel agent spawning reduces total review time by ~60%
- Each agent should complete analysis in under 2 minutes
- Debate synthesis adds ~1 minute
- Total skill execution: ~5-7 minutes for comprehensive review

## Legacy Metadata

```yaml
skill: combat-ai-review
invoke: /combat-systems:combat-ai-review
type: code-review
category: ai-behavior
scope: $env:TEMP/SipherAIBPTools/**/*BT*.md, $env:TEMP/SipherAIBPTools/**/*ST*.md, .blueprints/**/*BT*.md, .blueprints/**/*ST*.md, Content/**/BT_*.uasset, Content/**/ST_*.uasset
```
