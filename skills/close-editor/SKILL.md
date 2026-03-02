---
name: close-editor
description: Close Unreal Editor gracefully or forcefully
---

# Close Unreal Editor

**Platform:** Windows

## Workflow

### Step 1: Check if Editor is Running

```bash
tasklist | grep -i UnrealEditor
```

If no output, editor is not running. Inform user and exit.

### Step 2: Graceful Close

Try graceful termination first:

```bash
taskkill //IM UnrealEditor.exe
```

Wait 2-3 seconds, then verify:

```bash
tasklist | grep -i UnrealEditor
```

### Step 3: Force Close (if needed)

If still running (likely waiting for save dialog):

```bash
taskkill //F //IM UnrealEditor.exe
```

### Step 4: Confirm

Verify closed:

```bash
tasklist | grep -i UnrealEditor
```

No output = success.

## Example Session

```
User: close editor
Assistant:
1. Checking if Unreal Editor is running... Found (PID 12345)
2. Sending termination signal...
3. Editor closed successfully.
```

## Notes

- Graceful close allows editor to prompt for unsaved changes
- Force close (`//F`) skips save prompts - use when stuck
- User can invoke with "force" to skip graceful attempt

## Legacy Metadata

```yaml
skill: close-editor
invoke: /dev-workflow:close-editor
type: utility
category: editor-tools
scope: project-root
```
