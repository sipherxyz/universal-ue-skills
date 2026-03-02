# Bug Screenshot Tool - Technical Specification

## 1. Overview

**Purpose**: Automated tool to capture standardized screenshots at bug locations reported by QA, including multiple view modes, collision visualization, and material validation.

**Target Users**: Artists, Art Leads, Producers (non-technical users)

**Expected Runtime**: Maximum 5-10 minutes per request

**Performance Note**: Do NOT re-checkout branch or re-open UE if unnecessary (e.g., same branch/level as previous run)

**Platform**: Unreal Engine 5.7 (Editor Utility Widget or Standalone App)

---

## 2. Input Parameters

### 2.1 Required Inputs

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| **Git Issue Code** | String | Bug tracking ID or identifier | `BUGFIX-1234`, `ISSUE-5678` |
| **Bug It Go Code** | String | Camera position/rotation from QA playtest | `BugItGo -58230.549394 5626.046468 -704.216648 -34.523047 -152.561813 -0.000000` |
| **Location** | Dropdown/String | Level/map name to load | `loc1`, `loc3`, or custom level name |
| **Branch** | String | Git branch to checkout | `main` (latest), or custom branch name |
| **Data Layer Set** | Dropdown | World Partition Data Layer configuration | `Default`, `Mirror`, `Limbo` |

### 2.2 Optional Inputs

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| **Device** | Dropdown | Machine to run tool on | Local machine |
| **LI Nesting Depth** | Integer | Maximum Level Instance nesting depth to open | 3 |
| **Skip Deep LI** | Boolean | Skip opening deeply nested Level Instances | false |

**Note**: Remote device option (game room machine) is **NOT in scope** for initial version.

---

## 3. Pre-Execution Steps

### 3.1 Git Operations

```
1. Check current branch state
2. If already on correct branch:
   - Skip checkout (performance optimization)
3. If branch = "main": 
   - Fetch latest from origin
   - Pull latest main
   - Checkout main (only if not already on main)
4. Else:
   - Fetch latest from origin
   - Checkout specified branch (only if not already on it)
5. If checkout fails (conflicts, uncommitted changes):
   - STOP and display error
   - Do not proceed
```

**Performance Optimization**: Tool should detect if already on correct branch to avoid unnecessary checkout operations.

### 3.2 Level Loading

```
1. Check if Unreal Editor is already open
   - If yes and correct level is loaded: Skip reload (performance optimization)
   - If yes but wrong level: Load specified level
   - If no: Open Unreal Editor
2. Load specified level/map (.umap file)
3. If level not found or crashes:
   - STOP and display CRITICAL error
   - Do not proceed
4. Wait for level to fully load (shader compilation, etc.)
```

**Performance Optimization**: Tool should detect if correct level is already loaded to avoid unnecessary reload operations.

### 3.3 Data Layer Configuration

```
1. Read Data Layer rules from config MD file
2. Enable/Disable Data Layers based on selected set:
   - Example: "Default" → Enable DL_Default_01, DL_Default_dc_03, DL_Light_default_07
   - Example: "Mirror" + "Default" → Both sets include DL_Collision_fixed
3. Wait for Data Layers to load
4. Load all Level Instances (recursively up to depth limit)
```

### 3.4 Camera Positioning

```
1. Open Unreal Editor Console Command window
2. Paste Bug It Go code: "BugItGo X Y Z Pitch Yaw Roll"
3. Viewport camera jumps to exact position and rotation
4. Lock camera (prevent accidental movement during capture)
```

---

## 4. Screenshot Capture Sequence

### 4.1 Output Folder Structure

**Folder Name Pattern**:
```
{GitIssueCode}_{Branch}_{Location}/
```

**Example**:
```
BUGFIX-1234_main_loc1/
├── report.md
├── 001_Game_Epic.jpg
├── 002_Game_High.jpg
├── 003_Game_Low.jpg
├── 004_PBR_Color.jpg
├── 005_PBR_Emissive.jpg
├── 006_PBR_Normal.jpg
├── 007_PBR_AO.jpg
├── 008_PBR_AO_Mtl.jpg
├── 009_PBR_Rough.jpg
├── 010_PBR_Spec.jpg
├── 011_PBR_Metallic.jpg
├── 012_Collision_Grid.jpg
├── 013_Collision_Types.jpg
├── 014_NavMesh_On.jpg
├── 015_NavMesh_Off.jpg
└── 016_Material_Issues.jpg
```

