---
name: ue-toolbar-extension
description: Add a focused Unreal Editor toolbar or menu action using UToolMenus and validate its lifecycle.
---

# Add an Unreal Editor Toolbar Action

Use this skill to add one editor-facing action to an existing editor module/plugin. Confirm the target editor, user action, selection/context rules, and command side effect before writing code.

## Operating order

1. Locate the owning editor module and the appropriate menu/toolbar registration point.
2. Define a command with a clear label, tooltip, icon strategy, and `CanExecute` condition. Disable it when its context is invalid.
3. Register through `UToolMenus` during module startup; unregister owner/menus during shutdown so Live Coding and reloads do not duplicate entries.
4. Keep the command handler narrow. Route asset or Editor actions through supported Unreal APIs, not raw package writes.
5. Compile the editor module and verify the command appears once, responds to valid context, and remains unavailable or disabled for invalid context.

## Guardrails

- Use `unreal-mcp` for requested Editor-session discovery or verification only after discovering its toolsets.
- Do not restart the Editor, change plugin enablement, or mutate assets without authorization.
- Use the bundled templates and `editor-menus-reference.md` as implementation aids, not as project conventions.

## Completion

Report the target menu/toolbar, owner module, command behavior, build result, and observed lifecycle verification.
