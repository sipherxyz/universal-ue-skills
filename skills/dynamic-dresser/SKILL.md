---
name: dynamic-dresser
description: Open Dynamic Dresser tool for VFX/Blueprint asset collection, tagging, preview, and level placement
---

# Dynamic Dresser Tool

**Category:** Level & World (Green accent)
**Plugin:** `Plugins/EditorTools/SipherDynamicDresser/`
**Engine:** Unreal Engine 5.7.1
**Platform:** Editor-only (Win64)

## Overview

Dynamic Dresser is a set dressing tool for VFX artists and level designers. It streamlines the workflow of:
1. Collecting VFX (Niagara) and Blueprint assets
2. Organizing them with customizable tags
3. Previewing with real-time parameter tweaking
4. Dragging to level with applied parameters

## Quick Start

**Open the tool:**
- Tool Hub > Level & World > Dynamic Dresser
- Or console: `SipherDynamicDresser.Open`

## Features

### 1. Asset Collection

**Add assets via:**
- **Drag-drop** from Content Browser to the asset list
- **Add button** - Opens asset picker (filters to Niagara + Blueprint)
- **Folder button** - Scans a content folder with Select All/None options

**Supported asset types:**
- `NiagaraSystem` - VFX effects
- `Blueprint` - Actor-based blueprints only

### 2. Tag System

Tags are defined in `Config/Tags.md` (markdown format):

```markdown
# Dynamic Dresser Tags

| ID | Display | Color |
|----|---------|-------|
| ene | Enemy | #E74C3C |
| boss | Boss | #9B59B6 |
| env_bg | Env Background | #27AE60 |
| env_event | Env Event | #3498DB |
```

**Features:**
- **Auto-refresh**: Edit `Tags.md` and UI updates automatically
- **Toggle chips**: Click tag buttons in filter bar to filter
- **Per-asset tags**: Click tag chips on each asset row to toggle
- **Max 32 tags** (uint32 bitmask)

### 3. 3D Preview

- **Orbit camera**: LMB + drag to orbit, RMB + drag to pan, scroll to zoom
- **Ground grid**: Visual reference plane
- **Auto-focus**: Camera centers on spawned asset

**Preview types:**
- **Niagara**: Spawns `UNiagaraComponent` in preview scene
- **Blueprint**: Spawns transient actor instance

### 4. Parameter Panel

- Shows `IDetailsView` for the preview object
- **Niagara**: Edit component properties (User Parameters, etc.)
- **Blueprint**: Edit actor properties (EditAnywhere, BlueprintReadWrite)
- **Real-time updates**: Changes reflect immediately in preview

### 5. Preset System

**Save presets:**
1. Modify parameters in the panel
2. Click **Save** button
3. Enter preset name
4. Saved to `Saved/DynamicDresser/Presets/{AssetName}_{PresetName}.json`

**Load presets:**
1. Select an asset
2. Click **Load** button
3. Choose from available presets for that asset

**Reset:**
- Click **Reset** to restore CDO defaults

### 6. Drag to Level

1. Select asset in list
2. Modify parameters as needed
3. Drag from asset row to level viewport
4. Actor spawns at drop location with applied parameters

**Drag decorator shows:**
- Asset thumbnail
- Asset name
- Number of modified properties

## UI Layout

```
+-------------------------+-----------------------------------+
| FILTERS                 |                                   |
| [All][ene][boss]...     |      3D PREVIEW VIEWPORT          |
+-------------------------+                                   |
| ASSETS                  |                                   |
| +---------------------+ +-----------------------------------+
| | NS_Fire      [ene]  | | PARAMETERS                        |
| | BP_Torch  [env_bg]  | | +- Property1: [value]             |
| | NS_Smoke    [boss]  | | +- Property2: [value]             |
| +---------------------+ |                                   |
|                         | PRESETS                           |
| [+ Add] [+ Folder]      | [Save] [Load] [Reset]             |
| -- Drop zone --         |                                   |
+-------------------------+-----------------------------------+
```

## File Structure

