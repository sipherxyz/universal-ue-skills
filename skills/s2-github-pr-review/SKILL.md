---
name: s2-github-pr-review
description: Review sipherxyz/s2 GitHub pull requests like an AI Eng Forge reviewer. Use when asked to review an s2 PR, inspect GitHub PR code changes, maintain the single AI Eng Forge Review dashboard comment, compare review quality with Copilot/Claude, or run a Copilot-style Unreal Engine PR code review.
---

# S2 GitHub PR Review

Review `sipherxyz/s2` PRs, find actionable code/content issues, then maintain one compact GitHub issue comment titled `🤖 AI Eng Forge Review #<PR>`.

Use the bundled helper for GitHub plumbing and token-efficient local context:

```bash
python3 .codex/skills/s2-github-pr-review/scripts/pr_review_helper.py collect <PR> --out /tmp/s2-pr-<PR>
python3 .codex/skills/s2-github-pr-review/scripts/pr_review_helper.py rules <PR> --artifacts /tmp/s2-pr-<PR>
python3 .codex/skills/s2-github-pr-review/scripts/pr_review_helper.py checkout <PR> --artifacts /tmp/s2-pr-<PR> --force
python3 .codex/skills/s2-github-pr-review/scripts/pr_review_helper.py render <PR> --findings /tmp/s2-pr-<PR>/findings.json --out /tmp/s2-pr-<PR>/dashboard.md
python3 .codex/skills/s2-github-pr-review/scripts/pr_review_helper.py post <PR> --body /tmp/s2-pr-<PR>/dashboard.md
python3 .codex/skills/s2-github-pr-review/scripts/pr_review_helper.py cleanup <PR> --artifacts /tmp/s2-pr-<PR>
```

## Fast Workflow

1. Resolve PR number. Default repo is `sipherxyz/s2`.
2. Run `collect`. It writes:
   - `pr.json`: metadata, head SHA, files.
   - `diff.patch`: full patch.
   - `changed_files.txt`: one changed path per line.
   - `comments.json`: existing issue comments.
   - `previous_dashboard.md`: current AI Eng Forge Review dashboard, if any.
3. Run `rules`, then read only the rule files it prints. It also writes `rule_files.txt` and `selected_rules.json`.
4. For non-trivial code/content PRs, run `checkout`. It creates a sparse final-state worktree at `/tmp/s2-pr-<PR>-wt` and writes `worktree_path.txt`.
5. Review only relevant readable changes:
   - Start from `changed_files.txt`, `selected_rules.json`, and targeted `rg` over `diff.patch`.
   - Prefer final files in the sparse worktree for code context; use patch hunks only to see what changed.
   - Do not load whole large diffs or broad docs when file-specific search is enough.
6. Write `/tmp/s2-pr-<PR>/findings.json` using `templates/findings.schema.json`.
7. Run `render` to produce the dashboard. It preserves one comment, carries previous resolved rows forward, and marks old active keys resolved when they disappear.
8. Unless the user asked for `--dry-run`, run `post`.
9. Run `cleanup` for temporary worktrees after posting.

## Re-review / Updated PR Workflow

- Always rerun `collect`; compare the new `headRefOid` in `pr.json` with the dashboard head.
- If the head changed, rerun `rules` and re-check existing active findings against the new final-state worktree.
- Keep stable finding keys for still-active issues. Remove fixed findings from `findings.json`; `render` marks them resolved.
- Do not re-argue resolved findings unless the regression reappears.

## Review Rules

