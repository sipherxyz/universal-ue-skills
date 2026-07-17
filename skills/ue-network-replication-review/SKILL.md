---
name: ue-network-replication-review
description: Review Unreal replication for server authority, correct state sync, relevancy, and measured bandwidth.
---

# Review Unreal Replication

Use this skill for a multiplayer feature, replication defect, or network performance regression. Start from the actual server/client symptom and the owning actor/component; source patterns alone do not prove network behavior.

For offline Huli/S2 cases, classify the skill as not applicable unless the event or reproduction includes a real networked path. For applicable UE5.8 work, record engine/project revisions, server/client builds, topology, and the exact latency/loss profile before changing code.

## Operating order

1. Define authority, owner, recipients, join-in-progress expectations, and the exact state/action being reviewed.
2. Trace the state from client input through server validation/ownership, authoritative mutation, replication/RPC delivery, client application, and late-join behavior.
3. Check each replicated property is registered and has a deliberate condition, notification, initial state, and relevancy/dormancy behavior.
4. Check RPC direction, caller authorization, server-side input validation, reliability, payload size, frequency, and failure handling.
5. Reproduce with at least server plus client under representative latency/loss. Capture network stats or traces before recommending an optimization.

## Review matrix

| Area | Evidence to inspect |
| --- | --- |
| Authority | server mutation and rejection of invalid client requests |
| State sync | registration, conditions, `OnRep` handling, initial/late-join state |
| RPCs | caller ownership, validation, reliability, payload, execution context |
| Relevancy | replication graph/cull distance, dormancy, owner-only or skip-owner intent |
| Cost | actor count, update rate, property/RPC size, network trace or `stat net` |

## Guardrails

- Do not estimate bytes per frame from C++ types alone; serialization, conditions, and update frequency matter.
- Do not replace authoritative game logic with a cosmetic multicast to hide a state-sync error.
- Do not introduce Fast Array, dormancy, or a custom condition without measured evidence and join-in-progress tests.

## Completion

Report the revisions, topology and test conditions, observed behavior, confirmed issue, changed rule/code, and server/client plus late-join verification. Include network measurements when the conclusion concerns bandwidth; otherwise keep the issue blocked or not applicable rather than infer behavior from source alone.
