# GPU Device-Loss Evidence

Use this reference for GPU hangs, TDRs, page faults, and device-removed or device-lost errors. The goal is a GPU-side causal chain, not a label derived from the final API error.

## Evidence contract

Preserve a manifest that ties every artifact to one run:

- trigger, timestamps, process ID, build configuration, executable, and command line;
- Engine/project revisions, platform, RHI, GPU, driver, OS, and debug configuration;
- first API error plus the device-removed reason;
- full Unreal log and crash context;
- RHI breadcrumbs and active/finished/not-started GPU work;
- DRED mode, last completed operation, faulting virtual address, and matching active or recently freed objects when available;
- vendor dump, shader binaries, shader debug data, shader hashes, marker data, and analysis-tool version when available;
- process health and whether the trigger completed.

Keep large dumps, logs, symbols, and generated reports outside the source checkout. Record missing artifacts as evidence gaps. A dump without matching build and run metadata cannot prove the event; missing shader data limits source mapping.

## Route by API and hardware

| Conditions | Primary evidence |
| --- | --- |
| D3D12 on any vendor | Unreal RHI breadcrumbs plus lightweight or full DRED |
| D3D12 shader resource or state validation | D3D12 Debug Layer and GPU-Based Validation in a dedicated diagnostic run |
| Supported NVIDIA hardware and driver | Nsight Aftermath dump with matching shader binaries and debug data |
| Supported AMD hardware, OS, and driver | Radeon GPU Detective dump and text/JSON analysis |
| Supported DirectX Dump environment | DirectX Dump plus PIX analysis as an explicitly experimental route |
| Stable frame or visual/pipeline failure | RenderDoc capture; use `renderdoc-gpu-debug` |

DRED is the vendor-neutral baseline for D3D12 device loss. Vendor tools add shader, resource, residency, and hardware-specific detail. Verify current hardware, OS, driver, API, and tool compatibility before selecting a vendor route.

RenderDoc is a frame-inspection route. Use it when a valid capture can contain the suspicious pass or state; it is not the default post-mortem artifact for an asynchronous device loss. Run interception-based tools separately unless current vendor documentation and the selected configuration prove coexistence.

## Diagnostic ladder

1. Inspect the event artifacts before reproducing. Classify timeout, page fault, reset, out-of-memory, or unknown from the API result, device-removed reason, log, and dump data.
2. Reproduce the unmodified event configuration with a fresh process and log.
3. Add the lightest supported breadcrumbs or DRED profile and verify its startup markers.
4. Escalate one evidence gap at a time to full DRED, D3D validation, Aftermath, RGD, DirectX Dump, or narrow instrumentation.
5. Use feature, execution, residency, and VRAM-pressure A/B tests to rank a named hypothesis. Return to the event configuration for causal confirmation.

Completion criterion: each run changes one recorded diagnostic dimension, produces attributable artifacts, and either advances a named hypothesis or closes the route with a specific evidence gap.

## Interpret artifacts

| Evidence | Supported inference | Remaining alternatives |
| --- | --- | --- |
| Timeout with a repeatable active pass or shader | Work in that region did not complete in time | Excessive work, infinite loop, synchronization, driver, or hardware |
| Page fault matching a recently freed object | Resource lifetime is the leading ownership area | Confirm pending GPU use and the releasing path |
| Page fault matching an active object | The virtual address belongs to a live allocation | Residency, tiled mapping, stale descriptor, incompatible state, or out-of-bounds access |
| D3D validation error | The reported API, descriptor, binding, or resource-state contract was violated | Connect the message to the event trigger and ownership |
| Vendor dump with shader/source mapping | The fault or active warp maps to the identified shader work | Confirm inputs, resource state, and the triggering runtime path |
| Crash disappears after a feature or scheduling toggle | The toggle exposes a causal region | It is not a fix and may hide a timing, memory, or workload problem |
| Device reset without matching project GPU work | Another graphics context or environment is plausible | Reason codes are not fully reliable; correlate system and application evidence |
| GPU out-of-memory evidence | Memory budget or residency pressure is material | Route sustained growth to `ue-memory-leak-hunter` and distinguish exhaustion from page-fault ownership |

## Resolve Unreal diagnostics from the selected Engine

Treat the selected Engine source as the single source of truth for console variables, command-line flags, defaults, compile guards, and artifact paths. Before a run:

1. Locate the diagnostic registration and platform guards in that Engine revision.
2. Confirm the chosen setting exists for the target RHI and build configuration.
3. Record its default, requested value, and startup log marker.
4. Reject the run as invalid evidence when enablement cannot be read back.

Documentation examples can drift between Engine versions and forks. Resolve names from the selected source instead of carrying a command from an earlier incident.

## TDR safety

A TDR registry change is a host mutation and a diagnostic configuration:

- obtain explicit approval;
- record whether `TdrDelay` and `TdrDdiDelay` exist and preserve their exact values;
- record the new values, reboot requirement, host, and run ownership;
- restore the original state and verify it after the diagnostic run;
- classify results under the changed timeout as supporting evidence, not normal-configuration GREEN.

Prefer smaller workloads, tiled passes, or a narrower reproduction when those retain the event semantics. A longer timeout can reveal more evidence, but disappearance of the timeout does not prove the underlying defect is fixed.

## Primary references

- [Epic Games: Dealing with a GPU Crash](https://dev.epicgames.com/documentation/en-us/unreal-engine/dealing-with-a-gpu-crash-when-using-unreal-engine)
- [Microsoft: Use DRED to diagnose GPU faults](https://learn.microsoft.com/en-us/windows/win32/direct3d12/use-dred)
- [Microsoft: GPU-Based Validation](https://learn.microsoft.com/en-us/windows/win32/direct3d12/using-d3d12-debug-layer-gpu-based-validation)
- [NVIDIA: Nsight Aftermath SDK Guide](https://docs.nvidia.com/nsight-aftermath/SDK/index.html)
- [AMD: Radeon GPU Detective manual](https://gpuopen.com/manuals/rgd_manual/)
- [Microsoft: DirectX Dump Files preview](https://devblogs.microsoft.com/directx/dx-dump-files-preview/)