- Default to posting/updating the dashboard. Use chat-only output only when the user asks for dry-run/local-only/don't-post.
- Keep exactly one persistent top-level issue comment containing `<!-- s2-ai-code-review -->`.
- Do not create inline comments unless the user explicitly asks for `--inline`, “file review boxes”, or “inline comments”.
- Do not approve or request changes unless explicitly asked. Normal review action is neutral/comment-only.
- Do not mention Jenkins, pending checks, CI queues, or build status unless the user explicitly asks for CI triage.
- Findings must be concrete and verified against code context. Drop speculative or style-only comments.
- Put all actionable review items only in `findings`. Do not duplicate findings in notes, suggestions, summaries, or any second action-item section.
- Render long finding text as list items with compact metadata, not as wide Markdown tables.
- The rendered dashboard title and status line include the PR number, for example `🤖 AI Eng Forge Review #123` and `👀 Needs Attention · PR #123`.
- The status icon must match the synced GitHub comment reaction: P0 `confused` / `😕`, P1 `eyes` / `👀`, P2/P3 `+1` / `👍`, no active findings `hooray` / `🎉`.
- `post` also syncs the review comment reaction by active severity: P0 `confused`, P1 `eyes`, P2/P3 `+1`, no active findings `hooray`.
- Do not print secrets. If a secret may be exposed, name the file and risk without revealing the value.
- For large PRs, prioritize highest-risk changed surfaces first: build/cook/load behavior, runtime paths, asset lifecycle, Blueprint API changes, platform/content validation, then polish.

## Severity

- `P0`: Critical. Crash/common-path regression, broken build/cook, data loss, security exposure, or severe player-facing regression.
- `P1`: Warning. Should fix before merge: lifecycle, correctness, replication, performance, content, or platform risk.
- `P2`: Note. Worth fixing: edge case, missing validation, plausible maintainability risk.
- `P3`: Suggestion. Polish only; avoid unless requested or no higher-signal findings exist.

## Team Review Rules

Team-specific review rules live in `references/review-rules/*.md`. Do not bake team rules into this `SKILL.md` unless they affect every review.

To add or update rules:

1. Copy `templates/team-rule.md` into `references/review-rules/<team-or-domain>.md`.
2. Set `id`, `description`, and `globs`.
3. Keep bullets concise and actionable.
4. Run `pr_review_helper.py rules <PR> --artifacts /tmp/s2-pr-<PR>` to verify the file is selected for matching PRs.

Current built-in rule files:

- `references/review-rules/core.md`: always loaded.
- `references/review-rules/ue-cpp.md`: loaded for `Source/**/*.h`, `Source/**/*.cpp`, `Plugins/**/*.h`, and `Plugins/**/*.cpp`.
- `references/review-rules/s2-project-cpp.md`: S2-specific C++ rules from `AGENTS.md`.
- `references/review-rules/blueprint-assets.md`: Blueprint export and binary asset review scope.
- `references/review-rules/materials.md`: material, texture, and VT validation rules.
- `references/review-rules/vfx.md`: VFX/Niagara performance and integration rules.
- `references/review-rules/animation-combat.md`: combat montage and notify rules.
- `references/review-rules/cinematics.md`: Sequencer/cutscene performance rules.
- `references/review-rules/ai-behavior.md`: AI, BT/StateTree, pathfinding, perception rules.
- `references/review-rules/world-partition-ci.md`: World Partition Jenkins/generated-content rules.

Use domain skills only when the diff clearly matches them, for example `audio-code-review`, `combat-ai-review`, `ue-network-replication-review`, `ue-montage-sync-checker`, or `s2-pr-status-check` for explicit CI triage.

## Findings JSON

Keep keys stable across re-reviews:

```json
{
  "findings": [
    {
      "level": "P1",
      "key": "P1:path-short-issue",
      "path": "Source/Foo.cpp",
      "line": 123,
      "title": "Timer captures actor by reference",
      "body": "Timer captures an actor by reference across delayed execution; capture `TWeakObjectPtr<AActor>` and validate before use."
    }
  ],
  "focus": ["UObject lifetime", "Changed tests"]
}
```

If there are no active findings, use `"findings": []`. The helper will render `🎉 Looks Good · PR #<PR>` and keep previously resolved findings visible.

## Response Shape

After posting:

```text
Updated AI Eng Forge Review dashboard on PR #<PR>.

Findings:
- 🚨 Active / P0: <n>
- ⚠️ Active / P1: <n>
- ✅ Resolved: <n>

Reaction: <reaction>
Dashboard: <url>
```
