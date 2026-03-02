---
name: debug-cvar-prompt
description: Proactively prompt to create runtime-toggleable console variables when implementing debug visualization or draw debug features. Triggers on requests containing "debug", "draw debug", "visualize", "show debug", "debug draw", or any request to add debug/diagnostic rendering that could benefit from runtime toggling.
---

# Debug Console Variable Prompt

**Role:** Proactive Debug Infrastructure Advisor
**Trigger:** Any request involving debug visualization, draw debug, or diagnostic rendering

## Objective

When a user requests debug functionality (drawing, visualization, logging), automatically suggest creating a console variable (CVar) to enable/disable it at runtime without recompilation.

## When This Skill Activates

Trigger on requests containing:
- "debug", "draw debug", "show debug"
- "visualize", "visualization"
- "diagnostic", "debug draw"
- "add debug [feature]", "draw [something] for debugging"
- Any request to render shapes, lines, text for debugging purposes

## Proactive Behavior

**BEFORE implementing any debug feature**, prompt the user:

```
I notice you're adding debug functionality. For runtime control, I recommend creating a console variable.

Would you like me to:
1. Add a CVar to `Source/S2/Public/Utils/S2ConsoleVariables.h` for this feature?
2. Implement the debug code gated behind the CVar?

This allows toggling via console command (e.g., `Sipher.Debug.{FeatureName} 1`) without recompiling.
```

## Console Variable Patterns

### Location
All project CVars live in: `Source/S2/Public/Utils/S2ConsoleVariables.h`

### Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Debug toggle | `Sipher.Debug.{Feature}` | `Sipher.Debug.GrappleHook` |
| Show debug | `Sipher.ShowDebug.{Feature}` | `Sipher.ShowDebug.Camera` |
| Cheat/bypass | `Sipher.{Action}` | `Sipher.ByPassSavePoint` |
| Player cheat | `PlayerCheat{Feature}` | `PlayerCheatInstantStun` |

### Code Templates

**Boolean toggle (most common):**
```cpp
inline static TAutoConsoleVariable<bool> CVarDebug{FeatureName}(
    TEXT("Sipher.Debug.{FeatureName}"),
    false,
    TEXT("Show debug {description}"),
    ECVF_Default);
```

**Integer option:**
```cpp
inline static TAutoConsoleVariable<int> CVar{Name}(
    TEXT("Sipher.{Category}.{Name}"),
    0,
    TEXT("Description:\n")
    TEXT("  '0': Option A\n")
    TEXT("  '1': Option B\n"),
    ECVF_Default);
```

**Float value:**
```cpp
inline static TAutoConsoleVariable<float> CVar{Name}(
    TEXT("Sipher.Debug.{Name}"),
    0.f,
    TEXT("Set {description} (0 = disabled)"),
    ECVF_Default);
```

### Usage in Code

**Reading CVar value:**
```cpp
#include "Utils/S2ConsoleVariables.h"

void USomeComponent::DrawDebug()
{
    if (!CVarDebugMyFeature.GetValueOnGameThread())
    {
        return;
    }

    // Debug drawing code here
    DrawDebugSphere(GetWorld(), Location, 50.f, 12, FColor::Green);
}
```

**Thread-safe reading (if accessed from multiple threads):**
```cpp
if (!CVarDebugMyFeature.GetValueOnAnyThread())
{
    return;
}
```

## Existing CVars Reference

Current debug CVars in the project (for consistency):

| CVar | Console Command | Purpose |
|------|-----------------|---------|
| `CVarShowDebugCamera` | `Sipher.ShowDebug.Camera` | Camera debug |
| `CVarShowDebugDamageShape` | `ShowDebug.DamageShape` | Damage hitbox visualization |
| `CVarDebugParryEnable` | `Sipher.DebugParry.Enable` | Parry system debug |
| `CVarDebugLockOn` | `Sipher.Debug.LockOn` | Lock-on targeting debug |
| `CVarDebugGrappleHook` | `Sipher.Debug.GrappleHook` | Grapple hook debug |
| `CVarDebugRetribution` | `Sipher.DebugRetribution` | Retribution system debug |
| `CVarShowDebugProjectile` | `Sipher.Debug.Projectile` | Projectile debug |
| `CVarDebugInteractionLadder` | `Sipher.Debug.Interaction.Ladder` | Ladder interaction debug |

## Workflow

1. **User requests debug feature** → Skill activates
2. **Prompt user** → Ask if they want a CVar for runtime control
3. **If yes:**
   - Generate CVar name following conventions
   - Add CVar to `S2ConsoleVariables.h`
   - Implement debug code gated behind CVar
4. **If no:**
   - Proceed with simple `#if UE_BUILD_DEBUG` or always-on debug code

## Implementation Checklist

When adding debug functionality:

- [ ] CVar added to `S2ConsoleVariables.h`
- [ ] CVar name follows `Sipher.Debug.{Feature}` pattern
- [ ] Default value is `false` (debug off by default)
- [ ] Description clearly explains what it shows
- [ ] Debug code checks `GetValueOnGameThread()` before executing
- [ ] Consider adding to existing debug categories if related

## Console Commands for Users

Remind users how to toggle in-game:
```
~ (tilde) to open console
Sipher.Debug.{Feature} 1    // Enable
Sipher.Debug.{Feature} 0    // Disable
```

## Notes

- CVars persist for the session but reset on editor restart
- Use `ECVF_Default` unless specific flags needed
- Boolean CVars are most common for debug toggles
- Float CVars useful for adjustable parameters (speeds, distances)
- Integer CVars good for multi-mode debug (0=off, 1=basic, 2=verbose)

## Legacy Metadata

```yaml
skill: debug-cvar-prompt
invoke: /dev-workflow:debug-cvar-prompt
type: proactive
category: cpp-development
scope: project-wide
```
