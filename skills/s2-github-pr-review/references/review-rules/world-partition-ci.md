---
id: world-partition-ci
description: World Partition Jenkins pipeline and generated-content safety rules.
globs:
  - Jenkins/JenkinsFile.WorldPartition
  - Jenkins/config/worldpartition-watchlist.json
  - Jenkins/README.WorldPartition.md
  - Source/S2Editor/**/Streaming/**
  - Source/S2EditorCommandlets/**/WorldPartition/**
  - Content/**/.worldpartition/**
---

# World Partition CI Review Rules

- Resume from previous World Partition branches must validate metadata against source branch, mode, target level scope, builder, and trigger identity before restoring generated `Content/`. Usually `P1`.
- Scope guards should stage only expected generated files; unexpected `Content/` changes should be excluded and surfaced for review rather than committed. Usually `P1`.
- Do not commit runtime coordination data from `Saved/SipherWorldPartitionBuilder`; only tracked metadata such as `.worldpartition/wp-resume-metadata.json` belongs in git. Usually `P1`.
- Scheduled or asynchronous follow-up builds must carry explicit branch/PR identity such as target level, WP branch, trigger run id, and correlation key. Usually `P2`.
- PR creation and notification failures should not discard generated WP branch state; treat metadata publishing as best-effort unless the generated content is unsafe.