```
Plugins/EditorTools/SipherDynamicDresser/
+-- SipherDynamicDresser.uplugin
+-- Config/
|   +-- Tags.md                    # Tag definitions
+-- Source/SipherDynamicDresser/
    +-- Public/
    |   +-- SipherDynamicDresserModule.h
    |   +-- DynamicDresserTypes.h
    |   +-- DynamicDresserTagManager.h
    |   +-- DynamicDresserPresetManager.h
    |   +-- UI/
    |   |   +-- SDynamicDresserWindow.h
    |   |   +-- SDynamicDresserAssetList.h
    |   |   +-- SDynamicDresserPreview.h
    |   |   +-- SDynamicDresserParams.h
    |   |   +-- SDynamicDresserFolderPicker.h
    |   |   +-- FDynamicDresserPreviewClient.h
    |   +-- Drag/
    |       +-- FDynamicDresserDragDropOp.h
    +-- Private/
        +-- [Implementation files]
```

## Key Classes

| Class | Purpose |
|-------|---------|
| `FSipherDynamicDresserModule` | Module + `ISipherToolProvider` registration |
| `FDynamicDresserTagManager` | Parses `Tags.md`, watches for changes |
| `FDynamicDresserPresetManager` | Save/load JSON presets |
| `SDynamicDresserWindow` | Main split-panel UI |
| `SDynamicDresserAssetList` | Left panel asset list with drag-drop |
| `SDynamicDresserPreview` | 3D viewport (`SEditorViewport` + `FGCObject`) |
| `SDynamicDresserParams` | Parameter panel (`IDetailsView`) |
| `FDynamicDresserDragDropOp` | Custom drag operation with modified properties |

## Data Types

```cpp
// Tag definition (from Tags.md)
struct FDynamicDresserTagDef
{
    FString TagId;           // "ene", "boss"
    FString DisplayName;     // "Enemy", "Boss"
    FLinearColor Color;      // Chip color
    uint32 BitValue;         // 1, 2, 4, 8...
};

// Asset entry in the list
struct FDynamicDresserAssetEntry
{
    FSoftObjectPath AssetPath;
    FString DisplayName;
    FTopLevelAssetPath AssetClass;
    uint32 TagMask;          // Bitmask of applied tags
    TSharedPtr<FAssetThumbnail> Thumbnail;
};

// Saved preset
struct FDynamicDresserPreset
{
    FString PresetName;
    FSoftObjectPath AssetPath;
    TMap<FName, FString> PropertyValues;  // Serialized via FProperty
};
```

## Console Commands

```
SipherDynamicDresser.Open    # Open the tool window
```

## Dependencies

```cpp
// SipherDynamicDresser.Build.cs
PublicDependencyModuleNames.AddRange({
    "Core", "CoreUObject", "Engine",
    "Slate", "SlateCore", "InputCore",
    "UnrealEd", "AssetRegistry", "ContentBrowser",
    "PropertyEditor", "AdvancedPreviewScene",
    "Niagara", "NiagaraEditor",
    "SipherToolHub",    // ISipherToolProvider
    "DirectoryWatcher", // Tag file watching
    "Json", "JsonUtilities"
});
```

## Troubleshooting

### Parameters panel is empty
- Ensure you selected an asset in the list
- Check Output Log for spawn errors
- Niagara shows component properties, Blueprint shows actor properties

### Tags not updating
- Verify `Config/Tags.md` syntax (markdown table format)
- Check Output Log for parse errors
- File watcher may have 1-2 second delay

### Drag-to-level not working
- Ensure viewport is in focus
- Check if asset is valid (not corrupted)
- Modified properties only apply to matching FProperty names

### Preview not showing
- Check Output Log for asset loading errors
- Blueprint must be Actor-based (not UObject-only)
- Niagara system must be valid and compilable

## Legacy Metadata

```yaml
skill: dynamic-dresser
invoke: /editor-tools:dynamic-dresser
type: utility
category: level-world
scope: Plugins/EditorTools/SipherDynamicDresser
```
