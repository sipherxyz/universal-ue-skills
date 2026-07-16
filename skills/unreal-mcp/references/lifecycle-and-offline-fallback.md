# Lifecycle and offline fallback

## Launch and shutdown

Ask before launching, restarting, or closing an Unreal Editor session unless the user already authorized that action in the current turn. Resolve the `.uproject` and engine association from the project; do not write machine-specific caches into `Saved/`.

Start the official server explicitly when automatic startup is not configured:

```text
UnrealEditor.exe <Project.uproject> -ModelContextProtocolStartServer
```

Use the project's configured endpoint. When Codex and Editor are on separate machines, forward the Editor loopback port over SSH before connecting.

Graceful shutdown is an explicit user action. Force termination requires a separate explicit confirmation because unsaved Editor work can be lost.

## Offline and headless work

Use a commandlet, automation test, or offline parser only when at least one condition holds:

- the user asks for headless, CI, or batch execution;
- the Editor cannot be connected after diagnosis; or
- the discovered official toolsets do not expose the required operation.

Treat offline `.uasset` parsing as evidence extraction, not asset mutation. State that it cannot prove every serialized property or live Editor result.
