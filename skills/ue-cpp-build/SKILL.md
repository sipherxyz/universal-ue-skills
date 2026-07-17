---
name: ue-cpp-build
description: Build Unreal C++ targets and diagnose compiler, linker, UHT, and module errors.
---

# Build Unreal C++

Use this skill after a C++ change or when a build fails. Resolve the project, target, engine, platform, and configuration from the repository before running anything.

For UE5.8 Sentry work, treat the engine branch/commit and project revision as a hard gate. Compare the selected Windows checkout with the affected event/release before building; stop on revision drift instead of silently compiling a different engine.

## Operating order

1. Identify the `.uproject`, engine association or documented engine path, engine branch/commit when available, and the target from `Source/*Target.cs`.
2. Start with the smallest appropriate target/configuration. Use the project's build wrapper when it exists; otherwise use the engine's `Build.bat` (or platform equivalent).
3. Read the first actual UHT, compiler, or linker error, then inspect the referenced source and its immediate dependencies.
4. Make one focused correction. Rebuild the same target and report the first error if it remains.
5. Escalate to a clean or full rebuild only for generated-code, module-boundary, build-rule, or stale-artifact evidence.

For a RED/GREEN proof, use the same target, platform, configuration, flags, and source fixture for both runs. Live Coding is an iteration aid, not packaged-client or final-cleanup proof. Preserve the exact command, exit code, first real error/success line, log path, and dirty-boundary result; do not clean or reset pre-existing user state.

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

Finish with the exact engine/project revisions, target/configuration, exit status, and relevant success or remaining failure line. A successful build proves compilation only; do not claim a crash fix without comparable runtime evidence.
