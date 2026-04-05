---
name: github-create-issue
description: Create GitHub task issues with hybrid auto-generation and user review
---

## Configuration
This skill reads project-specific values from `skills.config.json` at the repository root.
Required keys: `github.repo`, `github.owner`, `github.project_number`, `milestones.*`, `team.*`
If not found, prompt the user for repository and project details.

# GitHub Issue Creator Skill

**Role:** GitHub Issue Automation
**Scope:** Project-wide issue creation with intelligent context extraction
**Platform:** Windows + gh CLI
**Repository:** {github.repo}
**Project:** {project.fullname}

## Objective

Create well-formed GitHub task issues by extracting context from git history, auto-generating draft content, and guiding user review before submission. Integrates with project boards and validates labels.

## Prerequisites

Before using this skill:
1. Ensure `gh` CLI is authenticated: `gh auth status`
2. Verify project scope: `gh auth refresh -s project` (if needed)
3. Working in a feature branch (not main)

## Issue Templates

**CRITICAL:** Always read templates from `.github/ISSUE_TEMPLATE/` before creating issues.

### Available Templates

| Template File | Type | Use Case |
|---------------|------|----------|
| `task.md` | Task | New features, improvements, planned work |
| `bug.md` | Bug | Defects, crashes, unexpected behavior |
| `vfx_task.md` | VFX Task | VFX team work items |
| `ene_proto.md` | Enemy Prototype | GD enemy/elite/boss prototypes |
| `2d_3d_task.md` | Art Task | 2D/3D art work items |
| `epic.md` | Epic | Large feature epics |
| `feature_request.md` | Feature Request | New feature proposals |

### Template Selection Logic

```
1. Read user input or detect from context:
   - Keywords "bug", "fix", "crash", "broken" → bug.md
   - Keywords "vfx", "particle", "effect" → vfx_task.md
   - Keywords "enemy", "boss", "elite", "prototype" → ene_proto.md
   - Keywords "art", "texture", "model", "asset" → 2d_3d_task.md
   - Keywords "epic", "milestone", "phase" → epic.md
   - Default → task.md

2. Read selected template:
   Read .github/ISSUE_TEMPLATE/{selected_template}

3. Parse template structure to extract:
   - Required sections
   - Default labels from frontmatter
   - Title format from frontmatter
```

### Template Formatting Rules

Per `create-gitissue-guidelines.md`:

| Rule | Description |
|------|-------------|
| Line breaks | Use `<br />` instead of newlines in body |
| Headers | Use `**Header**<br />` instead of `## Header` |
| Bold | Section headers only |
| Dates | Always YYYY-MM-DD format, calculated manually |

### Title Format

```
Format: task_S02_[TechnicalType]_[SubType]_[UniqueName]

Examples:
- task_S02_ENG_Framework_convert-resting-point-to-smartio
- task_S02_ENG_Combat_add-parry-timing-window
- task_S02_VFX_Boss_tiger-flame-attack
- task_S02_GD_Ene_spear-wielder-prototype

Technical Types:
- ENG = Engineering
- VFX = Visual Effects
- GD = Game Design
- ART = Art/Animation
- UI = User Interface
- AI = Artificial Intelligence
- LVL = Level Design

Sub Types (by domain):
- ENG: Framework, Combat, AI, UI, Tools, System
- VFX: Boss, Enemy, Player, Environment
- GD: Ene, Boss, Elite, Player
- ART: Char, Env, Prop, Anim
```

## Dynamic Context Resolution

```
{CWD} = Current Working Directory
{Branch} = Current git branch name
{BaseCommit} = Merge base with main branch
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
| `combat`, `gameplay` | {milestones.combat.name} ({milestones.combat.number}) |
| `ai`, `system` | {milestones.game_ai.name} ({milestones.game_ai.number}) |
| `vfx`, `ArtAnim`, `main-char` | PRE-PROD: META (10) |
| `level-design` | PRE-PROD: ENV (1) |
| `UXUI` | PRE-PROD: META (10) |
| `Engineering` (framework) | {milestones.game_ai.name} ({milestones.game_ai.number}) or {milestones.combat.name} ({milestones.combat.number}) based on content |
| Default | alpha (9) |

## Workflow

### Step 0: Load Template

Read appropriate template from `.github/ISSUE_TEMPLATE/`:

```bash
# Determine template based on user input or context
# Default: task.md

