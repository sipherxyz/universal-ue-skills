---
name: plugin-documenter
description: Write task-focused documentation for Unreal plugins used by designers, artists, and QA.
---

# Document an Unreal Plugin

Use this skill when a plugin needs practical user-facing documentation. Document verified behavior, not implementation guesses.

## Operating order

1. Identify the audience, plugin version, supported engine/project versions, prerequisites, permissions, and the one or two workflows users need.
2. Verify menu paths, labels, settings, defaults, side effects, and error states in the target build. Use `unreal-mcp` for a requested live Editor inspection after toolset discovery.
3. Write an outcome-first guide: purpose, setup, numbered workflow, field definitions, expected result, recovery/troubleshooting, and support boundary.
4. Add only screenshots that prove an important location, configuration, or result. Each placeholder must name the exact state to capture.
5. Have a representative non-programmer follow the primary workflow or explicitly record that it remains unvalidated.

## Style

- Use the exact UI names users see.
- Explain consequences before irreversible operations.
- Keep code and internal class names out of the main workflow unless users must enter them.
- Version and date the guide when behavior may change between plugin releases.

## Completion

Deliver the documentation path, verified build/plugin version, workflows covered, screenshot status, and any unverified behavior.
