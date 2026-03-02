---
name: ue-anim-notify-patterns
description: Animation notify and montage tool patterns for UE5
---

# UE5 AnimNotify & Montage Tool Patterns

**Role:** Animation Tool Engineer
**Scope:** Creating/modifying FAnimNotifyEvent in editor tools
**Engine:** UE 5.5+

## Critical Pattern: FAnimNotifyEvent Creation

When programmatically creating `FAnimNotifyEvent` entries for montages, you MUST follow the engine's expected initialization pattern. Missing any step causes editor bugs (selection issues, visual glitches, notify state backgrounds not rendering).

### Required Steps

```cpp
#include "Animation/AnimTypes.h"  // For GetTriggerTimeOffsetForType()

FAnimNotifyEvent NewEvent;

// 1. CRITICAL: Unique GUID for selection handling
NewEvent.Guid = FGuid::NewGuid();

// 2. Set the notify object (choose ONE)
// For instant notifies:
NewEvent.Notify = NewObject<UAnimNotify>(Montage, NotifyClass, NAME_None, RF_Transactional);
// OR for notify states:
NewEvent.NotifyStateClass = NewObject<UAnimNotifyState>(Montage, NotifyStateClass, NAME_None, RF_Transactional);
NewEvent.SetDuration(Duration);

// 3. Link to montage timeline
NewEvent.Link(Montage, StartTime);
NewEvent.TriggerTimeOffset = GetTriggerTimeOffsetForType(Montage->CalculateOffsetForNotify(StartTime));
NewEvent.TrackIndex = TrackIndex;

// 4. FOR NOTIFY STATES ONLY: Link the end time
if (NewEvent.NotifyStateClass)
{
    float EndTime = StartTime + Duration;
    NewEvent.EndLink.Link(Montage, EndTime);
    NewEvent.EndTriggerTimeOffset = GetTriggerTimeOffsetForType(Montage->CalculateOffsetForNotify(EndTime));
}

// 5. Add to montage
Montage->Notifies.Add(NewEvent);

// 6. Refresh after all notifies added
Montage->RefreshCacheData();
```

### What Breaks Without Each Step

| Missing Step | Bug |
|--------------|-----|
| `Guid = FGuid::NewGuid()` | All notifies select together, positions jump when moving one |
| `EndLink.Link()` | NotifyState duration handle doesn't work, can't resize |
| `EndTriggerTimeOffset` | End time snapping broken |
| `NotifyStateClass` with base `UAnimNotifyState` | No background color renders (need concrete subclass) |

### NotifyState Visual Rendering

Base `UAnimNotifyState` has no visual representation. For editor-visible notify states, create a concrete subclass:

```cpp
UCLASS()
class UAnimNotifyState_MyCustom : public UAnimNotifyState
{
    GENERATED_BODY()
public:
    UAnimNotifyState_MyCustom()
    {
#if WITH_EDITORONLY_DATA
        NotifyColor = FColor(255, 216, 0, 255); // Yellow
#endif
    }

    virtual FLinearColor GetEditorColor() override
    {
        return FLinearColor(1.0f, 0.85f, 0.0f, 1.0f);
    }
};
```

### Engine Reference

See `Engine/Source/Editor/Persona/Private/SAnimNotifyPanel.cpp` lines 2510-2579 for the canonical implementation.

## Common Mistakes

1. **Not setting unique GUIDs** - Causes multi-selection bugs
2. **Using base UAnimNotifyState** - No background color in timeline
3. **Forgetting EndLink for states** - Duration handles don't work
4. **Missing RefreshCacheData()** - Notifies don't appear until save/reload
5. **Wrong object outer** - Use `Montage` as outer for notify objects

## Legacy Metadata

```yaml
skill: ue-anim-notify-patterns
invoke: /editor-tools:ue-anim-notify-patterns
```
