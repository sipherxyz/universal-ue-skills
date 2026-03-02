---
name: ue-audio-metasound-integration
description: Generate MetaSound audio integration code including Control Bus modulation, Quartz synchronization, environment controllers, and State Tree audio transitions. Use when integrating MetaSound audio, creating sound triggers, or setting up audio systems. Triggers on "MetaSound", "audio integration", "sound event", "Control Bus", "Quartz", "audio trigger", "audio environment".
---

# UE Audio MetaSound Integration

Generate MetaSound audio integration code following SipherAudio plugin patterns.

## Quick Start

1. Specify audio requirement (sound playback, environment, music, etc.)
2. Generate integration code matching SipherAudio patterns
3. Get implementation guidance

## Project Audio Architecture

| System | Purpose |
|--------|---------|
| `USipherAudioManagerSubsystem` | Game instance audio management |
| `USipherAudioManagerWorldSubsystem` | Per-world audio control |
| `USipherAudioEnvironment_ControllerBase` | Environment-specific audio logic |
| `USipherAudioEnvironment_DataAsset` | Environment audio configuration |
| State Tree | Audio state transitions |
| Control Bus Mix | Volume/modulation control |
| Quartz | Music quantization and sync |

## Integration Types

### 1. Basic Sound Playback

```cpp
#include "Kismet/GameplayStatics.h"
#include "Components/AudioComponent.h"

// Play 2D sound (UI, non-positional)
void ASipherCharacter::PlayUISound()
{
    if (UISound)
    {
        UGameplayStatics::PlaySound2D(
            this,
            UISound,
            1.0f,  // Volume
            1.0f,  // Pitch
            0.0f,  // Start time
            nullptr,  // Concurrency
            nullptr,  // Owner for lifetime
            true  // Is UI sound
        );
    }
}

// Play 3D sound at location
void ASipherCharacter::PlayFootstepSound()
{
    if (FootstepSound)
    {
        UGameplayStatics::PlaySoundAtLocation(
            this,
            FootstepSound,
            GetActorLocation(),
            GetActorRotation(),
            1.0f,  // Volume
            1.0f,  // Pitch
            0.0f,  // Start time
            FootstepAttenuation,
            nullptr  // Concurrency
        );
    }
}

// Spawn persistent audio component
UAudioComponent* ASipherCharacter::SpawnLoopingSound(USoundBase* Sound)
{
    UAudioComponent* AudioComp = UGameplayStatics::SpawnSoundAttached(
        Sound,
        GetMesh(),
        NAME_None,  // Socket
        FVector::ZeroVector,
        FRotator::ZeroRotator,
        EAttachLocation::KeepRelativeOffset,
        true,  // Stop when attached destroyed
        1.0f,  // Volume
        1.0f,  // Pitch
        0.0f,  // Start time
        nullptr,  // Attenuation
        nullptr,  // Concurrency
        true  // Auto destroy
    );

    return AudioComp;
}
```

### 2. Audio Environment System

```cpp
#include "SipherAudioManagerSubsystem.h"

// Set audio environment via gameplay tag
void ASipherLevelVolume::OnPlayerEnter(AActor* Player)
{
    if (UGameInstance* GI = GetGameInstance())
    {
        if (USipherAudioManagerSubsystem* AudioManager = GI->GetSubsystem<USipherAudioManagerSubsystem>())
        {
            // Environment tag triggers controller activation
            AudioManager->SetAudioEnvironmentTag(EnvironmentTag);
        }
    }
}

// Get current environment
FGameplayTag GetCurrentAudioEnvironment()
{
    if (USipherAudioManagerSubsystem* AudioManager = GetAudioManager())
    {
        return AudioManager->GetAudioEnvironmentTag();
    }
    return FGameplayTag::EmptyTag;
}
```

### 3. Control Bus Modulation

```cpp
#include "AudioModulationStatics.h"
#include "SoundControlBusMix.h"

// Apply volume settings via Control Bus Mix
void USipherAudioManagerSubsystem::ApplyNewVolumeToSoundClass(
    const float BGVolume,
    const float VOVolume,
    const float SEVolume)
{
    if (CBM_User)
    {
        // Update Control Bus Mix values
        // Values are applied through the modulation system
        UAudioModulationStatics::UpdateMixByFilter(
            this,
            CBM_User,
            TEXT("BGM"),
            BGVolume
        );
    }
}

// Initialize Control Bus Mixes
void USipherAudioManagerWorldSubsystem::InitControlBusMixes()
{
    if (GI_Manager && ModulationManager)
    {
        if (GI_Manager->CBM_Designer)
        {
            UAudioModulationStatics::ActivateBusMix(this, GI_Manager->CBM_Designer);
        }
        if (GI_Manager->CBM_User)
        {
            UAudioModulationStatics::ActivateBusMix(this, GI_Manager->CBM_User);
        }
    }
}
```

