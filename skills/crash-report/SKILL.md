---
name: crash-report
description: Create GitHub issues from crash logs with automatic parsing and optional AI analysis
---

# Crash Report Skill

**Role:** Crash-to-GitHub Issue Automation
**Scope:** Parse crash logs, create GitHub issues
**Platform:** Windows + PowerShell

## Objective

Convert crash logs into GitHub issues with structured information:
1. Find recent crash logs (configurable time window)
2. Parse crash type, callstack, error message
3. Optionally analyze with crash-investigator agent
4. Create GitHub issue via `gh`

## Prerequisites

- GitHub CLI (`gh`) authenticated
- Crash logs in `Saved/Logs/`
- (Optional) Sentry credentials in `.claude/credentials/sentry.env` for enriched crash data

## Script Location

```
./scripts/crash-parser.ps1
```

## Sentry Integration

The crash-report skill uses a **hybrid approach** for crash data:

### Local Log (Primary Source)
The Sentry SDK writes symbolicated callstacks directly to the local log file. This is the most reliable source because:
- Available immediately after crash
- Full function names with file:line info
- Works even when crash is too severe to send to server

### Sentry API (Supplementary)
When Sentry credentials are configured, the skill fetches additional context:
- **Breadcrumbs** - Events leading to the crash (log messages, UI interactions)
- **Tags** - GPU, OS, build config from similar crashes
- **Pattern Matching** - Finds related Sentry issues to understand crash frequency

**Note:** Hard crashes (Access Violations, VectorVM crashes) often don't reach Sentry server because the process terminates too quickly. The local log data is more complete for these cases.

### Sentry Configuration

Create `.claude/credentials/sentry.env`:

```
SENTRY_URL=https://sentry.atherlabs.io
SENTRY_AUTH_TOKEN=your_token_here
SENTRY_ORG=atherlabs
SENTRY_PROJECT=huli
```

**Note:** This file is gitignored and should not be committed.

## Workflow

### Step 0: Ask User for Log Source

**ASK the user** which log source to search:

```
Which build would you like to check for crashes?

Options:
  [S] Steam (default) - Shipping build from Steam installation
  [E] Editor - Development build from project folder
  [B] Both - Search all available sources
```

**Default to Steam** if user doesn't specify.

### Step 1: List Recent Crashes

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/crash-parser.ps1" -Action list-crashes -Source {Steam|Editor|Both} -HoursBack 24
```

**Parameters:**
- `-Source` - Log source: Steam (default), Editor, or Both
- `-HoursBack` - How far back to search (default: 24 hours)

**Expected Output:**
- `LOG_SOURCES=N` with list of directories being searched
- `NO_CRASHES_FOUND` if no crashes detected
- `CRASHES_FOUND=N` with numbered list of crashes (showing [Steam] or [Editor] prefix)

**If no crashes:** Inform user no crashes found in the time window. Ask if they want to extend the search window or try a different source.

**If crashes found:** Display the list and ask user which crash to report (or "all").

### Step 2: Get Crash Details

For the selected crash (add `-UseSentry` to fetch Sentry API data):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/crash-parser.ps1" -Action get-crash -LogPath "{full_path_to_log}" -UseSentry
```

**Output includes:**
- `CRASH_TYPE` - Fatal Error, Assertion, Access Violation, GPU Crash, etc.
- `CRASH_TIME` - When the crash occurred
- `ERROR_MESSAGE` - The error description
- Callstack (raw and Sentry-symbolicated from logs)
- Relevant warning/error logs

**With `-UseSentry` flag (if credentials configured):**
- `SENTRY_ISSUE` - Matched Sentry issue ID
- `SENTRY_EVENT` - Sentry event ID
- Breadcrumbs from Sentry API
- Full stacktrace from Sentry API
- Tags (GPU, OS, build config, device)

**Display:** Show the crash summary to the user.

### Step 3: ASK User for Options

Present options:

