---
name: graphics-debug
description: Diagnose Unreal rendering failures using reproducible RHI, shader, DRED, and GPU-capture evidence.
---

# Debug Unreal Rendering Failures

Use this skill for renderer assertions, GPU device loss, corrupted output, shader failures, and render-thread crashes. Begin with the exact platform, RHI, GPU driver, build, and reproduction path.

## Operating order

1. Classify the incident from the first error and callstack: CPU render-thread assertion, shader/material/pipeline failure, GPU device removal, or visual regression.
2. Capture the smallest useful evidence: full log, crash context, RHI/GPU dump, DRED data, and a RenderDoc capture for visual failures where possible.
3. Check the first project frame and the named pass/resource before changing render-thread settings or feature flags.
4. Isolate one variable at a time: affected content, shader permutation, feature, thread mode, RHI, or driver. Record the command/configuration and result.
5. Apply the smallest correction, restore diagnostic settings, and reproduce under the normal configuration.

## Evidence guide

| Signal | Initial focus |
| --- | --- |
| `DXGI_ERROR_DEVICE_REMOVED` / device lost | DRED/GPU dump, driver, last submitted GPU work |
| Uniform-buffer or shader-parameter assertion | parameter layout, resource lifetime, shader permutation |
| Render-thread or RHI task crash | first project frame, object/resource lifetime, thread ownership |
| Black/missing/incorrect draw | RenderDoc event, pipeline state, resource binding, material usage |
| Cooked-only rendering issue | platform shader/cook output and runtime feature availability |

## Guardrails

- Treat debug layers, GPU validation, thread serialization, and TDR changes as temporary diagnostics; they can drastically change timing and performance.
- Ask before editing engine/project configuration, registry settings, launching a different RHI, or restarting the Editor.
- Use `unreal-mcp` for requested live Editor actions after discovering the available toolsets. Use `renderdoc-gpu-debug` for detailed frame inspection.

## Completion

Report the reproduction, build/device/RHI, evidence captured, isolated variable, root-cause confidence, fix, and normal-configuration verification.
