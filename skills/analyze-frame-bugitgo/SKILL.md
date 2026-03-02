---
name: analyze-frame-from-bugitgo-request
description: Automated screenshot capture and material validation at QA-reported bug locations using BugItGo coordinates
---

# Bug Screenshot Analysis Skill

**Role:** Bug Screenshot Capture & Material Validation Specialist
**Target Users:** Artists, Art Leads, Producers (non-technical)
**Scope:** Any level with World Partition Data Layers
**Platform:** Windows (Editor Utility Widget)
**Engine Version:** UE 5.7.1

## Objective

Automate the capture of 16 diagnostic screenshots at QA-reported bug locations, validate materials for deprecated nodes and texture issues, and generate actionable reports for the Art Team.

**Use Cases:**
- QA bug reproduction and visual documentation
- Material/shader error detection (deprecated nodes, VT issues)
- Collision and NavMesh visualization for debugging
- Cross-branch comparison for visual regression

---

## Prerequisites

Before using this skill, ensure:

1. **UE Editor** is installed and registered in Epic Games Launcher
2. **Project opened at least once** (shaders compiled, content cached)
3. **Network folder accessible**: `\\172.30.22.11\artteam\Temp\s2\report_from_bugitgo`
4. **Git credentials configured** for branch checkout operations
5. **Config folder exists**: `./config/`
6. **VPN connected** if working remotely (for network storage access)

---

## Dynamic Path Resolution

```
{CWD} = Current Working Directory (project root)
{ProjectFile} = S2.uproject
{EnginePath} = Resolved via open-editor skill (see ../open-editor/SKILL.md)
{ConfigPath} = {CWD}/./config/
{OutputPath} = \\172.30.22.11\artteam\Temp\s2\report_from_bugitgo
{FallbackOutput} = {CWD}/Saved/BugScreenshots/
{ReportFolder} = {OutputPath}/{issue_code}_{branch}_{location}/
```

> **Note:** Engine path resolution (cache file, registry lookup, EngineAssociation matching) is handled by [open-editor skill](../open-editor/SKILL.md). Do not duplicate that logic here.

---

## Usage

```
/analyze_frame_from_bugitgo_request <issue_code> <bugitgo_command> [options]
```

## Parameters

### Required

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `issue_code` | String | Bug tracking ID | `BUGFIX-1234`, `ISSUE-5678` |
| `bugitgo_command` | String | Full BugItGo console command from QA | `BugItGo -58230.549394 5626.046468 -704.216648 -34.523047 -152.561813 0.0` |
| `location` | String/Dropdown | Level/map shortcut or path. See [config/locations.md](config/locations.md) | `loc1`, `loc3`, `arena` |
| `branch` | String | Git branch to checkout | `main` (latest), or custom branch name |
| `data_layer` | Dropdown | World Partition realm. See [config/data_layer_rules.md](config/data_layer_rules.md) | `Default`, `Dream`, `Limbo` |

### Optional

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `--li-depth` | Integer | `3` | Max Level Instance nesting depth to open |
| `--skip-deep-li` | Boolean | `false` | Skip opening deeply nested Level Instances |

**Note**: Remote device execution (game room machine) is NOT in scope for V1.

---

## Examples

**Basic usage on main branch, loc1, Default data layer:**
```
/analyze_frame_from_bugitgo_request BUGFIX-1234 "BugItGo -58230.549394 5626.046468 -704.216648 -34.523047 -152.561813 0.0" loc1 main Default
```

**Custom branch and location:**
```
/analyze_frame_from_bugitgo_request ISSUE-5678 "BugItGo -12000.0 8500.0 -200.0 -15.0 45.0 0.0" loc3 feature/art-fixes Default
```

**With Dream data layer:**
```
/analyze_frame_from_bugitgo_request BUGFIX-9999 "BugItGo -5000.0 1000.0 -100.0 0.0 90.0 0.0" loc1 main Dream
```

**With custom LI depth:**
```
/analyze_frame_from_bugitgo_request BUGFIX-1234 "BugItGo -5000.0 1000.0 -100.0 0.0 90.0 0.0" loc1 main Default --li-depth 5
```

---

## Workflow

### Phase 1: Pre-Execution

#### 1.1 Git Operations
```
1. Check current branch
2. If already on correct branch → SKIP checkout (performance)
3. If branch = "main":
   - git fetch origin
   - git pull origin main
   - git checkout main (only if not already)
4. Else:
   - git fetch origin
   - git checkout <branch>
5. On conflict/uncommitted changes → STOP with error
```