**Note**: `{GitIssueCode}` is the bug tracking ID or identifier (e.g., BUGFIX-1234, ISSUE-5678)

**Storage Location**: Google Drive or local network folder (configurable in MD config)

---

### 4.2 Screenshot List & Settings

**Resolution**: Defined in config MD file (e.g., 1920x1080)

**Format**: JPEG

**Naming Convention**: Editable via `screenshot_naming.md` config file

| # | Filename Pattern | View Mode | Settings | Notes |
|---|------------------|-----------|----------|-------|
| 001 | `Game_Epic.jpg` | Game View | Graphic: Epic | Standard game view |
| 002 | `Game_High.jpg` | Game View | Graphic: High | |
| 003 | `Game_Low.jpg` | Game View | Graphic: Low | |
| 004 | `PBR_Color.jpg` | PBR | Base Color | |
| 005 | `PBR_Emissive.jpg` | PBR | Emissive | |
| 006 | `PBR_Normal.jpg` | PBR | Normal | |
| 007 | `PBR_AO.jpg` | PBR | Ambient Occlusion | |
| 008 | `PBR_AO_Mtl.jpg` | PBR | AO Material | |
| 009 | `PBR_Rough.jpg` | PBR | Roughness | |
| 010 | `PBR_Spec.jpg` | PBR | Specular | |
| 011 | `PBR_Metallic.jpg` | PBR | Metallic | |
| 012 | `Collision_Grid.jpg` | Collision | Grid visible | Show ALL collision including inside nested LIs |
| 013 | `Collision_Types.jpg` | Collision | Color-coded blocks | No grid, only collision volumes with color codes |
| 014 | `NavMesh_On.jpg` | Nav Mesh | Nav mesh visible | |
| 015 | `NavMesh_Off.jpg` | Nav Mesh | Nav mesh hidden | |
| 016 | `Material_Issues.jpg` | Material Overlay | Highlight problems | Overlay colors on problematic materials |

---

### 4.3 Collision Visualization Details

#### 4.3.1 Collision Grid (Alt+C Enhanced)

**Problem**: Default UE `Alt+C` only shows collision on outermost Level Instances. Nested LI collision is hidden.

**Solution**:
```
1. Recursively open all Level Instances up to depth limit
2. For each LI: Ctrl+E to edit
3. Show collision grid for ALL objects in frame
4. Capture screenshot
5. Objects in front occlude objects behind
```

**Performance Consideration**: 
- Depth limit configurable (default: 3 levels)
- Option to skip deep nesting if performance issues

#### 4.3.2 Collision Type Color Coding

**Requirement**: Show collision volumes as solid colored blocks (no grid), color-coded by type.

**Common Collision Types** (defined in `collision_colors.md`):

| Collision Type | Color Code | Example |
|----------------|------------|---------|
| Block All | Red | `#FF0000` |
| Invisible Wall | Blue | `#0000FF` |
| Overlap/Trigger | Green | `#00FF00` |
| No Collision | Gray | `#808080` |
| Custom types... | ... | ... |

**Note**: Color scheme editable in config file.

---

### 4.4 Material & Shader Validation

#### 4.4.1 Scope

- **Scan only materials visible in current camera frame** (frustum culling)
- Do NOT scan entire level (performance)

#### 4.4.2 Validation Checks

**Check 1: Deprecated Nodes** (UE 5.6 → 5.7 migration)
```
1. Get list of all materials in frame
2. Trace to parent Material Masters
3. Check Material Master for deprecated nodes
4. Common deprecated nodes:
   - WorldAlignedTexture
   - DepthFade
   - (others as discovered)
```

**Check 2: Virtual Texture (VT) Issues**
- Missing VT references
- VT configuration errors

**Check 3: Texture Standard Violations**
- Defined in `texture_standards.md`
- Examples: Wrong resolution, missing mipmaps, incorrect compression

#### 4.4.3 Output Format

**Screenshot**: Overlay colored highlights on problematic materials
- Objects in front occlude objects behind
- Color code by issue type (configurable)

**Markdown Report Table**:
```markdown
| Material Path | Issue Type | Details |
|---------------|------------|---------|
| /Game/Materials/M_Wall_Master | Deprecated Node | WorldAlignedTexture (deprecated in 5.7) |
| /Game/Materials/M_Floor_VT | VT Error | Missing virtual texture reference |
| /Game/Materials/M_Prop_Fabric | Texture Violation | Resolution exceeds 2048x2048 limit |
```

