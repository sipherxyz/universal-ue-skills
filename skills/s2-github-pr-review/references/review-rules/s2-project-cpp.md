---
id: s2-project-cpp
description: S2 project-specific Unreal C++ review rules from AGENTS.md.
globs:
  - Source/**/*.h
  - Source/**/*.cpp
  - Plugins/**/*.h
  - Plugins/**/*.cpp
---

# S2 Project C++ Review Rules

- Flag gameplay/runtime code that introduces `LoadSynchronous()` or blocking soft-object loads; prefer existing async load or pre-resolved asset paths. Usually `P1`.
- Flag `UGameplayTagsManager::RequestGameplayTag()` in constructors, CDO/static initialization, namespace/global initialization, or function-local statics; request tags in runtime-safe phases or lazy non-static paths. Usually `P1`.
- Flag static CVars in headers; use a single `.cpp` definition such as `FAutoConsoleVariableRef`. Header statics are Live Coding/hot-reload crash risk. Usually `P1`.
- Flag committed `LogTemp`, every-frame logging in tick paths, or expensive verbose logs without `UE_LOG_ACTIVE`/non-shipping guards. Usually `P2`, `P1` if hot path.
- Treat changes to Blueprint-exposed `UFUNCTION`/`UPROPERTY` names, types, specifiers, or removals as breaking-risk only when code context or readable asset references show an affected caller/asset, or the API is clearly public and likely serialized. Do not create per-symbol evidence-gap findings; group a concrete migration risk into one finding at most.
- After plugin code changes, check whether `Plugins/{Plugin}/CHANGELOG.md` was updated when the plugin has an existing changelog. Usually `P2`.
