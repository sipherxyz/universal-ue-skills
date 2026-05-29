---
id: cinematics
description: Cutscene, Sequencer, and cinematic performance review rules.
globs:
  - Content/S2/Cinematics/**
  - Content/**/Cutscene/**
  - Content/**/Cinematic/**
  - Plugins/**/SipherCutscene*/**
  - Source/**/Cutscene/**
  - Plugins/**/Source/**/Cutscene/**
  - docs/engineer/cutscene/**
---

# Cinematics Review Rules

- Runtime Level Sequences should use baked or linked animation sequences after animation finalization; flag live Control Rig tracks left active for runtime playback. Usually `P1`.
- Avoid sequences locked to 30 FPS or `Lock to Display Rate at Runtime`; S2 cinematic guidance expects 60 FPS display rate without runtime locking. Usually `P1` when runtime-facing.
- Prefer replaceable bindings to pre-spawned actors over Sequencer spawnables for characters with gameplay state/equipment; spawnables can hitch and lose state. Usually `P1`.
- Niagara tracks in cinematics need scalability enabled and configured; heavy VFX should be baked to flipbooks or Sim Cache when scalability cannot keep budget. Usually `P1`.
- Expensive VFX/light tracks should use Conditional Tracks or equivalent quality gating when they are not essential at low settings. Usually `P2`.
- Cinematic PRs should mention Sequence Validator or equivalent validation when changing runtime-facing Level Sequences. Usually `P2`.
