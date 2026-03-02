---
name: implementation-plan
description: This skill should be used when creating detailed implementation plans with task breakdown, file manifests, and dependencies. Triggers on "plan implementation", "create plan", "break down tasks", or after ideation when ready to plan the HOW.
---

# Implementation Planning Skill

Create detailed, actionable implementation plans from ideation briefs or feature requirements.

## When to Use

- After ideation phase completes
- Requirements are clear and approach chosen
- Ready to break down work into tasks

## Prerequisites

Either:
- Ideation brief exists in `claude-agents/ugm/ideation/`
- Clear, detailed requirements provided by user

## Process

### Phase 1: Gather Context

Check for ideation output:
```bash
ls -la claude-agents/ugm/ideation/*.md | tail -5
```

Research existing patterns:
```bash
rg -l "{feature_keywords}" --type cpp --type h | head -20
```

### Phase 2: Architecture Decision

For significant changes, document ADR:

```markdown
## Architecture Decision

**Decision:** {One sentence}
**Context:** {Why needed}
**Consequences:** {Trade-offs accepted}
```

### Phase 3: Task Breakdown

Break into small, reviewable tasks:

```markdown
### Task 1: {Title}

**Files:**
- `{Path/File.h}` - [New/Modify]
- `{Path/File.cpp}` - [New/Modify]

**Changes:**
1. {Specific change}

**Dependencies:** None | Task N

**Verification:**
- [ ] Compiles without warnings
- [ ] {Specific verification}

**Complexity:** S/M/L
```

### Phase 4: File Manifest

| File | Change Type | Tasks |
|------|-------------|-------|
| {Path} | New/Modify/Delete | 1, 2 |

### Phase 5: Test Strategy

```markdown
## Test Strategy

### Automated
- [ ] Unit test for {core logic}

### Manual
- [ ] PIE verification of {behavior}
```

### Phase 6: Save Plan

Save to `claude-agents/ugm/plans/{feature}-plan.md`

## Task Ordering Rules

1. Headers before implementation
2. Base classes before derived
3. Data structures before logic
4. Core functionality before edge cases
5. Each task independently committable

## Output

Implementation plan saved to `claude-agents/ugm/plans/`

Next: `/ugm:implement` to execute the plan

## Legacy Metadata

```yaml
skill: implementation-plan
invoke: /ugm:implementation-plan
```
