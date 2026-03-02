---
name: ue-open-level-full-load
description: Open a level in UE Editor with full Data Layer and Level Instance loading based on selected realm
---

# Sipher Realm Loader - Unified Level & Realm Management

**Role:** Editor Tools Engineer
**Target Users:** Level Designers, Artists, QA (non-technical)
**Scope:** Editor-only tool (Slate Widget in Tool Hub)
**Engine Version:** UE 5.7.1
**Quality Standard:** Production-ready, user-friendly UI

## Objective

Unified Editor Tool that combines level loading, realm configuration, runtime grid checking, and bug screenshot capture into a single panel accessible from the Sipher Tool Hub.

**Integrated Features:**
- **Level Selection** - Open levels from dropdown (configured via locations.md)
- **Realm Selection** - Enable Data Layers for selected realm (Default, Dream, Limbo, Cinematic)
- **Data Layer Checkboxes** - Fine-grained control over individual Data Layers
- **Runtime Grid Checker** - Scan and fix invalid RuntimeGrid assignments
- **Bug Screenshot Capture** - Capture 16 diagnostic screenshots at BugItGo location

**Use Cases:**
- Quick level loading with correct realm configuration
- Testing specific realm setups without manual Data Layer toggling
- Consistent Data Layer state for QA reproduction
- Finding and fixing invalid RuntimeGrid actor assignments
- Capturing diagnostic screenshots for QA bug reports

---

## Plugin Location

```
Plugins/EditorTools/SipherRealmLoader/
├── Source/SipherRealmLoader/
│   ├── Public/
│   │   ├── SipherRealmLoaderTypes.h        # Core data types
│   │   ├── SipherRealmLoaderConfigCache.h  # Config parsing
│   │   ├── SSipherRealmLoaderPanel.h       # Main UI panel
│   │   ├── SipherRuntimeGridChecker.h      # Grid validation
│   │   ├── SipherScreenshotCapture.h       # Screenshot capture
│   │   └── SipherRealmStreamingHelper.h    # Data Layer helpers
│   └── Private/
│       └── [corresponding .cpp files]
└── SipherRealmLoader.uplugin
```

---

## Configuration Files

> **Config files location:** `../analyze-frame-bugitgo/config/`

| File | Purpose |
|------|---------|
| [data_layer_rules.md](../../../qa-testing/skills/analyze-frame-bugitgo/config/data_layer_rules.md) | Data Layer enable/disable rules per realm |
| [locations.md](../../../qa-testing/skills/analyze-frame-bugitgo/config/locations.md) | Level shortcut mapping |

---

## Usage

### Access the Tool

The Sipher Realm Loader is accessible from:
- **Sipher Tool Hub** (main toolbar button)
- **Tools Menu** > Sipher Tools > Realm Loader

### Level Selection

1. Select a level from the Level dropdown (populated from locations.md)
2. Click "Open" to load the level
3. Click the search icon to show the level in Content Browser

### Realm Selection

1. Select a realm from the Realm dropdown (Default, Dream, Limbo, Cinematic)
2. Data Layer checkboxes update automatically based on realm rules
3. Check/uncheck individual Data Layers for fine-grained control
4. Click "Load Realm" to apply the Data Layer configuration

### Runtime Grid Checker

1. Click "Check Grids" to scan all actors for invalid RuntimeGrid assignments
2. If issues found, click "Fix All" to clear invalid grids and save

### Bug Screenshot Capture

1. Enter Issue Code (e.g., BUGFIX-1234)
2. Enter BugItGo coordinates from QA (e.g., BugItGo -58230.5 5626.0 -704.2 -34.5 -152.5 0.0)
3. Click "Capture Bug Screenshots" to capture 16 diagnostic screenshots

---

## UI Layout

```
┌─────────────────────────────────────────────────────┐
│  [Level Icon] Level                                  │
├─────────────────────────────────────────────────────┤
│  Level:  [▼ loc1 - SonDoong         ] [Open][🔍]   │
├─────────────────────────────────────────────────────┤
│  [World Icon] Realm & Data Layers                    │
├─────────────────────────────────────────────────────┤
│  Realm:  [▼ Default                 ]               │
│                                                      │
│  Data Layers (8 selected):  [Select All][Clear All] │
│  ┌─────────────────────────────────────────────────┐│
│  │ ☑ DL_Default                                    ││
│  │ ☑ DL_Fixed_Collision                            ││
│  │ ☑ DL_Default_Audio                              ││
│  │ ... (scrollable)                                ││
│  └─────────────────────────────────────────────────┘│
│                                                      │
│  [Load Realm]  [Unload All]  [Refresh Config]        │
│  Status: Ready                                       │
├─────────────────────────────────────────────────────┤
│  [Grid Icon] Runtime Grid Checker                    │
├─────────────────────────────────────────────────────┤
│  [Check Grids]  [Fix All]                            │
│  Click 'Check Grids' to scan for invalid assignments │
│  ▶ Grid Issues (expandable)                          │
├─────────────────────────────────────────────────────┤
│  [Camera Icon] Bug Screenshot Capture                │
├─────────────────────────────────────────────────────┤
│  Issue Code:  [BUGFIX-1234                      ]   │
│  BugItGo:     [BugItGo X Y Z Pitch Yaw Roll     ]   │
│                                                      │
│  [Capture Bug Screenshots]                           │
│  Enter issue code and BugItGo coordinates...         │
└─────────────────────────────────────────────────────┘
```

