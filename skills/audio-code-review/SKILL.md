---
name: audio-code-review
description: Technical Director review of audio system code quality
---

# Audio Systems Code Quality Review

**Role:** Technical Director - Audio Systems Specialist
**Scope:** `Plugins/SipherAudio/`, `Plugins/S2ContextEffects/`, `Content/S2/Audio/`
**Platform Focus:** PC, PS5, Xbox Series X, Next-gen consoles
**Performance Target:** 60 FPS with dynamic audio

## Objective

Conduct a strict, high-performance code review of audio system implementations, focusing on:
- ✅ Console certification compliance (zero blocking loads)
- ✅ UE5 best practices (Async loading, Audio Modulation, Quartz)
- ✅ Memory safety (no leaks, proper UObject lifecycle)
- ✅ Performance optimization (< 1ms audio overhead per frame)
- ✅ Thread safety (Audio thread vs Game thread separation)
- ✅ Audio asset naming conventions (Content/S2/Audio/)
- ✅ Asset organization and folder structure

## Review Checklist

### 🔴 Critical Issues (Console Cert Blockers)

**1. Synchronous Asset Loading**
```cpp
// ❌ BLOCKING - Console cert FAIL
CBM_Designer = AudioSettings->DesignerControlBusMix.LoadSynchronous();
UClass* ControllerClass = ControllerClassSoft.LoadSynchronous();
LoadedObj = ObjPath.TryLoad();

// ✅ CORRECT - Async with FStreamableManager
FStreamableManager& Streamable = UAssetManager::GetStreamableManager();
Streamable.RequestAsyncLoad(AssetPath,
    FStreamableDelegate::CreateUObject(this, &ThisClass::OnAssetsLoaded),
    FStreamableManager::AsyncLoadHighPriority);
```

**Check for:**
- [ ] No `LoadSynchronous()` calls in any audio code
- [ ] No `TryLoad()` calls during gameplay
- [ ] All `TSoftObjectPtr` loads are async
- [ ] All `TSoftClassPtr` loads are async
- [ ] Asset loading moved to safe times (BeginPlay, level load, loading screens)

**2. Audio Component Lifecycle**
```cpp
// ❌ WRONG - Memory leak risk
FGameplayEffectSpec* GESpec = new FGameplayEffectSpec(...);

// ❌ WRONG - No pooling, GC pressure
UAudioComponent* Comp = UGameplayStatics::CreateSound2D(this, Sound);

// ✅ CORRECT - Use FGameplayEffectSpecHandle
FGameplayEffectSpecHandle SpecHandle = ASC->MakeOutgoingSpec(...);

// ✅ CORRECT - Implement audio component pool
UAudioComponent* AcquireComponentFromPool();
void ReleaseComponentToPool(UAudioComponent* Component);
```

**Check for:**
- [ ] No raw `new` for UObjects or FGameplayEffectSpec
- [ ] Audio components reused via pooling system
- [ ] No frequent component creation/destruction (GC spikes)
- [ ] Proper `UPROPERTY()` on all UObject references

### 🟡 High Priority (Performance Impact)

**3. Audio Thread Safety**
```cpp
// ❌ WRONG - All audio on game thread
AudioComponent->SetSound(NewSound);
AudioComponent->FadeIn(FadeTime, TargetVolume);

// ✅ CORRECT - Delegate to audio thread
FAudioThread::RunCommandOnAudioThread([AudioComponent, NewSound]()
{
    if (AudioComponent && NewSound)
    {
        AudioComponent->SetSound(NewSound);
    }
});
```

**Check for:**
- [ ] Audio operations use `FAudioThread::RunCommandOnAudioThread()`
- [ ] No direct manipulation of audio components on game thread
- [ ] Parameter updates are async
- [ ] Quartz commands properly queued

**4. Component Caching**
```cpp
// ❌ WRONG - O(n) lookup every call
auto AudioManager = GetWorld()->GetSubsystem<USipherAudioManagerSubsystem>();

// ⚠️ QUESTIONABLE - TWeakObjectPtr overhead
TWeakObjectPtr<USipherAudioManagerWorldSubsystem> WorldManagerWeak;

// ✅ CORRECT - Cache in PostInitializeComponents
UPROPERTY(Transient)
TObjectPtr<USipherAudioManagerSubsystem> CachedAudioManager;

void PostInitializeComponents()
{
    Super::PostInitializeComponents();
    CachedAudioManager = GetGameInstance()->GetSubsystem<USipherAudioManagerSubsystem>();
}
```