# Read template file
cat .github/ISSUE_TEMPLATE/task.md
```

**Template Parsing:**
1. Extract frontmatter (between `---` markers):
   - `name`: Template name
   - `title`: Title format pattern
   - `labels`: Default labels (comma-separated)
   - `assignees`: Default assignees

2. Extract body sections:
   - Find all `## Section Name` headers
   - Store section names and default content
   - These become required fields in the draft

**Example Parsed Template (task.md):**
```
Frontmatter:
  name: Task
  title: [TASK-ID] Task title
  labels: task

Sections:
  - Task Description
  - Task ID
  - Epic
  - Acceptance Criteria
  - Dependencies
  - Size & Effort
  - Due Date
  - Additional Context
```

### Step 1: Validate Environment

Check prerequisites before proceeding:

```bash
# Verify gh CLI authentication
gh auth status

# Get current branch
git rev-parse --abbrev-ref HEAD

# Fetch available labels
gh label list --json name --jq '.[].name'
```

**Validation Rules:**
- If `gh auth status` fails → Error: "GitHub CLI not authenticated. Run: gh auth login"
- If current branch is "main" → Error: "Cannot create issue from main branch. Create a feature branch first."
- Store available labels for later validation

### Step 2: Extract Git Context

Gather information from current branch state:

```bash
# Get current branch name
git rev-parse --abbrev-ref HEAD

# Get commit messages since diverged from main
git log main...HEAD --oneline --no-decorate

# Get file changes with statistics
git diff main...HEAD --stat --no-color

# Get uncommitted changes
git status --short
```

**Store:**
- Branch name (e.g., "feature/smart-io-creator-tool")
- Array of commit messages
- Changed files with line counts (e.g., "SSipherSmartObjectCreatorWindow.cpp | 848 +++++++")
- Uncommitted file list

**Handle Edge Cases:**
- If no commits on branch → Offer manual input mode
- If no file changes → Warn: "No changes detected"

### Step 3: Auto-Detect Domain Labels

Map file paths to domain labels based on project structure:

**Label Detection Rules:**

| File Path Pattern | Domain Labels |
|-------------------|---------------|
| `Plugins/Frameworks/Sipher*` | `Engineering`, `system` |
| `Plugins/EditorTools/*` | `Engineering`, `tools` |
| `Source/S2/Private/Combat/*` | `combat`, `Engineering` |
| `Source/S2/Private/AI/*` | `ai`, `Engineering` |
| `Source/S2/UI/*` | `UXUI`, `Engineering` |
| `Content/S2/Core_VFX/*` | `vfx` |
| `Content/S2/Core_Char/S2_char_MC/*` | `main-char`, `ArtAnim` |
| `Content/S2/Core_Boss/*` | `combat`, `gameplay` |
| `Content/S2/Maps/*` | `level-design` |
| `*.cpp`, `*.h` | `Engineering` |
| `*.uasset` (in Anim folders) | `ArtAnim` |
| `Docs/*`, `*.md` | `documentation` |

**Logic:**
1. Extract all changed file paths from git diff
2. Match each path against patterns above
3. Collect unique labels
4. Always add "task" label
5. Remove duplicates

**Example:**
```
Changed files:
- Plugins/Frameworks/SipherInteractionObjectFramework/Source/SipherIOTypes.h (+200)
- Content/S2/Core_Boss/s2_boss_tiger/BP_Tiger.uasset (+50)

Detected labels: task, Engineering, system, combat, gameplay
```

### Step 4: Estimate Size from Changes

Calculate T-shirt size based on total lines changed:

