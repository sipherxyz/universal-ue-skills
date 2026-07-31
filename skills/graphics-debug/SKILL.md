---
name: graphics-debug
description: Diagnose Unreal renderer assertions, GPU device loss, shader or pipeline failures, and visual regressions with reproducible evidence.
---

# Debug Unreal Rendering Failures

Use the selected Engine source and the failing build as the authority. Freeze the incident before enabling diagnostics because GPU tools, thread serialization, and feature toggles can change timing, memory pressure, and the failure itself.

## 1. Freeze the incident

Record:

- failure class: renderer assertion, shader or pipeline failure, GPU device loss, GPU out-of-memory, or visual regression;
- platform, RHI, GPU, driver, OS, build configuration, and Engine/project revisions;
- first error and reason code, symbolicated callstack, named pass or resource, and available crash attachments;
- frozen trigger, content, runtime state, expected result, observation window, and process health.

For GPU device loss, record the graphics API result and device-removed reason separately. The CPU frame that detects an asynchronous GPU failure is context, not a causal frame.

For remote Sentry work, require an explicitly selected Windows host before credentials, checkout, process, or diagnostic action. Record its hardware, revisions, process state, and entry configuration.

Completion criterion: one failure class and one frozen trigger are explicit, and every material build, revision, hardware, and configuration mismatch is accepted with causal relevance or reported as a proof blocker.

## 2. Select the proof branch

| Failure class | Proof branch |
| --- | --- |
| GPU device loss, hang, TDR, or page fault | Read [references/gpu-device-loss.md](references/gpu-device-loss.md) completely before changing diagnostics |
| GPU out-of-memory or sustained memory growth | Use `ue-memory-leak-hunter` and the platform GPU-memory tools |
| Renderer/RHI assertion | Trace the first actionable frame, object or resource lifetime, thread ownership, and named render pass |
| Shader/material/pipeline failure | Compare the failing permutation, parameter layout, binding, resource state, and cooked shader availability |
| Black, missing, or incorrect D3D12 draw | Use PIX GPU Capture for replay, pipeline state, shader, and bound-resource evidence |
| GPU bottleneck, stutter, or CPU-GPU scheduling | Use Nsight Systems on a supported NVIDIA debug host |
| Packaged- or cooked-only failure | Preserve the target configuration and validate platform shader, cook, and runtime feature availability |

Use `unreal-mcp` only when live Editor state or interaction is required. Editor, PIE, commandlet, and frame-capture evidence remain isolation when the event came from a packaged client unless equivalence is proved.

Install graphics diagnostics only on the selected Windows debug host that runs the reproduction. For a D3D12 host, propose PIX when it is missing. For a supported NVIDIA host, propose Nsight Systems as well. Require explicit authorization, use official installers, and record the installed versions and paths before capture.

Completion criterion: the selected branch names its target signal, required artifacts, diagnostic configuration, prerequisites, and proof level before execution.

## 3. Establish RED

Start process-local failures with a fresh process and log. Record a zero baseline for the target signature where counting applies. Run the frozen trigger under the event configuration before adding instrumentation.

Change one diagnostic variable per comparison unless the selected Engine and tool documentation require a supported combination. Preserve the exact command or config, startup enablement evidence, timestamps, logs, artifacts, result, and process health.

A missing prerequisite, unavailable artifact, failed tool bootstrap, or run that misses the target signal is invalid RED. Repair only run-owned prerequisites, then rerun. A feature toggle, serialized thread profile, debug layer, vendor dump, or TDR change can rank a hypothesis; it cannot establish a fix.

Require explicit authorization before editing Engine/project configuration, changing the RHI, modifying registry state, restarting an existing Editor, or installing graphics tools.

Completion criterion: the target signal is repeatably RED with valid prerequisites, or the attempted route and exact evidence gap are preserved without a product change.

## 4. Prove the causal chain

Connect trigger → invalid state or GPU work → failing pass, shader, resource, or API contract → ownership. Test viable alternatives one at a time and classify each as rejected, residual, or blocked.

Use the first project or Engine frame only when it is causally supported. For asynchronous device loss, prefer breadcrumbs, page-fault data, resource history, shader mapping, and vendor crash dumps over the CPU detection frame.

Completion criterion: the chosen ownership follows from runtime artifacts or narrow instrumentation, and every viable competing hypothesis has a recorded disposition.

## 5. Verify the normal configuration

When a fix is authorized, patch the narrowest proven ownership layer. Remove proof-only diagnostics and restore every run-owned configuration, registry value, process, capture session, and generated artifact.

Run the frozen trigger on the final source state under the normal target configuration. Keep the original packaged, RHI, hardware, and observation gates unless equivalence is proved. A run with altered TDR limits, disabled features, extra validation, or a different target is supporting evidence rather than normal-configuration GREEN.

Completion criterion: the final source state has comparable GREEN evidence under the normal configuration, or the remaining runtime, packaged, hardware, or deployment gate is explicit.

## Report

Report the failure class, frozen trigger, build/device/RHI, proof level, artifacts, causal chain, rejected or residual hypotheses, fix or recommendation, RED/GREEN comparison, restored state, confidence, and remaining gate.
