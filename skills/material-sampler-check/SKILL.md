---
name: material-sampler-check
description: Guide to run Material Sampler Fixer tool before committing material changes
---

# Material Sampler Type Check - Pre-Commit Guide

**Purpose:** Ensure material instances have correct sampler types before committing changes via Git Fork

## When to Run This Check

Run the Material Sampler Fixer tool **before committing** when your changes include:
- Material Instances (`.uasset` files in Materials folders)
- Texture assignments to materials
- Any assets that reference materials

## How to Run the Tool

### Method 1: Tool Hub (Recommended)

1. Open Unreal Editor
2. Press `Ctrl+Shift+H` to open **Sipher Tool Hub**
3. Search for "**Material Sampler Fixer**" or find it under **Utility** category
4. Click to launch the tool

### Method 2: Direct Keyboard Shortcut

1. Open Unreal Editor
2. Press `Ctrl+Shift+M` to open Material Sampler Fixer directly

## Using the Tool

### Step 1: Select Folder to Scan

1. Click **Browse...** button
2. Navigate to your project's Content folder: `F:\s2\Content`
3. Or select a specific subfolder if you know where your changed materials are

### Step 2: Scan for Issues

1. Click **Scan Materials** button
2. Wait for the scan to complete (progress bar shows status)
3. Review the list of mismatches found

### Step 3: Understanding the Results

Each row shows:
| Column | Description |
|--------|-------------|
| Status Icon | Red = unfixed, Green = fixed |
| Material Name | The material instance with issues |
| Parameter | The texture parameter slot name |
| Expected Type | What the parent material expects (e.g., Normal, Color) |
| Actual Type | What the assigned texture actually is |

### Step 4: Fix Issues

**Option A: Fix All**
- Click **Fix All** button to replace all mismatched textures with appropriate placeholders

**Option B: Fix Selected**
- Select specific items in the list
- Click **Fix Selected** to fix only those

**Option C: Fix Individual**
- Click the **Fix** button on each row

### Step 5: Verify and Save

- If **Auto-save** is checked, materials are saved automatically after fixing
- If unchecked, save the materials manually in Content Browser

## Git Fork Workflow

### Before Staging Files

1. Open Unreal Editor
2. Run Material Sampler Fixer (`Ctrl+Shift+M`)
3. Scan the Content folder
4. Fix any issues found
5. Close Unreal Editor (or save all)

### In Git Fork

1. Open Git Fork
2. Go to **Local Changes** tab
3. Review your changed files
4. Look for any `.uasset` files in Materials folders
5. If material files are present, ensure you ran the tool
6. Stage your files
7. Write commit message
8. Commit

## Common Sampler Type Mismatches

| Issue | Cause | Fix Applied |
|-------|-------|-------------|
| Color texture in Normal slot | Wrong texture assigned | Replaced with DefaultNormal |
| Normal texture in Color slot | Wrong texture assigned | Replaced with DefaultDiffuse |
| sRGB texture in Linear slot | Texture has wrong color space | Replaced with DefaultWhite |
| Virtual texture in non-VT slot | VT/non-VT mismatch | Replaced with matching placeholder |

## Placeholder Textures Used

| Sampler Type | Placeholder |
|--------------|-------------|
| Normal, Virtual Normal | `/Engine/EngineMaterials/DefaultNormal` |
| Color, Linear Color | `/Engine/EngineMaterials/DefaultDiffuse` |
| Masks, Grayscale, Alpha | `/Engine/EngineMaterials/DefaultWhite` |

## Troubleshooting

### Tool not found in Tool Hub
- Ensure the project was compiled after adding the plugin
- Restart Unreal Editor

### Scan finds no materials
- Check that you selected the correct folder
- Ensure the folder contains `.uasset` files

### Fix button doesn't work
- Material may be read-only or locked
- Check if the material is checked out in Perforce (if using)

## Quick Reference

```
Open Tool:     Ctrl+Shift+M  (or Ctrl+Shift+H → search "Material Sampler")
Scan:          Click "Scan Materials" after selecting folder
Fix:           Click "Fix All" or individual "Fix" buttons
Save:          Auto-save enabled by default, or save manually
```

## Commit Checklist

Before committing material changes in Git Fork:

- [ ] Opened Unreal Editor
- [ ] Ran Material Sampler Fixer (Ctrl+Shift+M)
- [ ] Scanned Content folder (or relevant subfolder)
- [ ] Fixed all sampler type mismatches
- [ ] Saved all modified materials
- [ ] Closed Editor or ensured all saves completed
- [ ] Reviewed changes in Git Fork
- [ ] Committed with descriptive message

## Legacy Metadata

```yaml
skill: material-sampler-check
invoke: /qa-testing:material-sampler-check
type: workflow
category: quality-assurance
scope: project-root
```
