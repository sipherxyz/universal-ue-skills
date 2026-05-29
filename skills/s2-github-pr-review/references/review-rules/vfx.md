---
id: vfx
description: VFX and Niagara performance review rules from S2 VFX docs.
globs:
  - Content/S2/Core_VFX/**
  - Content/**/VFX/**
  - Content/**/FX/**
  - Plugins/**/Content/**/VFX/**
  - Plugins/**/Content/**/FX/**
  - docs/vfx/**
  - docs/techart/vfx/**
  - Source/**/VFX/**
  - Plugins/**/Source/**/VFX/**
---

# VFX Review Rules

- Gameplay VFX should have explicit max particle counts, LOD/scalability, and distance culling; flag unbounded particle spawning or missing cleanup/pooling when visible. Usually `P1`.
- Prefer GPU Niagara simulation unless CPU collision/physics is required and documented; CPU simulation for common combat VFX is a performance risk. Usually `P1`.
- Combat VFX should generally be triggered through GameplayCue lifecycle paths rather than ad-hoc Blueprint/component spawns. Flag direct spawns that bypass cleanup or pooling. Usually `P1`.
- Watch translucent/alpha-blend overdraw and complex VFX materials; additive/unlit/simple materials are preferred unless smoke/fog/UI composition requires alpha. Usually `P2`, `P1` when repeated or central.
- Short-lived VFX should auto-destroy or be pooled; persistent VFX such as status, ambient, and weather need explicit ownership and cleanup.
