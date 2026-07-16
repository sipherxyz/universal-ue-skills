---
name: ue-xr-compliance-checker
description: Audit Unreal Xbox integration against current authorized Xbox Requirements and project evidence.
---

# Audit Xbox Requirements Readiness

Use this skill before an Xbox certification milestone or to investigate a concrete requirements finding. Xbox Requirements change: rely on the current authorized platform-holder documentation and SDK guidance rather than a static checklist.

## Operating order

1. Record target consoles, GDK/SDK version, submission phase, and the exact authorized requirement or finding.
2. Map each applicable requirement to code/configuration, test coverage, device evidence, and an accountable owner. Keep unknowns explicit.
3. Inspect applicable user/account, sign-out, storage/cloud-save, entitlement, achievement, suspend/resume, networking, controller, and error-message flows.
4. Validate on the required devkit/test environment, preserving the build identifier, logs, video, and test result.
5. Turn confirmed gaps into focused fixes with re-test criteria. A source scan can identify candidates but cannot establish compliance.

## Completion

Return a requirement-to-evidence table with confirmed gaps, unverified items, and the next required device/build test. Keep confidential requirements out of public reports.