```
Total Lines Changed → T-Shirt Size → Estimated Hours
< 100               → XS            → 2-4h
100-300             → S             → 4-8h
300-600             → M             → 8-16h
600-1200            → L             → 16-32h
> 1200              → XL            → 32h+
```

**Logic:**
1. Sum all line additions from `git diff --stat`
2. Apply size mapping
3. Suggest hours in middle of range (e.g., L → 24h)

**Special Case:**
- If XL detected → Warn: "Consider breaking this into smaller tasks"

### Step 5: Auto-Generate Draft Issue

Build complete draft issue from extracted context:

#### Title Generation

**Primary Format (from guidelines):**
```
task_S02_[TechnicalType]_[SubType]_[unique-name]
```

**Logic:**
```
1. Determine TechnicalType from domain labels:
   - Engineering/system/framework → ENG
   - combat → ENG (sub: Combat)
   - ai → ENG (sub: AI) or AI
   - vfx → VFX
   - ArtAnim → ART
   - UXUI → UI
   - level-design → LVL
   - gameplay/game-design → GD

2. Determine SubType based on file paths or context:
   - Plugins/Frameworks/* → Framework
   - Combat systems → Combat
   - AI systems → AI
   - UI systems → UI
   - Editor tools → Tools
   - Content/S2/Core_VFX/Boss/* → Boss
   - Content/S2/Core_Ene/* → Ene

3. Generate unique-name:
   - Extract from branch name or user input
   - Convert to kebab-case (lowercase, hyphens)
   - Remove common prefixes (feature/, fix/, etc.)

Examples:
- Branch: feature/convert-resting-point-smartio
  Labels: Engineering, system
  → task_S02_ENG_Framework_convert-resting-point-to-smartio

- Branch: fix/parry-timing-window
  Labels: combat, Engineering
  → task_S02_ENG_Combat_fix-parry-timing-window

- Branch: feature/tiger-boss-vfx
  Labels: vfx
  → task_S02_VFX_Boss_tiger-flame-attack
```

**Fallback Format (if naming convention unclear):**
```
[TASK-ID] Human Readable Title
Example: [ENG-FRAMEWORK-001] Convert Resting Point to SmartIO
```

#### Description Generation

```
Logic:
1. Summarize commit messages:
   - Extract all commit subjects
   - Group related commits
   - Create cohesive 2-4 sentence summary

2. Add technical details:
   - List key files modified (top 5 by lines changed)
   - Note any new systems/plugins added
   - Mention refactorings or deletions

Example:
"Implement Smart IO creator tool with behavior definitions. This adds
editor tooling for creating Smart Objects with modular behavior patterns.
Refactored SipherIOTypes to use class-based definitions instead of
struct-based approach.

Key changes:
- SSipherSmartObjectCreatorWindow.cpp (848 lines)
- SipherIOTypes.h/cpp (refactored)
- New state tree tasks for montage playback"
```

#### Task ID Generation

```
Format: ENG-{DOMAIN}-{NUMBER}

Logic:
1. Extract primary domain from labels:
   - If "system" in labels → ENG-FRAMEWORK-{NUMBER}
   - If "combat" in labels → ENG-COMBAT-{NUMBER}
   - If "ui" in labels → ENG-UI-{NUMBER}
   - Default → ENG-GENERAL-{NUMBER}

2. Suggest next available number:
   - Query existing issues: gh issue list --label {domain} --json number
   - Find max number, increment by 1
   - If no existing issues → Start at 001

Example: ENG-FRAMEWORK-001
```

#### Acceptance Criteria Generation

```
Logic:
1. Extract from commit messages:
   - Each significant commit → One checkbox
   - Focus on "what" not "how"
   - Use action verbs (Implement, Add, Fix, Refactor)

2. Add standard criteria:
   - "Code compiles successfully" (always)
   - "Tests pass" (if test files in changes)
   - "Documentation updated" (if public API changes)

Example:
- [ ] Smart Object creator window implemented
- [ ] Behavior definition system working
- [ ] State tree tasks updated
- [ ] Code compiles successfully
- [ ] Tests pass
```

