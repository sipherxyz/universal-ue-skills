# RenderDoc Debugging Recipes

Use these recipes after `rdc open` when you know the symptom but not the cause.

## Object Is Invisible

1. Find the draw with `rdc draws --limit 50 --json`.
2. Check rasterizer state with `rdc pipeline EID rs --json`.
3. Check depth-stencil state with `rdc pipeline EID ds --json`.
4. Confirm geometry exists with `rdc draw EID --json`.
5. Debug a representative vertex with `rdc debug vertex EID 0 --json`.

Typical causes: wrong winding, bad viewport or scissor, depth rejection, zero color write mask, off-screen transforms.

## Colors Are Wrong

1. Export the current render target with `rdc rt EID -o ./captures/analysis/wrong-color.png`.
2. Check the pixel value with `rdc pick-pixel X Y EID --json`.
3. Inspect texture and sampler bindings with `rdc bindings EID --json`.
4. Export the bound texture with `rdc texture RESID -o ./captures/analysis/bound-texture.png`.
5. Inspect material constants with `rdc shader EID ps --constants --json`.

Typical causes: wrong texture bound, bad material constants, sRGB mismatch, unexpected blend state, incorrect shader math.

## Shadows Are Broken

1. List passes with `rdc passes`.
2. Filter shadow pass draws with `rdc draws --pass "Shadow Pass" --json`.
3. Export the shadow map with `rdc rt SHADOW_EID -o ./captures/analysis/shadow-map.png`.
4. Check bias and culling with `rdc pipeline SHADOW_EID rs --json`.
5. Inspect light matrices and shadow parameters with `rdc shader LIGHT_EID ps --constants --json`.
6. Trace a broken pixel with `rdc debug pixel LIGHT_EID X Y --trace`.

Typical causes: low shadow-map resolution, bias too low or too high, incorrect light matrices, missing PCF filtering, shadow map not sampled.

## Performance Is Bad

1. Start with `rdc stats --json`.
2. Review pass structure with `rdc passes`.
3. Look for heavy draw ranges with `rdc draws --limit 200 --json`.
4. Inspect oversized textures or buffers.
5. Export wireframe overlays to spot overdraw or geometry explosion.

Typical causes: too many draws, oversized resources, redundant passes, expensive overdraw, excessive state churn.

## What Changed Between Frames

1. Run `rdc diff before.rdc after.rdc --shortstat`.
2. Compare draws with `rdc diff before.rdc after.rdc --draws --json`.
3. Compare resources with `rdc diff before.rdc after.rdc --resources --json`.
4. Export the framebuffer diff with `rdc diff before.rdc after.rdc --framebuffer --diff-output ./captures/analysis/frame-diff.png`.

Use this when a rendering regression appears after a code or content change.

## Debug This Pixel

1. Start with `rdc pixel X Y --json`.
2. Identify the last passing draw that touched the pixel.
3. Check the resolved color with `rdc pick-pixel X Y FINAL_EID --json`.
4. Trace shader execution with `rdc debug pixel FINAL_EID X Y --trace`.
5. Correlate with pipeline state using `rdc pipeline FINAL_EID --json`.

Typical causes: depth or stencil rejection, unexpected blending, wrong bound resources, or bad per-pixel shader logic.
