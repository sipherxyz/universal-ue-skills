---
name: open-editor
description: Open Unreal Editor with auto-detection of custom engine builds
---

# Open Unreal Editor Skill

**Role:** Editor Launch Utility
**Scope:** Current Working Directory (dynamic)
**Engine Version:** Auto-detected from *.uproject
**Platform:** Windows

## Objective

Automatically launch Unreal Editor with the correct custom engine build. The skill manages engine path caching and supports project file regeneration. All paths are dynamically resolved from the current working directory.

## Dynamic Path Resolution

The skill uses the current working directory to find all paths:

```
{CWD} = Current Working Directory (from environment)
{ProjectFile} = First *.uproject file found in {CWD}
{ProjectName} = Name extracted from {ProjectFile} (without .uproject extension)
{CacheFile} = {CWD}/Saved/claude-data.txt
```

### Step 0: Detect Project File

First, find the .uproject file in the current working directory:

```bash
# Find .uproject file in current directory
dir /b *.uproject
```

This returns the project file name (e.g., `S2.uproject`). Use this for all subsequent operations.

## Workflow

### Step 1: Read Cached Engine Path

Check if the engine path is cached in `./Saved/claude-data.txt`:

```
Read file: {CWD}/Saved/claude-data.txt
```

**Expected format:**
```txt
[UnrealEngine]
EnginePath=F:/S2UE
EngineAssociation=5.7.1-huli
LastOpened=2025-12-14T12:00:00

[ProjectInfo]
ProjectName=S2
ProjectPath={CWD}/{ProjectFile}
```

### Step 2: If No Cache, Query Registry

If `claude-data.txt` doesn't exist or is invalid, query the Windows Registry:

```bash
reg query "HKEY_CURRENT_USER\SOFTWARE\Epic Games\Unreal Engine\Builds"
```

Then read the project file to get the EngineAssociation:

```
Read file: {CWD}/{ProjectFile}
```

Extract `EngineAssociation` field (e.g., `5.7.1-huli`) and match it with registry entries.

### Step 3: Save Cache

Save the engine path to `./Saved/claude-data.txt`:

```bash
# Ensure Saved directory exists
mkdir "{CWD}\Saved" 2>nul
```

Use Write tool to create/update `{CWD}/Saved/claude-data.txt` with the detected path.

### Step 4: Launch Editor

Launch Unreal Editor using the detected path:

```bash
start "" "{EnginePath}/Engine/Binaries/Win64/UnrealEditor.exe" "{CWD}\{ProjectFile}"
```

### Step 5: Regenerate Project Files (Optional)

If user requests or if project files are stale, regenerate:

```bash
"{EnginePath}/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" -projectfiles -project="{CWD}\{ProjectFile}" -game -engine -progress
```

Or use the batch file if available:

```bash
"{EnginePath}/GenerateProjectFiles.bat" "{CWD}\{ProjectFile}"
```

## Implementation Steps

### 1. Detect Project File

```markdown
Action: Find .uproject in current directory
Command: dir /b *.uproject (or use Glob tool with pattern "*.uproject")
Result: Store as {ProjectFile} variable
```

### 2. Check Cache File

```markdown
Action: Read {CWD}/Saved/claude-data.txt
- If exists and valid: Extract EnginePath, proceed to Step 5
- If missing or invalid: Proceed to Step 3
```

### 3. Auto-Detect Engine

```markdown
Action: Query registry and read {ProjectFile}
Commands:
1. reg query "HKEY_CURRENT_USER\SOFTWARE\Epic Games\Unreal Engine\Builds"
2. Read {CWD}/{ProjectFile}
3. Match EngineAssociation with registry entry
4. Save result to claude-data.txt
```

### 4. Create/Update Cache

```markdown
Action: Write to {CWD}/Saved/claude-data.txt
Format:
[UnrealEngine]
EnginePath={detected_path}
EngineAssociation={from_uproject}
LastOpened={current_timestamp}

[ProjectInfo]
ProjectName={ProjectName}
ProjectPath={CWD}/{ProjectFile}
```

### 5. Launch Editor

```markdown
Action: Execute launch command
Command: start "" "{EnginePath}/Engine/Binaries/Win64/UnrealEditor.exe" "{CWD}\{ProjectFile}"
```

### 6. Regenerate Project (If Requested)

```markdown
Ask user: "Do you want to regenerate project files?"
Options:
- Yes, regenerate Visual Studio/Rider project files
- No, just open the editor
- Regenerate and open editor
```

## User Interaction

### Default Behavior (No Options)