---

## 5. Output Report

### 5.1 Markdown Report Template

**Filename**: `report.md`

```markdown
# Bug Screenshot Report

## Request Summary

| Field | Value |
|-------|-------|
| **Git Issue Code** | BUGFIX-1234 |
| **Bug It Go Code** | BugItGo -58230.549394 5626.046468... |
| **Location** | loc1 |
| **Branch** | main |
| **Data Layer Set** | Default |
| **Device** | Local Machine |
| **Executed By** | {Username} |
| **Timestamp** | 2024-12-22 14:35:21 |
| **Execution Time** | 6m 42s |

---

## Screenshots

| # | Filename | Description | Status |
|---|----------|-------------|--------|
| 001 | Game_Epic.jpg | Game view at Epic settings | ✓ |
| 002 | Game_High.jpg | Game view at High settings | ✓ |
| ... | ... | ... | ... |
| 016 | Material_Issues.jpg | Material validation overlay | ⚠ Issues found |

---

## Material Issues Found

| Material Path | Issue Type | Details |
|---------------|------------|---------|
| /Game/Materials/M_Wall_Master | Deprecated Node | WorldAlignedTexture (deprecated) |
| /Game/Materials/M_Floor_VT | VT Error | Missing VT reference |

---

## Warnings & Errors

### Non-Critical Warnings
- ⚠ Missing texture: T_Detail_Noise.png (replaced with placeholder)
- ⚠ Shader compilation took longer than expected (2m 15s)

### Critical Errors
- None

---

## Configuration Used

- Screenshot Resolution: 1920x1080
- LI Nesting Depth: 3
- Collision Color Scheme: collision_colors_v2.md
- Texture Standards: texture_standards_v1.3.md
```

---

## 6. Configuration Files

### 6.1 Config File Structure

**Location**: In project repository (version controlled)

**Files**:
```
/Config/BugScreenshotTool/
├── screenshot_naming.md
├── screenshot_resolution.md
├── collision_colors.md
├── texture_standards.md
├── data_layer_rules.md
└── output_location.md
```

### 6.2 Config File Format Examples

#### `screenshot_naming.md`

```markdown
# Screenshot Naming Convention

| Order | Prefix | View Mode | Example |
|-------|--------|-----------|---------|
| 1 | 001 | Game_Epic | 001_Game_Epic.jpg |
| 2 | 002 | Game_High | 002_Game_High.jpg |
| 3 | 003 | Game_Low | 003_Game_Low.jpg |
...
```

#### `screenshot_resolution.md`

```markdown
# Screenshot Resolution Settings

| Setting | Value |
|---------|-------|
| Width | 1920 |
| Height | 1080 |
| DPI | 96 |
```

#### `collision_colors.md`

```markdown
# Collision Type Color Coding

| Collision Type | Hex Color | RGB | Preview |
|----------------|-----------|-----|---------|
| Block All | #FF0000 | 255,0,0 | 🟥 |
| Invisible Wall | #0000FF | 0,0,255 | 🟦 |
| Overlap/Trigger | #00FF00 | 0,255,0 | 🟩 |
| No Collision | #808080 | 128,128,128 | ⬜ |
```

#### `data_layer_rules.md`

```markdown
# Data Layer Configuration Rules

## Default Set
- DL_Default_01: ✓ Enabled
- DL_Default_dc_03: ✓ Enabled
- DL_Light_default_07: ✓ Enabled
- DL_Collision_fixed: ✓ Enabled

## Mirror Set
- DL_Mirror_01: ✓ Enabled
- DL_Mirror_lights_05: ✓ Enabled
- DL_Collision_fixed: ✓ Enabled (shared with Default)

## Limbo Set
- DL_Limbo_main: ✓ Enabled
- DL_Limbo_fx_02: ✓ Enabled
...
```

### 6.3 Config Update Behavior

- Tool reads config files **at runtime** (every execution)
- Changes in MD files take effect **immediately** on next run
- No need to restart tool or rebuild
- Git pull ensures latest config is used

---

## 7. Error Handling

### 7.1 Critical Errors (STOP execution)

