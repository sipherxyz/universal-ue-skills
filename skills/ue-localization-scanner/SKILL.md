---
name: ue-localization-scanner
description: Scan codebase for hardcoded strings, validate FText usage, check string tables, and identify localization issues. Use when preparing for localization, auditing i18n compliance, or finding hardcoded user-facing text. Triggers on "localization", "hardcoded strings", "FText", "string table", "i18n", "translation", "localization scan".
---

# UE Localization Scanner

Scan for localization issues and hardcoded user-facing strings.

## Quick Start

1. Specify scan scope (C++, Blueprints, or both)
2. Run localization analysis
3. Get violation report and fix guidance

## Scan Categories

### 1. C++ Code Scanning

| Pattern | Severity | Description |
|---------|----------|-------------|
| Literal in FText::FromString | Error | Hardcoded localizable text |
| Missing LOCTEXT | Warning | Text should use LOCTEXT |
| Print/Log with literals | Info | May need localization |
| UI Text literals | Error | User-facing must be FText |

### 2. Blueprint Scanning

| Pattern | Severity | Description |
|---------|----------|-------------|
| Text literal nodes | Warning | Should use string table |
| Print String | Info | Check if user-facing |
| Widget text properties | Error | Must be localizable |

### 3. String Table Validation

| Check | Severity | Description |
|---------|----------|-------------|
| Orphan entries | Warning | Unused string table entries |
| Missing entries | Error | Referenced but not defined |
| Duplicate keys | Error | Key conflicts |

## Scan Workflow

### Step 1: C++ Code Analysis

```markdown
## C++ Localization Scan

### Patterns Searched
```cpp
// VIOLATION: Hardcoded string in FText
FText::FromString("Attack failed")  // Should be LOCTEXT

// VIOLATION: Literal in Format
FText::Format(LOCTEXT(...), "hardcoded")  // Arg should be FText

// OK: Proper LOCTEXT usage
LOCTEXT("AttackFailed", "Attack failed")

// OK: String table reference
FText::FromStringTable(TEXT("ST_Combat"), TEXT("AttackFailed"))
```

### Violations Found
| File | Line | Pattern | Text |
|------|------|---------|------|
| CombatUI.cpp | 142 | FromString | "Health: {0}" |
| AbilitySystem.cpp | 89 | Literal | "Cannot activate" |
| DialogueManager.cpp | 256 | Format arg | "Player" |
```

### Step 2: Blueprint Analysis

```markdown
## Blueprint Localization Scan

### Widget Text Properties
| Widget | Property | Value | Status |
|--------|----------|-------|--------|
| WBP_MainMenu | Button_Start | "Start Game" | Error |
| WBP_HUD | Text_Health | Bound | OK |
| WBP_Inventory | Item_Name | Literal | Error |

### Print String Nodes
| Blueprint | Node | Text | User-Facing |
|-----------|------|------|-------------|
| BP_Player | PrintString | "Debug" | No (OK) |
| BP_Tutorial | PrintString | "Press X" | Yes (Error) |
```

### Step 3: String Table Audit

```markdown
## String Table Audit

### Tables Found
| Table | Entries | Used | Unused |
|-------|---------|------|--------|
| ST_UI | 245 | 230 | 15 |
| ST_Combat | 89 | 85 | 4 |
| ST_Dialogue | 1250 | 1250 | 0 |

### Missing References
| Reference | Location | Expected Table |
|-----------|----------|----------------|
| "HUD_Stamina" | WBP_HUD | ST_UI |
| "Combat_Parry" | CombatManager.cpp | ST_Combat |

### Orphan Entries
| Table | Key | Last Modified |
|-------|-----|---------------|
| ST_UI | "OldButton_Label" | 2024-01-15 |
| ST_UI | "Deprecated_Title" | 2023-11-20 |
```

## Common Violations

### 1. FText::FromString with Literal

```cpp
// WRONG
FText DisplayText = FText::FromString("Player Health");

// CORRECT - Using LOCTEXT
#define LOCTEXT_NAMESPACE "HUD"
FText DisplayText = LOCTEXT("PlayerHealth", "Player Health");
#undef LOCTEXT_NAMESPACE

// CORRECT - Using String Table
FText DisplayText = FText::FromStringTable(TEXT("ST_HUD"), TEXT("PlayerHealth"));
```

### 2. Format String Arguments

```cpp
// WRONG - Hardcoded argument
FText::Format(LOCTEXT("Damage", "{0} dealt {1} damage"), "Player", DamageAmount);

// CORRECT - FText arguments
FText::Format(LOCTEXT("Damage", "{0} dealt {1} damage"), CharacterName, DamageAmount);
```

### 3. Blueprint Text Literals

```
// WRONG
Text Block → Text: "Press X to interact"

// CORRECT
Text Block → Text: (Bound to String Table)
String Table: ST_Tutorial
Key: Interact_Prompt
```

## Search Patterns

### C++ Patterns

```regex
# Hardcoded FText
FText::FromString\s*\(\s*"[^"]+"\s*\)

# Missing LOCTEXT namespace
^(?!.*LOCTEXT_NAMESPACE).*LOCTEXT\s*\(

# Literal in Format
FText::Format\s*\([^)]*,\s*"[^"]+"\s*[,)]

# UI text without FText
->SetText\s*\(\s*"[^"]+"\s*\)
```

### Blueprint Patterns

```
# Text property with literal value
# (Requires asset parsing)

# Print String with user-facing text
# (Requires context analysis)
```

## Report Template

```markdown
# Localization Scan Report

## Executive Summary
- **Files Scanned**: {N}
- **Violations**: {N}
- **Critical (User-Facing)**: {N}
- **Estimated Fix Time**: {N} hours

## Violations by Category

### Critical - User-Facing Text
| Location | Line | Text | Suggested Key |
|----------|------|------|---------------|
| {File} | {N} | "{Text}" | {Key} |

### Warning - Potentially User-Facing
| Location | Line | Text | Context |
|----------|------|------|---------|
| {File} | {N} | "{Text}" | {Context} |

### Info - Review Needed
| Location | Line | Text |
|----------|------|------|
| {File} | {N} | "{Text}" |

## String Table Health

| Table | Status | Issues |
|-------|--------|--------|
| ST_UI | Warning | 15 orphan entries |
| ST_Combat | OK | None |
| ST_Dialogue | OK | None |

## Recommendations

1. **Immediate**: Fix {N} critical user-facing strings
2. **Short-term**: Clean up {N} orphan entries
3. **Long-term**: Establish localization review process

## Localization Checklist
- [ ] All user-facing text uses FText
- [ ] String tables are organized by domain
- [ ] No orphan entries in string tables
- [ ] Format strings use FText arguments
- [ ] BP widgets use bound text or string tables
```

## Best Practices

### String Table Organization

```
StringTables/
├── ST_UI.csv           # All UI text
├── ST_Combat.csv       # Combat messages
├── ST_Dialogue.csv     # NPC dialogue
├── ST_Tutorial.csv     # Tutorial prompts
├── ST_Items.csv        # Item names/descriptions
└── ST_Achievements.csv # Achievement text
```

### LOCTEXT Namespace Convention

```cpp
// File: CombatUI.cpp
#define LOCTEXT_NAMESPACE "CombatUI"

// All LOCTEXT in this file uses "CombatUI" namespace
FText DamageText = LOCTEXT("DamageDealt", "Damage Dealt");

#undef LOCTEXT_NAMESPACE
```