---

## Examples

### Open Level with Default Realm
```
1. Select "loc1 - SonDoong" from Level dropdown
2. Click "Open" button
3. Select "Default" from Realm dropdown
4. Click "Load Realm" button
```

### Check and Fix Runtime Grids
```
1. Load a level (as above)
2. Click "Check Grids" button
3. Review issues in the expandable list
4. Click "Fix All" to clear invalid assignments and save
```

### Capture Bug Screenshots
```
1. Load the level mentioned in the bug report
2. Enter the issue code: BUGFIX-1234
3. Enter BugItGo: BugItGo -58230.5 5626.0 -704.2 -34.5 -152.5 0.0
4. Click "Capture Bug Screenshots"
5. Screenshots saved to: Saved/BugScreenshots/
```

---

## Core Classes

### SSipherRealmLoaderPanel
Main UI panel widget containing all sections.

### FSipherRealmLoaderConfigCache
Singleton that parses configuration from markdown files:
- `GetRealmConfigs()` - Returns realm configurations
- `GetLevelShortcuts()` - Returns level shortcut mappings
- `ResolveLevelPath()` - Resolves shortcut to full level path

### FSipherRuntimeGridChecker
Static helper for runtime grid validation:
- `CheckRuntimeGrids()` - Scan for invalid grid assignments
- `FixAndSaveIssues()` - Clear invalid grids and save packages
- `GetSipherGridNames()` - Get valid Sipher grid names

### FSipherScreenshotCapture
Static helper for viewport screenshot capture:
- `ExecuteBugItGo()` - Position camera from BugItGo coordinates
- `CaptureAll()` - Capture all 16 diagnostic screenshots
- `GetDefaultConfigs()` - Get screenshot configuration list

---

## Screenshot Configurations

The tool captures 16 diagnostic screenshots:

| Order | Filename | View Mode | Description |
|-------|----------|-----------|-------------|
| 1 | 001_Game_Epic.jpg | Game_Epic | Game view at Epic quality |
| 2 | 002_Game_High.jpg | Game_High | Game view at High quality |
| 3 | 003_Game_Low.jpg | Game_Low | Game view at Low quality |
| 4 | 004_PBR_Color.jpg | PBR_Color | Base Color buffer |
| 5 | 005_PBR_Emissive.jpg | PBR_Emissive | Emissive buffer |
| 6 | 006_PBR_Normal.jpg | PBR_Normal | World Normal buffer |
| 7 | 007_PBR_AO.jpg | PBR_AO | Ambient Occlusion buffer |
| 8 | 008_PBR_AO_Mtl.jpg | PBR_AO_Mtl | Material AO channel |
| 9 | 009_PBR_Rough.jpg | PBR_Rough | Roughness buffer |
| 10 | 010_PBR_Spec.jpg | PBR_Spec | Specular buffer |
| 11 | 011_PBR_Metallic.jpg | PBR_Metallic | Metallic buffer |
| 12 | 012_Collision_Grid.jpg | Collision_Grid | Collision wireframe grid |
| 13 | 013_Collision_Types.jpg | Collision_Types | Color-coded collision volumes |
| 14 | 014_NavMesh_On.jpg | NavMesh_On | Navigation mesh visible |
| 15 | 015_NavMesh_Off.jpg | NavMesh_Off | Navigation mesh hidden |
| 16 | 016_Lit_Final.jpg | Lit | Final lit view |

---

## Error Handling

| Error Type | Behavior |
|------------|----------|
| Level not found | Display error in Status, abort |
| Level crash on load | Display error in Status, abort |
| Data Layer not found | Log warning, skip layer, continue |
| Invalid BugItGo format | Display error, abort capture |
| Grid fix failed | Log warning, continue with next |
| Screenshot failed | Log warning, continue with next |

---

## Integration with Other Skills

### open-editor
```
/open-editor
# After editor opens, use the Realm Loader from Tool Hub
```

### analyze_frame_from_bugitgo_request
The Bug Screenshot Capture feature is an integrated version of the analyze_frame_from_bugitgo_request skill. For the full automated workflow including git checkout and material validation, use:
```
/qa-testing:analyze-frame-bugitgo BUGFIX-1234 "BugItGo ..." loc1 main Default
```

---

## Notes

- Windows-specific (Slate Widget)
- Config files shared with `analyze_frame_from_bugitgo` skill
- First run on level slower (shader cache cold)
- Screenshots saved to `Saved/BugScreenshots/` by default
- RuntimeGrid fixer modifies and saves actor packages directly

## Legacy Metadata

```yaml
skill: ue-open-level-full-load
invoke: /editor-tools:ue-open-level-full-load
type: implementation
category: editor-tools
scope: Plugins/EditorTools/SipherRealmLoader/
```
