---
name: validation-rule-generator
description: Generate C++ validation rules from JSON definitions. Use when team updates ValidationRules.json or asks to add/modify validation rules.
---

# Validation Rule Generator

Generate or update C++ validation rule classes from JSON definitions.

## When to Use

- User edits `Plugins/EditorTools/SipherChecklist/Config/ValidationRules.json`
- User asks to add a new validation rule in natural language
- User asks to modify existing validation rule behavior

## Workflow

### 1. Read Current JSON Rules

```
Read: Plugins/EditorTools/SipherChecklist/Config/ValidationRules.json
```

### 2. For Natural Language Requests

If user describes a rule in natural language:

1. Parse intent into JSON rule structure
2. Add to ValidationRules.json
3. Generate corresponding C++ code

**Example user request:**
> "Add a rule that checks all montages have at least one sound notify"

**Generated JSON:**
```json
{
  "id": "sound_notify_required",
  "name": "Sound Notify Required",
  "description": "All combat montages should have audio feedback",
  "category": "audio",
  "severity": "warning",
  "target": "montage",
  "conditions": {
    "montage_pattern": "AMT_*",
    "check": "has_notify",
    "notify_class_contains": ["Sound", "Audio", "PlaySound"],
    "minimum_count": 1
  },
  "error_template": "{count}/{total} montages missing sound notify: {list}"
}
```

### 3. Generate C++ Validation Rule

For each rule in JSON, generate a `UValidationRule_{RuleId}` class.

**Output files:**
- `Public/ValidationRules/ValidationRule_{Category}.h`
- `Private/ValidationRules/ValidationRule_{Category}.cpp`

**C++ Template:**

```cpp
// Header
UCLASS(DisplayName = "{name}")
class SIPHERCHECKLIST_API UValidationRule_{PascalId} : public USipherChecklistValidationRule
{
    GENERATED_BODY()

public:
    // Configurable thresholds from JSON
    UPROPERTY(EditDefaultsOnly, Category = "Thresholds")
    float {threshold_name} = {default_value};

    virtual FSipherAutoValidationResult Validate_Implementation(const FString& EnemyContentPath) const override;
    virtual FString GetRuleName_Implementation() const override { return TEXT("{name}"); }
};
```

```cpp
// Implementation
FSipherAutoValidationResult UValidationRule_{PascalId}::Validate_Implementation(const FString& EnemyContentPath) const
{
    TArray<UAnimMontage*> Montages;
    SipherCombatMontageValidation::GetCombatMontagesForEnemy(EnemyContentPath, Montages);

    if (Montages.Num() == 0)
    {
        return FSipherAutoValidationResult::Pass();
    }

    TArray<FString> FailedMontages;

    for (const UAnimMontage* Montage : Montages)
    {
        // Check condition based on JSON "check" type
        bool bPassed = false;

        // Generated check logic based on conditions...
        for (const FAnimNotifyEvent& NotifyEvent : Montage->Notifies)
        {
            FString ClassName;
            if (NotifyEvent.NotifyStateClass)
            {
                ClassName = NotifyEvent.NotifyStateClass->GetName();
            }
            else if (NotifyEvent.Notify)
            {
                ClassName = NotifyEvent.Notify->GetClass()->GetName();
            }

            // Check against notify_class_contains
            for (const FString& Pattern : {notify_patterns})
            {
                if (ClassName.Contains(Pattern))
                {
                    bPassed = true;
                    break;
                }
            }
            if (bPassed) break;
        }

        if (!bPassed)
        {
            FailedMontages.Add(Montage->GetName());
        }
    }

    if (FailedMontages.Num() > 0)
    {
        // Format error using error_template
        FString ErrorMsg = FString::Printf(TEXT("{error_template_formatted}"),
            FailedMontages.Num(), Montages.Num(),
            *FString::Join(FailedMontages, TEXT(", ")));
        return FSipherAutoValidationResult::Fail(ErrorMsg);
    }

    return FSipherAutoValidationResult::Pass();
}
```

### 4. Update SSipherCombatAuditPanel

After generating new rules, update `ValidateEnemy()` in SSipherCombatAuditPanel.cpp to include the new rule.

### 5. Compile and Verify

Run `/dev-workflow:ue-cpp-build` to compile and verify no errors.

## JSON → C++ Mapping

| JSON Field | C++ Element |
|------------|-------------|
| `id` | Class suffix: `UValidationRule_{PascalCase(id)}` |
| `name` | `GetRuleName_Implementation()` return value |
| `description` | Class UCLASS DisplayName |
| `severity` | Affects `FSipherAutoValidationResult::Fail()` vs `::Warning()` |
| `conditions.notify_class_contains` | String array for Contains() checks |
| `conditions.minimum_count` | Threshold for pass/fail |
| `conditions.duration_*` | UPROPERTY threshold values |
| `error_template` | FString::Printf format string |

## Example: Adding a VFX Rule

**User:** "Add a rule that warns if attack montages don't have a hit VFX notify"

**Steps:**
1. Add to ValidationRules.json:
```json
{
  "id": "hit_vfx_required",
  "name": "Hit VFX Required",
  "description": "Attack montages should spawn VFX on hit for visual feedback",
  "category": "vfx",
  "severity": "warning",
  "target": "montage",
  "conditions": {
    "prerequisite": "has_hitbox_notify",
    "check": "has_notify",
    "notify_class_contains": ["VFX", "Niagara", "Effect", "Particle"],
    "minimum_count": 1
  },
  "error_template": "{count} attack montages without hit VFX: {list}"
}
```

2. Generate C++ class `UValidationRule_HitVfxRequired`

3. Add to ValidationRule_CombatMontage.h/cpp

4. Update SSipherCombatAuditPanel::ValidateEnemy() to run the new rule

5. Compile

## Keeping Rules in Sync

The JSON is the **source of truth**. When regenerating:
- Read existing C++ to preserve custom logic
- Only regenerate the auto-generated portions
- Add `// AUTO-GENERATED - DO NOT EDIT` markers for generated sections