**Check for:**
- [ ] No `GetSubsystem()` calls in hot paths (Tick, frequent calls)
- [ ] Subsystems cached during initialization
- [ ] Weak pointers used only when necessary
- [ ] Raw pointers preferred for cached, non-UPROPERTY references

**5. Logging & Error Handling**
```cpp
// ❌ WRONG - LogTemp usage
UE_LOG(LogTemp, Warning, TEXT("Audio failed"));

// ❌ WRONG - No validation
SetSound(NewSound);

// ✅ CORRECT - Custom log category
DEFINE_LOG_CATEGORY_STATIC(LogSipherAudio, Log, All);
UE_LOG(LogSipherAudio, Warning, TEXT("Audio environment %s failed to load"), *Tag.ToString());

// ✅ CORRECT - Validate before use
if (!IsValid(NewSound))
{
    UE_LOG(LogSipherAudio, Error, TEXT("Invalid sound asset"));
    return;
}
```

**Check for:**
- [ ] Custom log categories (LogSipherAudio, not LogTemp)
- [ ] Proper validation of all UObject pointers (`IsValid()`)
- [ ] Graceful failure (warnings, not crashes)
- [ ] Error logs include context (asset names, tags, state)

### 🟢 Medium Priority (Technical Debt)

**6. UE5 Audio Features**
```cpp
// ⚠️ MISSING - No MetaSounds usage
UPROPERTY(EditAnywhere)
TObjectPtr<USoundBase> BGMSound;

// ✅ GOOD - Use MetaSoundSource for dynamic parameters
UPROPERTY(EditAnywhere)
TObjectPtr<UMetaSoundSource> BGMMetaSound;

void UpdateCombatIntensity(float Intensity)
{
    if (AudioComponent)
    {
        AudioComponent->SetFloatParameter(FName("CombatIntensity"), Intensity);
    }
}
```

**Check for:**
- [ ] MetaSounds integration for dynamic music
- [ ] Audio Modulation properly used (Control Bus Mixes)
- [ ] Quartz synchronization for beat-aligned events
- [ ] Spatial audio support (PS5 Tempest, Xbox Spatial Sound)

**7. Code Organization**
```cpp
// ❌ WRONG - Monolithic function (300+ lines)
void CrossFadeNewBGM(FName BGMIdToTransit)
{
    if (CurrentWorldPlaylist.IsEmpty()) { }
    else {
        if(CurrentWorldPlaylist.Find(BGMIdToTransit)) {
            if (!CurrentBGMPlayer) { }
            else {
                if (CurrentBGMPlayer->GetSound() == NewBGM.BGM) { }
                else {
                    // ... 200 more lines ...
                }
            }
        }
    }
}

// ✅ CORRECT - Decomposed into focused functions
void CrossFadeNewBGM(FName BGMIdToTransit)
{
    if (!ValidatePlaylist(BGMIdToTransit)) return;

    USoundBase* NewSound = GetBGMFromPlaylist(BGMIdToTransit);
    if (ShouldCrossfade(NewSound))
    {
        StartCrossfade(NewSound);
    }
}
```

**Check for:**
- [ ] Functions under 50 lines (Cyclomatic Complexity < 10)
- [ ] Single Responsibility Principle
- [ ] No deeply nested conditionals (max 3 levels)
- [ ] Clear, descriptive function names

**8. Blueprint Exposure**
```cpp
// ❌ WRONG - Public state flags (race conditions)
UPROPERTY(BlueprintReadWrite)
bool isLoadingFlag = false;

UPROPERTY(BlueprintReadWrite)
bool OnAudioTransitionFlag = false;

// ✅ CORRECT - Encapsulated with accessors
UPROPERTY(BlueprintReadOnly, Category = "Audio State", meta = (AllowPrivateAccess = "true"))
bool bIsTransitioning = false;

UFUNCTION(BlueprintPure, Category = "Audio State")
bool IsTransitioning() const { return bIsTransitioning; }
```

**Check for:**
- [ ] No `BlueprintReadWrite` on state machine flags
- [ ] Proper naming conventions (`bIsActive`, not `isActiveFlag`)
- [ ] State exposed via getters, not direct access
- [ ] Pure functions marked `const`

## UE5-Specific Audio Patterns

