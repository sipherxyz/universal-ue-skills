# Graphics Debug Skill — Test Cases

**Version:** 1.0
**Total Test Cases:** 14

## Overview

| ID | Test Case | Category | Priority |
|----|-----------|----------|----------|
| TC-01 | Stack trace on worker thread → guide to render thread | Stack Trace Triage | Critical |
| TC-02 | Stack trace on render thread → identify pass + root cause | Stack Trace Triage | Critical |
| TC-03 | Stack trace on RHI thread → identify pass + root cause | Stack Trace Triage | Critical |
| TC-04 | GPU crash (DXGI_ERROR_DEVICE_REMOVED) → GPU Debug mode | Stack Trace Triage | Critical |
| TC-05 | RHI Profile 1 — add CVars to DefaultEngine.ini | RHI Debug | Critical |
| TC-06 | RHI Profile 1 — clean CVars from DefaultEngine.ini | RHI Debug | Critical |
| TC-07 | RHI Profile 1+ — guide console command after CVars | RHI Debug | High |
| TC-08 | RHI Profile 2 — output command-line flag | RHI Debug | High |
| TC-09 | GPU Profile S1 — add DRED CVars | GPU Debug | High |
| TC-10 | GPU Profile S3 — add Nsight shader symbol CVars | GPU Debug | High |
| TC-11 | GPU Profile S3+S1 — combined gpu-crash+dred CVars | GPU Debug | High |
| TC-12 | Nanite bisection — output console commands in order | GPU Debug | Medium |
| TC-13 | Identify Nanite pass from shader name in stack trace | Stack Trace Analysis | High |
| TC-14 | Identify material usage root cause from hash mismatch | Stack Trace Analysis | High |

---

## TC-01: Stack trace on worker thread → guide to render thread

**Category:** Stack Trace Triage
**Priority:** Critical

**Input:**
```
/system-architect:graphics-debug
ValidateBoundUniformBuffer() D3D12Commands.cpp:51
SetUniformBufferResourcesFromTables<…>()
FD3D12CommandContext::CommitComputeResourceTables()
FD3D12CommandContext::SetupDispatch()
FD3D12CommandContext::RHIDispatchIndirectComputeShader()
FRHICommand::ExecuteAndDestruct() RHICommandList.h
FRHICommandListBase::Execute() RHICommandList.cpp
FRHICommandListExecutor::FTranslateState::Translate()
FRHICommandListExecutor::FSubmitState::Dispatch()
FRHICommandListExecutor::FTaskPipe::Execute()
TGraphTask::ExecuteTask()
LowLevelTasks::FScheduler::WorkerLoop()
```

**Expected Result:**
- [ ] Skill detects `WorkerLoop` / `FTaskPipe::Execute` on worker thread
- [ ] Skill tells user: stack trace is on a worker thread, too noisy to diagnose
- [ ] Skill instructs to run RHI Profile 1 (`rhi profile 1`) to add CVars
- [ ] Skill instructs to type `r.RHIThread.Enable 0` in editor console
- [ ] Skill instructs to reproduce crash and re-capture stack trace on render thread
- [ ] Skill does NOT attempt to diagnose root cause from worker thread trace

---

## TC-02: Stack trace on render thread → identify pass + root cause

**Category:** Stack Trace Triage
**Priority:** Critical

**Input:**
```
/system-architect:graphics-debug
ValidateBoundUniformBuffer() D3D12Commands.cpp:51
BindUniformBuffer()
SetShaderParametersOnContext() D3D12Commands.cpp:693
FD3D12CommandContext::RHISetShaderParameters(FRHIComputeShader*)
FRHICommandSetShaderParameters::Execute()
FRHICommandListBase::Execute()
FRHICommandListExecutor::FTranslateState::Translate()
FRHICommandListExecutor::FTaskPipe::Execute()
FTaskGraphInterface::ProcessThreadUntilIdle()
FRenderingThread::Run()
```

