---
name: huli-feature
description: |-
  BMGD-driven workflow for implementing UE5.7 features in Huli project. Orchestrates the full
  development lifecycle from PRD/TechDoc/GDD through to PR creation. Use when implementing new
  gameplay features, systems, or tools that require structured planning and development phases.

  Triggers: "implement feature", "new feature workflow", "BMGD workflow", "full dev pipeline",
  or when user provides a PRD/TechDoc/GDD document for implementation.
---

# Huli Feature Implementation Workflow

PRD-driven development using BMGD agents and workflows for UE5.7.1.

## Input

Accept one of:
- **Document path**: `claude-agents/s2/*.md` or similar
- **Inline description**: Feature requirements in chat

## Output Location

All artifacts go to `claude-agents/s2/`:
```
claude-agents/s2/
├── game-brief.md         (Phase 1)
├── gdd.md                (Phase 2)
├── architecture.md       (Phase 3)
├── sprint-status.yaml    (Phase 4)
├── stories/              (Phase 5)
│   ├── story-001.md
│   └── ...
└── implementation-artifacts/
```

## Workflow Phases

Check for existing artifacts before each phase. Skip if valid artifact exists.

### Phase 1: Preproduction
```
Skill: /bmad:bmgd:workflows:create-game-brief
Output: claude-agents/s2/game-brief.md
```
Skip if game-brief.md exists and matches current feature scope.

### Phase 2: Design
```
Skill: /bmad:bmgd:workflows:gdd
Input: game-brief.md
Output: claude-agents/s2/gdd.md
```

### Phase 3: Technical Architecture
```
Skill: /bmad:bmgd:workflows:game-architecture
Input: gdd.md
Output: claude-agents/s2/architecture.md
```

**CHECKPOINT**: Confirm architecture with user before proceeding.

### Phase 4: Sprint Planning
```
Skill: /bmad:bmgd:workflows:sprint-planning
Input: architecture.md, gdd.md
Output: claude-agents/s2/sprint-status.yaml
```

### Phase 5: Story Creation (Loop)
```
Skill: /bmad:bmgd:workflows:create-story
Output: claude-agents/s2/stories/story-NNN.md
```
Repeat until all stories from sprint-status.yaml are created.

**CHECKPOINT**: Review stories with user before development.

### Phase 6: Development (Loop per Story)
```
Skill: /bmad:bmgd:workflows:dev-story
Input: stories/story-NNN.md
Output: Source code in Plugins/
```
Execute each story in priority order from sprint-status.yaml.

### Phase 7: Build
```
Skill: /dev-workflow:ue-cpp-build
```
Compile and fix errors. Do NOT auto-run - wait for user to verify.

**CHECKPOINT**: Confirm build success before review.

### Phase 8: Code Review (3x Adversarial)
```
Skill: /bmad:bmgd:workflows:code-review
```
Run 3 times for thorough adversarial review. Each pass should find issues.

### Phase 9: Automated Tests
```
Skill: /bmad:bmgd:workflows:gametest-automate
```
Generate and run tests for implemented features.

### Phase 10: Delivery
```
git checkout -b feature/<short-slug>
git add <changed-files>
git commit -m "<conventional-commit>"
git push -u origin feature/<short-slug>
gh pr create --title "<feature>" --body "..."
```

## Phase Skip Rules

| Artifact | Skip Condition |
|----------|----------------|
| game-brief.md | Exists and covers feature scope |
| gdd.md | Exists and references current brief |
| architecture.md | Exists and matches gdd |
| sprint-status.yaml | Exists with valid stories |
| stories/*.md | Individual story exists |

When resuming, read sprint-status.yaml to determine current phase.

## Example Usage

```
User: Implement companion state tree refactor from PRD
Claude:
1. Check claude-agents/s2/ for existing artifacts
2. Resume from last completed phase
3. Execute remaining phases with checkpoints
```

## Error Handling

- Build failures: Fix and retry, don't skip
- Review findings: Address before proceeding
- Test failures: Fix implementation, re-run tests

## Legacy Metadata

```yaml
skill: huli-feature
invoke: /dev-workflow:huli-feature
```
