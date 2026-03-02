---
name: ue-gameplay-tag-manager
description: Batch manage gameplay tags including adding, renaming, deprecating, and finding references across the codebase. Use when reorganizing tag hierarchy, renaming tags safely, or auditing tag usage. Triggers on "gameplay tag", "rename tag", "tag management", "tag refactor", "tag hierarchy", "find tag references".
---

# UE Gameplay Tag Manager

Batch operations for gameplay tag management with safe refactoring support.

## Quick Start

1. Choose operation (add, rename, deprecate, audit)
2. Specify tag(s) to operate on
3. Execute with reference updates

## Operations

### 1. Add New Tags

**Process:**
1. Determine tag hierarchy placement
2. Add to appropriate .ini file
3. Validate no conflicts

**Tag File Locations:**
```
Config/Tags/
├── SipherAbilitiesTags.ini       # Ability-related tags
├── SipherCharacterStateTags.ini  # Character state tags
├── SipherCombatTags.ini          # Combat system tags
├── SipherGameplayCueTags.ini     # Gameplay cue tags
└── DefaultGameplayTags.ini       # General tags
```

**Format:**
```ini
[/Script/GameplayTags.GameplayTagsList]
+GameplayTagList=(Tag="Ability.Combat.HeavyAttack",DevComment="Heavy melee attack ability")
+GameplayTagList=(Tag="State.Character.Attacking",DevComment="Character is in attack animation")
```

### 2. Rename Tags

**Safe Rename Process:**

```markdown
## Tag Rename: {OldTag} → {NewTag}

### Step 1: Find All References
Search patterns:
- C++: `FGameplayTag::RequestGameplayTag(FName("{OldTag}")`
- C++: `FName("{OldTag}")`
- Blueprints: Tag property values
- DataTables: Tag columns
- Config: .ini files

### Step 2: Create Redirect
Add to DefaultGameplayTags.ini:
```ini
+GameplayTagRedirects=(OldTagName="{OldTag}",NewTagName="{NewTag}")
```

### Step 3: Update References
{List of files to update}

### Step 4: Verify
- Compile C++
- Load all BPs with tag references
- Test tag queries
```

**Search Commands:**
```bash
# Find C++ references
grep -r "OldTagName" --include="*.cpp" --include="*.h"

# Find config references
grep -r "OldTagName" --include="*.ini"
```

### 3. Deprecate Tags

**Deprecation Process:**

```markdown
## Deprecate Tag: {TagName}

### Step 1: Add Redirect to Replacement
```ini
+GameplayTagRedirects=(OldTagName="{TagName}",NewTagName="{ReplacementTag}")
```

### Step 2: Mark as Deprecated (Optional)
```ini
; DEPRECATED - Use {ReplacementTag} instead
+GameplayTagList=(Tag="{TagName}",DevComment="DEPRECATED: Use {ReplacementTag}")
```

### Step 3: Update Code References
{Files requiring update}

### Step 4: Schedule Removal
- Add TODO with removal date
- Track in tech debt
```

### 4. Audit Tag Usage

**Audit Report:**

```markdown
## Gameplay Tag Audit Report

### Tag Hierarchy Summary
| Root | Children | Depth | Usage Count |
|------|----------|-------|-------------|
| Ability | {N} | {N} | {N} |
| State | {N} | {N} | {N} |
| Effect | {N} | {N} | {N} |

### Unused Tags
Tags defined but never referenced:
| Tag | Defined In | Last Modified |
|-----|------------|---------------|
| {Tag} | {File} | {Date} |

### Orphan References
Tags referenced but not defined:
| Tag | Referenced In | Line |
|-----|---------------|------|
| {Tag} | {File} | {N} |

### Duplicate Definitions
Tags defined in multiple files:
| Tag | Files |
|-----|-------|
| {Tag} | {Files} |

### Naming Convention Violations
| Tag | Issue | Suggested |
|-----|-------|-----------|
| {Tag} | {Issue} | {Fix} |
```

## Tag Hierarchy Guidelines

### Sipher Tag Structure

```
Ability.
├── Combat.
│   ├── Light.{AbilityName}
│   ├── Heavy.{AbilityName}
│   └── Special.{AbilityName}
├── Movement.
│   ├── Dash
│   ├── Jump
│   └── Dodge
├── Cooldown.{AbilityName}
└── Blocked.By.{Reason}

State.
├── Character.
│   ├── Alive
│   ├── Dead
│   └── Stunned
├── Combat.
│   ├── Attacking
│   ├── Blocking
│   └── Parrying
├── Ability.{AbilityName}.Active
└── Effect.{EffectName}

Effect.
├── Damage.
│   ├── Physical
│   └── Elemental.{Type}
├── Buff.{BuffName}
├── Debuff.{DebuffName}
└── Status.{StatusName}

GameplayCue.
├── Character.
│   ├── Hit.{Type}
│   └── Death
├── Ability.{AbilityName}
└── Effect.{EffectName}
```

## Batch Operations

### Batch Add

```cpp
// Script to add multiple tags
TArray<FString> NewTags = {
    "Ability.Combat.NewAttack1",
    "Ability.Combat.NewAttack2",
    "State.Effect.NewStatus"
};

for (const FString& Tag : NewTags)
{
    // Add to appropriate ini file
    AddTagToConfig(Tag, GetTagCategory(Tag));
}
```

### Batch Rename

```markdown
## Batch Rename Operation

| Old Tag | New Tag | References |
|---------|---------|------------|
| {Old1} | {New1} | {N} files |
| {Old2} | {New2} | {N} files |

### Generated Redirects
```ini
+GameplayTagRedirects=(OldTagName="{Old1}",NewTagName="{New1}")
+GameplayTagRedirects=(OldTagName="{Old2}",NewTagName="{New2}")
```

### Files to Update
{Consolidated file list}
```

### Find References

```markdown
## Tag Reference Report: {TagName}

### C++ References
| File | Line | Context |
|------|------|---------|
| {File} | {N} | {Code snippet} |

### Blueprint References
| Asset | Property |
|-------|----------|
| {Asset} | {Property path} |

### Config References
| File | Line |
|------|------|
| {File} | {N} |

### DataTable References
| Table | Row | Column |
|-------|-----|--------|
| {Table} | {Row} | {Column} |

### Total: {N} references in {N} files
```

## Validation Rules

| Rule | Check | Severity |
|------|-------|----------|
| Unique | No duplicate definitions | Error |
| Hierarchy | Parent tag exists | Warning |
| Naming | Follows convention | Warning |
| Reference | All references valid | Error |
| Redirect | No circular redirects | Error |

## Output

### Tag Addition
- Updated .ini file with new tag
- DevComment for documentation

### Tag Rename
- Redirect entry in config
- List of files requiring update
- Validation of all references updated

### Tag Audit
- Full usage report
- Cleanup recommendations
- Health score
