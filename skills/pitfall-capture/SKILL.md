---
name: pitfall-capture
description: This skill should be used when documenting problems encountered and how to avoid them in the future. Triggers on "capture pitfall", "document mistake", "save this warning", or after encountering a significant issue during development.
---

# Pitfall Capture Skill

Document problems encountered to prevent future occurrences.

## When to Use

- After encountering a non-obvious bug
- When review findings reveal common mistakes
- When discovering a subtle API gotcha
- When hitting a certification blocker

## Pitfall Document Structure

Save to `claude-agents/pitfalls/{issue}-pitfall.md`:

```markdown
---
date: YYYY-MM-DD
pitfall: {pitfall-slug}
domain: {GAS|Combat|AI|Animation|Memory|Platform|...}
severity: {Critical|High|Medium}
source-feature: {feature-slug}
---

# Pitfall: {Title}

## Problem

{What went wrong}

## Symptoms

- {Observable symptom 1}
- {Observable symptom 2}
- {How this manifests at runtime}

## Root Cause

{Technical explanation of why this happens}

## Wrong Approach

```cpp
// What NOT to do
{Bad code example with explanation}
```

## Correct Approach

```cpp
// What to do instead
{Good code example}
```

## Detection

How to catch this in the future:

- {Review checklist item to add}
- {Static analysis rule if applicable}
- {Test case to write}

## Related Issues

- {Link to ticket if applicable}
- {Link to related pitfalls}
```

## Good Pitfall Candidates

| Type | Example |
|------|---------|
| Memory | Raw `new` for GE causing leak |
| Certification | LoadSynchronous blocking |
| Runtime | Uncached component lookup |
| Subtle Bug | TPair without template params |
| Platform | Console-specific issue |

## Not Good Candidates

- Typos (too trivial)
- Personal preferences (not universal)
- Already in CODING_PITFALLS.md (duplicate)

## Process

1. **Document** - Capture while fresh
2. **Generalize** - Beyond specific instance
3. **Add Detection** - How to prevent recurrence
4. **Update Standards** - Add to CODING_PITFALLS.md if significant

## Update CODING_PITFALLS.md

For significant pitfalls, add to project standards:

```markdown
## {Domain}: {Pitfall Title}

**Problem:** {Brief description}

**Wrong:**
```cpp
{Bad code}
```

**Correct:**
```cpp
{Good code}
```

**Why:** {Explanation}
```

## Integration

Pitfalls are referenced by:
- `/ugm:review` - Check for known pitfalls
- `/ugm:implement` - Avoid documented mistakes
- ue-code-reviewer - Add to review checklist

## Legacy Metadata

```yaml
skill: pitfall-capture
invoke: /ugm:pitfall-capture
```