### Audio Modulation (Control Bus Mixes)
```cpp
// ✅ GOOD USAGE
void InitControlBusMixes()
{
    if (UModulationStatics* Modulation = GEngine->GetAudioDeviceManager())
    {
        Modulation->ActivateBusMix(*CBM_Designer);

        // Load user settings
        TArray<FSoundControlBusMixStage> MixStages =
            Modulation->LoadMixFromProfile(UserProfileIndex, *CBM_User);
    }
}
```

**Check for:**
- [ ] Designer and User Control Bus Mixes separated
- [ ] Profile save/load implemented for user settings
- [ ] Modulation manager properly accessed
- [ ] Bus mixes activated on subsystem init

### Quartz Synchronization
```cpp
// ✅ GOOD USAGE
void PlayBGMQuantized(UQuartzClockHandle* MusicClock)
{
    if (AudioComponent && MusicClock)
    {
        FQuartzQuantizationBoundary Boundary;
        Boundary.Quantization = EQuartzCommandQuantization::Bar;
        Boundary.CountingReferencePoint = EQuarztQuantizationReference::BarRelative;

        AudioComponent->PlayQuantized(GetWorld(), MusicClock,
            Boundary, FOnQuartzCommandEventBP());
    }
}
```

**Check for:**
- [ ] Global Quartz clock created for music sync
- [ ] Beat-aligned transitions implemented
- [ ] Clock handle cached and restored on level transitions
- [ ] Pending Quartz commands re-registered after load

## Performance Profiling Checklist

**Frame Budget Analysis:**
- [ ] Audio subsystem updates < 1ms per frame
- [ ] No hitches > 16ms during audio transitions
- [ ] Memory stable over 10-minute session (no leaks)
- [ ] Audio component count stays under 50 active

**Unreal Insights Checks:**
```bash
# Profile audio systems
UnrealEditor.exe S2.uproject -game -trace=cpu,loadtime,audio -tracefile=audio_profile

# Analysis targets:
# 1. Zero LoadSynchronous calls during gameplay
# 2. Audio thread shows activity (not all on game thread)
# 3. No frame spikes during environment transitions
# 4. Asset streaming working correctly
```

**Check Insights for:**
- [ ] `LoadSynchronous` / `TryLoad` calls (should be 0)
- [ ] Audio thread CPU usage (should show activity)
- [ ] Game thread audio overhead (< 0.5ms target)
- [ ] Memory allocations (component pooling effective?)

## Console Certification Requirements

### PS5 / Xbox Series X
- [ ] Zero blocking loads > 33ms during gameplay
- [ ] All assets preloaded or async loaded
- [ ] No hitches during level transitions
- [ ] Audio persists across suspend/resume
- [ ] Memory budget < 100MB for audio systems
- [ ] Spatial audio compatible (Tempest/Atmos ready)

### Platform-Specific Checks
```cpp
// PS5 Tempest Audio
#if PLATFORM_PS5
    AudioComponent->SetSpatializationMethod(ESpatializationMethod::HRTF);
#endif

// Xbox Spatial Sound
#if PLATFORM_XBOXONE || PLATFORM_XSX
    AudioComponent->EnableSpatialSound(true);
#endif
```

**Check for:**
- [ ] Platform-specific audio paths tested
- [ ] No hardcoded platform assumptions
- [ ] Scalability settings for different platforms

## Audio Asset Naming Convention Review

### Asset Naming Standards (Content/S2/Audio/)

**Objective:** Ensure consistent, descriptive naming for all audio assets following UE5 and project conventions.

#### Standard Prefixes by Asset Type

**Sound Assets:**
```
SW_     - Sound Wave (imported audio files)
SC_     - Sound Cue (sound composition/logic)
MS_     - MetaSound Source
MSP_    - MetaSound Patch
```

**Audio Configuration:**
```
SoundClass_      - Sound Class hierarchy nodes
Mix_             - Sound Mix (legacy volume control)
CBM_             - Control Bus Mix (Audio Modulation)
Bus_             - Audio Bus (submix routing)
ControlBus_      - Control Bus (modulation parameter)
Att_             - Attenuation Settings (spatial audio)
```

**Quartz Assets:**
```
QC_     - Quartz Clock Handle
QCH_    - Quartz Clock Handle (alternative)
Quartz_ - General Quartz configuration
```

**Context Effects:**
```
CE_     - Context Effect configuration
CEL_    - Context Effect Library
```

#### Folder Structure Standards

