---
name: ue-memory-leak-hunter
description: Compare Unreal memory evidence to find retained allocations, UObject growth, and budget regressions.
---

# Investigate Unreal Memory Growth

Use this skill when memory grows across a repeatable scenario, a platform budget is exceeded, or an out-of-memory event occurs.

## Operating order

1. Define the repeatable scenario, build, platform, memory budget, and baseline/warm-up point.
2. Capture comparable evidence at baseline and after each repetition: `memreport -full`, allocator stats, object listings, and platform profiler captures as available.
3. Compare deltas by allocator, asset/resource class, and UObject/class count. Separate expected streaming/cache growth from retained growth after cleanup.
4. Trace the largest persistent delta to an owner, reference chain, subsystem lifetime, or allocation site.
5. Make one narrow remediation, then repeat the identical scenario and compare the new deltas.

## Guardrails

- Do not call a one-time load spike a leak without a post-GC/unload observation.
- Keep capture settings, map, device, build, and warm-up consistent.
- Check object references and delegate/timer ownership before adding forced collection.
- Use platform-native tooling for console or GPU memory; a PC `memreport` may not represent that budget.

## Completion

Report the scenario, before/after evidence, persistent delta, suspected owner, remediation, and repeat-run result. If the evidence is inconclusive, state the next capture needed.
