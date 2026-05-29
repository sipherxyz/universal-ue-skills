---
id: animation-combat
description: Combat animation montage and notify review rules from S2 montage guidelines.
globs:
  - Content/S2/**/Animation/**
  - Content/S2/**/Animations/**
  - Content/S2/**/Montage/**
  - Content/S2/**/Montages/**
  - docs/gamedesign_new/**/Animation*
  - docs/gamedesign_new/**/*Montage*
  - Source/**/Animation/**
  - Plugins/**/Source/**/Animation/**
---

# Animation Combat Review Rules

- Combat montages should preserve clear `Preparation/Anticipation`, `Attack`, and `Recovery` phases; flag changes that make hit windows unreadable or remove recovery opportunity without design notes. Usually `P1` for combat behavior changes.
- Multi-hit or multi-attack montages need repeated notify states per attack segment, not one broad notify covering unrelated phases.
- Check gameplay-critical notifies/tags such as damage windows, combo/cancel windows, parry/perfect dodge/counter windows, ignore hit reaction, block action, root motion/warp/rotate-to-target, and collision disable windows.
- Root motion, motion warping, and rotation windows must match the intended movement distance/targeting behavior; flag mismatches between montage setup and code/DataAsset assumptions.
- Attack SFX/VFX should be socket/frame aligned; flag missing or duplicated notifies when changed assets/docs expose the montage timing.
- Do not commit local cheat/stat tuning data used only for montage testing.
