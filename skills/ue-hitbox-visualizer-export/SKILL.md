---
name: ue-hitbox-visualizer-export
description: Export hitbox visualization frames to image sequences for combat design review. Capture hitbox timing, position, and coverage across attack animations. Use when reviewing combat hitboxes, documenting attack ranges, or debugging hit detection. Triggers on "hitbox export", "hitbox visualization", "attack frames", "hitbox timing", "combat frames", "hit detection visual".
---

# UE Hitbox Visualizer Export

Export hitbox visualization to image sequences for design review.

## Quick Start

1. Specify character and attack montage
2. Configure capture settings
3. Export frame sequence with hitbox overlay

## Export Workflow

### Step 1: Configure Capture

```markdown
## Capture Configuration

### Target
| Setting | Value |
|---------|-------|
| Character | {CharacterClass} |
| Montage | AMT_{MontageName} |
| Frame Rate | 30 FPS |
| Resolution | 1920x1080 |

### Visualization
| Setting | Value |
|---------|-------|
| Hitbox Color | Red (Active) / Gray (Inactive) |
| Hurtbox Color | Green |
| Show Skeleton | Yes |
| Show Timing | Yes |
| Background | Neutral Gray |
```

### Step 2: Capture Frames

```cpp
// Capture setup
void CaptureHitboxSequence(UAnimMontage* Montage)
{
    // Disable game rendering, enable debug
    GetWorld()->bDebugDrawAllTraceTags = true;

    float Duration = Montage->GetPlayLength();
    float FrameRate = 30.f;
    int32 TotalFrames = FMath::CeilToInt(Duration * FrameRate);

    for (int32 Frame = 0; Frame < TotalFrames; Frame++)
    {
        float Time = Frame / FrameRate;

        // Seek montage to time
        AnimInstance->Montage_SetPosition(Montage, Time);

        // Update hitbox state
        HitboxComponent->DebugDrawHitboxes(World);

        // Capture screenshot
        FString FileName = FString::Printf(TEXT("Frame_%04d.png"), Frame);
        CaptureScreenshot(OutputPath / FileName);
    }
}
```

### Step 3: Generate Timeline

```markdown
## Hitbox Timeline: AMT_{MontageName}

### Frame Data
| Frame | Time | Hitbox Active | Position | Size |
|-------|------|---------------|----------|------|
| 0 | 0.00s | No | - | - |
| 5 | 0.17s | No | - | - |
| 10 | 0.33s | Yes | (100, 0, 50) | R:80 |
| 11 | 0.37s | Yes | (120, 10, 50) | R:80 |
| 12 | 0.40s | Yes | (140, 20, 50) | R:80 |
| 13 | 0.43s | No | - | - |

### Active Frames
- Start Frame: 10 (0.33s)
- End Frame: 12 (0.40s)
- Duration: 3 frames (0.10s)
```

## Visualization Options

### Hitbox Rendering

```cpp
// Draw hitbox as wireframe sphere/capsule/box
void DrawHitbox(const FSipherHitboxData& Hitbox)
{
    FColor Color = Hitbox.bActive ? FColor::Red : FColor::Gray;

    switch (Hitbox.Shape)
    {
    case ESipherHitboxShape::Sphere:
        DrawDebugSphere(World, Hitbox.Location, Hitbox.Radius, 16, Color);
        break;

    case ESipherHitboxShape::Capsule:
        DrawDebugCapsule(World, Hitbox.Location, Hitbox.HalfHeight, Hitbox.Radius, Hitbox.Rotation, Color);
        break;

    case ESipherHitboxShape::Box:
        DrawDebugBox(World, Hitbox.Location, Hitbox.Extent, Hitbox.Rotation, Color);
        break;
    }
}
```

### Overlay Information

```markdown
## Frame Overlay Elements

### Always Visible
- Frame number
- Timestamp
- Hitbox active indicator

### Optional
- Skeleton bones
- Movement vector
- Damage value
- Range circle on ground
```

## Export Formats

### Image Sequence

```
Output/
├── {MontageName}/
│   ├── Frame_0000.png
│   ├── Frame_0001.png
│   ├── ...
│   ├── Frame_0030.png
│   └── metadata.json
```

### Metadata JSON

```json
{
    "montage": "AMT_Player_LightAttack_01",
    "duration": 1.0,
    "frameRate": 30,
    "frames": [
        {
            "index": 10,
            "time": 0.33,
            "hitboxes": [
                {
                    "name": "MainHitbox",
                    "active": true,
                    "position": [100, 0, 50],
                    "radius": 80,
                    "damage": 25
                }
            ]
        }
    ]
}
```

### Video Export

```bash
# FFmpeg command to create video from frames
ffmpeg -framerate 30 -i Frame_%04d.png -c:v libx264 -pix_fmt yuv420p hitbox_visualization.mp4
```

## Analysis Report

```markdown
# Hitbox Analysis: AMT_{MontageName}

## Summary
| Metric | Value |
|--------|-------|
| Total Duration | {N}s |
| Active Frames | {N} ({N}%) |
| Max Hitbox Size | {N} cm |
| Coverage Area | {N} cm² |

## Hitbox Timeline
```
Frame: 0----5----10---15---20---25---30
       ░░░░░░░░░████████░░░░░░░░░░░░░░
       [Startup] [Active] [Recovery]
```

## Active Window Analysis
- **Startup**: 10 frames (0.33s) - Pre-attack animation
- **Active**: 3 frames (0.10s) - Damage can be dealt
- **Recovery**: 17 frames (0.57s) - Post-attack vulnerability

## Spatial Coverage
{Top-down diagram of hitbox sweep area}

## Design Notes
- Hitbox aligns with weapon swing
- Range is {N}cm from character center
- Sweep covers {N}° arc

## Comparison
| Attack | Active Frames | Range | Startup |
|--------|---------------|-------|---------|
| Light 1 | 3 (0.10s) | 80cm | 10 |
| Light 2 | 4 (0.13s) | 90cm | 8 |
| Heavy 1 | 6 (0.20s) | 120cm | 18 |

## Recommendations
1. {Timing adjustment suggestion}
2. {Range adjustment suggestion}
```

## Console Commands

| Command | Purpose |
|---------|---------|
| `SipherHitbox.Debug.Draw 1` | Enable hitbox visualization |
| `SipherHitbox.Debug.ShowInactive 1` | Show inactive hitboxes |
| `SipherHitbox.Debug.ExportFrames` | Trigger frame export |
| `SipherHitbox.Debug.Color R G B` | Set hitbox color |

## Integration

### Montage Export Script

```python
# Python script to batch export all combat montages
import unreal

def export_all_hitbox_visualizations():
    montages = unreal.EditorAssetLibrary.list_assets('/Game/S2/Animation/Combat/', recursive=True)

    for montage_path in montages:
        if 'AMT_' in montage_path:
            export_hitbox_sequence(montage_path)
```

### CI/CD Integration

```yaml
# Run hitbox export on combat animation changes
on:
  push:
    paths:
      - 'Content/**/AMT_*.uasset'

jobs:
  export-hitboxes:
    runs-on: self-hosted
    steps:
      - name: Export Hitbox Visualizations
        run: UnrealEditor-Cmd.exe -run=HitboxExport
```
