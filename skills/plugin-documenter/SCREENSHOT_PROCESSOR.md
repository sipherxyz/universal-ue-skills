# Screenshot Processor Workflow

When user says "Process screenshots for {PluginName}":

## Step 1: Find Input Screenshots

```
Path: claude-agents/docs/plugins/{PluginName}/images/input/
Extensions: .png, .jpg, .jpeg, .gif, .webp
```

## Step 2: Analyze Each Image

For each screenshot, use the Read tool to view it and determine:

1. **Category**: Which section does it belong to?
   - `menu` - Right-click menus, context menus
   - `dialog` - Main plugin window/dialog
   - `settings` - Project Settings panels
   - `section` - Specific UI sections (expandable areas)
   - `button` - Button focus shots
   - `workflow` - Step-by-step action shots
   - `preset` - Preset creation/editing

2. **Subcategory**: More specific identification
   - For `dialog`: overview, tabs, status-bar
   - For `section`: bones, virtual-bones, sockets, curves, compatible
   - For `settings`: main, bones-array, presets
   - For `workflow`: before, after, step-N

3. **Content**: What specific UI elements are visible?

## Step 3: Generate Filename

Pattern: `{sequence}-{category}-{subcategory}.png`

Examples:
- `01-menu-rightclick.png`
- `10-dialog-overview.png`
- `20-section-bones.png`
- `40-settings-main.png`

## Step 4: Move and Rename

Move from `input/` to parent `images/` folder with new name.

## Step 5: Update Documentation

Find all placeholders in .md files matching pattern:
```
> **Screenshot**: {description}
```

Replace with:
```
![{description}](images/{filename})
```

## Step 6: Report Results

Output a summary:
```
Processed X screenshots:
- filename.png → 01-menu-rightclick.png (matched to GETTING_STARTED.md)
- another.png → 10-dialog-overview.png (matched to OVERVIEW.md)
- ...

Remaining placeholders (no matching screenshot):
- "Project Settings showing plugin section" in PARAMETERS.md
```

---

## Matching Logic

### Menu Screenshots
Look for: context menu, right-click menu, dropdown options
Match to: GETTING_STARTED.md step 2, OVERVIEW.md Quick Access

### Dialog Overview
Look for: full window with preset dropdown, sections, buttons
Match to: GETTING_STARTED.md step 3, OVERVIEW.md "What It Looks Like"

### Section Screenshots
Look for: expandable areas with lists of items, checkboxes, status colors
Match to: GETTING_STARTED.md step 4, PARAMETERS.md sections

### Settings Screenshots
Look for: Project Settings window, category tree, property fields
Match to: PARAMETERS.md "Project Settings" section

### Preset Screenshots
Look for: Data Asset editor, preset fields, template section
Match to: WORKFLOWS/create-preset.md

### Workflow Screenshots
Look for: sequential actions, before/after states
Match to: WORKFLOWS/*.md step sections