| Error | Behavior |
|-------|----------|
| Branch checkout failed | Display error message, do not proceed |
| Level not found | Display error message, do not proceed |
| Level crash on load | Display error message, do not proceed |
| Unreal Editor crash | Log crash, restart if possible |

### 7.2 Non-Critical Warnings (CONTINUE execution)

| Warning | Behavior |
|---------|----------|
| Missing material reference | Use placeholder, log warning in report |
| Missing texture | Use placeholder, log warning in report |
| Slow shader compilation | Log warning, continue |
| LI nesting exceeds depth limit | Skip deeper levels, log warning |

### 7.3 Error Report Format

Errors and warnings logged in `report.md` under dedicated sections (see template above).

---

## 8. Technical Implementation Notes

### 8.1 Technology Stack

**Option A: Unreal Editor Utility Widget**
- Pros: Native UE integration, easy viewport access
- Cons: Requires UE Editor open, Python/Blueprint hybrid

**Option B: Standalone Application**
- Pros: Independent process, better error handling
- Cons: More complex UE automation, requires UE Automation API

**Recommendation**: Start with **Editor Utility Widget** for faster prototyping.

### 8.2 Key UE APIs to Use

- `EditorLevelLibrary`: Level loading, world partition
- `AutomationLibrary`: Screenshot capture
- `AssetRegistry`: Material scanning
- `LevelInstance`: Nested LI handling
- `Console Commands`: BugItGo, view modes

### 8.3 Performance Optimization

- Async screenshot capture where possible
- Frustum culling for material scanning
- Configurable LI depth limit
- Batch view mode switches with minimal delay

### 8.4 Testing Checklist

- [ ] Git checkout (main, custom branch, conflicts)
- [ ] Level loading (valid, invalid, crash)
- [ ] Data Layer switching (Default, Mirror, Limbo)
- [ ] Camera positioning (BugItGo accuracy)
- [ ] All 16 screenshots captured correctly
- [ ] Collision grid shows nested LI collision
- [ ] Collision color coding accurate
- [ ] Material validation detects deprecated nodes
- [ ] Markdown report generates correctly
- [ ] Config file changes take effect
- [ ] Error handling (critical & non-critical)
- [ ] Runtime under 10 minutes

---

## 9. Phase 1 Priority Features

Based on your feedback, **prioritize these features first**:

1. ✅ **Collision visualization** (grid + color-coded types)
2. ✅ **PBR view modes** (all 8 modes)
3. ✅ **Material/shader error detection** (deprecated nodes, VT issues)

**Lower Priority (Phase 2)**:
- Nav mesh capture
- Texture standard validation (expand rules)
- Remote device execution

---

## 10. Future Enhancements (Out of Scope for V1)

- Remote device queue system (game room machines)
- Integration with bug tracking system (auto-attach screenshots)
- Batch processing (multiple bugs at once)
- Video capture option (animated camera path)
- AI-powered material issue detection
- Real-time preview before capture

---

## 11. Questions for Claude Code / Game Engineers

When implementing, please clarify:

1. **Python vs Blueprint**: Prefer Python scripting or Blueprint graphs for Editor Utility Widget?
2. **Screenshot API**: Use `AutomationLibrary.TakeScreenshot()` or custom viewport capture?
3. **Material Scanning**: How to efficiently query materials in camera frustum?
4. **Deprecated Node Detection**: Parse material graph nodes or use reflection API?
5. **Config Parsing**: Use built-in MD parser or custom solution?

---

## 12. Success Criteria

Tool is considered successful if:

- ✅ Executes in **under 10 minutes**
- ✅ Generates **all 16+ screenshots** accurately
- ✅ Detects **material issues** (deprecated nodes, VT errors)
- ✅ Shows **nested LI collision** correctly
- ✅ Produces **clean markdown report**
- ✅ Handles **common errors** gracefully
- ✅ **Config files** are easily updatable by non-tech users

---

## Appendix A: Glossary

- **Bug It Go**: Console command to set camera position/rotation from QA playtest
- **LI**: Level Instance (UE's way to nest levels)
- **DL**: Data Layer (UE World Partition system)
- **VT**: Virtual Texture (streaming texture system in UE5)
- **PBR**: Physically Based Rendering (material view modes)
- **QA**: Quality Assurance (testers)

---

**Document Version**: 1.0  
**Last Updated**: 2024-12-22  
**Author**: Art Team Lead (via Claude)  
**Target Audience**: Game Engineers, AI Code Assistants
