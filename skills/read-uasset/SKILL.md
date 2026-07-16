---
name: read-uasset
description: Offline Unreal .uasset evidence extraction.
disable-model-invocation: true
---

# Offline UAsset Extraction

Use this only when the user explicitly requests offline inspection, needs headless evidence, or official Unreal MCP is unavailable. For live asset work, use `unreal-mcp` first.

## Workflow

1. Confirm the target files are available locally and read-only access is sufficient.
2. Use `extract_uasset_strings.ps1` for quick string evidence or `scripts/parse_uasset.py` for structured metadata and dependency hints.
3. Label every result as string extraction or parsed metadata. Do not infer unseen graph state or mutate the asset.

```bash
python scripts/parse_uasset.py "<asset.uasset>" --summary
python scripts/parse_uasset.py "<asset.uasset>" --deep --format text
```

Completion: the report identifies the exact files read, the extraction method, and any uncertainty that needs live Editor verification.