```
Content/S2/Audio/
├── BGM/                    # Background Music
│   ├── Combat/            # Combat music layers
│   ├── Exploration/       # Ambient exploration
│   └── Boss/              # Boss encounter themes
├── SFX/                   # Sound Effects
│   ├── Character/         # Character sounds
│   │   ├── Footsteps/
│   │   ├── Vocals/
│   │   └── Abilities/
│   ├── Weapons/           # Weapon sounds
│   ├── UI/                # UI feedback
│   └── Ambience/          # Environmental ambience
├── Dialogue/              # Voice acting
│   ├── Player/
│   ├── NPCs/
│   └── Bosses/
├── AudioConfig/           # Configuration assets
│   ├── Attenuation/       # Att_* files
│   ├── Modulation/        # CBM_*, ControlBus_* files
│   ├── SoundClasses/      # SoundClass_* hierarchy
│   └── Quartz/            # QC_* timing assets
└── MetaSounds/            # MetaSound sources
    ├── Music/             # Dynamic music systems
    └── Procedural/        # Procedural audio
```

### Naming Convention Checklist

#### ✅ Good Examples:
```
✓ SW_BGM_Boss_Intro_Loop
✓ SC_Player_Footstep_Stone
✓ MS_Combat_Dynamic_Layer
✓ CBM_MasterVolume
✓ Att_Weapon_Close
✓ SoundClass_SFX_Weapons
✓ QC_MusicClock
✓ CE_Footstep_Surface_Stone
```

#### ❌ Bad Examples:
```
✗ NewSound1                    # No prefix, vague name
✗ sound_cue_final_v2          # Lowercase, version suffix, no context
✗ BGM-BossMusic               # Wrong separator (use underscore)
✗ SFX.Footstep.Stone          # Wrong separator (use underscore)
✗ SW_ALLCAPS                  # Don't use all caps after prefix
✗ SW_Boss Music Loop          # No spaces (use underscore)
✗ SC_Test                     # Temporary/test assets shouldn't be committed
```

#### Naming Pattern Rules:

**1. Structure:**
```
[Prefix]_[Category]_[Subcategory]_[Descriptor]_[Variant]
```

**Examples:**
```
SW_Character_Player_Jump_01
SW_Weapon_Sword_Swing_Heavy
SC_UI_Button_Hover
MS_BGM_Combat_Intensity_System
CBM_Gameplay_DynamicMix
```

**2. Descriptive Clarity:**
- [ ] Name describes audio content/function
- [ ] No generic names (Untitled, NewSound, Test)
- [ ] No version numbers (v1, v2, Final, FinalFinal)
- [ ] No developer initials or dates
- [ ] No temporary/debug assets in production folders

**3. Consistency:**
- [ ] All files in same category use same prefix
- [ ] Similar assets follow same naming pattern
- [ ] Variants numbered with leading zeros (01, 02, not 1, 2)
- [ ] Compound words use PascalCase (PlayerFootstep, not playerfootstep)

**4. Special Cases:**

**Variations:**
```
SW_Character_Grunt_01
SW_Character_Grunt_02
SW_Character_Grunt_03
```

**Layered Music:**
```
SW_BGM_Combat_Base_Loop
SW_BGM_Combat_Drums_Loop
SW_BGM_Combat_Melody_Loop
```

**State-Driven:**
```
SC_BGM_Exploration_Calm
SC_BGM_Exploration_Alert
SC_BGM_Exploration_Combat
```

### Asset Organization Review

**Check for:**
- [ ] All assets in appropriate category folders
- [ ] No loose files in root Audio/ folder
- [ ] Related assets grouped together (e.g., all footsteps in Footsteps/)
- [ ] No duplicate assets in multiple locations
- [ ] Source WAV files organized same as Unreal assets
- [ ] MetaSounds separate from basic Sound Cues
- [ ] Configuration assets (Att_, CBM_) in AudioConfig/ folder

### Platform-Specific Asset Naming

**Console Audio Assets:**
```
# ❌ WRONG - Don't duplicate assets per platform
SW_Explosion_PS5
SW_Explosion_Xbox
SW_Explosion_PC

# ✅ CORRECT - Use single asset with platform scalability
SW_Explosion
# Configure platform-specific compression in asset settings
```

**Check for:**
- [ ] No platform suffixes in names (_PS5, _Xbox, _PC)
- [ ] Platform differences handled via compression settings
- [ ] Scalability configured in Audio Quality settings
- [ ] Spatial audio compatibility (works on Tempest/Atmos/Stereo)

### Audio Asset Review Process

**1. Scan Asset Folders:**
```bash
# List all audio assets
ls -R Content/S2/Audio/

# Find assets without proper prefixes
grep -r "^[^A-Z]" Content/S2/Audio/
```

