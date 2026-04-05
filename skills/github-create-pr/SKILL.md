---
name: github-create-pr
description: Create GitHub PRs with linked issues following project templates
---

> **CRITICAL:** This skill MUST use the exact PR template structure. NEVER use alternative formats like `## Summary` / `## Changes` / `## Test plan`. See [Template Compliance](#️-critical-template-compliance) section before building PR body.

## Configuration
This skill reads project-specific values from `skills.config.json` at the repository root.
Required keys: `github.repo`, `github.owner`, `github.project_number`, `milestones.*`, `team.*`
If not found, prompt the user for repository and project details.

# GitHub PR Creator Skill

## Quick Reference

| Flag | Purpose |
|------|---------|
| `--auto` | Fully automated mode - auto-pushes, skips issue creation, pre-ticks all fields |
| `--issue 123` | Use existing issue instead of creating new |
| `--base develop` | Target different base branch |
| `--quick` | Skip review step, create immediately |
| `--draft` | Create as draft PR |
| `--update 123` | Update existing PR with metadata |

### --auto Mode Summary

```bash
/github-workflow:github-create-pr --auto
```

**Behavior:**
- Auto-pushes branch if needed (no prompt)
- **Skips issue creation** - PR has no linked issue
- Auto-detects all fields from branch name and file changes
- Shows single confirmation with pre-ticked values
- No field editing option (Y/n only)

**Auto-Detection Logic:**
| Field | Detection Rule |
|-------|----------------|
| Type | `feature/*` → New feature, `fix/*` → Bug fix, `*.md` only → Documentation |
| QA | Code changes → Yes, docs only → No |
| Performance | `M_*.uasset`, `L_*_dec/*`, `L_*_ene/*`, `L_*_light/*` → Moderate; `*/Tick*`, `*/AI/*`, `*/Combat/*` → Minor |
| Regression | Moderate/High/Minor impact → Yes; No Impact → No |

**Role:** Pull Request Automation
**Scope:** Project-wide PR creation with issue linking
**Platform:** Windows + gh CLI
**Repository:** {github.repo}
**Project:** {project.fullname}

## Objective

Create pull requests from feature branches to main, following the project's PR template, with automatically linked task issues. Extracts context from commits and file changes, guides user through required fields, and ensures proper integration with project workflows.

## --auto Mode

The `--auto` flag enables fully automated PR creation without interactive prompts.

### Behavior Changes

| Step | Normal Mode | `--auto` Mode |
|------|-------------|---------------|
| Push confirmation | Prompts user | Auto-pushes if needed |
| Issue creation | Calls github-create-issue | **SKIPPED** |
| Draft review | Shows preview, asks confirmation | **Shows preview with pre-ticked boxes, single confirm** |
| Field editing | Interactive menu | **DISABLED** (no edit option) |
| PR creation | After user confirmation | **After single confirm in --auto** |

### Exit Conditions (--auto)

- On main branch → Error
- No commits → Error
- PR already exists → Error with URLs
- Authentication fails → Error

### Auto-Tick Logic

#### 1. Push Confirmation
**Auto-tick:** Always `Yes` - push required for PR creation

#### 2. Type of Change

| Condition | Checkbox |
|-----------|----------|
| Branch: `fix/*`, `bugfix/*`, `hotfix/*` | `[x] Bug fix` |
| Branch: `feature/*` | `[x] New feature` |
| Commit contains `BREAKING CHANGE` | `[x] Breaking change` |
| Only `*.md` files | `[x] Documentation update` |
| Default | `[x] New feature` |

#### 3. Request QA

| Condition | Checkbox |
|-----------|----------|
| New feature detected | `[x] Yes` |
| Bug fix detected | `[x] Yes` |
| Only docs/config/assets | `[x] No` |

#### 4. Performance Impact Assessment

**PRIORITY ORDER (first match wins):**

| Priority | Pattern | Impact Level | Regression Test |
|----------|---------|--------------|-----------------|
| 1 | Files: `M_*.uasset` (Materials/Shaders) | `[x] Moderate` | `[x] Yes` |
| 1 | Folders: `L_*_dec/*` (Level Decoration) | `[x] Moderate` | `[x] Yes` |
| 1 | Folders: `L_*_ene/*` (Level Enemies) | `[x] Moderate` | `[x] Yes` |
| 1 | Folders: `L_*_light/*` (Level Lighting) | `[x] Moderate` | `[x] Yes` |
| 2 | Files: `*/Tick*`, `*/AI/*`, `*/Combat/*` + perf keywords | `[x] Minor` | `[x] Yes` |
| 3 | Only docs/config/editor tools | `[x] No Impact` | `[x] No` |
| 4 | Default | `[x] No Impact` | `[x] No` |

**Performance keywords:** "performance", "optimize", "fps", "frame", "lag", "slow"

#### 5. Regression Test Needed

| Performance Impact | Checkbox |
|-------------------|----------|
| Moderate/High | `[x] Yes` |
| Minor | `[x] Yes` |
| No Impact | `[x] No` |

#### 6. Draft Confirmation (--auto Step 9)

**--auto mode display:**
```
═══════════════════════════════════════
DRAFT PULL REQUEST (Auto-Generated)
═══════════════════════════════════════

Title: {Auto-detected title}
Base: main ← Head: {branch}
Linked Issue: N/A (auto-mode)

All fields auto-detected and pre-ticked based on file analysis.
Type: New feature | Impact: Moderate | QA: Yes

═══════════════════════════════════════
BODY PREVIEW
═══════════════════════════════════════
## Purpose * :information_source:
...

## Type of Change :page_facing_up:
- [x] New feature (auto-detected from branch prefix)
...

## Performance Impact Assessment *:
**Impact Level** *(select one)*:
- [ ] No Impact
- [x] Minor (auto-detected from changed files)
...

═══════════════════════════════════════

Create PR with these auto-detected values?
[Y/n]: _
```

**User Interaction:**
- User enters `Y` or presses Enter → Proceed to create PR
- User enters `n` → Cancel and exit
- NO "Edit" option in --auto mode (use normal mode for editing)

## ⚠️ MANDATORY: Required PR Metadata

**EVERY PR MUST have these fields set. NEVER create a PR without them:**

| Field | Source | Command |
|-------|--------|---------|
| **Assignee** | Auto-detect from `gh api user --jq '.login'` | `--assignee {username}` |
| **Labels** | Auto-detect from file changes (see Label Detection) | `--label "task,Engineering,..."` |
| **Milestone** | Auto-detect from domain labels (see Milestone Detection) | `--milestone {number}` |
| **Project** | Always "{project.fullname}" (project {github.project_number}) | `gh project item-add {github.project_number} --owner {github.owner} --url {pr_url}` |
| **Linked Issue** | Create via github-create-issue or use existing | `Closes #{number}` in body |

**If `gh pr edit` fails due to Projects Classic deprecation, use API:**
```bash
gh api repos/{github.repo}/issues/{pr_number} -X PATCH \
  -f milestone={milestone_number} \
  -f "labels[]=task" -f "labels[]=Engineering" -f "labels[]=..."
```

## Prerequisites

Before using this skill:
1. Ensure `gh` CLI is authenticated: `gh auth status`
2. Working in a feature branch (not main)
3. Branch has commits to merge
4. Remote repository is accessible

## Dynamic Context Resolution

```
{CWD} = Current Working Directory
{Branch} = Current git branch name
{RemoteBranch} = Remote tracking branch (origin/{Branch})
{BaseBranch} = Target branch (default: main)
{ProjectName} = "{project.fullname}"
{ProjectNumber} = {github.project_number}
{ProjectID} = "{github.project_node_id}"
{RepoOwner} = "{github.owner}"
{RepoName} = "s2"
{Today} = Current date in YYYY-MM-DD format
```

## Available Milestones

Query available milestones at runtime:
```bash
gh api repos/{github.repo}/milestones --jq '.[] | "\(.number): \(.title)"'
```

**Domain-to-Milestone Mapping:**

| Domain Labels | Suggested Milestone |
|---------------|---------------------|
| `combat`, `gameplay` | PRE-PROD: Core Combat Complete (2) |
| `ai`, `system` | {milestones.game_ai.name} ({milestones.game_ai.number}) |
| `vfx`, `ArtAnim`, `main-char` | PRE-PROD: META (10) |
| `level-design` | PRE-PROD: ENV (1) |
| `UXUI` | PRE-PROD: UIUX COMPLETE (17) |
| `Engineering` (framework) | PRE-PROD: Core Combat Complete (2) |
| Default | PRE-PROD: Core Combat Complete (2) |

**Note:** Query current milestones with `gh api repos/{github.repo}/milestones --jq '.[] | "\(.number): \(.title)"'`

## PR Template Reference

This skill follows the structure from `pull_request_template.md`:

```markdown
## Purpose * :information_source:
{Summary of changes}

**Related Issue:** Closes #{IssueNumber}

## Type of Change :page_facing_up:
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

## Impacted * (MC, BVT, ...):
{Affected areas}

## Request QA *:
- [ ] Yes
- [ ] No

## Performance Impact Assessment *:
**Impact Level**:
- [ ] No Impact
- [ ] Minor
- [ ] Moderate
- [ ] High

{Conditional fields if impact ≠ No Impact}

## Note (optional):
{Additional context}
```

## Workflow

### Step 1: Validate Current Branch

Ensure branch is ready for PR:

```bash
# Get current branch
git rev-parse --abbrev-ref HEAD

# Verify not on main
# If result is "main" → Error
```

**Validation:**
- If on main → Error: "Cannot create PR from main branch"
- Store current branch name

### Step 2: Check for Commits

Verify branch has changes to merge:

```bash
# Get commits ahead of main
git log main...HEAD --oneline --no-decorate
```

**Validation:**
- If no commits → Error: "No commits to create PR. Make changes first."
- Count commits (used for context generation)

### Step 3: Check Remote Status

Determine if branch needs pushing:

```bash
# Check if remote branch exists
git rev-parse --verify origin/{branch} 2>nul
```

**Logic:**
- If remote branch exists:
  - Check if local is ahead: `git rev-list --count origin/{branch}..HEAD`
  - If ahead > 0 → Need to push
- If remote branch doesn't exist:
  - Need to push with `-u` flag

**Normal Mode - If push needed:**
```
Branch "{branch}" not pushed to remote or has unpushed commits.

Push now?
1. Yes, push changes
2. No, cancel PR creation

Your choice: _
```

If user chooses "Yes":
```bash
# Push to remote with upstream tracking
git push -u origin {branch}
```

**--auto Mode - If push needed:**
```
[--auto] Branch "{branch}" not pushed. Auto-pushing...
```

```bash
# Auto-push without prompt
git push -u origin {branch}
```

```
✓ Branch pushed successfully (auto-mode)
```

### Step 4: Check for Existing PR

Avoid duplicate PRs:

```bash
# Check if PR already exists for this branch
gh pr view {branch} --json number,url 2>nul
```

**Logic:**
- If PR exists:
  ```
  Error: PR already exists for this branch

  PR #1234: Existing PR Title
  URL: https://github.com/{github.repo}/pull/1234
  Status: Open

  Actions:
  1. View existing PR: gh pr view {branch}
  2. Update existing PR: Make new commits and push
  3. Close existing PR: gh pr close {branch}

  Cannot create duplicate PR.
  ```
  Exit skill

### Step 5: Extract PR Context

Gather information for PR generation:

```bash
# Get all commits for PR (from main to HEAD)
git log main...HEAD --oneline --no-decorate

# Get file changes with statistics
git diff main...HEAD --stat --no-color

# Get detailed diff for analysis
git diff main...HEAD --name-status
```

**Store:**
- Commit messages (array)
- Changed files with stats
- File change types (A=Added, M=Modified, D=Deleted)

### Step 6: Create Linked Issue (Normal Mode) / Skip ( --auto Mode)

**Normal Mode:**

Invoke github-create-issue skill programmatically:

```markdown
Action: Call /github-create-issue skill
Context: Pass git context from current PR workflow
Mode: Programmatic (skip user prompts if possible)

Expected Return:
- IssueNumber: e.g., 16177
- IssueURL: e.g., https://github.com/{github.repo}/issues/16177
- IssueTitle: e.g., "[ENG-FRAMEWORK-001] Smart IO Creator Tool"
```

**Implementation:**
Use the Skill tool to invoke github-create-issue:

```
Skill(github-create-issue)
```

**Handle Result:**
- If issue creation succeeds:
  - Store IssueNumber
  - Store IssueURL
  - Proceed to PR generation
- If issue creation fails:
  ```
  Error: Failed to create linked issue

  Reason: {Error message from issue skill}

  A linked issue is required for PRs in this workflow.
  Please fix the issue creation error and try again.
  ```
  Exit skill

**--auto Mode:**

Skip issue creation entirely. PR will have no linked issue.

```
[--auto] Skipping issue creation (auto-mode)
```

Set IssueNumber = null, IssueURL = null, IssueTitle = null
Proceed directly to PR generation.

### Step 7: Auto-Generate PR Fields

Build PR content from extracted context:

#### PR Title

**Normal Mode:**
```
Logic:
1. Use issue title (without [TASK-ID] prefix):
   Issue: "[ENG-FRAMEWORK-001] Smart IO Creator Tool"
   PR Title: "Smart IO Creator Tool"

2. Fallback to first commit message if issue creation skipped
3. Ensure < 100 characters
```

**--auto Mode:**
```
Logic:
1. Convert branch name to title:
   Branch: "feature/smart-io-creator-tool"
   Title: "Smart IO Creator Tool"

2. Replace hyphens with spaces, capitalize each word
3. Fallback to first commit message if branch name unclear
4. Ensure < 100 characters
```

#### Purpose Section

```
Logic:
1. Summarize commits into 2-3 sentences:
   - Extract key changes from commit messages
   - Focus on "what" and "why", not "how"
   - Use present tense ("Adds", "Fixes", "Refactors")

2. Add related issue link:
   "**Related Issue:** Closes #{IssueNumber}"

Example:
"Implements Smart IO creator tool with behavior definitions. Adds editor
tooling for creating Smart Objects with modular behavior patterns.
Refactors SipherIOTypes to use class-based definitions.

**Related Issue:** Closes #16177"
```

#### Type of Change Detection

**Normal Mode:**
```
Logic:
1. Detect from branch prefix:
   - "feature/" → Check "New feature"
   - "fix/" or "bugfix/" → Check "Bug fix"
   - "refactor/" → Check "Bug fix" (if improving code)

2. Scan commits for keywords:
   - "BREAKING" or "BREAKING CHANGE" → Check "Breaking change"
   - "docs:", "documentation" → Check "This change requires a documentation update"

3. Default if unclear:
   - Check "New feature" (safest assumption for feature branches)

Example:
- [x] New feature (non-breaking change which adds functionality)
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] Breaking change (...)
- [ ] This change requires a documentation update
```

**--auto Mode:**
```
Logic:
1. Priority detection from branch prefix:
   - "fix/*", "bugfix/*", "hotfix/*" → [x] Bug fix
   - "feature/*" → [x] New feature
   - "docs/*" → [x] Documentation update

2. Scan commits for keywords:
   - "BREAKING CHANGE" in any commit → [x] Breaking change

3. Scan file changes:
   - Only *.md files changed → [x] Documentation update

4. Default:
   - [x] New feature

Auto-tick result - no user prompt.
```

#### Impacted Areas

```
Logic:
1. Extract from changed file paths:
   - Source/S2/Private/Combat/* → "Combat"
   - Source/S2/UI/* → "UI"
   - Content/S2/Core_Char/S2_char_MC/* → "MC" (Main Character)
   - Content/S2/Core_Boss/* → "BVT" (Boss, likely Boss Vertical Test)
   - Plugins/Frameworks/* → "Framework"
   - Content/S2/Maps/* → "Level Design"

2. Format as comma-separated list:
   "Framework, MC, Combat"

3. If no clear mapping:
   "General" or prompt user
```

#### Request QA

**Normal Mode:**
```
Logic:
1. Default based on change type:
   - New feature → Yes
   - Bug fix → Yes
   - Refactor with no gameplay changes → No
   - Documentation only → No

2. Detect from file types:
   - If only *.md files changed → No
   - If *.cpp, *.h, *.uasset changed → Yes

3. Prompt user for confirmation:
   "Request QA testing? (Based on changes: Yes) [Y/n]: "
```

**--auto Mode:**
```
Logic:
1. Auto-detect based on changes:
   - New feature or Bug fix detected → [x] Yes
   - Only docs/config/assets → [x] No
   - Code files (*.cpp, *.h, *.uasset) → [x] Yes

2. Auto-tick result - no user prompt.
```

#### Performance Impact Assessment

**Normal Mode:**
```
Logic:
1. Default: "No Impact"

2. Detect potential impact:
   - If commits mention "performance", "optimize", "fps" → Flag for review
   - If changed files include:
     - */AI/* → Potential impact (AI system)
     - */Tick* → Potential impact (tick functions)
     - */Combat/* → Potential impact (combat loops)

3. If flagged:
   Prompt user:
   "Performance-related changes detected. Impact level?
   1. No Impact
   2. Minor
   3. Moderate
   4. High

   Your choice [1]: "

4. Always include mandatory fields (even if impact = No Impact):

   **Impact Scenario / Locations / Related Issue:**
   - If impact = No Impact → Leave as placeholder text
   - If impact ≠ No Impact → Prompt: "Impact Scenario/Locations: "

   **Regression Test Needed?**
   - If impact = No Impact → Default to "No" (unchecked Yes, checked No)
   - If impact ≠ No Impact → Prompt: "Regression Test Needed? [Y/n]: "

   **[Optional] Additional Notes for QA:**
   - Always include this section
   - Auto-generate based on change type:
     - New feature → "New feature - test {feature description}"
     - Bug fix → "Bug fix - verify {bug description} is resolved"
     - Refactor → "No functional changes expected"
   - User can override/add more context
```

**--auto Mode:**
```
Logic:
1. Priority detection from changed files (first match wins):

   Priority 1 (Moderate Impact):
   - Files matching: M_*.uasset (Materials/Shaders)
   - Folders matching: L_*_dec/* (Level Decoration)
   - Folders matching: L_*_ene/* (Level Enemies)
   - Folders matching: L_*_light/* (Level Lighting)
   → [x] Moderate, [x] Yes regression

   Priority 2 (Minor Impact):
   - Files: */Tick*, */AI/*, */Combat/*
   - AND commits mention: "performance", "optimize", "fps", "frame", "lag", "slow"
   → [x] Minor, [x] Yes regression

   Priority 3 (No Impact):
   - Only docs/config/editor tools (*.md, *.ini, Editor/)
   → [x] No Impact, [x] No regression

   Priority 4 (Default):
   → [x] No Impact, [x] No regression

2. Auto-generate Impact Scenario text:
   - Moderate: "{File descriptions} - may impact {performance area}"
   - Minor: "{File descriptions} - monitor {performance metrics}"
   - No Impact: "N/A"

3. Auto-generate Additional Notes:
   - Moderate: "Verify changes don't cause {specific issues}. Test in relevant areas."
   - Minor: "Monitor {metrics} during {scenarios}."
   - No Impact: "N/A"

4. Auto-tick result - no user prompt.
```

#### Assignee Detection

```
Logic:
1. Auto-assign to current git user:
   - Get git config: git config user.email
   - Map email to GitHub username:
     - Query: gh api user --jq '.login'
   - Default assignee: current user

2. Fallback if mapping fails:
   - Prompt user: "Assign to (GitHub username or 'none'): "
   - Validate username exists: gh api users/{username}

3. Multiple assignees:
   - Support comma-separated list
   - Validate each username

Example:
- Auto-detected: @DuyTranSipher
- User can override or add more
```

#### Label Detection

```
Logic:
1. Reuse label detection from github-create-issue skill:
   - Map file paths to domain labels
   - Source/S2/Private/Combat/* → combat, Engineering
   - Source/S2/UI/* → UXUI, Engineering
   - Content/S2/Core_VFX/* → vfx
   - *.cpp, *.h → Engineering

2. Add PR-specific labels:
   - All PRs → "task"
   - feature/* branches → "enhancement"
   - fix/* or bugfix/* branches → "bug"

3. Validate labels exist:
   - Query: gh label list --json name
   - Remove invalid labels
   - Warn user if label doesn't exist

Example labels: task, Engineering, combat, enhancement
```

#### Milestone Detection

```
Logic:
1. Query available milestones:
   - Command: gh api repos/{github.repo}/milestones --jq '.[] | "\(.number): \(.title)"'
   - Get current open milestones

2. Auto-select based on domain labels (priority order):
   - If "combat" or "gameplay" in labels → PRE-PROD: Core Combat Complete (2)
   - If "ai" in labels → {milestones.game_ai.name} ({milestones.game_ai.number})
   - If "system" in labels → {milestones.game_ai.name} ({milestones.game_ai.number})
   - If "vfx" or "ArtAnim" in labels → PRE-PROD: META (10)
   - If "level-design" in labels → PRE-PROD: ENV (1)
   - If "UXUI" in labels → PRE-PROD: UIUX COMPLETE (17)
   - If "Engineering" (framework code) → PRE-PROD: Core Combat Complete (2)
   - If linked issue has milestone → Use same milestone
   - Default → PRE-PROD: Core Combat Complete (2)

3. Store milestone number (not title) for gh CLI

Example:
Labels: task, Engineering, system
Auto-detected Milestone: {milestones.game_ai.name} ({milestones.game_ai.number})
```

#### Project Assignment

```
Logic:
1. Default project: "{project.fullname}" (number {github.project_number})
2. Project ID: {github.project_node_id}
3. After PR creation, add to project board:
   gh project item-add {github.project_number} --owner {github.owner} --url {pr_url}

Note: The --project flag in gh pr create may not work reliably.
Use gh project item-add after creation for guaranteed assignment.
```

## ⚠️ CRITICAL: Template Compliance

**MANDATORY:** The PR body MUST use the EXACT template structure defined below.

**NEVER use alternative formats such as:**
- `## Summary` / `## Changes` / `## Test plan` / `## Issues`
- `## Description` / `## What Changed`
- Any custom section headers

**REQUIRED sections (in order):**
1. `## Purpose * :information_source:` - with `**Related Issue:** Closes #X`
2. `## Type of Change :page_facing_up:` - with checkboxes
3. `## Impacted * (MC, BVT, ...):` - affected areas
4. `## Request QA *:` - Yes/No checkboxes
5. `## Performance Impact Assessment *:` - with all subsections
6. `## Note (optional):` - additional context

**Validation Checklist:**
- [ ] PR body starts with `## Purpose * :information_source:`
- [ ] Contains `**Related Issue:** Closes #` line
- [ ] Has `## Type of Change :page_facing_up:` with checkboxes
- [ ] Has `## Impacted *` section
- [ ] Has `## Request QA *:` with Yes/No
- [ ] Has `## Performance Impact Assessment *:` with Impact Level and all subsections
- [ ] Ends with `## Note (optional):`

If the PR body does not match this exact structure, the skill has FAILED.

### Step 8: Build PR Body

**Normal Mode:**

Construct complete PR body following template:

```markdown
## Purpose * :information_source:
{Auto-generated purpose}

**Related Issue:** Closes #{IssueNumber}

## Type of Change :page_facing_up:
{Checkboxes with detected types checked}

## Impacted * (MC, BVT, ...):
{Auto-detected areas}

## Request QA *:
{Checkbox based on detection}

## Performance Impact Assessment *:
**Impact Level** *(select one)*:
{Checkbox for selected impact level}

> If ⚠️ ⚠️ ⚠️ **Impact Level ≠ No Impact**, please fill in the following mandatory fields:

**Impact Scenario / Locations / Related Issue:** (e.g., "BVT Boss Fight", "Walk in Tower area", or link to related Git issue)
{User input if impact ≠ No Impact, otherwise leave as placeholder}

**Regression Test Needed?**
- [ ] Yes
- [x] No
{Default to No if impact = No Impact, otherwise ask user}

**[Optional] Additional Notes for QA:**
{User input or auto-generated QA notes, can be empty}

## Note (optional):
{Additional context from user or empty}
```

**--auto Mode:**

Same structure, but:
- **Related Issue:** "N/A (auto-mode)" instead of "Closes #X"
- All checkboxes pre-ticked based on auto-detection
- Impact Scenario auto-generated from file analysis
- Additional Notes auto-generated
- Note section includes: "Auto-generated PR via --auto flag."

**IMPORTANT:** The "Regression Test Needed?" and "[Optional] Additional Notes for QA:" sections MUST ALWAYS be present, even when Impact Level = "No Impact". These are mandatory template fields.

**Example:**
```markdown
## Purpose * :information_source:
Implements Smart IO creator tool with behavior definitions. Adds editor tooling for creating Smart Objects with modular behavior patterns. Refactors SipherIOTypes to use class-based definitions.

**Related Issue:** Closes #16177

## Type of Change :page_facing_up:
- [x] New feature (non-breaking change which adds functionality)
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

## Impacted * (MC, BVT, ...):
Framework, Smart Objects

## Request QA *:
- [x] Yes
- [ ] No

## Performance Impact Assessment *:
**Impact Level** *(select one)*:
- [x] No Impact
- [ ] Minor
- [ ] Moderate
- [ ] High

> If ⚠️ ⚠️ ⚠️ **Impact Level ≠ No Impact**, please fill in the following mandatory fields:

**Impact Scenario / Locations / Related Issue:** (e.g., "BVT Boss Fight", "Walk in Tower area", or link to related Git issue)

**Regression Test Needed?**
- [ ] Yes
- [x] No

**[Optional] Additional Notes for QA:**
Smart Object creator tool - editor-only, no runtime impact.

## Note (optional):
Tested with existing Smart Object implementations. No breaking changes to existing systems.
```

### Step 9: Present Draft to User

**Normal Mode:**

Display complete PR draft for review:

```
═══════════════════════════════════════
DRAFT PULL REQUEST
═══════════════════════════════════════

Title: Smart IO Creator Tool
Base: main ← Head: feature/smart-io-creator-tool
Linked Issue: #16177

═══════════════════════════════════════
BODY PREVIEW
═══════════════════════════════════════
## Purpose * :information_source:
Implements Smart IO creator tool with behavior definitions...

**Related Issue:** Closes #16177

## Type of Change :page_facing_up:
- [x] New feature
...

═══════════════════════════════════════

Options:
1. Create PR with this draft
2. Edit specific fields
3. Cancel

Your choice (1/2/3): _
```

**User Interaction:**

If user chooses "2. Edit specific fields":
```
Which field to edit?
a. Title
b. Purpose
c. Type of Change
d. Impacted Areas
e. Request QA
f. Performance Impact
g. Additional Notes
h. Milestone
i. Done editing, create PR

Your choice: _
```

For each field:
1. Show current value
2. Prompt for new value
3. Validate input
4. Update draft
5. Show updated preview
6. Return to field selection menu

**--auto Mode:**

Display complete PR draft with pre-ticked values:

```
═══════════════════════════════════════
DRAFT PULL REQUEST (Auto-Generated)
═══════════════════════════════════════

Title: Smart IO Creator Tool
Base: main ← Head: feature/smart-io-creator-tool
Linked Issue: N/A (auto-mode)

All fields auto-detected and pre-ticked based on file analysis.
Type: New feature | Impact: Moderate | QA: Yes

═══════════════════════════════════════
BODY PREVIEW
═══════════════════════════════════════
## Purpose * :information_source:
Implements Smart IO creator tool with behavior definitions...

**Related Issue:** N/A (auto-mode)

## Type of Change :page_facing_up:
- [x] New feature (auto-detected from branch prefix)
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

## Impacted * (MC, BVT, ...):
Framework, Smart Objects

## Request QA *:
- [x] Yes (auto-detected: code changes)
- [ ] No

## Performance Impact Assessment *:
**Impact Level** *(select one)*:
- [ ] No Impact
- [ ] Minor
- [x] Moderate (auto-detected: M_*.uasset files changed)
- [ ] High

> If ⚠️ ⚠️ ⚠️ **Impact Level ≠ No Impact**, please fill in the following mandatory fields:

**Impact Scenario / Locations / Related Issue:** (e.g., "BVT Boss Fight", "Walk in Tower area", or link to related Git issue)
Material shader changes: M_MasterCharacter, M_MasterEnvironment - may impact rendering performance across all levels using these materials.

**Regression Test Needed?**
- [x] Yes (auto-detected: performance impact)
- [ ] No

**[Optional] Additional Notes for QA:**
Verify material changes don't cause shader compilation stutter. Test on BVT and open world areas.

## Note (optional):
Auto-generated PR via --auto flag.

═══════════════════════════════════════

Create PR with these auto-detected values?
[Y/n]: _
```

**User Interaction (--auto):**
- User enters `Y` or presses Enter → Proceed to Step 10, create PR
- User enters `n` → Cancel and exit
- NO "Edit" option in --auto mode (use normal mode for editing)

### Step 10: Create Pull Request

Submit PR via gh CLI with ALL required metadata:

```bash
# MANDATORY: All these flags must be present
gh pr create \
  --base main \
  --head {current-branch} \
  --title "Smart IO Creator Tool" \
  --body "$(cat <<'EOF'
## Purpose * :information_source:
Implements Smart IO creator tool...

**Related Issue:** Closes #16177

## Type of Change :page_facing_up:
...
EOF
)" \
  --assignee {auto-detected-username} \
  --label "task,Engineering,gameplay" \
  --milestone 2 \
  --repo {github.repo}
```

**⚠️ CRITICAL - All flags are REQUIRED:**
- `--assignee`: Auto-detect via `gh api user --jq '.login'`
- `--label`: Always include `task`, plus domain labels from file changes
- `--milestone`: Use NUMBER (not title) - default is 2 (PRE-PROD: Core Combat Complete)
- `--base main`: Target branch
- `--head {branch}`: Source branch
- `--repo {github.repo}`: Repository

**If `gh pr create` fails to set labels/milestone, use API fallback:**
```bash
gh api repos/{github.repo}/issues/{pr_number} -X PATCH \
  -f milestone=2 \
  -f "labels[]=task" \
  -f "labels[]=Engineering" \
  -f "labels[]=gameplay"
```

**Parse Output:**
```
Example output:
https://github.com/{github.repo}/pull/1234

Extract:
- PR URL (full)
- PR number (1234)
```

### Step 11: Add PR to Project Board

After PR creation, add to {project.fullname} project:

```bash
gh project item-add {github.project_number} --owner {github.owner} --url https://github.com/{github.repo}/pull/1234
```

**Logic:**
1. Use project number {github.project_number} ({project.fullname})
2. Pass the newly created PR URL
3. If fails due to missing scope, warn user:
   ```
   Warning: Could not add PR to project board.
   Run: gh auth refresh -s project
   Then manually add at: https://github.com/orgs/{github.owner}/projects/{github.project_number}
   ```

### Step 12: Return Success Info

Output formatted success message with both PR and issue info:

```
✓ Pull Request created successfully!

PR #1234: Smart IO Creator Tool
URL: https://github.com/{github.repo}/pull/1234

Linked Issue: #16177
URL: https://github.com/{github.repo}/issues/16177

Branch: feature/smart-io-creator-tool → main
Status: Open (ready for review)

Summary:
- Type: New feature
- Impacted: Framework, Smart Objects
- QA Requested: Yes
- Performance Impact: No Impact
- Milestone: GAME-AI
- Project: {project.fullname}

Next steps:
1. Request reviewers:
   gh pr edit 1234 --add-reviewer @username

2. Monitor CI checks:
   gh pr checks 1234

3. Address review feedback:
   - Make changes locally
   - Commit and push
   - PR will auto-update

4. Update project board status:
   - Set Status to "In Review"

View PR: gh pr view 1234
View in browser: gh pr view 1234 --web
```

## Error Handling

### Error: Not Authenticated

```
Command failed: gh auth status
Error: GitHub CLI not authenticated

Solution:
1. Run: gh auth login
2. Select: GitHub.com
3. Choose: HTTPS or SSH
4. Authenticate in browser
5. Verify: gh auth status

Then run this skill again.
```

### Error: On Main Branch

```
Error: Cannot create PR from main branch
Current branch: main

Reason: Pull requests require a feature/fix branch as source.

Solution:
1. Create a feature branch:
   git checkout -b feature/your-feature-name

2. Make your changes and commit

3. Run this skill again from the feature branch
```

### Error: No Commits

```
Error: No commits to create PR
Branch "feature/smart-io-creator" has no commits ahead of main

Solution:
1. Make your changes
2. Commit your changes:
   git add .
   git commit -m "Your commit message"
3. Run this skill again

Current status:
git log main...HEAD → (empty)
```

### Error: Branch Not Pushed

```
Branch "feature/smart-io-creator" not pushed to remote.

Push now?
1. Yes, push changes
2. No, cancel PR creation

Your choice: 1

[Pushing branch...]
git push -u origin feature/smart-io-creator

✓ Branch pushed successfully!
[Continuing with PR creation...]
```

### Error: PR Already Exists

```
Error: Pull request already exists for this branch

PR #1234: Existing PR Title
URL: https://github.com/{github.repo}/pull/1234
Status: Open
Created: 2025-12-20

Actions:
1. View existing PR:
   gh pr view feature/smart-io-creator --web

2. Update existing PR:
   - Make new commits on this branch
   - Push: git push
   - PR will automatically update

3. Close existing PR (if you want to recreate):
   gh pr close 1234
   Then run this skill again

Cannot create duplicate PR for the same branch.
```

### Error: Issue Creation Failed

```
Error: Failed to create linked issue

Reason: Label 'nonexistent-label' doesn't exist in repository

A linked issue is required for PRs in this workflow.

Solution:
1. Fix the issue creation error (check labels, authentication, etc.)
2. Run this skill again

Alternatively:
- Create issue manually first
- Then create PR with --issue flag: /github-create-pr --issue 16177
```

### Error: Network/API Error

```
Error: Failed to create pull request

Command: gh pr create ...
Output: {error message from gh CLI}

Common causes:
1. Network connectivity issues
2. Repository permissions
3. Branch protection rules
4. API rate limiting

Solution:
1. Verify network connection
2. Check repository access: gh repo view {github.repo}
3. Retry after a moment (if rate limited)
4. Check branch protection rules on main

Try again: /github-create-pr
```

## Advanced Usage

### --auto Mode (Fully Automated)

Create PR with zero interactive prompts:

```bash
Invocation: /github-create-pr --auto
```

**Behavior:**
1. Auto-pushes branch if needed (no prompt)
2. **Skips issue creation** - PR has no linked issue
3. Auto-detects all fields from branch name and file changes
4. Shows single confirmation with pre-ticked values
5. No field editing option (Y/n only)

**Auto-Detection Rules:**

| Field | Detection Rule |
|-------|----------------|
| **Title** | Branch name converted: `feature/smart-io` → "Smart Io" |
| **Type** | `feature/*` → New feature, `fix/*` → Bug fix, `*.md` only → Documentation |
| **QA** | Code changes → Yes, docs only → No |
| **Performance** | `M_*.uasset`, `L_*_dec/*`, `L_*_ene/*`, `L_*_light/*` → Moderate; `*/Tick*`, `*/AI/*`, `*/Combat/*` → Minor |
| **Regression** | Moderate/High/Minor impact → Yes; No Impact → No |

**Example:**
```bash
/github-create-pr --auto

[--auto] Validating branch...
✓ Current branch: feature/update-master-materials

[--auto] Checking commits...
✓ 3 commits ahead of main

[--auto] Checking remote status...
✓ Remote up to date

[--auto] Skipping issue creation (auto-mode)

[--auto] Auto-detecting fields...
✓ Type: New feature (from branch prefix)
✓ Performance: Moderate (M_*.uasset detected)
✓ QA: Yes (code changes)
✓ Regression: Yes (performance impact)

═══════════════════════════════════════
DRAFT PULL REQUEST (Auto-Generated)
═══════════════════════════════════════
...

Create PR with these auto-detected values?
[Y/n]: Y

[--auto] Creating PR...
✓ Pull Request created successfully!

PR #1234: Update Master Materials
URL: https://github.com/{github.repo}/pull/1234
```

### Specify Existing Issue

Link to existing issue instead of creating new one:

```bash
Invocation: /github-create-pr --issue 16177
```

**Workflow:**
1. Skip Step 6 (issue creation)
2. Use provided issue number
3. Fetch issue details: `gh issue view 16177 --json title,url`
4. Use issue title for PR title
5. Proceed with PR generation

### Specify Base Branch

Target different base branch (not main):

```bash
Invocation: /github-create-pr --base develop
```

**Workflow:**
1. Use specified base instead of main
2. All git operations use: main → {base}
3. PR created with: --base {base}

### Quick Mode

Skip review step, create immediately:

```bash
Invocation: /github-create-pr --quick
```

**Workflow:**
1. Auto-generate all fields
2. Create issue (auto-mode)
3. Create PR immediately
4. Return URLs

Use when confident in auto-generation.

### Draft PR

Create as draft (not ready for review):

```bash
Invocation: /github-create-pr --draft
```

**Workflow:**
1. Normal workflow
2. Add `--draft` flag to gh pr create
3. PR created in draft state
4. Can be marked ready later: `gh pr ready {number}`

### Update Existing PR

Update an existing PR with missing metadata (assignees, labels, project, milestone):

```bash
Invocation: /github-create-pr --update 16226
```

**Workflow:**

1. **Fetch Existing PR:**
   ```bash
   gh pr view 16226 --json number,title,headRefName,labels,assignees,projectCards,milestone
   ```

2. **Auto-Detect Missing Fields:**
   - Check current assignees → If empty, detect from git user
   - Check current labels → If missing domain labels, detect from file changes
   - Check project assignment → If not assigned, add to "{project.fullname}"
   - Check milestone → If not set, prompt user or use issue milestone

3. **Update PR Metadata:**
   ```bash
   # Add assignees
   gh pr edit 16226 --add-assignee DuyTranSipher

   # Add labels
   gh pr edit 16226 --add-label "task,Engineering,combat,enhancement"

   # Add to project (requires project scope)
   gh project item-add {project-id} --owner {github.owner} --url https://github.com/{github.repo}/pull/16226

   # Set milestone
   gh pr edit 16226 --milestone {milestone-number}
   ```

4. **Report Updates:**
   ```
   ✓ PR #16226 updated successfully!

   Added assignees: @DuyTranSipher
   Added labels: task, Engineering, combat, enhancement
   Added to project: {project.fullname}
   Set milestone: Sprint 24

   View PR: gh pr view 16226 --web
   ```

**Use Cases:**
- PR created without metadata (using basic gh pr create)
- PR created by external tool or script
- Bulk update PRs with missing fields
- Correct missing project/milestone assignments

**Example:**
```bash
# Update PR 16226 with full metadata
/github-create-pr --update 16226

# Auto-detect and apply:
# - Assignee: DuyTranSipher (from git user)
# - Labels: task, Engineering, combat (from file changes)
# - Project: {project.fullname}
# - Milestone: (prompt user if not set)
```

## Integration with Other Skills

### Calls github-create-issue

This skill programmatically invokes github-create-issue:

```markdown
Step 6: Create linked issue
Action: Invoke /github-create-issue skill
Context: Use same git context (branch, commits, diff)
Mode: Automatic (minimal prompts)
Result: Issue #16177 created
Use: Link in PR body with "Closes #16177"
```

The github-create-issue skill returns:
- IssueNumber
- IssueURL
- IssueTitle

These are used in PR generation.

## Success Criteria

- [x] Skill file created at `./SKILL.md`
- [ ] Validates branch (not main, has commits)
- [ ] Checks remote status, pushes if needed
- [ ] Checks for existing PR
- [ ] Extracts PR context from git
- [ ] Invokes github-create-issue skill
- [ ] Receives issue number from issue skill
- [ ] Auto-generates PR title from issue
- [ ] Auto-generates purpose from commits
- [ ] Detects change type from branch/commits
- [ ] Detects impacted areas from file changes
- [ ] Determines QA request based on changes
- [ ] Assesses performance impact
- [ ] Auto-detects milestone from domain labels
- [ ] Adds PR to {project.fullname} project board
- [ ] Builds PR body following template
- [ ] Presents draft for user review
- [ ] Allows field editing (including milestone)
- [ ] Creates PR with gh CLI
- [ ] Assigns milestone via --milestone flag
- [ ] Includes "Closes #{IssueNumber}" in body
- [ ] Returns PR and issue URLs
- [ ] Handles authentication errors
- [ ] Handles unpushed branch
- [ ] Handles existing PR
- [ ] Handles issue creation failure
- [ ] Handles missing project scope
- [ ] Supports --issue flag for existing issues
- [ ] Supports --base flag for custom base
- [ ] Supports --quick flag for skip review
- [ ] Supports --draft flag for draft PRs
- [ ] Supports --update flag for updating existing PRs
- [ ] **Supports --auto flag for fully automated PR creation**
- [ ] **--auto mode auto-pushes without prompt**
- [ ] **--auto mode skips issue creation**
- [ ] **--auto mode auto-detects all fields from branch/files**
- [ ] **--auto mode shows pre-ticked draft with single Y/n confirm**
- [ ] **--auto mode disables field editing**
- [ ] **--auto mode detects M_*.uasset as Moderate impact**
- [ ] **--auto mode detects L_*_dec/ene/light/* as Moderate impact**
- [ ] **--auto mode detects */Combat/*, */AI/* as Minor impact**
- [ ] **--auto mode detects docs only as No Impact, No QA**

## Example Sessions

### Session 1: Successful PR Creation

```
User: /github-create-pr

[Validating environment...]
✓ Current branch: feature/smart-io-creator-tool
✓ 15 commits ahead of main
✓ Remote branch exists and is up to date

[Creating linked issue...]
✓ Issue #16177 created

[Generating PR draft...]

═══════════════════════════════════════
DRAFT PULL REQUEST
═══════════════════════════════════════
Title: Smart IO Creator Tool
Base: main ← Head: feature/smart-io-creator-tool
Linked Issue: #16177
═══════════════════════════════════════

Options:
1. Create PR with this draft
2. Edit specific fields
3. Cancel

Your choice: 1

[Creating pull request...]

✓ Pull Request created successfully!

PR #1234: Smart IO Creator Tool
URL: https://github.com/{github.repo}/pull/1234

Linked Issue: #16177
URL: https://github.com/{github.repo}/issues/16177

Branch: feature/smart-io-creator-tool → main
Status: Open (ready for review)
```

### Session 2: Branch Not Pushed

```
User: /github-create-pr

[Validating environment...]
✓ Current branch: feature/new-combat-system
✓ 8 commits ahead of main
⚠ Remote branch not found

Branch "feature/new-combat-system" not pushed to remote.

Push now?
1. Yes, push changes
2. No, cancel PR creation

Your choice: 1

[Pushing branch...]
✓ Branch pushed to origin/feature/new-combat-system

[Continuing with PR creation...]
[Creating linked issue...]
✓ Issue #16178 created
...
```

### Session 3: Edit Before Creation

```
User: /github-create-pr

[Draft presented]

Your choice: 2

Which field to edit?
a. Title
...
f. Performance Impact
...

Your choice: f

Current impact: No Impact

Performance impact detected in changed files:
- Source/S2/Private/AI/PathfindingOptimization.cpp

Select impact level:
1. No Impact
2. Minor
3. Moderate
4. High

Your choice: 2

Impact Scenario/Locations: AI pathfinding in open world areas

Regression Test Needed? [Y/n]: Y

Additional Notes for QA: Test with 50+ AI agents in Tower area

✓ Performance impact updated

[Updated draft shown]

Your choice: h (Done editing, create PR)

✓ Pull Request created successfully!
```

### Session 4: PR Already Exists

```
User: /github-create-pr

[Validating environment...]
✓ Current branch: feature/smart-io-creator-tool

Error: Pull request already exists for this branch

PR #1234: Smart IO Creator Tool
URL: https://github.com/{github.repo}/pull/1234
Status: Open

Actions:
1. View existing PR: gh pr view 1234 --web
2. Update by making new commits and pushing
3. Close and recreate: gh pr close 1234

Cannot create duplicate PR.
```

### Session 5: --auto Mode with Material Changes (Moderate Impact)

```
User: /github-create-pr --auto

[--auto] Validating branch...
✓ Current branch: feature/update-master-materials

[--auto] Checking commits...
✓ 3 commits ahead of main

[--auto] Checking remote status...
⚠ Remote branch not found
[--auto] Auto-pushing branch...
✓ Branch pushed to origin/feature/update-master-materials

[--auto] Skipping issue creation (auto-mode)

[--auto] Analyzing changed files...
- Content/Materials/M_MasterCharacter.uasset
- Content/Materials/M_MasterEnvironment.uasset

[--auto] Auto-detecting fields...
✓ Title: Update Master Materials
✓ Type: New feature (from branch prefix)
✓ Impacted: Materials, Rendering
✓ QA: Yes (code/asset changes)
✓ Performance: Moderate (M_*.uasset detected)
✓ Regression: Yes (performance impact)

═══════════════════════════════════════
DRAFT PULL REQUEST (Auto-Generated)
═══════════════════════════════════════

Title: Update Master Materials
Base: main ← Head: feature/update-master-materials
Linked Issue: N/A (auto-mode)

All fields auto-detected and pre-ticked based on file analysis.
Type: New feature | Impact: Moderate | QA: Yes

═══════════════════════════════════════
BODY PREVIEW
═══════════════════════════════════════
## Purpose * :information_source:
Updates master material definitions for character and environment shaders.

**Related Issue:** N/A (auto-mode)

## Type of Change :page_facing_up:
- [x] New feature (non-breaking change which adds functionality)
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

## Impacted * (MC, BVT, ...):
Materials, Rendering

## Request QA *:
- [x] Yes (auto-detected: code/asset changes)
- [ ] No

## Performance Impact Assessment *:
**Impact Level** *(select one)*:
- [ ] No Impact
- [ ] Minor
- [x] Moderate (auto-detected: M_*.uasset files changed)
- [ ] High

> If ⚠️ ⚠️ ⚠️ **Impact Level ≠ No Impact**, please fill in the following mandatory fields:

**Impact Scenario / Locations / Related Issue:** (e.g., "BVT Boss Fight", "Walk in Tower area", or link to related Git issue)
Material shader changes: M_MasterCharacter, M_MasterEnvironment - may impact rendering performance across all levels using these materials.

**Regression Test Needed?**
- [x] Yes (auto-detected: performance impact)
- [ ] No

**[Optional] Additional Notes for QA:**
Verify material changes don't cause shader compilation stutter. Test on BVT and open world areas.

## Note (optional):
Auto-generated PR via --auto flag.

═══════════════════════════════════════

Create PR with these auto-detected values?
[Y/n]: Y

[--auto] Creating PR...
✓ Pull Request created successfully!

PR #1234: Update Master Materials
URL: https://github.com/{github.repo}/pull/1234

Branch: feature/update-master-materials → main
Status: Open (ready for review)

Summary:
- Type: New feature
- Impacted: Materials, Rendering
- QA Requested: Yes
- Performance Impact: Moderate
- Regression Test: Yes
```

### Session 6: --auto Mode with Level Decoration (Moderate Impact)

```
User: /github-create-pr --auto

[--auto] Validating branch...
✓ Current branch: fix/tower-decorations

[--auto] Checking commits...
✓ 2 commits ahead of main

[--auto] Checking remote status...
✓ Remote up to date

[--auto] Skipping issue creation (auto-mode)

[--auto] Analyzing changed files...
- Content/Levels/L_Tower_dec/FlowerPots.uasset
- Content/Levels/L_Tower_dec/Banners.uasset

[--auto] Auto-detecting fields...
✓ Title: Tower Decorations
✓ Type: Bug fix (from branch prefix)
✓ Impacted: L_Tower_dec, Environment
✓ QA: Yes (asset changes)
✓ Performance: Moderate (L_*_dec/* detected)
✓ Regression: Yes (performance impact)

═══════════════════════════════════════
DRAFT PULL REQUEST (Auto-Generated)
═══════════════════════════════════════
...
## Type of Change :page_facing_up:
- [ ] New feature
- [x] Bug fix (auto-detected from branch prefix)
...
## Performance Impact Assessment *:
**Impact Level** *(select one)*:
- [ ] No Impact
- [ ] Minor
- [x] Moderate (auto-detected: L_*_dec/* files changed)
- [ ] High

**Impact Scenario / Locations / Related Issue:**
Level decoration changes: L_Tower_dec - may impact GPU memory and draw calls in Tower area.

**Regression Test Needed?**
- [x] Yes (auto-detected: performance impact)
- [ ] No

**[Optional] Additional Notes for QA:**
Verify decoration changes don't cause frame drops in Tower area. Check draw call counts.
...
═══════════════════════════════════════

Create PR with these auto-detected values?
[Y/n]: Y

[--auto] Creating PR...
✓ Pull Request created successfully!

PR #1235: Tower Decorations
URL: https://github.com/{github.repo}/pull/1235
```

### Session 7: --auto Mode with Combat Code (Minor Impact)

```
User: /github-create-pr --auto

[--auto] Validating branch...
✓ Current branch: feature/new-combo-system

[--auto] Checking commits...
✓ 8 commits ahead of main

[--auto] Analyzing changed files...
- Source/S2/Private/Combat/SipherComboGraph.cpp
- Source/S2/Public/Combat/SipherComboGraph.h

[--auto] Auto-detecting fields...
✓ Title: New Combo System
✓ Type: New feature
✓ Impacted: Combat, MC
✓ QA: Yes (code changes)
✓ Performance: Minor (*/Combat/* detected)
✓ Regression: Yes (performance impact)

═══════════════════════════════════════
DRAFT PULL REQUEST (Auto-Generated)
═══════════════════════════════════════
...
## Performance Impact Assessment *:
**Impact Level** *(select one)*:
- [ ] No Impact
- [x] Minor (auto-detected: */Combat/* files changed)
- [ ] Moderate
- [ ] High

**Impact Scenario / Locations / Related Issue:**
Combat system changes - monitor frame times during heavy combat scenarios.

**Regression Test Needed?**
- [x] Yes (auto-detected: performance impact)
- [ ] No

**[Optional] Additional Notes for QA:**
New feature - test combo transitions and ability chaining in combat. Verify no frame drops during combo execution.
...
═══════════════════════════════════════

Create PR with these auto-detected values?
[Y/n]: Y

[--auto] Creating PR...
✓ Pull Request created successfully!

PR #1236: New Combo System
URL: https://github.com/{github.repo}/pull/1236
```

### Session 8: --auto Mode with Documentation Only (No Impact)

```
User: /github-create-pr --auto

[--auto] Validating branch...
✓ Current branch: feature/update-readme

[--auto] Checking commits...
✓ 1 commit ahead of main

[--auto] Analyzing changed files...
- README.md
- docs/setup.md

[--auto] Auto-detecting fields...
✓ Title: Update Readme
✓ Type: Documentation update (only *.md files)
✓ Impacted: Documentation
✓ QA: No (documentation only)
✓ Performance: No Impact (documentation only)
✓ Regression: No (no impact)

═══════════════════════════════════════
DRAFT PULL REQUEST (Auto-Generated)
═══════════════════════════════════════
...
## Type of Change :page_facing_up:
- [ ] New feature
- [ ] Bug fix
- [ ] Breaking change
- [x] This change requires a documentation update (auto-detected: only *.md files)

## Impacted * (MC, BVT, ...):
Documentation

## Request QA *:
- [ ] Yes
- [x] No (auto-detected: documentation only)

## Performance Impact Assessment *:
**Impact Level** *(select one)*:
- [x] No Impact (auto-detected: documentation only)
- [ ] Minor
- [ ] Moderate
- [ ] High

> If ⚠️ ⚠️ ⚠️ **Impact Level ≠ No Impact**, please fill in the following mandatory fields:

**Impact Scenario / Locations / Related Issue:** (e.g., "BVT Boss Fight", "Walk in Tower area", or link to related Git issue)
N/A

**Regression Test Needed?**
- [ ] Yes
- [x] No (auto-detected: no performance impact)

**[Optional] Additional Notes for QA:**
N/A
...
═══════════════════════════════════════

Create PR with these auto-detected values?
[Y/n]: Y

[--auto] Creating PR...
✓ Pull Request created successfully!

PR #1237: Update Readme
URL: https://github.com/{github.repo}/pull/1237
```

### Session 9: --auto Mode Cancelled

```
User: /github-create-pr --auto

[--auto] Validating branch...
✓ Current branch: feature/experimental-feature

[--auto] Checking commits...
✓ 5 commits ahead of main

[--auto] Skipping issue creation (auto-mode)

[--auto] Auto-detecting fields...
✓ Title: Experimental Feature
✓ Type: New feature
✓ Performance: No Impact
...

═══════════════════════════════════════
DRAFT PULL REQUEST (Auto-Generated)
═══════════════════════════════════════
...

Create PR with these auto-detected values?
[Y/n]: n

[--auto] Cancelled by user. No PR created.
```

## Notes

- All `gh` commands are already permitted in `settings.local.json`
- Project: "{project.fullname}" (number {github.project_number}, ID: {github.project_node_id})
- Repository is hardcoded: {github.repo}
- Base branch defaults to: main
- No Claude attribution footer (per CLAUDE.md guidelines)
- PR template follows `pull_request_template.md` structure
- Issue creation is required in normal mode (linked via "Closes #X")
- **--auto mode skips issue creation - PR has no linked issue**
- Can use existing issue with --issue flag
- Supports draft PRs with --draft flag
- Auto-detects change type, impacted areas, QA needs
- Performance impact assessment with conditional fields
- Milestone is assigned via --milestone NUMBER (not title)
- Domain-to-milestone mapping auto-selects appropriate milestone
- Project assignment via `gh project item-add` after PR creation
- Project assignment requires `project` scope: `gh auth refresh -s project`
- **--auto mode is ideal for rapid iteration when issue tracking is not required**
- **--auto mode pattern matching: M_*.uasset, L_*_dec/ene/light/*, */Tick*, */AI/*, */Combat/**

## Legacy Metadata

```yaml
skill: github-create-pr
invoke: /github-workflow:github-create-pr
type: workflow
category: github
scope: project-root
flags:
  - '--auto': Fully automated PR creation without interactive prompts
  - '--issue': Use existing issue instead of creating new
  - '--base': Target different base branch
  - '--quick': Skip review, create immediately
  - '--draft': Create as draft PR
  - '--update': Update existing PR with metadata
```
