# Animation Notify Reference

Comprehensive reference for animation notify classes used in analysis.

## Engine Built-in Notifies

### Audio

| Class | Description | Parameters |
|-------|-------------|------------|
| `AnimNotify_PlaySound` | Play sound at notify | USoundBase* Sound |
| `AnimNotify_PlaySoundAtLocation` | Play sound at location | USoundBase*, FVector |

### VFX

| Class | Description | Parameters |
|-------|-------------|------------|
| `AnimNotify_PlayNiagaraEffect` | One-shot Niagara system | UNiagaraSystem*, Socket |
| `AnimNotifyState_TimedNiagaraEffect` | Duration-based Niagara | UNiagaraSystem*, Duration |
| `AnimNotify_PlayParticleEffect` | Legacy Cascade effect | UParticleSystem* |
| `AnimNotifyState_Trail` | Weapon trail effect | Start/End sockets |

### Physics

| Class | Description |
|-------|-------------|
| `AnimNotify_ResetDynamics` | Reset physics simulation |
| `AnimNotify_ResetClothingSimulation` | Reset cloth simulation |

### Gameplay

| Class | Description |
|-------|-------------|
| `AnimNotify_SendGameplayEvent` | Send GAS event |
| `AnimNotify_PlayMontageNotify` | Montage notify event |
| `AnimNotifyState_DisableRootMotion` | Disable root motion |

---

## S2 Project Custom Notifies

### Foley System

All project foley notifies inherit from `AN_S2_Foley_Base`.

| Class | Purpose | Ground Detection |
|-------|---------|------------------|
| `AN_S2_Foley_Walk_L` | Left foot walk | Yes |
| `AN_S2_Foley_Walk_R` | Right foot walk | Yes |
| `AN_S2_Foley_Run_L` | Left foot run | Yes |
| `AN_S2_Foley_Run_R` | Right foot run | Yes |
| `AN_S2_Foley_Sprint_L` | Left foot sprint | Yes |
| `AN_S2_Foley_Sprint_R` | Right foot sprint | Yes |
| `AN_S2_Foley_Sprint_Stop` | Sprint stop | Yes |
| `AN_S2_Foley_Jump` | Jump takeoff | No |
| `AN_S2_Foley_Land` | Landing | Yes |
| `AN_S2_Foley_Fall` | Falling loop | No |
| `AN_S2_Foley_Scuff_L` | Left scuff | Yes |
| `AN_S2_Foley_Scuff_R` | Right scuff | Yes |
| `AN_S2_Foley_Handplant_L` | Left hand plant | Yes |
| `AN_S2_Foley_Handplant_R` | Right hand plant | Yes |
| `AN_S2_Foley_DetectGround` | Manual ground detect | Yes |

### Voice System

| Class | Purpose | Event Type |
|-------|---------|------------|
| `AN_S2_Voice` | Base voice notify | Generic |
| `AN_S2_Voice_Attack` | Attack vocalization | Combat |
| `AN_S2_Voice_GetHit` | Hit reaction voice | Damage |

### Combat System

| Class | Purpose | Parameters |
|-------|---------|------------|
| `SipherAbilityNotifyData_Hitbox` | Hitbox activation | Shape, Size, Duration |
| `DamageShape_Sphere` | Spherical damage area | Radius |
| `DamageShape_Box` | Box damage area | Extent |
| `DamageShape_Capsule` | Capsule damage area | Radius, HalfHeight |

### Movement System

| Class | Purpose | Parameters |
|-------|---------|------------|
| `BP_NotifyState_MotionWarping` | Motion warping window | Target, Settings |

### Camera System

| Class | Purpose | Parameters |
|-------|---------|------------|
| `BP_CameraShake_*` | Camera shake preset | Intensity, Duration |

---

## Detection Heuristics

When exact class matching fails, use these heuristics:

### Audio Detection
- Names containing `Sound` or `Audio` → Likely audio notify
- Names containing `Foley` → Foley system
- Names containing `Voice` → Voice system
- Names containing `SFX` → Sound effect

### VFX Detection
- Names containing `Niagara` → Niagara VFX
- Names containing `Particle` → Cascade or Niagara
- Names containing `VFX` or `FX` → Visual effect
- Names containing `Trail` → Trail effect

### Combat Detection
- Names containing `Hitbox` → Hitbox notify
- Names containing `Damage` → Damage system
- Names containing `DamageShape` → Damage shape
- Names containing `Impact` → Impact type

### Movement Detection
- Names containing `MotionWarp` or `Warping` → Motion warping
- Names containing `RootMotion` → Root motion modifier

### Camera Detection
- Names containing `CameraShake` or `Shake` → Camera effect
- Names containing `Camera` and `Effect` → Camera effect

---

## Notify State vs Notify

### AnimNotify (Instant)
- Fires at a single frame
- No duration
- Examples: PlaySound, PlayNiagaraEffect

### AnimNotifyState (Duration)
- Has Begin and End
- Spans multiple frames
- Examples: TimedNiagaraEffect, Trail, MotionWarping

### Detection in Parser
- State notifies often have `State` in class name
- State notifies reference `AnimNotifyState_*`
- Instant notifies reference `AnimNotify_*`

---

## Montage-Specific Notify Patterns

### Attack Montages Should Have
1. At least one `*Hitbox*` notify
2. Audio for swing/whoosh
3. VFX for weapon trail or impact
4. Motion warping (for gap closers)

### Hit Reaction Montages Should Have
1. Voice notify for pain grunt
2. Camera shake (for heavy hits)
3. VFX for impact

### Locomotion Montages Should Have
1. Foley notifies for footsteps
2. Ground detection for surface type

### Death Montages Should Have
1. Voice notify for death sound
2. VFX (if special death)

---

## Validation Rules

### P0 (Critical)
- Attack montage without hitbox notify
- Hitbox notify without matching end (orphaned)
- Missing base animation reference

### P1 (High)
- Attack montage without any audio
- Attack montage without any VFX
- Locomotion without foley notifies

### P2 (Medium)
- Heavy attack without camera shake
- Hit reaction without voice
- Movement without motion warping

### P3 (Low)
- Non-standard notify naming
- Redundant notifies at same time
- Unused notify references