**Expected Result:**
- [ ] Skill detects `FRenderingThread::Run()` → render thread (clean trace)
- [ ] Skill identifies crash function: `ValidateBoundUniformBuffer` → uniform buffer hash mismatch
- [ ] Skill suggests setting breakpoint at `D3D12Commands.cpp:51`
- [ ] Skill lists variables to inspect (`InBufferIndex`, `InShaderRHI->GetShaderName()`, hashes)
- [ ] Skill references Common Root Causes table (material usage flags, NaniteResources, LightingChannels)
- [ ] Skill does NOT tell user to switch threads (already on render thread)

---

## TC-03: Stack trace on RHI thread → identify pass + root cause

**Category:** Stack Trace Triage
**Priority:** Critical

**Input:**
```
/system-architect:graphics-debug
ValidateBoundUniformBuffer() D3D12Commands.cpp:51
SetShaderParametersOnContext()
FD3D12CommandContext::RHISetShaderParameters()
FRHICommandSetShaderParameters::Execute()
FRHICommandListBase::Execute()
FRHICommandListExecutor::FTranslateState::Translate()
FRHICommandListExecutor::FTaskPipe::Execute()
FTaskGraphInterface::ProcessThreadUntilIdle()
FRHIThread::Run()
```

**Expected Result:**
- [ ] Skill detects `FRHIThread::Run()` → RHI thread (Profile 1 active, usable trace)
- [ ] Skill proceeds to analyze the crash (same as TC-02)
- [ ] Skill optionally suggests Profile 1+ or Profile 2 to move to render thread for even cleaner trace
- [ ] Skill does NOT block analysis — RHI thread trace is good enough

---

## TC-04: GPU crash (DXGI_ERROR_DEVICE_REMOVED) → GPU Debug mode

**Category:** Stack Trace Triage
**Priority:** Critical

**Input:**
```
/system-architect:graphics-debug
LogD3D12RHI: Error: D3D12 Device Lost - DXGI_ERROR_DEVICE_REMOVED
LogD3D12RHI: Error: Device Removal Reason: DXGI_ERROR_DEVICE_HUNG (0x887A0006)
```

**Expected Result:**
- [ ] Skill detects `DXGI_ERROR_DEVICE_REMOVED` or `Device Lost`
- [ ] Skill recommends GPU Debug mode (not RHI Debug)
- [ ] Skill suggests Profile S3 (`gpu-crash`) for Nsight shader symbols
- [ ] Skill suggests Profile S1 (`dred`) for DRED breadcrumbs
- [ ] Skill instructs to delete shader caches before recompile
- [ ] Skill mentions `.nv-gpudmp` file for Nsight Graphics

---

## TC-05: RHI Profile 1 — add CVars to DefaultEngine.ini

**Category:** RHI Debug
**Priority:** Critical

**Input:**
```
/system-architect:graphics-debug rhi profile 1
```

**Precondition:** `Config/DefaultEngine.ini` exists with `[ConsoleVariables]` section, no debug CVars present.

**Expected Result:**
- [ ] Adds to `[ConsoleVariables]` section:
  - `r.RHICmd.ParallelTranslate.Enable=0`
  - `r.RDG.ParallelExecute=0`
  - `r.RDG.ParallelSetup=0`
  - `r.Nanite.AsyncRasterization=0`
