---
name: ue-cpp-build
description: Build Unreal C++ targets and diagnose compiler, linker, UHT, and module errors.
---

# Build Unreal C++

Use this skill after a C++ change or when a build fails. Resolve the project, target, engine, platform, and configuration from the repository before running anything.

## Operating order

1. Identify the `.uproject`, engine association or documented engine path, and the target from `Source/*Target.cs`.
2. Start with the smallest appropriate target/configuration. Use the project's build wrapper when it exists; otherwise use the engine's `Build.bat` (or platform equivalent).
3. Read the first actual UHT, compiler, or linker error, then inspect the referenced source and its immediate dependencies.
4. Make one focused correction. Rebuild the same target and report the first error if it remains.
5. Escalate to a clean or full rebuild only for generated-code, module-boundary, build-rule, or stale-artifact evidence.

## Standard command

On Windows, a direct command normally has this shape:

```powershell
<Engine>/Engine/Build/BatchFiles/Build.bat <Target> <Platform> <Configuration> `
  -Project="<Project>/<Project>.uproject" -WaitMutex
```

For headless CI builds, use the same target/configuration as the failing job and preserve its flags. Do not replace a project wrapper, toolchain selection, or custom engine path with a guessed default.

## Editor builds

When an Editor is already open, use a build or Live Coding operation only if the official `unreal-mcp` toolsets advertise it and the user asked for the change to be compiled in that session. Restarting the Editor, changing build configuration, or rebuilding binaries that may be loaded requires confirmation.

## Diagnose by failure class

| Evidence | Typical next check |
| --- | --- |
| UHT error | reflected declaration, generated-header order, module dependencies |
| C++ compiler error | declaration/definition match, include ownership, type visibility |
| Linker error | exported symbol, module dependency, implementation compiled into target |
| Missing module/plugin | `.uproject`/`.uplugin`, target rules, supported platform |
| Stale output | only after source/build-rule evidence; then clean the narrow affected target |

## Completion

Finish with the exact target/configuration, exit status, and the relevant success or remaining failure line. Do not claim a fix from source inspection alone.
