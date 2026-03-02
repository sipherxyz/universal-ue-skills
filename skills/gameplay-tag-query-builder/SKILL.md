---
name: gameplay-tag-query-builder
description: Build GameplayTagQuery expressions from natural language. Dynamically searches project INI files and SharedGameplayTags native definitions to find matching tags.
---

# GameplayTagQuery Builder

**Purpose:** Convert natural language descriptions into accurate UE5 FGameplayTagQuery expressions by dynamically searching all available project tags.

## Tag Sources (Search at Runtime)

The skill MUST search these sources for available tags:

### 1. INI Configuration Files

```bash
# Main project tags
Config/DefaultGameplayTags.ini

# Organized tag files (ability, character state, combo, fulu, etc.)
Config/Tags/*.ini

# Plugin-specific tags (search recursively)
Plugins/**/Config/**/*GameplayTags*.ini
Plugins/**/Config/**/Tags/*.ini
```

**INI Tag Pattern:**
```ini
+GameplayTagList=(Tag="Sipher.Ability.Attack.Heavy",DevComment="...")
```

Extract: `Tag="([^"]+)"` -> `Sipher.Ability.Attack.Heavy`

### 2. SharedGameplayTags Native Definitions

```bash
Plugins/Frameworks/SharedGameplayTags/Source/SharedGameplayTags/Public/GeneratedTags/*.h
```

**Native Tag Pattern:**
```cpp
SHAREDGAMEPLAYTAGS_API UE_DECLARE_GAMEPLAY_TAG_EXTERN(Character_State_Action_Attacking);
```

Transform: `Character_State_Action_Attacking` -> `Sipher.Character.State.Action.Attacking`

**Namespace Prefixes:**
- `namespace Sipher` -> `Sipher.` prefix
- `namespace SIO` -> `SIO.` prefix
- Other namespaces -> Use namespace as prefix

## Execution Workflow

### Step 1: Collect Available Tags

1. **Read INI files:**
```bash
# Use Grep to find all GameplayTagList entries
grep -r "GameplayTagList.*Tag=" Config/ Config/Tags/ Plugins/*/Config/ --include="*.ini"
```

2. **Read Native headers:**
```bash
# Find all native tag declarations
grep -r "UE_DECLARE_GAMEPLAY_TAG_EXTERN" Plugins/Frameworks/SharedGameplayTags/Source/ --include="*.h"
```

3. **Parse and normalize tags** into a searchable list

### Step 2: Parse User Intent

Analyze the user's natural language query to determine:

| Intent Type | Keywords | Query Type |
|-------------|----------|------------|
| Inclusion | "has", "with", "contains", "is", "are" | AllTagsMatch / AnyTagsMatch |
| Exclusion | "without", "not", "exclude", "no", "isn't" | NoTagsMatch |
| Any/Or | "any of", "either", "or" | AnyTagsMatch |
| All/And | "all of", "both", "and" | AllTagsMatch |

### Step 3: Match Tags to User Description

**Semantic Matching Rules:**

| User Says | Search Pattern |
|-----------|---------------|
| "attacking" | `*Attack*`, `*Attacking*` |
| "parrying", "parry" | `*Parry*`, `*Parrying*` |
| "blocking", "block" | `*Block*`, `*Blocking*` |
| "dodging", "dodge" | `*Dodge*`, `*Dodging*` |
| "stunned", "stun" | `*Stun*` |
| "hit reaction", "stagger" | `*HitReact*`, `*Stagger*` |
| "immune", "immunity" | `*Immune*` |
| "casting", "spell" | `*Casting*`, `*Spell*` |
| "fulu", "talisman" | `*Fulu*` |
| "cooldown" | `*.Cooldown` |
| "sprinting", "running" | `*Sprint*`, `*Running*` |
| "jumping", "in air" | `*Jump*`, `*InAir*` |
| "grounded" | `*Grounded*` |
| "boss" | `*Boss*` |
| "AI state" | `AIScalable.States.*` |
| "combat" | `*Combat*` |
| "heavy attack" | `Attack.Heavy` |
| "light attack" | `Attack.Light` |
| "elemental X" | `*Elemental*X*` |

### Step 4: Build Query Expression

## CRITICAL OUTPUT FORMAT - READ CAREFULLY

**YOUR ENTIRE RESPONSE MUST BE EXACTLY ONE LINE. NOTHING ELSE.**

### Format:
```
TYPE: Tag1, Tag2 AND TYPE: Tag3, Tag4
```

### Valid TYPE values: `ALL`, `ANY`, `NONE`

### Examples of CORRECT output (your response should look EXACTLY like one of these):
```
NONE: Sipher.Character.State.Action.Attacking
ANY: Sipher.Character.State.Action.Parrying, Sipher.Character.State.Action.Dodging
ANY: Sipher.Character.State.Action.Parrying AND NONE: Sipher.Character.State.Action.Attacking
ALL: Sipher.Character.State.ParryWindow AND NONE: Sipher.Character.State.Action.Attacking
```