```
Crash detected: {CRASH_TYPE}
Time: {CRASH_TIME}
Message: {ERROR_MESSAGE (truncated)}

Options:
  [Q] Quick issue - Create issue with parsed data only
  [A] Analyzed issue - Run crash-investigator for root cause analysis, then create issue
  [V] View full logs - Show complete crash details before deciding
  [S] Skip - Don't create issue for this crash
```

### Step 4a: Quick Issue Creation

If user chose Quick (Q):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "./scripts/crash-parser.ps1" -Action format-issue -LogPath "{full_path_to_log}" -UseSentry
```

This outputs `ISSUE_TITLE`, `ISSUE_LABELS`, and `ISSUE_BODY_START...ISSUE_BODY_END`.

**With `-UseSentry`:** Issue body includes Breadcrumbs and Full Stacktrace sections from Sentry.

Then create the issue:

```bash
gh issue create --title "{ISSUE_TITLE}" --label "bug,crash" --body "{ISSUE_BODY}"
```

**IMPORTANT:** Use a HEREDOC for the body to preserve formatting:

```bash
gh issue create --title "Crash: Access Violation - ..." --label "bug,crash" --body "$(cat <<'EOF'
## Crash Report
...body content...
EOF
)"
```

### Step 4b: Analyzed Issue Creation

If user chose Analyzed (A):

1. **Launch crash-investigator agent** using the Task tool:
   - Provide the full crash details (callstack, error, logs)
   - Request root cause analysis and fix recommendations

2. **Wait for analysis results**

3. **Append analysis to issue body:**
   - Add "## Analysis" section with investigator findings
   - Add "## Recommended Fix" section if provided
   - Add "## Prevention" section if provided

4. **Create the issue** with enhanced body

### Step 4c: View Full Logs

If user chose View (V):

Read the full log file tail (last 300 lines) and display to user. Then return to Step 3 for decision.

### Step 5: Confirm Creation

After issue is created, display:

```
GitHub Issue Created!
  URL: {issue_url}
  Title: {title}
  Labels: bug, crash

You can view and edit the issue at the URL above.
```

## Error Handling

### Error: gh not authenticated

```
ERROR: gh CLI not authenticated
```

**Solution:** Run `gh auth login` to authenticate with GitHub.

### Error: No crash detected in log

```
ERROR: No crash patterns found in log file
```

**Solution:** The log file exists but doesn't contain recognized crash patterns. User may need to check manually or the crash happened in a different session.

### Error: Log file not found

```
ERROR: Log file not found at {path}
```

**Solution:** Verify the path exists. Logs may have been cleaned up.

## Advanced Usage

### Search by source

```
/crash-report --source steam    # Steam shipping build (default)
/crash-report --source editor   # Editor/development build
/crash-report --source both     # Search all sources
```

### Search older crashes

```
/crash-report --hours 72
```

Searches last 72 hours instead of default 24.

### Specific log file

```
/crash-report --log Saved/Logs/S2-backup-2026.01.14-03.36.57.log
```

Reports a specific log file directly.

## Output Format

The generated GitHub issue follows this structure:

```markdown
## Crash Report

**Type:** {crash_type}
**Time:** {timestamp}
**Log File:** `{filename}`

## Error Message

{error_message}

## Callstack (Symbolicated)

{sentry_callstack from logs if available}

## Callstack (Raw)

{raw_callstack}

## Relevant Logs

{error_and_warning_lines}

## Breadcrumbs (Sentry)

Events leading to the crash:
{breadcrumbs from Sentry API - only with -UseSentry}

## Full Stacktrace (Sentry)

{symbolicated frames from Sentry API - only with -UseSentry}

## Environment

- **Platform:** Windows
- **Branch:** {git_branch}
- **Commit:** {git_short_hash}
- **GPU:** {from Sentry tags}
- **OS:** {from Sentry tags}
- **Build Config:** {from Sentry tags}
- **Sentry Issue:** {HULI-xxx}

---
*Auto-generated crash report*
```

If analyzed, additional sections are appended:

```markdown
## Analysis

{crash_investigator_analysis}

## Recommended Fix

{fix_recommendations}

## Prevention

{prevention_strategies}
```

## Legacy Metadata

```yaml
skill: crash-report
type: workflow
category: debugging
scope: project-root
```
