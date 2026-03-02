---
name: graphics-debug
description: Debug rendering crashes — RHI thread serialization, GPU crash dumps, D3D12 DRED, Nanite bisection, shader symbols
---

# Graphics Debug Skill

**Platform:** Windows (Win64, D3D12)

## Quick Start (for junior engineers)

### Step 1: Identify the crash type

Look at the crash callstack. Two cases:

**Case A — GPU crash** (log shows `DXGI_ERROR_DEVICE_REMOVED`, `Device Lost`, or no useful callstack):
→ Run `/system-architect:graphics-debug shader gpu-crash` to enable Nvidia Nsight shader symbols and GPU crash dump. Reproduce the crash, then open the `.nv-gpudmp` file in Nsight Graphics.

**Case B — RHI / rendering crash** (callstack shows `ValidateBoundUniformBuffer`, `SetShaderParametersOnContext`, `FRHICommand::Execute`, etc.):
→ The crash likely happens on a **random worker thread**, making the callstack noisy and hard to read. You need to move all draw commands to the **rendering thread** first.

### Step 2 (Case B): Move to rendering thread

UE5 dispatches RHI commands across multiple worker threads by default. To debug, disable multithreaded rendering so everything runs on one thread:

1. Run `/system-architect:graphics-debug rhi profile 1` — adds CVars to `DefaultEngine.ini`
2. Launch editor, open console (`~`), type: `r.RHIThread.Enable 0`
3. Reproduce the crash
4. Now the callstack is on the **rendering thread** — clean and readable

### Step 3: Paste the stack trace

Copy the full callstack and paste it to this skill:

```
/system-architect:graphics-debug <paste stack trace here>
```

The skill will:
- Identify which rendering pass crashed (Nanite raster, BasePass, ShadowDepths, etc.)
- Point to the likely root cause (missing uniform buffer, material usage flag, null texture, etc.)
- Suggest a fix

**If the stack trace shows `LowLevelTasks::FScheduler::WorkerLoop` or `FTaskPipe::Execute` on a worker thread**, the skill will tell you to switch to rendering thread first (Step 2) and re-capture — worker thread callstacks are too noisy to diagnose.

---

## Modes

| Mode | When to use |
|------|-------------|
| **RHI Debug** | Crashes in `ValidateBoundUniformBuffer`, `FRHICommand::Execute`, task graph workers |
| **GPU Debug** | Material binding mismatches, GPU device removed, Nanite crashes, `GetD3D12TextureFromRHITexture(null)` |

---

# Mode A: RHI Debug

Move crashes off random task graph workers onto a stable thread.

## UE 5.7 RHI Thread Architecture

RHI commands flow through three `FTaskPipe` stages: **Dispatch → Translate → Submit**. Crashes happen during Translate → `CmdList->Execute()` (RHICommandList.cpp:1092).

| Stage | `AllowParallel()=true` (default) | `AllowParallel()=false` |
|-------|----------------------------------|-------------------------|
| **Dispatch** | worker thread | render thread |
| **Translate** (crash site) | worker if `bParallel`, else RHI thread | render thread |
| **Submit** | RHI thread | render thread |

**`r.RHICmdBypass` is useless alone** — `Bypass()` is hard-gated by `!IsRunningRHIInSeparateThread()` (RHICommandList.cpp:1749). With RHI thread active (default), it's always `false`.

**`r.RHIThread.Enable` cannot go in INI** — registered as `FAutoConsoleCommand` (RenderingThread.cpp:1460), not `TAutoConsoleVariable`. INI processing calls `FindConsoleVariable()` → `AsVariable()` → returns `nullptr` for commands → creates dummy `IAmNoRealVariable`. Use `-norhithread` flag or type `r.RHIThread.Enable 0` in editor console instead.

## Profiles

### Profile 1: Translate → RHI Thread (CVar only, fastest)

`DefaultEngine.ini [ConsoleVariables]`:

```ini
r.RHICmd.ParallelTranslate.Enable=0
r.RDG.ParallelExecute=0
r.RDG.ParallelSetup=0
r.Nanite.AsyncRasterization=0
```

Crash breakpoint hits on RHI thread (stable named thread).

### Profile 1+: ALL RHI → Render Thread (CVar + console)

Profile 1 CVars + after editor launches, type in console: `r.RHIThread.Enable 0`

All three stages route to render thread. Brief hitch during thread restart.

### Profile 2: ALL RHI → Render Thread (command-line)

VS Command Arguments: `-norhithread`

Same result as 1+ but from startup. Also unblocks `r.RHICmdBypass`.

### Profile 3: Single Thread (Game + Render merged)

VS Command Arguments: `-norenderthread -norhithread`