#### Dependencies Field

```
Default: "None"
User will be prompted to specify if applicable
```

#### Due Date Calculation

```
Logic:
1. Start with today's date
2. Add days based on size:
   - XS → +2 days
   - S  → +3 days
   - M  → +5 days
   - L  → +7 days
   - XL → +14 days
3. Format as YYYY-MM-DD
```

#### Milestone Detection

```
Logic:
1. Query available milestones:
   gh api repos/{github.repo}/milestones --jq '.[] | "\(.number): \(.title)"'

2. Auto-select based on domain labels:
   - If "combat" or "gameplay" in labels → {milestones.combat.name} ({milestones.combat.number})
   - If "ai" in labels → {milestones.game_ai.name} ({milestones.game_ai.number})
   - If "system" in labels → {milestones.game_ai.name} ({milestones.game_ai.number})
   - If "vfx" or "ArtAnim" in labels → PRE-PROD: META (10)
   - If "level-design" in labels → PRE-PROD: ENV (1)
   - If "UXUI" in labels → PRE-PROD: META (10)
   - Default → alpha (9)

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
3. After issue creation, add to project board:
   gh project item-add {github.project_number} --owner {github.owner} --url {issue_url}
```

### Step 6: Present Draft to User

Display complete draft for review:

```
═══════════════════════════════════════
DRAFT ISSUE
═══════════════════════════════════════

Title: [ENG-FRAMEWORK-001] Smart IO Creator Tool

Description:
Implement Smart IO creator tool with behavior definitions. This adds
editor tooling for creating Smart Objects with modular behavior patterns.
Refactored SipherIOTypes to use class-based definitions instead of
struct-based approach.

Key changes:
- SSipherSmartObjectCreatorWindow.cpp (848 lines)
- SipherIOTypes.h/cpp (refactored)
- New state tree tasks for montage playback

Task ID: ENG-FRAMEWORK-001
Epic: N/A

Acceptance Criteria:
- [ ] Smart Object creator window implemented
- [ ] Behavior definition system working
- [ ] State tree tasks updated
- [ ] Code compiles successfully

Dependencies: None

Size: L (16-32 hours)
Estimated Hours: 24

Due Date: 2025-12-31

Labels: task, Engineering, system
Milestone: {milestones.game_ai.name} ({milestones.game_ai.number})
Project: {project.fullname}

═══════════════════════════════════════

Options:
1. Create issue with this draft
2. Edit specific fields
3. Cancel

Your choice (1/2/3): _
```

**User Interaction:**

If user chooses "2. Edit specific fields":
```
Which field to edit?
a. Title
b. Description
c. Task ID
d. Epic
e. Acceptance Criteria
f. Dependencies
g. Size/Hours
h. Due Date
i. Labels
j. Milestone
k. Project
l. Done editing, create issue

Your choice: _
```

For each field:
1. Show current value
2. Prompt for new value
3. Validate input
4. Update draft
5. Show updated draft
6. Return to field selection menu

**Validation Rules:**
- Title: 10-100 characters
- Task ID: Format ENG-{DOMAIN}-{NUMBER}
- Due Date: Must be YYYY-MM-DD format, future date
- Size: Must be XS/S/M/L/XL
- Hours: Must be number matching size range
- Labels: Must exist in available labels list

### Step 7: Validate Labels

Before creating issue, ensure all labels exist:

```bash
# Get available labels
gh label list --json name --jq '.[].name'
```

**Validation Logic:**
1. Compare each draft label with available labels
2. If label doesn't exist:
   - Remove from draft
   - Warn user: "Label '{label}' doesn't exist, removed"
   - Suggest similar labels (fuzzy match)

**Required Labels:**
- "task" (always required)
- At least one domain label (Engineering, vfx, combat, etc.)

If no domain label:
```
No domain label detected. Please select:
a. Engineering
b. combat
c. vfx
d. UXUI
e. ArtAnim
f. gameplay
g. ai
h. level-design
i. documentation

Your choice: _
```

