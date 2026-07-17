---
name: ue-detect-engine
description: Resolve and validate a custom Unreal Engine path, version, and source revision for a project build or Editor session.
---

# Detect Unreal Engine

Resolve the engine without changing the project or machine. Use this before a build, commandlet, Editor launch, or crash-source mapping.

## Operating order

1. Resolve the project root and `.uproject` from the current checkout; prefer an explicit `ENGINE_PATH` or `skills.config.json` value.
2. If no explicit path exists, read `EngineAssociation` and inspect the Windows Unreal Engine build registry or the documented build share.
3. Validate the candidate with `Build/BatchFiles/Build.bat`, `Engine/Binaries/DotNET/UnrealBuildTool/UnrealBuildTool.exe`, and the required Editor binary.
4. Read the engine version from `Build.version` and, when the engine is a source checkout, record its branch and commit. Do not treat a directory name alone as a revision.
5. For a UE5.8-only task, compare the resolved engine branch/commit with the affected event or release and stop on drift.

## Guardrails

- Read-only by default; do not edit `.uproject`, registry entries, source, or generated project files.
- Do not write machine-specific engine caches into `Saved/` or commit detected paths.
- Never fall back to a launcher engine when the issue requires a custom source build without recording the mismatch.
- If multiple candidates validate, report all candidates and the selection rule instead of guessing.

## Completion

Report the project path, exact engine path, version, branch/commit when available, validated executables, selection source, and any revision mismatch. A missing or ambiguous candidate is a blocked result, not a usable engine.
