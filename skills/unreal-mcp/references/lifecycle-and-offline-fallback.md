# Lifecycle and offline fallback

## Remote host gate

When the Editor is on Windows and the agent is remote, require the host to be named in the current request or reply. Before launching or connecting, record the hostname, Windows session/RDP state, project path, engine path and revision, and the initial Editor/MCP process state. Do not infer a host from old logs.

## Launch and shutdown

Ask before launching, restarting, or closing an Unreal Editor session unless the user already authorized that action in the current turn. Resolve the `.uproject` and engine association from the project; do not write machine-specific caches into `Saved/`.

Start the official server explicitly when automatic startup is not configured:

```text
UnrealEditor.exe <Project.uproject> -ModelContextProtocolStartServer
```

Use the project's configured endpoint. When Codex and Editor are on separate machines, forward the Editor loopback port over SSH before connecting.

Graceful shutdown is an explicit user action. Force termination requires a separate explicit confirmation because unsaved Editor work can be lost.

After the run, close only MCP sessions, tunnels, monitors, and Editor processes created by that run. Verify the MCP listener and Editor PID are gone, then re-check the initial tracked-dirty boundary.

## Offline and headless work

Use a commandlet, automation test, or offline parser only when at least one condition holds:

- the user asks for headless, CI, or batch execution;
- the Editor cannot be connected after diagnosis; or
- the discovered official toolsets do not expose the required operation.

Treat offline `.uasset` parsing as evidence extraction, not asset mutation. State that it cannot prove every serialized property or live Editor result.

For a packaged/Game crash, Editor or MCP evidence remains an isolation result unless the same packaged configuration and trigger were exercised. Preserve that remaining gate in the report.