### Step 8: Build Issue Body

**IMPORTANT:** Use `<br />` for line breaks and `**` for headers per project guidelines.

Construct body using template-compliant formatting:

```markdown
**Task Description**<br />
{Description from draft}

**Task ID**<br />
{Task ID}

**Epic**<br />
{Epic or "N/A"}

**Acceptance Criteria**<br />
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Code compiles successfully

**Dependencies**<br />
{Dependencies or "None"}

**Size & Effort**<br />
**T-Shirt Size:** {Size} ({Hours range})<br />
**Estimated Hours:** {Hours}

**Due Date**<br />
{YYYY-MM-DD}

**Additional Context**<br />
{Technical details, key files}
```

**Example (Properly Formatted):**
```markdown
**Task Description**<br />
Convert the existing Resting Point implementation to use the SmartIO (Smart Interaction Object) framework.

**Task ID**<br />
ENG-FRAMEWORK-001

**Epic**<br />
SmartIO Framework Migration

**Acceptance Criteria**<br />
- [ ] Resting Point converted to SmartIO-based implementation
- [ ] Behavior definitions properly configured
- [ ] State Tree tasks updated for SmartIO consumption
- [ ] Existing functionality preserved
- [ ] Code compiles successfully

**Dependencies**<br />
None

**Size & Effort**<br />
**T-Shirt Size:** M (8-16 hours)<br />
**Estimated Hours:** 12

**Due Date**<br />
2026-01-12

**Additional Context**<br />
Part of the ongoing effort to migrate interaction objects to the SmartIO framework using the SipherInteractionObjectFramework plugin.
```

**Formatting Rules:**
1. Use `**Section**<br />` for all section headers
2. Use `<br />` to separate sections
3. Checkboxes: `- [ ]` format (GitHub auto-renders)
4. No `##` headers in body (reserve for template parsing)
5. Keep descriptions concise

### Step 9: Create GitHub Issue

Submit issue via gh CLI:

```bash
gh issue create \
  --title "[ENG-FRAMEWORK-001] Smart IO Creator Tool" \
  --body "$(cat <<'EOF'
## Task Description
Implement Smart IO creator tool with behavior definitions...

## Task ID
ENG-FRAMEWORK-001

...
EOF
)" \
  --label "task,Engineering,system" \
  --milestone 13 \
  --repo {github.repo}
```

**Important:**
- Use heredoc for body to preserve formatting
- Escape any quotes in body content
- Use comma-separated labels (no spaces)
- `--milestone`: Use milestone NUMBER (not title)

**Parse Output:**
```
Example output:
https://github.com/{github.repo}/issues/16177

Extract:
- Issue URL (full)
- Issue number (16177)
```

### Step 10: Add Issue to Project Board

After issue creation, add to {project.fullname} project:

```bash
gh project item-add {github.project_number} --owner {github.owner} --url https://github.com/{github.repo}/issues/16177
```

**Logic:**
1. Use project number {github.project_number}
2. Pass the newly created issue URL
3. If fails due to missing scope, warn user:
   ```
   Warning: Could not add issue to project board.
   Run: gh auth refresh -s project
   Then manually add at: https://github.com/orgs/{github.owner}/projects/{github.project_number}
   ```

### Step 11: Return Success Info

Output formatted success message:

```
✓ Issue created successfully!

Issue #16177: Smart IO Creator Tool
URL: https://github.com/{github.repo}/issues/16177

Labels: task, Engineering, system
Milestone: GAME-AI
Project: {project.fullname}
Size: L (24 hours)
Due: 2025-12-31

Next steps:
1. Update project board fields:
   - Set Status to "To Do"
   - Set Iteration to current sprint
   - Set Priority based on urgency
2. Assign to team member if needed
3. Link to epic if applicable

Tip: Use /github-create-pr to create a PR linked to this issue
```

