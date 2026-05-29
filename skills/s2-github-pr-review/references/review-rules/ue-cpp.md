---
id: ue-cpp
description: Unreal Engine C++ safety rules.
globs:
  - Source/**/*.h
  - Source/**/*.cpp
  - Plugins/**/*.h
  - Plugins/**/*.cpp
---

# Unreal C++ Review Rules

- Check UObject lifetime, GC reachability, `UPROPERTY`, `TObjectPtr`, and weak handles for async/timer/delegate callbacks.
- Flag sync asset loads on runtime/editor tool paths when async loading or pre-resolved references are practical.
- Check editor-only code stays behind editor modules or `WITH_EDITOR` guards.
- Check replication changes for authority, lifetime props, RPC validation, relevancy, and bandwidth.
- Check Tick work for clear runtime need, gating, and allocation/logging cost.
- Check build/cook risk from module dependencies, includes, asset references, and platform-specific assumptions.
- Prefer minimal includes and project-local patterns over broad headers or new one-off abstractions.