### 4. Quartz Music Synchronization

```cpp
#include "Quartz/AudioMixerClockHandle.h"
#include "AudioMixerBlueprintLibrary.h"

// Create Quartz clock for music sync
void USipherMusicManager::InitializeQuartzClock()
{
    FQuartzClockSettings ClockSettings;
    ClockSettings.TimeSignature.NumBeats = 4;
    ClockSettings.TimeSignature.BeatType = EQuartzTimeSignatureQuantization::QuarterNote;

    ClockHandle = UAudioMixerBlueprintLibrary::CreateNewClock(
        this,
        GetWorld(),
        TEXT("MusicClock"),
        ClockSettings
    );
}

// Subscribe to beat events
void USipherMusicManager::SubscribeToBeat()
{
    if (ClockHandle)
    {
        FOnQuartzMetronomeEventBP BeatDelegate;
        BeatDelegate.BindDynamic(this, &USipherMusicManager::OnBeat);

        ClockHandle->SubscribeToQuantizationEvent(
            GetWorld(),
            EQuartzCommandQuantization::Beat,
            BeatDelegate,
            ClockHandle
        );
    }
}

// Handle beat callback
void USipherMusicManager::OnBeat(
    FName ClockName,
    EQuartzCommandQuantization QuantizationType,
    int32 NumBars,
    int32 Beat,
    float BeatFraction)
{
    // Sync game events to music beat
    OnMusicBeat.Broadcast(NumBars, Beat);
}
```

### 5. State Tree Audio Control

```cpp
#include "SipherAudioManagerSubsystem.h"

// Send event to audio State Tree
void ASipherGameMode::OnCombatStateChanged(bool bInCombat)
{
    if (USipherAudioManagerWorldSubsystem* AudioWorld = GetWorld()->GetSubsystem<USipherAudioManagerWorldSubsystem>())
    {
        FGameplayTag EventTag = bInCombat
            ? TAG_Audio_Event_CombatStart
            : TAG_Audio_Event_CombatEnd;

        AudioWorld->SendAudioStateEvent(EventTag);
    }
}

// Pause audio State Tree during loading
void ASipherLoadingScreen::OnLoadingStart()
{
    if (USipherAudioManagerWorldSubsystem* AudioWorld = GetAudioWorldSubsystem())
    {
        AudioWorld->PauseAudioStateTree();
    }
}

void ASipherLoadingScreen::OnLoadingComplete()
{
    if (USipherAudioManagerWorldSubsystem* AudioWorld = GetAudioWorldSubsystem())
    {
        AudioWorld->ResumeAudioStateTree();
    }
}
```

### 6. Environment Controller Pattern

```cpp
// Custom environment controller
UCLASS()
class USipherAudioEnvironment_ControllerCombat : public USipherAudioEnvironment_ControllerBase
{
    GENERATED_BODY()

public:
    virtual void OnActivate() override
    {
        Super::OnActivate();

        // Start combat music
        if (CombatMusicSound)
        {
            BGMComponent = UGameplayStatics::SpawnSound2D(
                this,
                CombatMusicSound,
                1.0f,
                1.0f,
                0.0f,
                nullptr,
                true,
                false
            );
        }
    }

    virtual void OnDeactivate() override
    {
        // Fade out combat music
        if (BGMComponent)
        {
            BGMComponent->FadeOut(2.0f, 0.0f);
        }

        Super::OnDeactivate();
    }

protected:
    UPROPERTY(EditDefaultsOnly, Category = "Audio")
    TObjectPtr<USoundBase> CombatMusicSound;

    UPROPERTY(Transient)
    TObjectPtr<UAudioComponent> BGMComponent;
};
```

## Animation Notify Integration

```cpp
// MetaSound Animation Notify
UCLASS()
class USipherAN_PlaySound : public UAnimNotify
{
    GENERATED_BODY()

public:
    UPROPERTY(EditAnywhere, Category = "Audio")
    TObjectPtr<USoundBase> Sound;

    UPROPERTY(EditAnywhere, Category = "Audio")
    FName AttachSocket;

    UPROPERTY(EditAnywhere, Category = "Audio")
    float VolumeMultiplier = 1.0f;

    UPROPERTY(EditAnywhere, Category = "Audio")
    float PitchMultiplier = 1.0f;

    virtual void Notify(USkeletalMeshComponent* MeshComp, UAnimSequenceBase* Animation,
        const FAnimNotifyEventReference& EventReference) override
    {
        if (!Sound || !MeshComp)
        {
            return;
        }

        AActor* Owner = MeshComp->GetOwner();
        if (!Owner)
        {
            return;
        }

        FVector Location = AttachSocket.IsNone()
            ? Owner->GetActorLocation()
            : MeshComp->GetSocketLocation(AttachSocket);

        UGameplayStatics::PlaySoundAtLocation(
            Owner,
            Sound,
            Location,
            FRotator::ZeroRotator,
            VolumeMultiplier,
            PitchMultiplier
        );
    }
};
```