**Return Values (for programmatic use):**
```
IssueNumber: 16177
IssueURL: https://github.com/{github.repo}/issues/16177
IssueTitle: [ENG-FRAMEWORK-001] Smart IO Creator Tool
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

### Error: Missing Project Scope

```
Issue created but not added to project board.
This may be due to missing 'project' scope.

Solution:
1. Run: gh auth refresh -s project
2. Manually add issue to project board:
   - Navigate to: https://github.com/orgs/{github.owner}/projects
   - Find project: "{project.fullname}"
   - Add issue #16177

Future runs should add to project automatically.
```

### Error: On Main Branch

```
Error: Cannot create issue from main branch
Current branch: main

Reason: Issues should be created from feature/fix branches to
provide context about what you're working on.

Solution:
1. Create a feature branch:
   git checkout -b feature/your-feature-name

2. Make your changes and commit

3. Run this skill again from the feature branch

Alternative:
- Use --manual flag to create issue without git context
```

### Warning: No Git Changes

```
Warning: No changes detected in current branch
Branch "feature/smart-io-creator" is in sync with main

Options:
1. Continue with manual input (no auto-generation)
2. Cancel and make changes first
3. Use only commit messages (ignore file changes)

Your choice (1/2/3): _
```

### Warning: Label Doesn't Exist

```
Warning: Label 'nonexistent-label' not found in repository

Available domain labels:
- Engineering
- combat
- vfx
- UXUI
- ArtAnim
- gameplay
- ai
- level-design
- documentation
- tools
- performance
- networking

Removed 'nonexistent-label' from draft.

Press Enter to continue...
```

### Error: No Commits on Branch

```
Error: No commits found on branch
Cannot auto-generate issue without commit history.

Options:
1. Make commits first, then run skill
2. Use manual input mode (--manual flag)

Your choice: _
```

## Advanced Usage

### Manual Input Mode

If no git context available or user prefers manual input:

```bash
Invocation: /github-create-issue --manual
```

**Workflow:**
1. Skip Steps 2-5 (git extraction, auto-generation)
2. Prompt user for each field:
   - Title: "Enter issue title: "
   - Description: "Enter description: "
   - Task ID: "Enter task ID (or press Enter for auto): "
   - Acceptance criteria: "Enter criteria (one per line, empty line to finish): "
   - Size: "Select size (XS/S/M/L/XL): "
   - Labels: "Enter labels (comma-separated): "
3. Build body and create issue

### Quick Mode

Skip review step, create immediately:

```bash
Invocation: /github-create-issue --quick
```

**Workflow:**
1. Auto-generate draft (Steps 1-5)
2. Validate labels (Step 7)
3. Create issue immediately (Steps 8-9)
4. Return success (Step 10)

Use when confident in auto-generation accuracy.

### Specify Epic

Link to existing epic during creation:

```bash
Invocation: /github-create-issue --epic TF01
```

**Workflow:**
1. Auto-generate draft as normal
2. Set Epic field to specified value
3. Proceed with review/creation

## Integration with Other Skills

### Called by github-create-pr

The github-create-pr skill invokes this skill programmatically:

```markdown
Within github-create-pr workflow:

Step X: Create linked issue
Action: Invoke /github-create-issue
Context: Pass git context from PR workflow
Result: Issue #16177 created
Store: IssueNumber = 16177
Use: Include "Closes #16177" in PR body
```

**Return Value:**
- IssueNumber (for PR linking)
- IssueURL (for reference)

## Success Criteria

- [x] Skill file created at `./SKILL.md`
- [ ] Extracts git context (branch, commits, diff, status)
- [ ] Auto-generates title from branch name
- [ ] Auto-generates description from commits
- [ ] Auto-generates acceptance criteria from commits
- [ ] Estimates size from lines changed
- [ ] Auto-detects domain labels from file paths
- [ ] Auto-detects milestone from domain labels
- [ ] Adds issue to {project.fullname} project board
- [ ] Presents draft for user review
- [ ] Allows editing specific fields (including milestone/project)
- [ ] Validates labels against repository
- [ ] Creates issue with proper markdown formatting
- [ ] Assigns milestone via --milestone flag
- [ ] Returns issue URL and number
- [ ] Handles authentication errors
- [ ] Handles main branch error
- [ ] Handles missing labels
- [ ] Handles no git changes
- [ ] Handles missing project scope
- [ ] Supports manual input mode
- [ ] Supports quick mode
- [ ] Can be called programmatically by other skills

## Example Sessions

### Session 1: Successful Auto-Generation

```
User: /github-create-issue