#### 1.2 Open UE Editor

> **Reference:** Use [open-editor skill](../open-editor/SKILL.md) for launching Unreal Editor with auto-detection of custom engine builds, engine path caching, and project file handling.

```
1. Check if UE Editor already open
   - If yes → SKIP (proceed to level check)
   - If no → Invoke /open-editor skill to launch UE Editor
2. Wait for Editor startup (see open-editor for timeout handling)
```

#### 1.3 Level Loading
```
1. Check current loaded level
   - If correct level loaded → SKIP reload
   - If wrong level → Load specified level (.umap file)
2. On level not found / crash → STOP with CRITICAL error
3. Wait for full load (shader compilation)
```

#### 1.4 Data Layer Configuration
```
1. Read rules from {ConfigPath}/data_layer_rules.md
2. Enable/Disable Data Layers based on selected realm set
3. Wait for Data Layers to load
4. Open all Level Instances recursively up to depth limit
```

See [config/data_layer_rules.md](config/data_layer_rules.md) for realm sets (Default, Dream, Limbo, Cinematic) and their child Data Layers.

#### 1.5 Camera Positioning
```
1. Open UE Console (~)
2. Execute: BugItGo X Y Z Pitch Yaw Roll
3. Viewport camera jumps to exact position/rotation
4. Lock camera to prevent accidental movement
```

---

### Phase 2: Screenshot Capture

Captures 16 diagnostic screenshots. See [config/screenshot_naming.md](config/screenshot_naming.md) for full sequence and naming, [config/screenshot_resolution.md](config/screenshot_resolution.md) for resolution and UE commands.

#### 2.1 Collision Grid Capture (Nested LI Problem)

**Problem**: Default `Alt+C` only shows collision on outermost Level Instances. Nested LI collision is hidden.

**Solution**:
```cpp
// Pseudocode
for each LevelInstance in LoadedLIs (up to depth limit):
    OpenLevelInstanceForEdit(LI)  // Ctrl+E equivalent

ShowCollision()  // Alt+C equivalent
CaptureScreenshot("012_Collision_Grid.jpg")
```

**Performance Consideration**:
- Depth limit configurable (default: 3 levels) via `--li-depth` parameter
- Option to skip deep nesting if performance issues via `--skip-deep-li` flag

#### 2.2 Collision Type Color Coding

Show collision volumes as solid colored blocks (no wireframe grid). See [config/collision_colors.md](config/collision_colors.md) for color mapping and [config/collision_colors_preview.html](config/collision_colors_preview.html) for visual preview.

---

### Phase 3: Material Validation

**Scope**: Only materials visible in current camera frustum (frustum culling for performance).

#### 3.1 Validation Checks

**Check 1: Deprecated Nodes** (UE 5.6 → 5.7 migration)
```
1. Get all materials in camera frustum
2. Trace to parent Material Masters
3. Scan Material Graph for deprecated nodes per texture_standards.md
```

See [config/texture_standards.md](config/texture_standards.md) for the full list of deprecated nodes.

**Check 2: Virtual Texture Issues**
- Missing VT references
- VT configuration errors

**Check 3: Texture Standard Violations**
- Wrong resolution (exceeds limits)
- Missing mipmaps
- Incorrect compression format

#### 3.2 Output

**Screenshot 016**: Overlay colored highlights on problematic materials (objects in front occlude behind).

**Report table**:
```markdown
| Material Path | Issue Type | Details |
|---------------|------------|---------|
| /Game/Materials/M_Wall_Master | Deprecated Node | WorldAlignedTexture (deprecated in 5.7) |
| /Game/Materials/M_Floor_VT | VT Error | Missing virtual texture reference |
| /Game/Materials/M_Prop_Fabric | Texture Violation | Resolution exceeds 2048x2048 limit |
```

---

## Output

See [config/output_location.md](config/output_location.md) for storage paths, folder structure, cleanup policy, and permissions.

See [config/report_template.md](config/report_template.md) for the generated report format and template variables.

---

## Configuration Files

Location: `./config/` (version controlled)

| File | Purpose | Format |
|------|---------|--------|
| [screenshot_naming.md](config/screenshot_naming.md) | Filename patterns and order | Markdown table |
| [screenshot_resolution.md](config/screenshot_resolution.md) | Width, Height, DPI, quality | Markdown table |
| [collision_colors.md](config/collision_colors.md) | Collision type → color mapping | Markdown table |
| [collision_colors_preview.html](config/collision_colors_preview.html) | Visual color preview | HTML |
| [data_layer_rules.md](config/data_layer_rules.md) | Which DLs enabled per realm | Markdown lists |
| [texture_standards.md](config/texture_standards.md) | Validation rules, deprecated nodes | Markdown |
| [locations.md](config/locations.md) | Level shortcuts mapping | Markdown table |
| [output_location.md](config/output_location.md) | Output paths and permissions | Markdown |
| [report_template.md](config/report_template.md) | Report format template | Markdown |