**2. Check for Common Issues:**
- [ ] Assets without prefixes
- [ ] Inconsistent naming patterns within categories
- [ ] Test/temp assets in production folders
- [ ] Version suffixes (_v1, _final, _old)
- [ ] Duplicate assets with different names
- [ ] Assets in wrong category folders

**3. Validate Against Standards:**
- [ ] Every Sound Wave starts with SW_
- [ ] Every Sound Cue starts with SC_
- [ ] Every MetaSound starts with MS_ or MSP_
- [ ] Configuration assets use proper prefixes
- [ ] Folder structure matches standard layout
- [ ] No orphaned assets (nothing references them)

### Asset Naming Report Format

When reviewing asset naming, include:

```markdown
## 🎵 Audio Asset Naming Review

**Assets Scanned:** X total
**Compliant:** Y (Z%)
**Issues Found:** W

### 📊 Compliance Breakdown

| Category | Total | Compliant | Issues |
|----------|-------|-----------|--------|
| Sound Waves (SW_) | 150 | 142 | 8 |
| Sound Cues (SC_) | 80 | 75 | 5 |
| MetaSounds (MS_) | 30 | 30 | 0 |
| Config Assets | 40 | 38 | 2 |

### 🔴 Critical Naming Issues

#### Issue #1: Missing Prefixes
**Location:** `Content/S2/Audio/SFX/`
**Files:**
- `ExplosionSound.uasset` → Should be `SW_Explosion` or `SC_Explosion`
- `FootstepGrass.uasset` → Should be `SW_Character_Footstep_Grass`

**Impact:** Breaks asset search/filtering, unclear asset type
**Fix Time:** 30 minutes (batch rename)

#### Issue #2: Inconsistent Patterns
**Location:** `Content/S2/Audio/BGM/`
**Files:**
- `SW_Boss1Music.uasset`
- `SW_BossMusic02.uasset`
- `SW_BGM_Boss_03.uasset`

**Expected Pattern:** `SW_BGM_Boss_[Name]_[Variant]`
**Fix Time:** 1 hour (standardize naming)

### 🟡 Organization Issues

#### Misplaced Assets
- `Content/S2/Audio/CBM_Volume.uasset` → Move to `AudioConfig/Modulation/`
- `Content/S2/Audio/SFX/Att_Global.uasset` → Move to `AudioConfig/Attenuation/`

### ✅ Well-Organized Sections

- ✓ `Content/S2/Audio/BGM/Combat/` - All assets follow `SW_BGM_Combat_*` pattern
- ✓ `Content/S2/Audio/MetaSounds/` - Proper MS_ prefixes, well categorized
- ✓ `Content/S2/Audio/AudioConfig/Quartz/` - Clean QC_ naming

### 🎯 Recommendations

**Immediate Actions:**
1. Rename 8 assets missing prefixes (30 min)
2. Standardize boss music naming pattern (1 hour)
3. Move misplaced config assets to AudioConfig/ (15 min)

**Batch Rename Script:**
\`\`\`python
# Example rename script for UE5 Python API
import unreal

# Rename assets without SW_ prefix in SFX folder
asset_registry = unreal.AssetRegistryHelpers.get_asset_registry()
assets = asset_registry.get_assets_by_path("/Game/S2/Audio/SFX/", recursive=True)

for asset_data in assets:
    asset_name = asset_data.asset_name
    if not asset_name.startswith(("SW_", "SC_", "MS_")):
        # Suggest proper name based on asset type
        new_name = f"SW_{asset_name}"
        print(f"Rename: {asset_name} → {new_name}")
\`\`\`

**Next Steps:**
- Review with audio team
- Update asset naming guide documentation
- Train team on naming standards
- Set up pre-commit hooks to enforce naming
```

## Output Format

Generate a report in: `claude-agents/reports/technical-director/audio/code_review_[date].md`

