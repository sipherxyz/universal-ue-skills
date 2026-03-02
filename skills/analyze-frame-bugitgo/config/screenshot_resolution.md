# Screenshot Resolution Settings

Defines the resolution and quality settings for captured screenshots.

---

## Resolution

### Game View (Lit) - 2K

| Setting | Value | Notes |
|---------|-------|-------|
| Width | 2560 | Pixels |
| Height | 1440 | Pixels |
| DPI | 96 | Standard screen DPI |
| Format | JPEG | Smaller file size than PNG |
| Quality | 100 | JPEG quality (1-100) |

### Debug Views (Buffer Visualization) - 1K

| Setting | Value | Notes |
|---------|-------|-------|
| Width | 1920 | Pixels |
| Height | 1080 | Pixels |
| DPI | 96 | Standard screen DPI |
| Format | JPEG | Smaller file size than PNG |
| Quality | 90 | JPEG quality (1-100) |

---

## Scalability Presets

Used for Game View screenshots (001-003).

| Preset | UE Command | Description |
|--------|------------|-------------|
| Epic | `sg.PostProcessQuality 3` | Maximum quality |
| High | `sg.PostProcessQuality 2` | High quality |
| Low | `sg.PostProcessQuality 0` | Performance mode |

---

## View Mode Commands

| View Mode | UE Console Command |
|-----------|-------------------|
| Base Color | `ViewMode BaseColor` |
| Emissive | `ViewMode Emissive` |
| World Normal | `ViewMode WorldNormal` |
| Ambient Occlusion | `ViewMode AmbientOcclusion` |
| Material AO | `ViewMode MaterialAO` |
| Roughness | `ViewMode Roughness` |
| Specular | `ViewMode Specular` |
| Metallic | `ViewMode Metallic` |
| Lit (Game View) | `ViewMode Lit` |

---

## Notes

- Resolution should match common monitor sizes for easy viewing
- JPEG quality 90 balances file size and visual fidelity
- Can increase to 4K (3840x2160) if needed for detailed inspection
