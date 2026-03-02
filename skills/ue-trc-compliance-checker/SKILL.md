---
name: ue-trc-compliance-checker
description: Check codebase for Sony PlayStation TRC (Technical Requirements Checklist) compliance issues. Scans for suspend/resume handling, save data requirements, trophy implementation, and PS5 certification requirements. Use before console submission or when preparing for Sony certification. Triggers on "TRC", "PlayStation certification", "Sony compliance", "PS5 cert", "console certification", "PS5 requirements".
---

# UE TRC Compliance Checker

Scan codebase for Sony PlayStation Technical Requirements Checklist (TRC) violations.

## Quick Start

1. Run compliance scan on codebase
2. Review categorized violations
3. Get remediation guidance

## TRC Categories

### 1. Application Behavior (Critical)

#### R4001 - Suspend/Resume

**Requirement**: Application must handle suspend/resume correctly.

**Check for**:
```cpp
// Must implement
virtual void ApplicationWillDeactivateDelegate();
virtual void ApplicationHasReactivatedDelegate();
virtual void ApplicationWillEnterBackgroundDelegate();
virtual void ApplicationHasEnteredForegroundDelegate();

// Audio must pause on suspend
FAudioDevice::Suspend();
FAudioDevice::Resume();
```

**Violations**:
- Missing suspend handlers
- Audio continues during suspend
- Network operations not paused
- Timers not adjusted for suspend duration

#### R4002 - Application Termination

**Requirement**: Save user progress before termination.

**Check for**:
```cpp
// Must hook into termination
FCoreDelegates::ApplicationWillTerminateDelegate.AddUObject(this, &UMyClass::OnTerminate);

// Save must complete within 10 seconds
// Use FPlatformProcess::IsFirstInstance() for mutex
```

### 2. Save Data (Critical)

#### R4010 - Save Data Corruption

**Requirement**: Prevent save corruption, handle errors gracefully.

**Check for**:
```cpp
// Must use async save with callbacks
ISaveGameSystem* SaveSystem = IPlatformFeaturesModule::Get().GetSaveGameSystem();
SaveSystem->SaveGame(/*bAttemptAsync=*/ true, SaveSlotName, UserIndex, SaveDelegate);

// Must handle failures
if (SaveResult != ESaveGameResult::Success)
{
    // Show user-facing error
    // Do NOT silently fail
}
```

**Violations**:
- Synchronous saves blocking main thread
- No error handling for save failures
- Save during loading screen (potential corruption)
- Multiple simultaneous saves to same slot

#### R4011 - Save Data Size

**Requirement**: Stay within save data limits.

| Platform | Limit |
|----------|-------|
| PS5 | 32 MB per save slot |
| PS4 | 1 GB total (varies by entitlement) |

### 3. User/Account (Critical)

#### R4030 - User Sign-In Status

**Requirement**: Handle user sign-out during gameplay.

**Check for**:
```cpp
// Must monitor sign-in status
FCoreDelegates::OnUserLoginChangedEvent.AddUObject(this, &UMyClass::OnLoginChanged);

// Return to title screen on sign-out
if (!bUserSignedIn)
{
    // Cannot continue gameplay
    // Must show appropriate message
    ReturnToTitleScreen();
}
```

#### R4031 - Controller Assignment

**Requirement**: Handle controller disconnection and reassignment.

**Check for**:
```cpp
// Monitor controller status
FCoreDelegates::OnControllerConnectionChange.AddUObject(...);

// Pause gameplay on disconnect
// Show reconnect prompt
// Resume on reconnect with same controller
```

### 4. Network (High)

#### R4050 - Network Connectivity

**Requirement**: Handle network loss gracefully (even for offline games).

**Check for**:
- PSN feature usage without connectivity check
- Trophy sync without network check
- Leaderboard access without error handling

#### R4051 - Online Messaging

**Requirement**: Use platform-appropriate online communication.

**Violations**:
- Custom profanity filters (must use PSN)
- Allowing banned users to communicate

### 5. Trophies (High)

#### R4070 - Trophy Unlock

**Requirement**: Trophies unlock correctly and persistently.

**Check for**:
```cpp
// Use platform trophy API
IOnlineSubsystem* OnlineSub = IOnlineSubsystem::Get(PLAYSTATION_SUBSYSTEM);
IOnlineAchievementsPtr Achievements = OnlineSub->GetAchievementsInterface();

// Trophy must unlock on achievement
Achievements->WriteAchievements(LocalUserNum, WriteObject, Delegate);

// Must handle unlock failure (retry later)
```

**Violations**:
- Trophy unlocks before condition fully met
- Missing Platinum trophy logic
- Trophy not unlocking on reload (must check state)

### 6. System Software Features (Medium)

#### R4080 - Activity Cards

**Requirement**: PS5 Activity Cards integration.

**Check for**:
- Activity card definitions in game data
- Progress tracking for activities
- Estimated time updates

#### R4081 - Game Help

**Requirement**: PS5 Game Help videos/tips.

## Scan Implementation

### File Patterns to Check

```
# Suspend/Resume
Grep: ApplicationWillDeactivate|ApplicationHasReactivated|OnApplicationWillDeactivate
Files: *.cpp, *.h

# Save System
Grep: SaveGame|LoadGame|ISaveGameSystem|AsyncSave
Files: *.cpp

# User Management
Grep: OnUserLoginChanged|GetLocalPlayer|GetControllerId
Files: *.cpp

# Trophies
Grep: WriteAchievements|AchievementsInterface|UnlockAchievement
Files: *.cpp
```

### Validation Rules

```yaml
rules:
  - id: TRC-R4001-SUSPEND
    pattern: "FAudioDevice::(?!Suspend|Resume)"
    context: "Delegate.*Background|Delegate.*Deactivate"
    message: "Audio device operations during suspend must use Suspend/Resume"

  - id: TRC-R4010-SYNC-SAVE
    pattern: "SaveGameToSlot\\([^)]*false"
    message: "Synchronous saves may block main thread - use async"

  - id: TRC-R4030-SIGNOUT
    pattern: "OnUserLoginChanged"
    require_handler: "ReturnToTitle|ReturnToMenu|ShowSignOutMessage"
    message: "Sign-out must return to title or show message"
```

## Report Template

```markdown
# TRC Compliance Report

## Executive Summary
- **Status**: {PASS/CONDITIONAL/FAIL}
- **Critical Violations**: {N}
- **High Priority**: {N}
- **Medium Priority**: {N}

## Violations by Category

### Critical - Must Fix for Submission

#### TRC-R4001: Suspend/Resume
**Status**: {PASS/FAIL}
**Files Checked**: {N}
**Issues Found**:
1. `{File}:{Line}` - {Description}
   - **Fix**: {Remediation}

### High Priority - Should Fix

{Similar format}

## Checklist for QA

- [ ] Suspend during gameplay - verify audio stops
- [ ] Suspend during save - verify no corruption
- [ ] Sign out during gameplay - verify return to title
- [ ] Controller disconnect - verify pause and prompt
- [ ] Network loss - verify graceful degradation
- [ ] Trophy unlock - verify persistence across sessions

## Recommended Testing

1. Suspend/Resume cycle during all game states
2. Sign-out at each save point
3. Network pull during any online feature
4. Controller disconnect/reconnect
5. Storage full during save
```

## Integration Notes

For Huli/S2 project:
1. Check `SipherSaveSubsystem` for async save compliance
2. Verify `ASipherPlayerController` handles sign-out
3. Ensure trophy hooks in `USipherAchievementSubsystem`
4. Validate Activity Cards in PS5-specific content
