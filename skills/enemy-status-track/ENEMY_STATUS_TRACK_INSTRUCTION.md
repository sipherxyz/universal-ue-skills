# Enemy Status Tracking Workflow

## Overview

This workflow audits enemy content folders and maintains the `enemy_status_tracker.md` spreadsheet at project root.

---

## Phase 1: Asset Discovery

### Step 1.1: Identify Target Enemy

For a specific enemy:
```powershell
Get-ChildItem -Path "Content/S2/Core_Ene" -Directory -Filter "*{enemy_name}*"
Get-ChildItem -Path "Content/S2/Core_Boss" -Directory -Filter "*{enemy_name}*"
```

For all enemies:
```powershell
Get-ChildItem -Path "Content/S2/Core_Ene" -Directory | Select-Object Name
Get-ChildItem -Path "Content/S2/Core_Boss" -Directory | Select-Object Name
```

### Step 1.2: Scan Folder Structure

For each enemy folder, check these subdirectories:

```powershell
$enemy = "{enemy_folder_path}"

# List all subfolders
Get-ChildItem -Path $enemy -Directory -Recurse | Select-Object FullName
```

Expected structure:
```
{enemy_id}/
├── Anim/           # Animation sequences and montages
│   ├── Attack/     # Attack animations
│   ├── HitReact/   # Hit reaction animations
│   ├── Death/      # Death animations
│   └── Loco/       # Locomotion (walk, run, idle)
├── Montage/        # Animation montages (alternative location)
├── AI/             # Behavior Trees, State Trees
├── VFX/            # Niagara systems
├── Audio/          # Sound assets
├── Mesh/           # Skeletal mesh
└── BP_*.uasset     # Blueprint actors
```

---

## Phase 2: Category Detection

### Death Animation

Search patterns:
```powershell
$enemy = "{enemy_folder_path}"
Get-ChildItem -Path $enemy -Recurse -Filter "*Death*.uasset" | Select-Object Name
Get-ChildItem -Path $enemy -Recurse -Filter "*Die*.uasset" | Select-Object Name
```

Mark `Y` if any death montage or sequence found.

### HitReact

Search patterns:
```powershell
Get-ChildItem -Path $enemy -Recurse -Filter "*HitReact*.uasset" | Select-Object Name
Get-ChildItem -Path $enemy -Recurse -Filter "*Stagger*.uasset" | Select-Object Name
Get-ChildItem -Path $enemy -Recurse -Filter "*Flinch*.uasset" | Select-Object Name
Get-ChildItem -Path $enemy -Recurse -Filter "*Knockdown*.uasset" | Select-Object Name
```

Mark `Y` if any hit reaction found.

### Attack

Search patterns:
```powershell
Get-ChildItem -Path $enemy -Recurse -Filter "*Attack*.uasset" | Select-Object Name
Get-ChildItem -Path $enemy -Recurse -Filter "*Combo*.uasset" | Select-Object Name
Get-ChildItem -Path $enemy -Recurse -Filter "AMT_*.uasset" | Select-Object Name
Get-ChildItem -Path "$enemy/Anim/Attack" -ErrorAction SilentlyContinue | Measure-Object
```

Mark `Y` if any attack montage found.

### Locomotion

Search patterns:
```powershell
Get-ChildItem -Path $enemy -Recurse -Filter "*Loco*.uasset" | Select-Object Name
Get-ChildItem -Path $enemy -Recurse -Filter "BS_*.uasset" | Select-Object Name  # BlendSpaces
Get-ChildItem -Path $enemy -Recurse -Filter "*Walk*.uasset" | Select-Object Name
Get-ChildItem -Path $enemy -Recurse -Filter "*Run*.uasset" | Select-Object Name
Get-ChildItem -Path $enemy -Recurse -Filter "*Idle*.uasset" | Select-Object Name
```

Mark `Y` if locomotion assets found.

### Blueprint

