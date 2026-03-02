---
name: feature-brainstorm
description: This skill should be used when exploring new feature ideas, clarifying requirements, or when facing ambiguous requests with multiple valid interpretations. Triggers on "brainstorm", "explore approaches", "what should we build", ambiguous feature requests, or when starting a new feature discussion.
---

# Feature Brainstorming Skill

Structured ideation process for exploring and clarifying feature requirements before planning.

## When to Use

- Starting a new feature discussion
- Requirements are unclear or ambiguous
- Multiple approaches seem valid
- Need to align on goals before implementation

## When to Skip

- Requirements are explicit and detailed
- User knows exactly what they want
- Task is a simple bug fix

## Process

### Phase 1: Understand the Idea

Ask questions **one at a time** to understand intent:

| Topic | Example Questions |
|-------|-------------------|
| **Purpose** | What problem does this solve? |
| **Users** | Who benefits from this feature? |
| **Success** | How will we know it's working? |
| **Constraints** | Any technical/design limitations? |

Prefer multiple choice questions when natural options exist.

### Phase 2: Explore Approaches

Present 2-3 concrete approaches:

```markdown
### Approach A: {Name}

{Description}

**UE5 Pattern:** {GAS/Component/Subsystem/etc.}

**Pros:**
- {Benefit 1}

**Cons:**
- {Drawback 1}
```

### Phase 3: Capture Design Brief

Save to `claude-agents/ugm/ideation/{feature}-brief.md`:

```markdown
---
date: YYYY-MM-DD
feature: {slug}
status: ideated
---

# Feature: {Title}

## Summary
{Description}

## Chosen Approach
{Selected approach with rationale}

## Key Decisions
- {Decision}: {Rationale}

## Success Criteria
- [ ] {Criterion 1}
```

## YAGNI Principles

During brainstorming:
- Don't design for hypothetical future needs
- Choose simplest viable approach
- Defer decisions that don't need to be made now

## Output

Design brief saved to `claude-agents/ugm/ideation/`

Next: `/ugm:plan` for implementation details

## Legacy Metadata

```yaml
skill: feature-brainstorm
invoke: /ugm:feature-brainstorm
```