## Audio Component Setup

```cpp
// Character audio component setup
void ASipherCharacter::SetupAudioComponents()
{
    // Main audio component for character sounds
    CharacterAudioComponent = CreateDefaultSubobject<UAudioComponent>(TEXT("CharacterAudio"));
    CharacterAudioComponent->SetupAttachment(RootComponent);
    CharacterAudioComponent->bAutoActivate = false;
    CharacterAudioComponent->bStopWhenOwnerDestroyed = true;

    // Voice component attached to head
    VoiceComponent = CreateDefaultSubobject<UAudioComponent>(TEXT("VoiceComponent"));
    VoiceComponent->SetupAttachment(GetMesh(), TEXT("head"));
    VoiceComponent->bAutoActivate = false;
    VoiceComponent->bStopWhenOwnerDestroyed = true;
}

// Play sound on component with fade
void ASipherCharacter::PlayCharacterSound(USoundBase* Sound, float FadeInDuration)
{
    if (CharacterAudioComponent && Sound)
    {
        CharacterAudioComponent->SetSound(Sound);
        CharacterAudioComponent->FadeIn(FadeInDuration);
    }
}
```

## Common Patterns

### Combat Audio

```cpp
void USipherCombatAudioComponent::PlayHitSound(const FSipherDamageEvent& DamageEvent)
{
    USoundBase* HitSound = GetHitSoundForDamageType(DamageEvent.DamageType);
    if (!HitSound)
    {
        return;
    }

    // Calculate volume based on damage intensity
    float Volume = FMath::GetMappedRangeValueClamped(
        FVector2D(0.f, 100.f),
        FVector2D(0.5f, 1.0f),
        DamageEvent.Damage
    );

    UGameplayStatics::PlaySoundAtLocation(
        this,
        HitSound,
        DamageEvent.HitLocation,
        FRotator::ZeroRotator,
        Volume
    );
}
```

### BGM Crossfade

```cpp
void USipherAudioManagerSubsystem::CrossfadeToBGM(USoundBase* NewBGM, float FadeDuration)
{
    // Start new BGM on support player
    if (SupportCrossFadePlayer)
    {
        SupportCrossFadePlayer->SetSound(NewBGM);
        SupportCrossFadePlayer->FadeIn(FadeDuration);
    }

    // Fade out current BGM
    if (CurrentBGMPlayer)
    {
        CurrentBGMPlayer->FadeOut(FadeDuration, 0.0f);
    }

    // Swap references
    Swap(CurrentBGMPlayer, SupportCrossFadePlayer);
}
```

### Memory Management

```cpp
// Trim audio streaming memory (can cause hitching)
void USipherAudioManagerSubsystem::TrimAudioStreamingMemory()
{
    // See UE docs: Audio Stream Caching - Trimming Memory
    // Call during loading screens or low-activity periods
    FAudioDevice* AudioDevice = GEngine->GetMainAudioDevice();
    if (AudioDevice)
    {
        AudioDevice->TrimMemory(AudioStreamingTrimMemoryTarget);
    }
}
```

## Data Asset Structure

```cpp
// Environment audio configuration
USTRUCT(BlueprintType)
struct FSipherAudioEnvironmentConfigData
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FGameplayTag Tag;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TSoftObjectPtr<USipherAudioEnvironment_DataAsset> DataAsset;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TSubclassOf<USipherAudioEnvironment_ControllerBase> ControllerClass;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    float BGMTransitionTime = 1.0f;
};
```

## Report Template

```markdown
# MetaSound Integration: {Feature}

## Sounds Required
| Sound | Type | Usage | Trigger |
|-------|------|-------|---------|
| {Sound} | {MetaSound/Cue} | {Usage} | {When triggered} |

## Control Buses
| Bus | Range | Controls |
|-----|-------|----------|
| {Bus} | {0-1} | {What it modulates} |

## Environment Tags
| Tag | Controller | BGM |
|-----|------------|-----|
| {Tag} | {Controller class} | {BGM asset} |

## State Tree Events
| Event Tag | Triggers |
|-----------|----------|
| {Tag} | {What happens} |

## Generated Code
{Code snippets}

## Asset Requirements
- MetaSounds: {List}
- Control Bus Mixes: {List}
- Data Assets: {List}
```

## Console Commands

| Command | Purpose |
|---------|---------|
| `au.Debug.Sounds` | Show active sounds |
| `au.Debug.SoundCues` | Debug sound cues |
| `au.3dVisualize.Enabled 1` | Visualize 3D audio |
| `AudioModulation.Debug` | Debug modulation |
