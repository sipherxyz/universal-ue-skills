---
name: ue-xr-compliance-checker
description: Check codebase for Microsoft Xbox XR (Xbox Requirements) compliance issues. Scans for account picker, cloud saves, achievements, Quick Resume, and Xbox certification requirements. Use before console submission or when preparing for Microsoft certification. Triggers on "XR", "Xbox certification", "Microsoft compliance", "Xbox cert", "Xbox requirements", "GDK compliance".
---

# UE XR Compliance Checker

Scan codebase for Microsoft Xbox Requirements (XR) violations.

## Quick Start

1. Run compliance scan on codebase
2. Review categorized violations
3. Get remediation guidance

## XR Categories

### 1. User & Account (Critical)

#### XR-015 - Account Picker

**Requirement**: Allow user to change account at any time.

**Check for**:
```cpp
// Must implement account picker access
void ShowAccountPicker()
{
    IOnlineSubsystem* OnlineSub = IOnlineSubsystem::Get(LIVE_SUBSYSTEM);
    IOnlineIdentityPtr Identity = OnlineSub->GetIdentityInterface();
    Identity->ShowAccountPickerUI(LocalUserNum, bShowUI, AccountPickerDelegate);
}

// Must be accessible from pause menu
// Must handle account change result
```

**Violations**:
- No account picker in pause menu
- Account change doesn't update game state
- Cached user data not refreshed

#### XR-045 - User Sign-Out

**Requirement**: Handle user sign-out during gameplay.

**Check for**:
```cpp
// Monitor sign-out
FCoreDelegates::OnUserLoginChangedEvent.AddUObject(this, &UMyClass::HandleLoginChange);

void HandleLoginChange(bool bLoggedIn, int32 UserId, int32 UserIndex)
{
    if (!bLoggedIn)
    {
        // Return to title or show account picker
        // Cannot continue with unsigned user
    }
}
```

### 2. Save Data (Critical)

#### XR-047 - Connected Storage

**Requirement**: Use Xbox Connected Storage for cloud saves.

**Check for**:
```cpp
// Must use GDK Connected Storage
#include "XGameSave.h"

// Save to Connected Storage
XGameSaveInitialize(XboxUser, ConfigId, &Context);
XGameSaveSubmitUpdate(Container, UpdateBlock, &AsyncOp);

// Handle sync conflicts
// Support roaming between devices
```

**Violations**:
- Local-only saves without cloud sync
- No conflict resolution for cloud saves
- Blocking save operations

#### XR-048 - Save Integrity

**Requirement**: Prevent save corruption, handle errors.

**Check for**:
- Atomic save operations
- Backup/recovery mechanism
- User notification on save failure

### 3. Quick Resume (Critical - Series X|S)

#### XR-062 - Quick Resume Support

**Requirement**: Properly support Quick Resume on Xbox Series X|S.

**Check for**:
```cpp
// Handle Quick Resume restoration
void OnQuickResumed()
{
    // Re-establish network connections
    // Refresh authentication tokens
    // Validate session state
    // Resume audio/video
    // Update time-sensitive state (timers, cooldowns)
}

// Register for suspend/resume
FCoreDelegates::ApplicationWillDeactivateDelegate.AddUObject(...);
FCoreDelegates::ApplicationHasReactivatedDelegate.AddUObject(...);
```

**Violations**:
- Stale network connections after resume
- Expired auth tokens not refreshed
- Time-based game logic incorrect after long suspend

### 4. Achievements (High)

#### XR-057 - Achievement Unlock

**Requirement**: Achievements unlock correctly and sync to Xbox Live.

**Check for**:
```cpp
// Use Xbox Achievement API
IOnlineSubsystem* OnlineSub = IOnlineSubsystem::Get(LIVE_SUBSYSTEM);
IOnlineAchievementsPtr Achievements = OnlineSub->GetAchievementsInterface();

// Write achievement progress
FOnlineAchievementsWritePtr WriteObject = MakeShareable(new FOnlineAchievementsWrite());
WriteObject->SetFloatStat(AchievementId, Progress);
Achievements->WriteAchievements(LocalUserNum, WriteObject, Delegate);

// Handle unlock failure (queue for retry)
```

**Violations**:
- Achievement unlocks without network (must queue)
- Missing Gamerscore totals (must equal defined values)
- Progress not tracked correctly

