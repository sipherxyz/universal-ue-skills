---
name: merge-main
description: Merge main branch into current feature branch with stashing, animated progress, conflict resolution, and auto-commit
---

# Merge Main Skill

**Role:** Git Merge Automation
**Scope:** Merge main into feature branches with conflict handling
**Platform:** Windows + PowerShell

## Objective

Automate the common workflow of merging main into a feature branch:
1. Stash uncommitted changes
2. Pull latest main with progress indicator
3. Merge main into current branch
4. Interactive conflict resolution
5. Auto-commit and restore stash

## Prerequisites

- Git repository with `main` branch
- Currently on a feature branch (not main)
- Network access to pull from origin

## Script Location

```
./scripts/merge-main.ps1
```

## Workflow

### Step 1: Validate Git State

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/merge-main.ps1" -Action validate
```

**Expected Output:**
- `BRANCH={current-branch}` on success
- Exit code 1 if not a git repo
- Exit code 2 if on main branch

**Error Handling:**
- If on main → Tell user to switch to a feature branch first
- If not a git repo → Tell user to navigate to the project root

### Step 2: Stash Uncommitted Changes

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/merge-main.ps1" -Action stash
```

**Expected Output:**
- `STASHED=true` if changes were stashed
- `STASHED=false` if worktree was clean

**Store:** Remember if stash was created for Step 7.

### Step 3: Pull Latest Main

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/merge-main.ps1" -Action pull-main
```

**Actions performed by script:**
1. Switch to main branch
2. Pull from origin with animated progress spinner
3. Switch back to feature branch

**Expected Output:**
- `CURRENT_BRANCH={branch}` on success
- Progress animation during pull
- Exit code 1 on failure

**Error Handling:**
- If local main doesn't exist → Script auto-fetches from origin
- If pull fails → Script switches back to feature branch, reports error

### Step 4: Merge Main

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/merge-main.ps1" -Action merge
```

**Expected Output:**
- `CONFLICTS=false` if merge succeeded
- `CONFLICTS=true` and `CONFLICT_COUNT={n}` if conflicts detected (exit code 3)
- Exit code 1 for other failures

**If no conflicts:** Skip to Step 6.

### Step 5: Resolve Conflicts (If Any)

First, list the conflicting files:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/merge-main.ps1" -Action list-conflicts
```

**Output format:**
```
MERGE CONFLICTS (3 files)
==================================================
  1. Source/S2/Combat/Damage.cpp                [text]     +50/-30
  2. Config/DefaultGame.ini                     [text]     +5/-2
  3. Content/BP_Player.uasset                   [binary]
```

**ASK THE USER** how they want to resolve conflicts:

```
How would you like to resolve these conflicts?

Options:
  [A] Accept ALL from main (theirs) - Use main branch version for all files
  [O] Keep ALL from current branch (ours) - Keep your version for all files
  [I] Resolve individually - Choose per file
  [M] Manual - Abort merge, resolve in IDE
```

**Resolution Commands:**

For "Accept ALL from main":
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/merge-main.ps1" -Action resolve-all-theirs
```

For "Keep ALL from current branch":
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/merge-main.ps1" -Action resolve-all-ours
```

For "Resolve individually", loop through each file and ask:
```
File: {filename}
  [O] Keep ours (current branch)
  [T] Accept theirs (main)
  [S] Skip (resolve manually later)
```

Then run for each file:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/merge-main.ps1" -Action resolve-file -File "{filename}" -Resolution "{ours|theirs|skip}"
```

For "Manual":
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/merge-main.ps1" -Action abort
```
Then tell user to resolve conflicts in their IDE and run `git add` + `git commit` when done.

### Step 6: Commit Merge

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/merge-main.ps1" -Action commit
```

**Note:** Only run this if conflicts were resolved. Skip if user chose "Manual" resolution.

### Step 7: Restore Stash (If Applicable)

Only if `STASHED=true` from Step 2:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/merge-main.ps1" -Action restore-stash
```

**Error Handling:**
- If stash pop fails due to conflicts → Tell user their changes are still in stash, run `git stash list` to see them

## Error Scenarios

### Error: Network Failure During Pull
```
ERROR: Failed to connect to origin
```
**Solution:** Check network connection, try again. If VPN required, ensure it's connected.

### Error: Merge Has No Common Ancestor
```
ERROR: refusing to merge unrelated histories
```
**Solution:** This usually means the branches diverged significantly. User should manually review with `git log --oneline main..HEAD`.

### Error: Stash Pop Conflicts
```
WARNING: Failed to restore stash
```
**Solution:** Stashed changes conflict with merged code. User should:
1. Run `git stash list` to see stashes
2. Run `git stash show -p stash@{0}` to see stashed changes
3. Manually apply needed changes

## Success Message

On completion, display:
```
Merge completed successfully!
  Branch: {current-branch}
  Merged: main → {current-branch}
  Stash: {restored/not needed}

You can now continue working or push your changes.
```

## Legacy Metadata

```yaml
skill: merge-main
type: workflow
category: git
scope: project-root
```
