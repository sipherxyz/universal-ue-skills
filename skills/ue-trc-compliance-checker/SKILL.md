---
name: ue-trc-compliance-checker
description: Audit Unreal PlayStation integration against the current authorized TRC requirements and project evidence.
---

# Audit PlayStation TRC Readiness

Use this skill before a certification milestone or to investigate a concrete PlayStation compliance finding. TRC requirements are confidential and change over time: use the current authorized platform-holder documentation as the source of truth.

## Operating order

1. Record the target platform, SDK version, submission phase, and the exact approved TRC source or finding being assessed.
2. Map each applicable requirement to implementation, configuration, test case, and evidence artifact. Mark unknowns as unknown.
3. Inspect the relevant flows: account/sign-out, suspend/resume, save and storage errors, network interruption, controller/device changes, user messaging, and trophies where applicable.
4. Reproduce on the required devkit/test environment and retain logs, video, and result identifiers.
5. Convert confirmed gaps into narrow owners and verification criteria; do not claim certification readiness from a static source scan.

## Completion

Return a requirement-to-evidence table, confirmed gaps, unverified requirements, and the exact device/build test still required. Keep confidential requirement text out of public reports.