### 5. Multiplayer (If Applicable)

#### XR-067 - Multiplayer Privileges

**Requirement**: Check multiplayer privileges before online play.

**Check for**:
```cpp
// Check privileges before online features
IOnlineSubsystem* OnlineSub = IOnlineSubsystem::Get(LIVE_SUBSYSTEM);
IOnlineIdentityPtr Identity = OnlineSub->GetIdentityInterface();

EUserPrivileges::Type Privilege = EUserPrivileges::CanPlayOnline;
Identity->GetUserPrivilege(LocalUserNum, Privilege, PrivilegeDelegate);

// Handle restricted users (child accounts, suspensions)
```

### 6. Input & Accessibility (Medium)

#### XR-022 - Controller Assignment

**Requirement**: Handle controller changes correctly.

**Check for**:
- Controller disconnect handling
- Controller reassignment
- Multiple controller support

#### XR-025 - Text-to-Speech

**Requirement**: Support Xbox Narrator if game has text.

**Check for**:
```cpp
// Check if Narrator is enabled
bool bNarratorEnabled = FWindowsPlatformMisc::IsTextToSpeechEnabled();

// Announce UI text changes
FWindowsPlatformMisc::SpeakWithSpeechSynthesizer(TextToSpeak, Locale);
```

## Scan Implementation

### File Patterns to Check

```
# Account Picker
Grep: ShowAccountPicker|AccountPickerUI|OnAccountPicked
Files: *.cpp

# Connected Storage
Grep: XGameSave|ConnectedStorage|CloudSave
Files: *.cpp

# Quick Resume
Grep: ApplicationWillDeactivate|ApplicationHasReactivated|OnQuickResume
Files: *.cpp

# Achievements
Grep: WriteAchievements|AchievementInterface|UnlockAchievement
Files: *.cpp

# Privileges
Grep: GetUserPrivilege|CanPlayOnline|CheckPrivilege
Files: *.cpp
```

### Validation Rules

```yaml
rules:
  - id: XR-015-ACCOUNT-PICKER
    require_in_files: "*PauseMenu*|*MainMenu*"
    pattern: "ShowAccountPicker"
    message: "Account picker must be accessible from menus"

  - id: XR-062-QUICK-RESUME
    pattern: "ApplicationHasReactivated"
    require_handler: "RefreshAuth|ReconnectNetwork|ValidateSession"
    message: "Quick Resume must refresh network/auth state"

  - id: XR-047-CLOUD-SAVE
    pattern: "SaveGame|SaveSlot"
    require: "XGameSave|ConnectedStorage"
    message: "Saves must sync to Connected Storage"
```

## Report Template

```markdown
# XR Compliance Report

## Executive Summary
- **Status**: {PASS/CONDITIONAL/FAIL}
- **Critical Violations**: {N}
- **High Priority**: {N}
- **Series X|S Specific**: {N}

## Platform Coverage
- [ ] Xbox One
- [ ] Xbox One X
- [ ] Xbox Series S
- [ ] Xbox Series X

## Violations by Category

### Critical - Must Fix for Submission

#### XR-015: Account Picker
**Status**: {PASS/FAIL}
**Files Checked**: {N}
**Issues Found**:
1. `{File}:{Line}` - {Description}
   - **Fix**: {Remediation}

### Series X|S Specific

#### XR-062: Quick Resume
**Status**: {PASS/FAIL}
{Details}

## Checklist for QA

- [ ] Account picker from pause menu
- [ ] Sign-out during gameplay - correct behavior
- [ ] Quick Resume after 1 hour suspend
- [ ] Quick Resume after 24 hour suspend
- [ ] Save to Connected Storage, load on different device
- [ ] Achievement unlock offline, verify sync when online
- [ ] Controller disconnect, reconnect different controller

## Test Scenarios

1. Sign out during save operation
2. Network loss during achievement unlock
3. Quick Resume with expired auth token
4. Profile change mid-gameplay
5. Storage quota exceeded during save
```

## Integration Notes

For Huli/S2 project:
1. Verify `USipherSaveSubsystem` uses Connected Storage
2. Check `ASipherPlayerController` has account picker integration
3. Ensure Quick Resume handling in game mode transitions
4. Validate achievement hooks in Xbox-specific code paths
5. Test offline achievement queueing