Cleanest callstacks, very slow. Use when Profile 1/2 insufficient.

### Profile 4: Task Graph Serialization

For crashes in task graph workers outside RHI (e.g. Mass Entity processors).

```ini
TaskGraph.ForceNumWorkerThreads=0
```

## Expected Callstack (Profile 1+/2)

```
ValidateBoundUniformBuffer()           ← BREAKPOINT
SetUniformBufferResourcesFromTables()
FD3D12CommandContext::SetupDispatch()
FRHICommand::ExecuteAndDestruct()
FRHICommandListBase::Execute()
FRHICommandListExecutor::FTranslateState::Translate()
FRHICommandListExecutor::FTaskPipe::Execute()  ← render thread (Profile 1: RHI thread)
```

---

# Mode B: GPU Debug

## Profiles

### Profile S1: D3D12 DRED + Debug Layer

GPU-side crash diagnosis. DRED shows last GPU operations before fault.

**DefaultEngine.ini** (combine with RHI Profile 1):

```ini
r.RHICmd.ParallelTranslate.Enable=0
D3D12.EnableDRED=1
D3D12.DREDMarkersOnly=0
```

**Or command-line** (combine with RHI Profile 2): `-norhithread -d3ddebug -gpuvalidation`

`-d3ddebug` enables D3D12 debug layer, `-gpuvalidation` catches shader resource access errors. Slow — use only after identifying the pass.

### Profile S2: Nanite Bisection

Disable features one at a time to narrow the crash source:

| Step | Console command | If crash stops → |
|------|-----------------|------------------|
| 1 | `r.Nanite.MaxNodes 0` | Nanite entirely |
| 2 | `r.Nanite.Visualize 0` | Visualization pass |
| 3 | `r.Nanite.AllowProgrammableRaster 0` | WPO raster |
| 4 | `r.Nanite.AllowMaskedMaterials 0` | Masked material binding |

Extra: `r.Nanite.ShowStats 1` for stats overlay.

### Profile S3: GPU Crash Dump + Shader Symbols (Nvidia Nsight)

Full shader debug info for `.nv-gpudmp` crash dumps. Disassembly maps 1:1 to HLSL.

**DefaultEngine.ini `[ConsoleVariables]`:**

```ini
r.Shaders.Optimize=0
r.Shaders.Symbols=1
r.Shaders.ExtraData=1
r.Shaders.SkipCompression=1
r.Shaders.SymbolsInfo=1
r.GPUCrashDebugging=1
r.GPUCrashDebugging.Aftermath.TrackAll=1
```

| CVar | Purpose |
|------|---------|
| `r.Shaders.Optimize=0` | Disable optimizations — assembly matches HLSL source |
| `r.Shaders.Symbols=1` | Emit PDB-style debug symbols in shaders |
| `r.Shaders.ExtraData=1` | Variable names + line numbers in shader blobs |
| `r.Shaders.SkipCompression=1` | Raw bytecode — Nsight reads directly |
| `r.Shaders.SymbolsInfo=1` | Write `.shaderinfo` sidecar files for external tools |
| `r.GPUCrashDebugging=1` | Breadcrumb markers + resource tracking |
| `r.GPUCrashDebugging.Aftermath.TrackAll=1` | Track all Aftermath resources (shaders, textures, buffers) |

**Requires shader recompilation.** Delete `Saved/ShaderDebugInfo/` and `Intermediate/Shaders/` after adding CVars. Combine with S1 DRED by adding `D3D12.EnableDRED=1` + `D3D12.DREDMarkersOnly=0`.

### Profile S4: Material Usage Validation

For actor-less proxies (FastGeo, cascade foliage) where `Nanite::FSceneProxy` constructor calls `CheckMaterialUsage_Concurrent(MATUSAGE_InstancedStaticMeshes)` (NaniteResources.cpp:911) — the concurrent version only CHECKS, can't SET. If flag missing → fallback to default material → uniform buffer hash mismatch.

**Fix:** Pre-call non-concurrent `CheckMaterialUsage` on game thread before proxy creation:

```cpp
UMaterial* BaseMat = Mat->GetMaterial();
BaseMat->CheckMaterialUsage(MATUSAGE_InstancedStaticMeshes);
BaseMat->CheckMaterialUsage(MATUSAGE_Nanite);
```

### Profile S5: Breakpoint Investigation

Set breakpoint at `D3D12Commands.cpp:51` (`ValidateBoundUniformBuffer`). The shader expects uniform buffer layout hash X at slot N, but hash Y was bound — wrong struct type.

