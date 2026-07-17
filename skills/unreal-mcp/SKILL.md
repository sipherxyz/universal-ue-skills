---
name: unreal-mcp
description: Use Epic's official Unreal MCP for live Editor and asset inspection, editing, toolset discovery, or editor-backed verification.
---

# Official Unreal MCP

Use Unreal Engine's `ModelContextProtocol` server and its runtime-discovered toolsets for live Editor work. This is the only live-asset route in this pack.

For remote crash or Sentry work, require an explicitly selected Windows host before credentials, SSH, RDP, MCP, or Editor actions. Record the host/session, project and engine revisions, tracked dirty boundary, process state, and evidence-log path before using the Editor.

## Operating order

1. Confirm scope and current state: active project, target build/configuration, Editor process, MCP connection, and whether the user authorized an Editor launch or restart. For a packaged/Game event, decide whether the failing path can execute in Editor before accepting MCP as proof. Completion: a reachable session or an explicit reason it cannot be reached, plus the proof boundary.
2. Complete the MCP handshake, then use `list_toolsets` and `describe_toolset` to find the narrowest toolset for the requested asset or operation. Completion: the selected tool's actual input schema is known.
3. Read the real asset or Editor state before proposing or making a change. Completion: report identifies the inspected object, its current state, and the evidence used.
4. Make only the requested mutation through the discovered tool. Do not guess tool names, parameters, or supported asset types. Completion: the MCP call succeeds without an unexpected fallback.
5. Read back the changed state, save when the toolset requires it, then run the domain-appropriate compile, validation, or smoke check. Completion: the readback and verification result are reported.

## Guardrails

- Do not use Agent Integration Kit, BpGeneratorUltimate, SipherAssetMCP, generic Python/Lua execution, or raw `.uasset`/`.umap` edits as a substitute for official MCP.
- A listening port is not proof of a usable server; verify `initialize` and `tools/list`.
- A short initial tool list is normal when tool search is enabled. Discover the registry before declaring a capability absent.
- If MCP does not expose the required operation, say so. Use a headless commandlet or offline parser only when the user requested it or live Editor access is unavailable.
- A successful Editor call is not packaged-client proof. Check compile/runtime guards, world type, feature CVars, platform/RHI support, and target-only initialization before using it to validate a packaged event.
- A fixture, setup, or toolset failure is blocked evidence, not a RED reproduction. Preserve the exact missing prerequisite and do not claim a fix from the call alone.

## References

- For safe launch, shutdown, and offline fallback rules, read [lifecycle-and-offline-fallback.md](references/lifecycle-and-offline-fallback.md).
- For domain review criteria after reading a live asset, read [asset-review-rules.md](references/asset-review-rules.md).

## Completion evidence

Report the selected toolset and schema, exact MCP calls, inspected object or runtime state, read-back, process health, and cleanup result. Close only sessions and Editor processes created by the run; preserve pre-existing user state.
