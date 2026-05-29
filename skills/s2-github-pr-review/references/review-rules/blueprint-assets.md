---
id: blueprint-assets
description: Blueprint export and binary asset review scope rules.
globs:
  - .blueprints/**/*.md
  - Content/**/*.uasset
  - Plugins/**/Content/**/*.uasset
---

# Blueprint And Asset Review Rules

- Review `.blueprints/**/*.md` as code-like logic: flag invalid control flow, unsafe casts, missing authority checks, lifecycle/order bugs, and broken asset references.
- Skip visualization-only Blueprint exports such as `*_vis.md`, `*_mermaid.md`, `*_tree.md`, and `*_box.md` unless the PR explicitly changes generated visualization logic.
- For binary `.uasset` changes, review only path, naming, ownership, obvious redirector/moved-asset risk, and whether related generated/source metadata is present; do not infer hidden graph/content behavior from the binary diff alone.
- Flag committed `*.uproject` or project descriptor churn unless the PR clearly requires it. Usually `P1` when it affects build/cook/plugin load behavior.
