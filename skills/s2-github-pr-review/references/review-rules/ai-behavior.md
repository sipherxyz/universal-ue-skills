---
id: ai-behavior
description: AI, Behavior Tree, State Tree, perception, and pathfinding review rules.
globs:
  - Content/S2/Core_Ene/**
  - Content/S2/Core_Boss/**
  - Content/**/BehaviorTree/**
  - Content/**/BehaviorTrees/**
  - Plugins/Frameworks/SipherAIScalableFramework/**
  - Source/**/AI/**
  - Plugins/**/Source/**/AI/**
  - docs/architecture/AAA_Enemy_Content_Design/**
  - docs/gamedesign_new/designerdocs/Enemy/**
---

# AI Behavior Review Rules

- Flag Behavior Tree/State Tree changes that add frequent polling, broad services, or per-frame condition checks without gating, LOD, or time slicing. Usually `P1`.
- Perception and target search should be distance/priority gated; flag unbounded scans over actors, senses, blackboard targets, or nearby enemies in tick/service paths.
- Pathfinding should have search limits, reuse/caching where practical, and failure handling; flag repeated full path requests from hot BT tasks/services.
- Enemy/boss content changes should keep referenced BTs, montages, abilities, DataAssets, and gameplay tags coherent with the GDD/design doc paths when those references are visible.
- Crowd or burst/special-attack coordination should avoid multiple normal enemies selecting the same high-priority action simultaneously unless boss/elite design explicitly allows it.
