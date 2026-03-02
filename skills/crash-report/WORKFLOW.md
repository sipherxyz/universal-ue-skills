# /crash-report Workflow

## Overview

Automated crash log parsing and GitHub issue creation for Unreal Engine crashes.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        /crash-report                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 1: SCAN LOGS                                              │
│  ─────────────────                                              │
│  • Search Saved/Logs/S2*.log                                    │
│  • Filter by time window (default: 24 hours)                    │
│  • Detect crash patterns:                                       │
│    - Fatal error, Assertion failed                              │
│    - Access violation, GPU crash, TDR                           │
│    - LogSentrySdk [Callstack] entries                           │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐
    │ NO_CRASHES_FOUND│             │ CRASHES_FOUND=N │
    └─────────────────┘             └─────────────────┘
              │                               │
              ▼                               ▼
    ┌─────────────────┐             ┌─────────────────────────────┐
    │ Ask: Extend     │             │ Display crash list:         │
    │ time window?    │             │ [1] 2026-01-13 14:39        │
    └─────────────────┘             │     Type: Assertion         │
                                    │     File: S2-backup-xxx.log │
                                    └─────────────────────────────┘
                                              │
                                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 2: PARSE CRASH DETAILS                                    │
│  ───────────────────────────                                    │
│  • Extract crash type & error message                           │
│  • Parse Sentry callstack (symbolicated with file:line)         │
│  • Identify root cause function in project code:                │
│    - Source/S2/                                                 │
│    - Plugins/Frameworks/Sipher*                                 │
│    - Plugins/GameFeatures/                                      │
│  • Collect relevant error/warning logs                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 3: USER CHOICE                                            │
│  ───────────────────                                            │
│                                                                 │
│  [Q] Quick issue    → Create with parsed data only              │
│  [A] Analyzed issue → Run crash-investigator agent first        │
│  [V] View logs      → Show full crash details                   │
│  [S] Skip           → Don't create issue                        │
└─────────────────────────────────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
   ┌─────────────┐    ┌──────────────┐    ┌─────────────┐
   │ Quick Issue │    │Analyzed Issue│    │    Skip     │
   └─────────────┘    └──────────────┘    └─────────────┘
          │                   │
          │                   ▼
          │           ┌──────────────────────────────┐
          │           │ Launch crash-investigator    │
          │           │ agent (Opus) for:            │
          │           │ • Root cause analysis        │
          │           │ • Recommended fix            │
          │           │ • Prevention strategies      │
          │           └──────────────────────────────┘
          │                   │
          └─────────┬─────────┘
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 4: CREATE GITHUB ISSUE                                    │
│  ───────────────────────────                                    │
│  gh issue create --repo sipherxyz/s2                            │
│    --title "Crash: {type} in {function}"                        │
│    --label bug,crash                                            │
│    --body-file {formatted_issue.md}                             │
│                                                                 │
│  Issue contains:                                                │
│  • Crash type, time, log file                                   │
│  • Symbolicated callstack                                       │
│  • Root cause location (if project code)                        │
│  • Analysis + fix (if analyzed)                                 │
│  • Git branch & commit                                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 5: CONFIRMATION                                           │
│  ────────────────────                                           │
│  GitHub Issue Created!                                          │
│    URL: https://github.com/sipherxyz/s2/issues/XXXXX            │
│    Title: Crash: Assertion in FooBar::DoThing                   │
│    Labels: bug, crash                                           │
└─────────────────────────────────────────────────────────────────┘
```

## Commands

| Command | Description |
|---------|-------------|
| `/crash-report` | Scan last 24 hours |
| `/crash-report --hours 72` | Scan last 3 days |
| `/crash-report --log Saved/Logs/S2-backup-xxx.log` | Report specific log |

## Crash Detection Patterns

The parser looks for these patterns in log files:

| Pattern | Crash Type |
|---------|------------|
| `Fatal error` | Fatal Error |
| `Assertion failed` | Assertion |
| `check/verify/ensure failed` | Assertion (check/verify/ensure) |
| `Access violation` | Access Violation |
| `GPU crashed`, `D3D Device Lost`, `TDR` | GPU Crash |
| `Unhandled Exception` | Unhandled Exception |
| `LogSentrySdk.*[Callstack]` | Any (triggers callstack parsing) |

## Callstack Priority

1. **Sentry Callstack** (preferred) - Symbolicated with file:line from `LogSentrySdk: Error: [Callstack]`
2. **Raw Callstack** (fallback) - Hex addresses without symbols

## Root Cause Detection

The parser identifies root cause by finding the first callstack frame in project code:

| Path Pattern | Classification |
|--------------|----------------|
| `\Source\S2\` | Project code |
| `\Plugins\Frameworks\Sipher*` | Project plugin |
| `\Plugins\GameFeatures\` | Project feature |
| `\Plugins\EditorTools\` | Project editor tool |
| `Engine\Source\` | Engine code (external) |
| `Engine\Plugins\` | Engine plugin (external) |
| `Plugins\Marketplace\` | Marketplace (external) |

## Issue Options

### Quick Issue
Creates GitHub issue with:
- Crash metadata (type, time, log file)
- Symbolicated callstack
- Root cause location
- Relevant error logs
- Git environment (branch, commit)

### Analyzed Issue
Adds to Quick Issue:
- Root cause analysis from crash-investigator agent
- Recommended fix/workaround
- Prevention strategies
- Classification (project vs engine bug)

## Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Crash logs in `Saved/Logs/`
- Labels `bug` and `crash` in repo (auto-created if missing)

## File Structure

```
.claude/skills/crash-report/
├── SKILL.md                    # Skill definition
├── WORKFLOW.md                 # This file
└── scripts/
    └── crash-parser.ps1        # PowerShell log parser
```