### FORBIDDEN - These will FAIL:
- Multiple lines
- Explanations or context text
- Markdown formatting (`**`, `` ` ``, code blocks)
- Nested structures like `ALL: [ANY: ...]`
- Bullet points or lists
- Any text before or after the query line

### If user asks "actor parrying or dodging but not attacking", output ONLY:
```
ANY: Sipher.Character.State.Action.Parrying, Sipher.Character.State.Action.Dodging AND NONE: Sipher.Character.State.Action.Attacking
```

**DO NOT EXPLAIN. DO NOT ADD CONTEXT. JUST OUTPUT THE SINGLE LINE.**

## Examples

### Example 1: Exclusion Query

**User:** "actor without attacking tags"

**Step 1:** Search for attack-related tags:
```
Sipher.Character.State.Action.Attacking
Sipher.Character.State.Action.Artifact.Attacking
Sipher.Ability.Attack.DodgeAttack
Sipher.Ability.Attack.Heavy
Sipher.Ability.Attack.Light
Sipher.Ability.Attack.Range
```

**Step 2:** Detect "without" = exclusion intent

**Output:**
```
NONE: Sipher.Character.State.Action.Attacking, Sipher.Ability.Attack.DodgeAttack, Sipher.Ability.Attack.Heavy, Sipher.Ability.Attack.Light, Sipher.Ability.Attack.Range
```

### Example 2: Inclusion Query

**User:** "actor that is parrying or blocking"

**Step 1:** Search for parry/block tags:
```
Sipher.Character.State.Action.Parrying
Sipher.Ability.Parry.Parrying
Sipher.Ability.Parry.Blocking
```

**Step 2:** Detect "or" = any match intent

**Output:**
```
ANY: Sipher.Character.State.Action.Parrying, Sipher.Ability.Parry.Parrying, Sipher.Ability.Parry.Blocking
```

### Example 3: Multiple Conditions

**User:** "enemy in combat state with stun immunity"

**Step 1:** Search for relevant tags:
```
Sipher.AIScalable.States.Combat
Sipher.HitReaction.Immune.Stun (if exists)
Sipher.Character.State.Action.HitReacting.Stun (negation candidate)
```

**Step 2:** Detect "with" = all match intent

**Output:**
```
ALL: Sipher.AIScalable.States.Combat, Sipher.HitReaction.Immune.All
```

### Example 4: State Check

**User:** "character currently dodging"

**Search & Output:**
```
ANY: Sipher.Character.State.Action.Dodging, Sipher.Ability.Dodge.JustDodged
```

### Example 5: Compound Query

**User:** "actor that has parry window but isn't attacking"

**Step 1:** Search for relevant tags:
```
Sipher.Character.State.ParryWindow
Sipher.Character.State.Action.Attacking
```

**Step 2:** Detect compound condition - must have parry AND must not have attacking

**Output:**
```
ALL: Sipher.Character.State.ParryWindow AND NONE: Sipher.Character.State.Action.Attacking
```

### Example 6: Complex Compound

**User:** "enemy doing heavy or light attack but not dodging"

**Output:**
```
ANY: Sipher.Ability.Attack.Heavy, Sipher.Ability.Attack.Light AND NONE: Sipher.Character.State.Action.Dodging
```

## Tag Hierarchy Awareness

When matching, prefer more specific tags over generic ones:

```
Sipher.Ability.Attack.Heavy       <- Specific (prefer)
Sipher.Ability.Attack             <- Generic
Sipher                            <- Too broad (avoid)
```

**Rules:**
1. Never select root tags (e.g., `Sipher`, `Locomotion`)
2. Prefer leaf tags or tags 2-3 levels deep
3. When ambiguous, ask user for clarification

## Output Rules

1. **Always search tags first** - Never guess or use hardcoded lists
2. **Verify tags exist** - Only output tags found in the search
3. **Use exact tag names** - Match case and dots exactly
4. **Limit to relevant tags** - Don't include tangentially related tags
5. **Prefer fewer, precise tags** over many vague ones

## Error Handling

**No matching tags found:**
```
No tags found matching "{user query}".
Available tag patterns in this area:
- {list 3-5 closest matches}

Please refine your query or choose from above.
```

**Ambiguous query:**
```
Multiple interpretations possible:
1. {interpretation 1} -> {tags}
2. {interpretation 2} -> {tags}

Which did you mean?
```

## Integration Notes

This skill is designed for the SipherClaudeCodeTool's GameplayTagQuery AI generator feature. The output format matches what the UE property customization expects.

## Legacy Metadata

```yaml
skill: gameplay-tag-query-builder
invoke: /editor-tools:gameplay-tag-query-builder
type: utility
category: editor-tools
scope: project-root
```