| Variable | What it tells you |
|----------|-------------------|
| `InBufferIndex` | Binding slot with mismatch |
| `InShaderRHI->GetShaderName()` | Shader name → identifies the pass |
| `InUniformBuffer->GetLayout().GetDebugName()` | Actual bound UB type |
| `ShaderTableHash` vs `UniformBufferHash` | Expected vs actual hash |

Pass identification: `NaniteRasterize` = HW/SW raster, `NaniteCull` = culling, `NaniteVisualize` = debug vis, `BasePass` = main pass, `ShadowDepths` = shadows.

---

# Common Root Causes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Null uniform buffer in compute | Missing `NaniteResources` on ProxyDesc | Set `ProxyDesc->NaniteResources` before proxy creation |
| UB hash mismatch | Material lacks `MATUSAGE_InstancedStaticMeshes` / `MATUSAGE_Nanite` | Profile S4: pre-call `CheckMaterialUsage()` on game thread |
| Null texture (`GetD3D12TextureFromRHITexture`) | Unresolved texture ref / GC collected | `ConditionalPostLoad()` + `TStrongObjectPtr` GC guard |
| Crash only in Nanite Mask vis | Vis pass reads fields not populated for actor-less proxies | Check `FPrimitiveSceneProxy::GetScene()` valid |
| Crash after streaming in/out | Race between `BatchRemovePrimitives` and new proxy | `ENQUEUE_RENDER_COMMAND` + two-pass flush |
| `LightingChannelMask=0` | ProxyDesc constructor defaults all-zero | Set `LightingChannels.bChannel0 = true` |
| Crash disappears with serialized RHI | Game/render thread race | `FlushRenderingCommands()` between destroy and create |

---

# Gotchas

| Problem | Solution |
|---------|----------|
| `-d3ddebug` causes TDR | Use `-gpuvalidation` alone, or increase TDR timeout (see below) |
| `r.RHICmdBypass 1` no effect | Requires `-norhithread` to unblock |
| `r.RHIThread.Enable 0` in INI no effect | `FAutoConsoleCommand`, not CVar — use console or `-norhithread` |
| DRED output missing | Search `Saved/Logs/S2.log` for `D3D12 DRED` |
| Dummy CVar warning in log | Search for `IAmNoRealVariable` — confirms command-as-CVar failure |

**TDR Timeout** (if `-gpuvalidation` causes Device Removed):

```powershell
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDelay /t REG_DWORD /d 60 /f
# Requires reboot
```

---

# Usage Examples

```bash
/system-architect:graphics-debug rhi profile 1        # Serialize to RHI thread
/system-architect:graphics-debug rhi profile 1+       # Serialize to render thread
/system-architect:graphics-debug shader dred           # DRED CVars
/system-architect:graphics-debug shader gpu-crash      # Nsight shader symbols
/system-architect:graphics-debug shader gpu-crash+dred # Full GPU debug
/system-architect:graphics-debug shader nanite-bisect  # Nanite bisection
/system-architect:graphics-debug clean                 # Remove debug CVars
```

---

# Engine Source References

| File | Line | What |
|------|------|------|
| `RHICommandList.cpp` | 64-68 | `r.RHICmd.ParallelTranslate.Enable` CVar definition |
| `RHICommandList.cpp` | 755 | `AllowParallel()` — gated by `!Bypass() && IsRunningRHIInSeparateThread()` |
| `RHICommandList.cpp` | 780-796 | `GetTranslateTaskPipe()` — thread routing decision |
| `RHICommandList.cpp` | 1731-1756 | `LatchBypass()` — hard-gated by `IsRunningRHIInSeparateThread()` |
| `RenderingThread.cpp` | 763-793 | `LatchRenderThreadConfiguration()` — runtime thread stop/restart |
| `RenderingThread.cpp` | 799-807 | `-norhithread` flag parsing |
| `RenderingThread.cpp` | 1460-1464 | `r.RHIThread.Enable` as `FAutoConsoleCommand` |
| `ConfigUtilities.cpp` | 310-415 | `OnSetCVarFromIniEntry()` — `FindConsoleVariable()` ignores commands |
| `D3D12Commands.cpp` | 42-58 | `ValidateBoundUniformBuffer()` — hash mismatch check |
| `NaniteResources.cpp` | 911 | `CheckMaterialUsage_Concurrent(MATUSAGE_InstancedStaticMeshes)` — can't set flag |
| `NaniteResources.cpp` | 927-930 | Fallback to default material when usage flag missing |
| `PrimitiveSceneProxyDesc.cpp` | 11-79 | Constructor defaults (`LightingChannels` all-zero) |

## Legacy Metadata

```yaml
skill: graphics-debug
invoke: /system-architect:graphics-debug
type: development
category: render-debugging
scope: project-root
```