Search patterns:
```powershell
Get-ChildItem -Path $enemy -Filter "BP_*.uasset" | Select-Object Name
Get-ChildItem -Path $enemy -Recurse -Filter "BP_*.uasset" | Select-Object Name
```

Mark `Y` if Blueprint actor found.

### AI

Search patterns:
```powershell
Get-ChildItem -Path $enemy -Recurse -Filter "BT_*.uasset" | Select-Object Name  # Behavior Tree
Get-ChildItem -Path $enemy -Recurse -Filter "ST_*.uasset" | Select-Object Name  # State Tree
Get-ChildItem -Path "$enemy/AI" -ErrorAction SilentlyContinue | Measure-Object
```

Mark `Y` if AI assets found.

### VFX

Search patterns:
```powershell
Get-ChildItem -Path $enemy -Recurse -Filter "NS_*.uasset" | Select-Object Name  # Niagara System
Get-ChildItem -Path $enemy -Recurse -Filter "NE_*.uasset" | Select-Object Name  # Niagara Emitter
Get-ChildItem -Path "$enemy/VFX" -ErrorAction SilentlyContinue | Measure-Object
```

Mark `Y` if VFX assets found.

### SFX

Search patterns:
```powershell
Get-ChildItem -Path $enemy -Recurse -Filter "*Sound*.uasset" | Select-Object Name
Get-ChildItem -Path $enemy -Recurse -Filter "*Audio*.uasset" | Select-Object Name
Get-ChildItem -Path "$enemy/Audio" -ErrorAction SilentlyContinue | Measure-Object
Get-ChildItem -Path "$enemy/SFX" -ErrorAction SilentlyContinue | Measure-Object
```

Mark `Y` if audio assets found.

---

## Phase 3: Update Tracker

### Step 3.1: Read Current Tracker

```
Read enemy_status_tracker.md
```

### Step 3.2: Update Row

Find the enemy row and update columns:

```markdown
| s2_eli_beast_01A | Y | Y | Y | Y | Y | Y | Y | Y | WIP | Updated 2025-12-26 |
```

Format: `| Enemy | Death | HitReact | Attack | Loco | BP | AI | VFX | SFX | Status | Notes |`

### Step 3.3: Add New Enemy

If enemy not in tracker, add new row in correct section:
- `Core_Ene` section for regular/elite enemies
- `Core_Boss` section for boss enemies

---

## Phase 4: Generate Report

### Missing Asset Report

For each category marked `-`:

```markdown
## Missing Assets: {enemy_id}

### Death Animation
- **Status:** Missing
- **Required:** Death animation montage
- **Owner:** Animation Team

### SFX
- **Status:** Missing
- **Required:** Attack whoosh, impact sounds, voice lines
- **Owner:** Audio Team
```

### Summary Statistics

```markdown
## Enemy Content Summary

| Category | Complete | Missing | % Coverage |
|----------|----------|---------|------------|
| Death | 12 | 65 | 15.6% |
| HitReact | 45 | 32 | 58.4% |
| Attack | 52 | 25 | 67.5% |
| ...
```

---

## Common Workflows

### Update Single Enemy

1. User specifies enemy name
2. Locate folder in Core_Ene or Core_Boss
3. Run all category checks
4. Update tracker row
5. Report changes

### Find Enemies Missing Specific Asset

1. Read tracker
2. Filter by column value `-`
3. List affected enemies
4. Group by folder (Core_Ene vs Core_Boss)

### Full Audit

1. Get all enemy folders
2. For each folder, run category checks
3. Compare against tracker
4. Update discrepancies
5. Generate summary report

---

## Output Locations

- **Tracker:** `enemy_status_tracker.md` (project root)
- **Reports:** `claude-agents/reports/enemy-status/` (optional detailed reports)

---

## Integration

### With boss-review
Run `/boss-review` for detailed boss audit after status tracking identifies gaps.

### With read-uasset
Use `/read-uasset` to inspect montage contents when verifying asset quality.
