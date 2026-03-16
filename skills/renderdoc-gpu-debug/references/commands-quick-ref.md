# RenderDoc Command Quick Reference

Use these commands as the first pass when debugging a capture with `rdc-cli`.

## Session

```bash
rdc open path/to/capture.rdc
rdc status
rdc close
```

## Overview

```bash
rdc info --json
rdc stats --json
rdc passes
rdc count draws
rdc gpus --json
```

## Draw And Event Navigation

```bash
rdc draws --limit 20
rdc draws --pass "Shadow Pass" --json
rdc draw EID --json
rdc events --limit 50
rdc event EID --json
```

## Pipeline And Bindings

```bash
rdc pipeline EID --json
rdc pipeline EID vs --json
rdc pipeline EID ps --json
rdc pipeline EID rs --json
rdc pipeline EID om --json
rdc bindings EID --json
rdc bindings EID --set 0 --json
```

## Shader Inspection

```bash
rdc shader EID vs --json
rdc shader EID ps --source
rdc shader EID ps --reflect --json
rdc shader EID ps --constants --json
rdc shaders --stage ps --json
rdc search "shadow" --stage ps
rdc shader-map --json
```

## Visual Export

```bash
mkdir -p ./captures/analysis
rdc rt EID -o ./captures/analysis/render_target.png
rdc rt EID --target 1 -o ./captures/analysis/rt1.png
rdc texture RESID -o ./captures/analysis/texture.png
rdc thumbnail -o ./captures/analysis/thumb.png
```

## Pixel And Shader Debugging

```bash
rdc pixel X Y --json
rdc pick-pixel X Y EID --json
rdc debug pixel EID X Y --json
rdc debug pixel EID X Y --trace
rdc debug vertex EID VERTEX_ID --json
rdc debug thread EID GX GY GZ TX TY TZ --json
```

## Diffing

```bash
rdc diff before.rdc after.rdc --shortstat
rdc diff before.rdc after.rdc --draws --json
rdc diff before.rdc after.rdc --resources --json
rdc diff before.rdc after.rdc --framebuffer --diff-output ./captures/analysis/diff.png
```

## Useful Flags

- `--json` for structured output
- `--limit N` to keep exploration manageable
- `--pass "Name"` to stay inside one render pass
- `-q` for terse ID-only output where supported
