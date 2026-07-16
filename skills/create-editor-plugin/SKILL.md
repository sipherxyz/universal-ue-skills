---
name: create-editor-plugin
description: Scaffold a focused Unreal Editor plugin with correct module boundaries, registration, and build verification.
---

# Create an Unreal Editor Plugin

Use this skill to add an editor-only plugin or module. Keep the plugin limited to its stated editor workflow; do not pull runtime gameplay dependencies into it without a concrete requirement.

## Operating order

1. Establish the plugin's user outcome, host project, engine version, target modules, and whether it must ship with a marketplace/distribution build.
2. Choose the smallest module layout: one `Editor` module unless a separate runtime API is genuinely required.
3. Create the `.uplugin`, module build rules, startup/shutdown registration, and source files. Reuse the bundled templates only after replacing every placeholder and checking the project's coding conventions.
4. Add only direct public/private module dependencies; avoid circular dependencies and editor-only dependencies in runtime modules.
5. Build the editor target, enable/load the plugin in the intended project, and exercise its registered entry point.

## Guardrails

- Do not modify the `.uproject`, enable the plugin, or restart the Editor without user authorization.
- If the Editor is running, use `unreal-mcp` for requested discovery or session actions after toolset discovery.
- Prefer `UToolMenus` for new menus/toolbars; use `ue-toolbar-extension` for a focused editor-toolbar implementation.

## Completion

Report the plugin/module names, dependency decisions, build target/result, and the observed registration result. A skeleton is not complete until it compiles in the target project.
