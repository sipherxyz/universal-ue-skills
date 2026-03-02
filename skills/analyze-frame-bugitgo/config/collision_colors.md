# Collision Type Color Coding

Defines the color scheme for collision volume visualization (screenshot 013).

**[👁 Open color preview in browser](collision_colors_preview.html)** - để xem màu trực quan

---

## Color Mapping

| Collision Type | Hex Color | RGB | Description |
|----------------|-----------|-----|-------------|
| Block All | #FF0000 | 255, 0, 0 | Blocks all traces and physics |
| Block All Dynamic | #FF4400 | 255, 68, 0 | Blocks dynamic objects only |
| Overlap All | #00FF00 | 0, 255, 0 | Overlap events, no blocking |
| Overlap All Dynamic | #00FF88 | 0, 255, 136 | Overlap dynamic only |
| Invisible Wall | #0000FF | 0, 0, 255 | Player blocking, invisible |
| Invisible Wall Dynamic | #4488FF | 68, 136, 255 | Dynamic blocking, invisible |
| Trigger | #FFFF00 | 255, 255, 0 | Trigger volumes |
| Pawn | #FF00FF | 255, 0, 255 | Pawn-specific collision |
| Camera | #00FFFF | 0, 255, 255 | Camera collision only |
| Physics Body | #FF8800 | 255, 136, 0 | Physics simulation bodies |
| Vehicle | #8800FF | 136, 0, 255 | Vehicle collision |
| Destructible | #FF0088 | 255, 0, 136 | Destructible mesh collision |
| No Collision | #808080 | 128, 128, 128 | Collision disabled |
| Custom Channel 1 | #A0522D | 160, 82, 45 | Project-specific channel |
| Custom Channel 2 | #228B22 | 34, 139, 34 | Project-specific channel |

---

## Collision Presets (Huli Project)

| Preset Name | Base Type | Notes |
|-------------|-----------|-------|
| Sipher_PlayerCapsule | Pawn | Player character |
| Sipher_EnemyCapsule | Pawn | Enemy characters |
| Sipher_Projectile | Overlap All | Projectile collision |
| Sipher_Hitbox | Overlap All Dynamic | Combat hitboxes |
| Sipher_Hurtbox | Overlap All Dynamic | Damage receivers |
| Sipher_InteractTrigger | Trigger | Interaction zones |
| Sipher_CameraBoom | Camera | Camera arm collision |
| Sipher_EnvironmentBlock | Block All | Static environment |

---

## Rendering Settings

| Setting | Value |
|---------|-------|
| Opacity | 0.7 |
| Outline | None |
| Wireframe | Off (solid blocks only) |

---

## Notes

- Colors chosen for maximum visual distinction
- Opacity allows seeing overlapping collision volumes
- Custom channels can be added for project-specific needs
- Edit this file to match your project's collision presets
