---
name: ue-localization-scanner
description: Find Unreal user-facing text that is not ready for the project's localization pipeline.
---

# Audit Unreal Localization Readiness

Use this skill to investigate a specific localization defect or audit a defined code/content scope. Learn the project's localization targets, string-table policy, supported cultures, and text-gather command before labeling a pattern a defect.

## Operating order

1. Establish the scope: C++, UI/Blueprint assets, data assets, plugins, and target cultures.
2. Search for likely user-facing literals, then classify each by context. Logs, developer diagnostics, test data, asset keys, and identifiers are not automatically localizable text.
3. Check that user-facing text uses the project-approved `FText`/`LOCTEXT`/string-table path and that namespace, key, and source text remain stable as required.
4. Run the project's gather/compile/validation command and inspect the generated manifest/archive or failures.
5. Verify representative text in at least one non-source culture and test format arguments, plural/gender handling, truncation, and input prompts where applicable.

## Finding quality

| Finding | Evidence required |
| --- | --- |
| Hardcoded player-facing text | source/asset location and visible UI path |
| Missing or unstable localization key | gather output and the owning text definition |
| Missing translation | target culture artifact and in-game observation |
| Layout/input defect | locale/device reproduction with a screenshot or capture |

## Guardrails

- Do not bulk-convert literals without confirming user visibility and the project's key policy.
- Do not claim a string-table entry is orphaned from a text-only scan; Blueprints, data, and dynamic keys may reference it.
- Use `unreal-mcp` for a requested live Editor inspection after toolset discovery; use repository search and the project's localization command for headless evidence.

## Completion

Report the scanned scope, exact findings with context, gather result, cultures verified, and any remaining content or UI validation.
