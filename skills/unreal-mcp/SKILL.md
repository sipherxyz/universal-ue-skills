---
name: unreal-mcp
description: Use Epic's official Unreal MCP for live Editor and asset inspection, editing, toolset discovery, or editor-backed verification.
---

# Official Unreal MCP

Use Unreal Engine's `ModelContextProtocol` server and its runtime-discovered toolsets for live Editor work. This is the only live-asset route in this pack.

## Operating order

1. Confirm scope and current state: active project, Editor process, MCP connection, and whether the user authorized an Editor launch or restart. Completion: a reachable session or an explicit reason it cannot be reached.
2. Complete the MCP handshake, then use `list_toolsets` and `describe_toolset` to find the narrowest toolset for the requested asset or operation. Completion: the selected tool's actual input schema is known.
3. Read the real asset or Editor state before proposing or making a change. Completion: report identifies the inspected object, its current state, and the evidence used.
4. Make only the requested mutation through the discovered tool. Do not guess tool names, parameters, or supported asset types. Completion: the MCP call succeeds without an unexpected fallback.
5. Read back the changed state, save when the toolset requires it, then run the domain-appropriate compile, validation, or smoke check. Completion: the readback and verification result are reported.

## Guardrails

- Do not use Agent Integration Kit, BpGeneratorUltimate, SipherAssetMCP, generic Python/Lua execution, or raw `.uasset`/`.umap` edits as a substitute for official MCP.
- A listening port is not proof of a usable server; verify `initialize` and `tools/list`.
- A short initial tool list is normal when tool search is enabled. Discover the registry before declaring a capability absent.
- If MCP does not expose the required operation, say so. Use a headless commandlet or offline parser only when the user requested it or live Editor access is unavailable.

## References

- For safe launch, shutdown, and offline fallback rules, read [lifecycle-and-offline-fallback.md](references/lifecycle-and-offline-fallback.md).
- For domain review criteria after reading a live asset, read [asset-review-rules.md](references/asset-review-rules.md).