When user invokes `open-editor` without options:
1. Detect .uproject file in current directory
2. Read or auto-detect engine path
3. Launch editor directly
4. Report status to user

### With Regeneration Request

When user asks to regenerate:
1. Run UnrealBuildTool with -projectfiles flag
2. Wait for completion
3. Launch editor

### Force Re-detect Engine

When user suspects wrong engine or cache is stale:
1. Delete or ignore claude-data.txt
2. Re-query registry
3. Update cache
4. Launch editor

## Error Handling

### No .uproject Found

If no .uproject file in current directory:
```markdown
Error: No .uproject file found in current directory
Solution:
1. Verify you are in the correct project directory
2. Current directory: {CWD}
3. Expected: A directory containing *.uproject file
```

### Engine Not Found

If registry query fails or EngineAssociation not matched:
```markdown
Error: Could not find Unreal Engine build for association '{EngineAssociation}'
Solution:
1. Verify {ProjectFile} EngineAssociation value
2. Check if custom engine is registered in Epic Games Launcher
3. Manually register engine:
   - Open Epic Games Launcher
   - Settings > Installed Engine Versions
   - Add custom engine path
```

### Editor Fails to Launch

If start command fails:
```markdown
Error: Failed to launch Unreal Editor
Checks:
1. Verify engine path exists: {EnginePath}/Engine/Binaries/Win64/UnrealEditor.exe
2. Verify project file exists: {CWD}/{ProjectFile}
3. Check for crash logs in: {CWD}/Saved/Crashes
```

### Project File Corruption

If .uproject is corrupted:
```markdown
Action: Offer to regenerate from template
Warning: This will reset plugin configuration
```

## Example Session

### Normal Launch
```
User: open editor
Assistant:
1. Detecting project file... Found: S2.uproject
2. Reading cached engine path from ./Saved/claude-data.txt...
3. Found: EnginePath=F:/S2UE (5.7.1-huli)
4. Launching Unreal Editor...
5. Done! Editor is starting.
```

### First Time / Cache Miss
```
User: open editor
Assistant:
1. Detecting project file... Found: S2.uproject
2. Cache not found, detecting engine...
3. Reading S2.uproject... EngineAssociation: 5.7.1-huli
4. Querying registry... Found: F:/S2UE
5. Saving cache to claude-data.txt...
6. Launching Unreal Editor...
7. Done! Editor is starting.
```

### With Regeneration
```
User: open editor and regenerate project files
Assistant:
1. Detecting project file... Found: S2.uproject
2. Reading cached engine path... Found: F:/S2UE
3. Regenerating project files...
4. Running UnrealBuildTool -projectfiles...
5. Project files regenerated successfully!
6. Launching Unreal Editor...
7. Done! Editor is starting.
```

## Cache File Format

**Location:** `{CWD}/Saved/claude-data.txt`

**Format (INI-style):**
```ini
[UnrealEngine]
EnginePath=F:/S2UE
EngineAssociation=5.7.1-huli
LastOpened=2025-12-14T10:30:00

[EditorSettings]
LastMap=/Game/Maps/DevMap
WindowMode=Windowed

[ProjectInfo]
ProjectName=S2
ProjectPath={CWD}/S2.uproject
```

## Commands Reference

### Find Project File
```bash
dir /b *.uproject
```

### Launch Editor
```bash
start "" "{EnginePath}/Engine/Binaries/Win64/UnrealEditor.exe" "{CWD}\{ProjectFile}"
```

### Regenerate Project Files
```bash
"{EnginePath}/Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe" -projectfiles -project="{CWD}\{ProjectFile}" -game -engine -progress
```

### Query Registry
```bash
reg query "HKEY_CURRENT_USER\SOFTWARE\Epic Games\Unreal Engine\Builds"
```

### Verify Editor Executable
```bash
if exist "{EnginePath}/Engine/Binaries/Win64/UnrealEditor.exe" (echo Editor found) else (echo Editor NOT found)
```

## Success Criteria

- Project file detected dynamically from current directory
- Editor launches successfully
- Cache file is created/updated with correct paths
- User receives clear status feedback
- Errors are handled gracefully with actionable solutions

## Notes

- This skill is Windows-specific (uses `start` command and registry queries)
- Engine path uses forward slashes for compatibility
- Project path uses backslashes (Windows native)
- The `start ""` syntax prevents blocking the terminal
- All paths are resolved relative to the current working directory
- Works with any Unreal project, not just S2

## Legacy Metadata

```yaml
skill: open-editor
invoke: /dev-workflow:open-editor
type: utility
category: editor-tools
scope: project-root
```
