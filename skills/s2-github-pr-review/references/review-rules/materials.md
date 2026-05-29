---
id: materials
description: Material, texture, and virtual texture review rules from S2 material guidelines.
globs:
  - Content/**/Material*/**
  - Content/**/Materials/**
  - Content/**/Texture*/**
  - Content/**/Textures/**
  - Content/**/VirtualTexture/**
  - Content/**/VT/**
  - Plugins/**/Content/**/Material*/**
  - Plugins/**/Content/**/Materials/**
  - Plugins/**/Content/**/Texture*/**
  - Plugins/**/Content/**/Textures/**
  - Plugins/**/Content/**/VirtualTexture/**
  - Plugins/**/Content/**/VT/**
  - Source/**/VirtualTexture/**
  - Source/**/Material*/**
  - Plugins/**/Source/**/VirtualTexture/**
  - Plugins/**/Source/**/Material*/**
  - docs/engineer/material/**
---

# Materials Review Rules

- Flag changes under `/Game/Textures` or broad texture edits when the PR is only fixing sampler/VT issues; the guideline says to minimize affected references and avoid modifying shared texture folders. Usually `P1`.
- For Virtual Texture conversions, check that related material/material-instance/texture changes are committed together; partial conversions can produce sampler mismatches. Usually `P1`.
- Base color textures should be sRGB/non-linear; metallic, roughness, mask, and packed data textures should be linear/non-sRGB with matching compression/sampler types. Usually `P1` when mismatch is visible in changed metadata or validator output.
- VFX materials, UI textures, and MetaHuman materials are exceptions to the default VT preference; do not require VT for those paths.
- Flag material samples or texture parameters with missing/default-invalid textures, parent material compile errors, or locked master material edits when visible in logs, validator output, or changed config. Usually `P1`.