**Note**: Config file names are fixed. Version info is tracked inside each file, not in filename.

**Runtime behavior**: Tool reads config files at execution time. Changes take effect immediately on next run, no rebuild needed. Git pull ensures latest config is used.

---

## Error Handling

### Critical Errors (STOP execution)

| Error | Behavior |
|-------|----------|
| Branch checkout failed | Display error, abort |
| Level not found | Display error, abort |
| Level crash on load | Display error, abort |
| UE Editor crash | Log crash, re-invoke open-editor skill |
| Engine not found | See [open-editor error handling](../open-editor/SKILL.md#error-handling) |

### Non-Critical Warnings (CONTINUE execution)

| Warning | Behavior |
|---------|----------|
| Missing material reference | Use placeholder, log in report |
| Missing texture | Use placeholder, log in report |
| Slow shader compilation | Log warning, continue |
| LI nesting exceeds depth | Skip deeper levels, log warning |

**Error Report Format**: Errors and warnings logged in `report.md` under dedicated "Warnings & Errors" section.

---

## Implementation Guide for Engineers

### Technology Stack Options

**Option A: Editor Utility Widget** (Recommended for V1)
- Pros: Native UE integration, easy viewport access
- Cons: Requires UE Editor open, Python/Blueprint hybrid

**Option B: Standalone Application**
- Pros: Independent process, better error handling
- Cons: More complex UE automation, requires UE Automation API

**Recommendation**: Start with **Editor Utility Widget** for faster prototyping.

### Key UE5.7 APIs

| Purpose | API |
|---------|-----|
| Level loading | `UEditorLevelLibrary` |
| World Partition | `UWorldPartitionSubsystem` |
| Screenshot capture | `FScreenshotRequest`, `UAutomationLibrary::TakeHighResScreenshot` |
| Material scanning | `UAssetRegistryHelpers`, `UMaterialInstance` |
| Level Instances | `ALevelInstance`, `ULevelInstanceSubsystem` |
| Console commands | `GEngine->Exec()` |
| View modes | `EViewModeIndex`, `FEditorViewportClient::SetViewMode` |

### Implementation Questions to Resolve

1. **Python vs Blueprint**: Prefer Python scripting for logic, Blueprint for UI?
2. **Screenshot API**: `UAutomationLibrary::TakeHighResScreenshot()` or custom viewport capture via `FViewport::Draw()`?
3. **Material Frustum Query**: Use `UGameplayStatics::GetAllActorsInViewFrustum()` then trace materials, or scene query?
4. **Deprecated Node Detection**: Parse `UMaterialExpression` graph nodes via `UMaterial::GetExpressions()` or reflection?
5. **MD Config Parsing**: Use `FFileHelper::LoadFileToString()` + custom parser, or integrate a markdown library?

### Performance Optimization Strategies

- Async screenshot capture where possible
- Frustum culling for material scanning (don't scan entire level)
- Configurable LI depth limit
- Batch view mode switches with minimal delay between captures
- Skip git checkout if already on correct branch
- Skip level reload if correct level already loaded

### Code Structure Suggestion

```
Plugins/SipherBugScreenshot/
├── Source/
│   ├── SipherBugScreenshot.Build.cs
│   ├── Public/
│   │   ├── SipherBugScreenshotSubsystem.h
│   │   ├── SipherScreenshotCaptureComponent.h
│   │   ├── SipherMaterialValidator.h
│   │   └── SipherConfigReader.h
│   └── Private/
│       ├── SipherBugScreenshotSubsystem.cpp
│       ├── SipherScreenshotCaptureComponent.cpp
│       ├── SipherMaterialValidator.cpp
│       └── SipherConfigReader.cpp
├── Content/
│   └── EditorUtilityWidgets/
│       └── EUW_BugScreenshotTool.uasset
└── Config/
    └── (default configs)
```

### Testing Checklist

- [ ] Git checkout (main, custom branch, conflicts)
- [ ] Level loading (valid, invalid, crash)
- [ ] Data Layer switching (Default, Dream, Limbo)
- [ ] Camera positioning (BugItGo accuracy)
- [ ] All 16 screenshots captured correctly
- [ ] Collision grid shows nested LI collision
- [ ] Collision color coding accurate
- [ ] Material validation detects deprecated nodes
- [ ] Markdown report generates correctly
- [ ] Config file changes take effect immediately
- [ ] Error handling (critical & non-critical)
- [ ] Runtime under 10 minutes

---

## Success Criteria

- [ ] Executes in **under 10 minutes**
- [ ] Generates **all 16 screenshots** accurately
- [ ] Detects **deprecated material nodes** (WorldAlignedTexture, DepthFade)
- [ ] Detects **VT errors**
- [ ] Shows **nested LI collision** correctly (not just outermost)
- [ ] Produces **clean markdown report**
- [ ] Handles **critical errors** (stops gracefully)
- [ ] Handles **non-critical warnings** (continues with logging)
- [ ] **Config files** editable by non-tech users (no rebuild)
- [ ] **Performance optimization**: skips unnecessary git/level operations

---

## Phase 1 Priority (V1 Scope)

**Must Have**:
1. Collision visualization (grid + color-coded types)
2. PBR view modes (all 8)
3. Material/shader error detection (deprecated nodes, VT issues)
4. Game view screenshots (Epic/High/Low)
5. Markdown report generation

**Phase 2 (Later)**:
- Nav mesh capture refinement
- Expanded texture standard validation
- Remote device execution (game room machines)
- Batch processing (multiple bugs)

---

## Performance

### Expected Execution Times

| Phase | Duration | Notes |
|-------|----------|-------|
| Git checkout/pull | 5-30 seconds | Depends on changes |
| Level loading | 30-90 seconds | Shader compilation on first load |
| Data Layer switching | 10-30 seconds | World Partition streaming |
| LI opening (recursive) | 5-20 seconds | Depends on nesting depth |
| Screenshot capture (16) | 60-120 seconds | View mode switching overhead |
| Material validation | 20-60 seconds | Frustum size dependent |
| Report generation | 2-5 seconds | Markdown writing |
| **Total runtime** | **3-10 minutes** | Typical range |

### Timeout Settings

```
Default command timeout: 600000ms (10 minutes)
Level load timeout: 120000ms (2 minutes)
Screenshot capture timeout: 10000ms per image
Material scan timeout: 60000ms
```

### Optimization Tips

- First run on a level is slower (shader cache cold)
- Subsequent runs on same level are faster
- Skip git/level operations when already correct (saves 1-2 minutes)
- Frustum culling reduces material scan from minutes to seconds
- Use `--skip-deep-li` flag if LI opening takes too long
- Network write adds 5-10s latency; use local fallback if time-critical

---

## Integration with Other Skills

### open-editor

> **See:** [open-editor skill](../open-editor/SKILL.md) for full documentation.

This skill automatically invokes `/open-editor` when UE Editor is not running. The open-editor skill handles:
- Engine path auto-detection from Windows registry
- Engine path caching in `./Saved/claude-data.txt`
- Custom engine builds (e.g., `5.7.1-huli`)
- Project file regeneration (optional)

**Manual pre-launch (optional):**
```
/open-editor
# Wait for editor to fully load
/analyze_frame_from_bugitgo_request ...
```

### /dev-workflow:ue-cpp-build

If `SipherBugScreenshot` plugin needs recompilation after code changes.

```
/dev-workflow:ue-cpp-build
# After successful build
/analyze_frame_from_bugitgo_request ...
```

### find-ref

Trace material issues back to source assets for deeper investigation.

```
# After finding material issues in report
/find-ref /Game/Materials/M_Problem_Material
```

### read-uasset

Inspect binary content of problematic materials or textures.

```
# Investigate a flagged material
/read-uasset Content/Materials/M_Wall_Master.uasset
```

### boss-review

Use after capturing boss arena bugs to cross-reference with boss asset audit.

---

## Example Session

### Successful Execution

```
User: /analyze_frame_from_bugitgo_request BUGFIX-1234 "BugItGo -58230.5 5626.0 -704.2 -34.5 -152.5 0.0" loc1 main Default

Agent:
1. Checking git branch... ✓ Already on main
2. Git pull origin main... ✓ Updated (3 files changed)
3. Checking UE Editor... ✓ Editor running
4. Loading level: /Game/Maps/Loc1/Loc1_Main... ✓ Loaded (45s)
5. Enabling Data Layers: Default set... ✓ Layers enabled per data_layer_rules.md
6. Opening Level Instances (depth 3)... ✓ 12 LIs opened
7. Executing BugItGo command... ✓ Camera positioned
8. Capturing screenshots...
   ████████████████████ 16/16 complete
9. Running material validation... ✓ 3 issues found
10. Generating report... ✓ Saved

Report: \\172.30.22.11\artteam\Temp\s2\report_from_bugitgo\BUGFIX-1234_main_loc1\report.md

Summary:
- 16 screenshots captured
- 3 material issues detected:
  - M_Wall_Master: WorldAlignedTexture (deprecated)
  - M_Floor_VT: Missing VT reference
  - T_Detail_Noise: Resolution exceeds 2048 limit

Total time: 4m 32s
```

### With Branch Checkout

```
User: /analyze_frame_from_bugitgo_request ISSUE-5678 "BugItGo -12000.0 8500.0 -200.0 -15.0 45.0 0.0" loc3 feature/art-fixes Default

Agent:
1. Checking git branch... Current: main
2. Fetching origin... ✓
3. Checking out feature/art-fixes... ✓ Switched
4. Loading level: /Game/Maps/Loc3/Loc3_Main... ✓ Loaded (62s)
...
```

### Error Handling Example

```
User: /analyze_frame_from_bugitgo_request BUGFIX-9999 "BugItGo -5000.0 1000.0 -100.0 0.0 90.0 0.0" loc1 main Default

Agent:
1. Checking git branch... ✓ Already on main
2. Git pull origin main... ✓ Updated
3. Checking UE Editor... ✗ Editor not running
4. Invoking /open-editor skill...
   - Reading cached engine path... Found: F:/S2UE (5.7.1-huli)
   - Launching Unreal Editor... ✓ Started
5. Waiting for Editor startup... (120s timeout)
6. Loading level: /Game/Maps/Loc1/Loc1_Main...
   ⚠ Warning: Shader compilation taking longer than expected
   Waiting... ✓ Loaded (95s)
7. Capturing screenshots...
   ████████████░░░░░░░░ 12/16
   ⚠ Warning: Missing texture T_Detail_Noise.png (using placeholder)
   ████████████████████ 16/16 complete
8. Running material validation... ✓ 5 issues found
9. Generating report... ✓ Saved

Warnings logged in report:
- Shader compilation took 95s (expected <60s)
- Missing texture: T_Detail_Noise.png

Total time: 7m 15s
```

### Network Failure Fallback

```
Agent:
...
9. Saving to network folder...
   ⚠ Warning: Network folder unreachable (\\172.30.22.11)
   Falling back to local storage...
   ✓ Saved to: D:\s2\Saved\BugScreenshots\BUGFIX-1234_main_loc1\

Action required: Manually copy to network when available.
```

---

## Future Enhancements (Out of Scope for V1)

- Remote device queue system (game room machines)
- Integration with bug tracking system (auto-attach screenshots to issues)
- Batch processing (multiple bugs at once)
- Video capture option (animated camera path)
- AI-powered material issue detection
- Real-time preview before capture

---

## Knowledge Base References

- [config/](config/) - All config files for this skill
- [claude-agents/docs/PLUGIN_REFERENCE.md](../../../claude-agents/docs/PLUGIN_REFERENCE.md) - Plugin catalog
- `Plugins/Frameworks/SipherWorldPartition/` - World Partition & Data Layer source
- `Content/S2/Main_Flow/` - Level assets for loc1, loc2, loc3
- [CLAUDE.md](../../../CLAUDE.md) - Project standards and code rules

---

## Glossary

| Term | Definition |
|------|------------|
| **BugItGo** | UE console command to set camera position/rotation from QA playtest |
| **LI** | Level Instance - UE's nested level system |
| **DL** | Data Layer - UE World Partition streaming system |
| **VT** | Virtual Texture - UE5 streaming texture system |
| **PBR** | Physically Based Rendering - material property view modes |
| **QA** | Quality Assurance - testers who report bugs |
| **Realm** | Game world state (Default, Dream, Limbo, Cinematic) |

---

## Notes

- This skill is Windows-specific (PowerShell, registry queries, network paths)
- Requires Unreal Editor 5.7.1 or later
- Config files use markdown format for non-tech user editability
- Network storage (`\\172.30.22.11`) requires VPN when working remotely
- First run on a level may take longer due to shader compilation (cold cache)
- "Mirror" realm has been renamed to "Dream" in the project
- All 16 screenshots are captured sequentially (no parallel capture due to view mode switching)

## Legacy Metadata

```yaml
invoke: /qa-testing:analyze-frame-bugitgo
type: utility
category: qa-tools
scope: Content/S2/**
```
