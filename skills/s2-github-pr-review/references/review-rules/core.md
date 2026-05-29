---
id: core
description: Rules that apply to every AI Eng Forge Review.
always: true
globs:
---

# Core Review Rules

- Report only concrete, verified risks from the PR diff and necessary surrounding context.
- Prefer high-signal runtime, build, cook, security, data-loss, platform, replication, content, and test-coverage issues.
- Avoid style-only feedback unless it hides a real defect or recurring maintenance risk.
- Keep findings short, actionable, and tied to a file/line.
- Do not mention Jenkins, pending checks, CI queues, or build status unless the user asks for CI triage.
- Do not reveal secrets. If a secret appears in a diff, describe the exposure without printing the value.

## Updating Rules

Team-specific rules should be added as separate markdown files in this folder. Use frontmatter with `id`, `description`, and `globs` so the helper can select only relevant rules for each PR.
