# AIK Extension Context

Use this document when extending NeoStack AI / Agent Integration Kit beyond basic project setup.

## Purpose

Capture the main implementation lessons from AIK that matter when designing Unreal skills for AI agents.

## Core takeaway

AIK is **not primarily a raw `.uasset` binary editor**.

Its strength is that it runs **inside Unreal Editor** and uses Unreal's editor/runtime APIs to:
- load assets as real `UObject` instances
- inspect properties, components, graphs, nodes, and pins
- expose those operations as AI-callable tools
- finalize, compile, validate, and save using Unreal's normal asset lifecycle

This is the main reason it works better than many external tools that try to treat `.uasset` as generic binary data.

## Recommended mental model

For Unreal-facing AI skills, prefer this flow:

1. **Discover** the target asset and identify its type
2. **Read** the asset through editor-native structures
3. **Mutate** only supported surfaces
4. **Finalize** based on asset type
5. **Validate / compile**
6. **Save** through Unreal package flow
7. **Report** changes in plain language

Do **not** assume that direct byte-level patching of `.uasset` files is a reliable default approach.

## Key patterns observed in AIK

### 1) Tool server runs inside Unreal Editor

AIK exposes MCP-style endpoints from within the editor process. The AI is effectively controlling editor-native tools rather than editing project files externally.

Relevant source:
- `Source/AgentIntegrationKit/Private/MCPServer.cpp`

### 2) Assets are opened as Unreal objects

For Blueprints and other supported assets, AIK loads real Unreal asset objects and works from those reflected/editor-native representations.

Relevant source:
- `Source/AgentIntegrationKit/Private/Blueprint/BlueprintUtils.cpp`
- `Source/AgentIntegrationKit/Private/Lua/Bindings/LuaBinding_AnimSequence.cpp`
- `Source/AgentIntegrationKit/Private/Lua/Bindings/LuaBinding_MaterialInstance.cpp`

### 3) AI uses structured, asset-specific tools

AIK does not rely only on a single generic execution surface. It provides bindings and tool surfaces for different systems such as Blueprint, animation, materials, and Python.

Relevant source:
- `Source/AgentIntegrationKit/Private/Lua/NeoLuaState.cpp`
- `Source/AgentIntegrationKit/Private/Lua/Bindings/`
- `AgentIntegrationKit.uplugin`

### 4) Graph assets need post-edit finalization

Graph edits are not complete after changing nodes or pins. Many asset types require synchronization, notifications, compile steps, or structural modification calls after mutation.

Relevant source:
- `Source/AgentIntegrationKit/Public/Lua/LuaGraphFinalizer.h`

This matters especially for Blueprint and material workflows, where the visible editor graph is not always the full serialized source of truth.

### 5) Python acts as a fallback layer

AIK also bridges Unreal Python for broader editor automation. This is useful when no dedicated typed tool exists, but it should generally remain a fallback rather than the primary interface.

Relevant source:
- `Source/AgentIntegrationKit/Private/Tools/ExecutePythonTool.cpp`
- `Source/AIK_Python/Private/LuaBinding_ExecutePython.cpp`

## Why raw `.uasset` tooling often fails

Many Unreal assets include more than a simple binary payload. Common concerns include:
- reflected UObject data
- editor-only metadata
- generated classes
- graph/editor representations
- compile or rebuild steps
- package dirty/save lifecycle

A tool may be able to read bytes and still fail to produce a valid or stable editor state after changes.

## Safety patterns worth copying

When designing AI-powered Unreal skills, prefer these patterns:

- **Game-thread execution** for editor mutations
- **Transactions / rollback** on failure
- **Asset-type-specific finalization**
- **Compile and validation after edits**
- **Dirty-package tracking before save**
- **Audit logs / breadcrumbs** for AI actions

## Suggested future skill split

If you extend AIK into a larger skill system, split responsibilities into specialist skills:

- **Asset discovery** — locate asset, resolve type, gather dependencies
- **Asset reader** — summarize graph/property state for the agent
- **Graph editor** — Blueprint, material, behavior tree, state tree, etc.
- **Property editor** — non-graph asset value changes
- **Python fallback** — broad editor automation when typed tools are missing
- **Validator** — compile, finalize, health-check, save
- **Reporter** — explain what changed and what to test next

## Guidance for non-technical users

The user should not need to think in terms of serialization or binary asset format.

A good AI skill should let them ask for outcomes like:
- "Fix this Anim BP transition"
- "Add a notify here"
- "Change this material parameter"
- "Summarize what is wrong with this Blueprint"

The skill should translate that request into:
- discovery
- safe editor-native read
- asset-specific mutation
- finalize + validate
- simple report

That is the main practical lesson from AIK.
