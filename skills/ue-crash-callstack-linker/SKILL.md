---
name: ue-crash-callstack-linker
description: Map Unreal crash callstacks to source, classify the failure, and propose evidence-backed fixes.
---

# Analyze an Unreal Crash

Use this skill for a crash report, fatal error, ensure, minidump, or callstack. Work from the exact build artifact and symbols when they are available.

For UE5.8 Sentry work, record the affected release, engine branch/commit, project revision, environment, and build configuration before mapping. A missing or opaque revision is a diagnosis gate, not permission to guess.

## Operating order

1. Preserve the original report: engine version, platform, build/changelist, error text, callstack, and reproduction frequency.
2. Verify symbol compatibility before mapping a minidump. A mismatched executable or PDB can produce convincing but false source locations.
3. Find the first actionable frame, whether engine, project, plugin, or third-party; map it to the checked-out revision and inspect its inputs and ownership. Do not treat the terminal assert site as ownership by itself.
4. Classify the failure (null/dangling access, bounds, thread affinity, lifetime, assertion, allocation, GPU/driver, or startup/configuration).
5. State the smallest plausible fix and the evidence needed to prove it. Treat an `ensure` separately from a fatal crash unless the log proves escalation, and use a fresh process when the signature may be process-local.

## What to report

| Field | Include |
| --- | --- |
| Signature | error text and top meaningful frame |
| Scope | affected build/platform and recurrence |
| Cause | evidence and uncertainty, not only a pattern match |
| Fix | narrow code/configuration change or next diagnostic |
| Verification | reproduction, targeted test, build, and no-new-event check |

## Source and symbol safety

- Never infer an exact source line from an unsymbolized address.
- For packaged crashes, keep the matching executable, PDBs, and CrashContext together.
- For GPU crashes, collect GPU/driver information and the DRED/GPU dump before blaming gameplay code.
- Use `unreal-mcp` for a requested Editor inspection; do not relaunch or alter the session without confirmation.
- For a proposed fix, distinguish evidence-only diagnosis, subsystem isolation, and full player-flow. A build or Editor pass alone is not GREEN; retain the packaged/release and no-new-event gate.

## Completion

Finish with a linked source location only when the revision and symbols agree, the ownership layer is explicit, and the report includes a comparable verification plan and remaining deployment/no-new-event gate.