[Skill executes Steps 1-6]

═══════════════════════════════════════
DRAFT ISSUE
═══════════════════════════════════════
Title: [ENG-FRAMEWORK-001] Smart IO Creator Tool
Description: Implement Smart IO creator tool...
Labels: task, Engineering, system
Size: L (24 hours)
═══════════════════════════════════════

Options:
1. Create issue with this draft
2. Edit specific fields
3. Cancel

Your choice: 1

[Creating issue...]

✓ Issue created successfully!
Issue #16177: Smart IO Creator Tool
URL: https://github.com/{github.repo}/issues/16177
```

### Session 2: Edit Before Creation

```
User: /github-create-issue

[Draft presented]

Your choice: 2

Which field to edit?
a. Title
...
h. Due Date
...

Your choice: h

Current due date: 2025-12-31
Enter new due date (YYYY-MM-DD): 2025-12-27

✓ Due date updated to 2025-12-27

[Updated draft shown]

Your choice: j (Done editing, create issue)

✓ Issue created successfully!
Issue #16178: Smart IO Creator Tool
URL: https://github.com/{github.repo}/issues/16178
```

### Session 3: Manual Input Mode

```
User: /github-create-issue --manual

No git context will be used.

Enter issue title: Optimize AI Pathfinding Performance
Enter description: Improve pathfinding performance for 50+ AI agents...
Enter task ID (ENG-AI-002): [Enter]
Using: ENG-AI-002

Enter acceptance criteria (one per line, empty to finish):
- Reduce pathfinding CPU time by 30%
- Implement path caching
- Test with 50+ agents
[Empty line]

Select size (XS/S/M/L/XL): M
Estimated hours (8-16): 12

Enter labels (comma-separated): task,Engineering,ai,performance

✓ Issue created successfully!
Issue #16179: Optimize AI Pathfinding Performance
```

## Notes

- All `gh` commands are already permitted in `settings.local.json`
- Project: "{project.fullname}" (number {github.project_number}, ID: {github.project_node_id})
- Repository is hardcoded: {github.repo}
- No Claude attribution footer (per CLAUDE.md guidelines)
- Date format is always YYYY-MM-DD
- Labels must be validated before creation
- Task ID follows format: ENG-{DOMAIN}-{NUMBER}
- Milestone is assigned via --milestone NUMBER (not title)
- Project assignment requires `project` scope: `gh auth refresh -s project`
- Domain-to-milestone mapping ensures issues land in correct milestone

## Template Reference Files

**Location:** `.github/ISSUE_TEMPLATE/`

| File | Purpose |
|------|---------|
| `task.md` | Standard task template |
| `bug.md` | Bug report template |
| `vfx_task.md` | VFX team task template |
| `ene_proto.md` | Enemy/boss prototype checklist |
| `2d_3d_task.md` | 2D/3D art task template |
| `epic.md` | Epic/milestone template |
| `feature_request.md` | Feature request template |
| `create-gitissue-guidelines.md` | **Formatting rules and guidelines** |
| `SampleTaskIssue.md` | Example of properly formatted task |

**ALWAYS read `create-gitissue-guidelines.md` for:**
- Title naming conventions
- Label categories and validation
- Body formatting rules (`<br />`, `**headers**`)
- Required information checklists
- Preliminary checks before issue creation

## Legacy Metadata

```yaml
skill: github-create-issue
invoke: /github-workflow:github-create-issue
type: workflow
category: github
scope: project-root
```
