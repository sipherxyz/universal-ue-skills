---
name: solution-capture
description: This skill should be used when documenting reusable patterns that worked well during implementation. Triggers on "capture solution", "document pattern", "save this approach", or after completing a feature that established a useful pattern.
---

# Solution Capture Skill

Document reusable patterns and approaches for future development.

## When to Use

- After completing a feature successfully
- When discovering a pattern worth reusing
- When solving a non-obvious problem
- When establishing a new project standard

## Solution Document Structure

Save to `claude-agents/solutions/{pattern}-solution.md`:

```markdown
---
date: YYYY-MM-DD
pattern: {pattern-slug}
domain: {GAS|Combat|AI|Animation|UI|Editor|...}
source-feature: {feature-slug}
---

# Solution: {Pattern Title}

## Context

When building {feature}, we needed to {problem}.

## Solution

{Description of the approach that worked}

## Implementation

### Key Files
- `{Path/File.h}` - {Purpose}
- `{Path/File.cpp}` - {Purpose}

### Code Pattern

```cpp
// Core implementation pattern
{Code snippet showing the key approach}
```

## When to Use

- {Situation where this pattern applies}
- {Another applicable situation}

## When NOT to Use

- {Situation where this is the wrong pattern}
- {Anti-pattern to avoid}

## Integration Notes

- {How to integrate with existing systems}
- {Dependencies to be aware of}

## Performance Considerations

- {Performance characteristics}
- {Scalability notes}

## References

- Source feature: {feature-slug}
- Related: {links to related docs}
```

## Good Solution Candidates

| Type | Example |
|------|---------|
| GAS Pattern | Ability with i-frames |
| Component Design | Cached component lookup pattern |
| Integration | Cross-system communication |
| Optimization | Batching approach |
| Workaround | Platform-specific fix |

## Not Good Candidates

- Feature-specific logic (not reusable)
- Standard UE patterns (already documented)
- One-off workarounds (use pitfall instead)

## Process

1. **Identify** - What pattern emerged from this work?
2. **Extract** - Generalize beyond specific feature
3. **Document** - Write clear, actionable guidance
4. **Index** - Add to `claude-agents/solutions/README.md`

## Integration

Solutions are referenced by:
- `/ugm:plan` - Checks for applicable patterns
- `/ugm:review` - Validates pattern compliance
- `/ugm:ideate` - Suggests proven approaches

## Legacy Metadata

```yaml
skill: solution-capture
invoke: /ugm:solution-capture
```