- [ ] Does NOT duplicate if CVars already present
- [ ] Does NOT add `r.RHIThread.Enable` (it's a command, not CVar)
- [ ] Outputs confirmation message

**Verification:**
```bash
grep -E "r\.RHICmd\.ParallelTranslate|r\.RDG\.Parallel|r\.Nanite\.Async" Config/DefaultEngine.ini
```

---

## TC-06: Clean — remove debug CVars from DefaultEngine.ini

**Category:** RHI Debug
**Priority:** Critical

**Input:**
```
/system-architect:graphics-debug clean
```

**Precondition:** `Config/DefaultEngine.ini` has debug CVars from Profile 1 + S1 + S3.

**Expected Result:**
- [ ] Removes all RHI debug CVars: `r.RHICmd.ParallelTranslate.Enable`, `r.RDG.ParallelExecute`, `r.RDG.ParallelSetup`, `r.Nanite.AsyncRasterization`
- [ ] Removes all GPU debug CVars: `D3D12.EnableDRED`, `D3D12.DREDMarkersOnly`, `r.Shaders.Optimize`, `r.Shaders.Symbols`, `r.Shaders.ExtraData`, `r.Shaders.SkipCompression`, `r.Shaders.SymbolsInfo`, `r.GPUCrashDebugging`, `r.GPUCrashDebugging.Aftermath.TrackAll`
- [ ] Does NOT remove non-debug CVars in the same section
- [ ] Does NOT remove `[ConsoleVariables]` section header
- [ ] Outputs list of removed CVars

**Verification:**
```bash
grep -E "r\.RHICmd|r\.RDG|r\.Nanite\.Async|D3D12\.(Enable|DRED)|r\.Shaders\.|r\.GPUCrash" Config/DefaultEngine.ini
# Expected: no output
```

---

## TC-07: RHI Profile 1+ — guide console command after CVars

**Category:** RHI Debug
**Priority:** High

**Input:**
```
/system-architect:graphics-debug rhi profile 1+
```

**Expected Result:**
- [ ] Adds same CVars as Profile 1 (TC-05)
- [ ] Additionally outputs instruction: type `r.RHIThread.Enable 0` in editor console after launch
- [ ] Explains why it cannot go in INI (FAutoConsoleCommand, not CVar)
- [ ] Mentions brief hitch during thread restart

---

## TC-08: RHI Profile 2 — output command-line flag

**Category:** RHI Debug
**Priority:** High

**Input:**
```
/system-architect:graphics-debug rhi profile 2
```

**Expected Result:**
- [ ] Outputs VS Command Arguments: `-norhithread`
- [ ] Does NOT modify DefaultEngine.ini (command-line only)
- [ ] Explains this achieves same result as Profile 1+ from startup

---

## TC-09: GPU Profile S1 — add DRED CVars

**Category:** GPU Debug
**Priority:** High

**Input:**
```
/system-architect:graphics-debug shader dred
```

**Expected Result:**
- [ ] Adds to `[ConsoleVariables]`:
  - `r.RHICmd.ParallelTranslate.Enable=0`
  - `D3D12.EnableDRED=1`
  - `D3D12.DREDMarkersOnly=0`
- [ ] Mentions alternative: `-norhithread -d3ddebug -gpuvalidation`
- [ ] Mentions DRED output location: `Saved/Logs/S2.log`

---

## TC-10: GPU Profile S3 — add Nsight shader symbol CVars

**Category:** GPU Debug
**Priority:** High

**Input:**
```
/system-architect:graphics-debug shader gpu-crash
```

**Expected Result:**
- [ ] Adds to `[ConsoleVariables]`:
  - `r.Shaders.Optimize=0`
  - `r.Shaders.Symbols=1`
  - `r.Shaders.ExtraData=1`
  - `r.Shaders.SkipCompression=1`
  - `r.Shaders.SymbolsInfo=1`
  - `r.GPUCrashDebugging=1`
  - `r.GPUCrashDebugging.Aftermath.TrackAll=1`
- [ ] Instructs to delete `Saved/ShaderDebugInfo/` and `Intermediate/Shaders/`
- [ ] Warns about slower shader compilation

---

## TC-11: GPU Profile S3+S1 — combined gpu-crash+dred CVars

**Category:** GPU Debug
**Priority:** High

**Input:**
```
/system-architect:graphics-debug shader gpu-crash+dred
```

**Expected Result:**
- [ ] Adds all S3 CVars (TC-10) PLUS S1 DRED CVars:
  - `D3D12.EnableDRED=1`
  - `D3D12.DREDMarkersOnly=0`
- [ ] No duplicate CVars
- [ ] Instructs to delete shader caches

---

## TC-12: Nanite bisection — output console commands in order

**Category:** GPU Debug
**Priority:** Medium

**Input:**
```
/system-architect:graphics-debug shader nanite-bisect
```

**Expected Result:**
- [ ] Outputs 4 console commands in order:
  1. `r.Nanite.MaxNodes 0`
  2. `r.Nanite.Visualize 0`
  3. `r.Nanite.AllowProgrammableRaster 0`
  4. `r.Nanite.AllowMaskedMaterials 0`
- [ ] Each step says what it means if the crash stops
- [ ] Does NOT modify DefaultEngine.ini (runtime console commands only)
- [ ] Mentions `r.Nanite.ShowStats 1` as optional extra

---

## TC-13: Identify Nanite pass from shader name in stack trace

**Category:** Stack Trace Analysis
**Priority:** High

**Input:**
```
/system-architect:graphics-debug
ValidateBoundUniformBuffer() D3D12Commands.cpp:51
BindUniformBuffer()
SetShaderParametersOnContext()
FD3D12CommandContext::RHISetShaderParameters(FRHIComputeShader* NaniteRasterizeBinCS)
FRHICommandSetShaderParameters::Execute()
FRHICommandListBase::Execute()
FRHICommandListExecutor::FTranslateState::Translate()
FRHICommandListExecutor::FTaskPipe::Execute()
FRenderingThread::Run()
```

**Expected Result:**
- [ ] Detects render thread (clean trace)
- [ ] Identifies shader name: `NaniteRasterizeBinCS` → Nanite HW/SW rasterization pass
- [ ] Suggests Nanite-specific root causes:
  - Missing `NaniteResources` on ProxyDesc
  - Material lacks `MATUSAGE_Nanite` / `MATUSAGE_InstancedStaticMeshes`
  - Material not post-loaded (`ConditionalPostLoad()`)
- [ ] Suggests Profile S2 (Nanite bisection) to narrow further
- [ ] References Profile S4 (material usage validation) as likely fix

---

## TC-14: Identify material usage root cause from hash mismatch

**Category:** Stack Trace Analysis
**Priority:** High

**Input:**
```
/system-architect:graphics-debug
The crash is ValidateBoundUniformBuffer hash mismatch in NaniteRasterize pass.
I'm using actor-less ISM proxies (cascade foliage / FastGeo pattern).
Materials are loaded via TSoftObjectPtr.
```

**Expected Result:**
- [ ] Identifies actor-less proxy pattern as high-risk for material usage flag issues
- [ ] Explains `CheckMaterialUsage_Concurrent` vs `CheckMaterialUsage` (concurrent only CHECKS, non-concurrent can SET)
- [ ] Suggests pre-calling `CheckMaterialUsage(MATUSAGE_InstancedStaticMeshes)` and `CheckMaterialUsage(MATUSAGE_Nanite)` on game thread
- [ ] Suggests `ConditionalPostLoad()` for TSoftObjectPtr-loaded materials
- [ ] Suggests `TStrongObjectPtr` GC guard to prevent material collection
- [ ] Suggests checking `LightingChannels.bChannel0 = true` on ProxyDesc
- [ ] References NaniteResources.cpp:911 and PrimitiveSceneProxyDesc.cpp:11-79

---

## Test Summary

| ID | Status | Notes |
|----|--------|-------|
| TC-01 | [ ] | |
| TC-02 | [ ] | |
| TC-03 | [ ] | |
| TC-04 | [ ] | |
| TC-05 | [ ] | |
| TC-06 | [ ] | |
| TC-07 | [ ] | |
| TC-08 | [ ] | |
| TC-09 | [ ] | |
| TC-10 | [ ] | |
| TC-11 | [ ] | |
| TC-12 | [ ] | |
| TC-13 | [ ] | |
| TC-14 | [ ] | |