**Report Structure:**
```markdown
# Audio Code Quality Review - [Component Name]

**Date:** YYYY-MM-DD
**Reviewer:** Technical Director AI Agent
**Files Reviewed:** [List of files]
**Assets Reviewed:** [Asset paths if applicable]
**Scope:** [Specific functionality reviewed]

## 📊 Executive Summary

🔴 **Critical Issues**: X | 🟡 **High Priority**: Y | 🟢 **Medium**: Z | ⚪ **Low**: W

**Overall Grade:** [A-F]
**Console Cert Status:** [PASS/FAIL]
**Performance Grade:** 🟩🟩🟩⬜⬜ 60%
**Asset Naming Compliance:** 🟩🟩🟩🟩⬜ 85% (if asset review performed)

## 🔴 Critical Issues

### Issue #1: [Title]
**File:** `Path/To/File.cpp:123`
**Severity:** 🔴 Critical
**Impact:** [Console cert blocker / Memory leak / Performance regression]

**Current Code:**
\`\`\`cpp
// Show problematic code
\`\`\`

**Fix:**
\`\`\`cpp
// Show correct implementation
\`\`\`

**Effort:** [Hours/Days]
**Priority:** P0

## 🟡 High Priority Issues

[Continue with high priority items...]

## 🟢 Medium Priority Issues

[Continue with medium priority items...]

## 🎵 Audio Asset Naming Review (if applicable)

**Assets Scanned:** X total
**Compliant:** Y (Z%)
**Issues Found:** W

### 📊 Compliance Breakdown

| Category | Total | Compliant | Issues |
|----------|-------|-----------|--------|
| Sound Waves (SW_) | 150 | 142 | 8 |
| Sound Cues (SC_) | 80 | 75 | 5 |
| MetaSounds (MS_) | 30 | 30 | 0 |
| Config Assets | 40 | 38 | 2 |

### Naming Issues Found

[List specific naming convention violations]

### Organization Issues

[List folder structure or asset organization problems]

## ✅ Strengths

- List positive findings
- Good patterns observed
- Best practices followed

## 📈 Performance Analysis

**Frame Budget Breakdown:**
- Audio updates: Xms (Y% of 16.67ms)
- Asset loading: Handled async ✅
- Memory usage: XMB (within budget)

## 🎯 Recommendations

**Immediate (This Sprint):**
1. Fix critical issue #1 (estimated: X hours)
2. Fix critical issue #2 (estimated: Y hours)
3. Rename non-compliant assets (estimated: X hours)

**Next Sprint:**
1. Address high priority issues
2. Implement performance optimizations
3. Reorganize misplaced assets

**Future:**
1. MetaSounds integration
2. Spatial audio support
3. Asset naming automation/validation

## 📋 Testing Checklist

- [ ] All fixes implemented
- [ ] Unreal Insights profiling clean
- [ ] Console cert tools pass
- [ ] Regression tests pass
- [ ] Audio still plays correctly
- [ ] Asset renames propagated to all references
- [ ] No broken asset references after reorganization

---

**Report Generated:** [Timestamp]
**Next Review:** [Date]
\`\`\`

## Example Invocation

To use this skill, invoke it when reviewing audio code or assets:

**Code Review:**
\`\`\`
/skill audio-code-review

Please review the following audio implementation:
- Plugins/SipherAudio/Source/SipherAudio/Private/SipherAudioManagerSubsystem.cpp
- Focus on the SetAudioEnvironmentTag and CreateEnvironmentController functions
\`\`\`

**Asset Naming Convention Review:**
\`\`\`
/skill audio-code-review

Please review the audio asset naming conventions in Content/S2/Audio/
- Check all Sound Waves, Sound Cues, and MetaSounds for proper prefixes
- Verify folder organization matches standards
- Identify any misnamed or misplaced assets
\`\`\`

**Combined Review:**
\`\`\`
/skill audio-code-review

Conduct a comprehensive audio review:
1. Code quality in Plugins/SipherAudio/
2. Asset naming conventions in Content/S2/Audio/
3. Generate unified report with priorities
\`\`\`

## Knowledge Base References

- `claude-agents/reports/technical-director/audio/audio-systems-review.md` - Initial audit
- `claude-agents/reports/technical-director/audio/audio-systems-fast-implementation-plan.md` - Fix timeline
- `/CLAUDE.md` - Project standards and common pitfalls
- `.github/copilot-instructions.md` - UE5 coding standards

## Success Criteria

**Code Review Complete When:**
- ✅ All critical issues documented with line numbers
- ✅ Performance analysis includes frame budget impact
- ✅ Console cert compliance assessed
- ✅ Actionable recommendations with effort estimates
- ✅ Test plan provided for validation
- ✅ Report follows visual standards (emojis, progress bars)

## Legacy Metadata

```yaml
skill: audio-code-review
invoke: /audio-systems:audio-code-review
type: code-review
category: technical-director
scope: Plugins/SipherAudio, Plugins/S2ContextEffects, Content/S2/Audio
```
