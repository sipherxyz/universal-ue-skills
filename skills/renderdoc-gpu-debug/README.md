# RenderDoc GPU Debug Skill

Universal skill package for GPU frame capture and inspection with [RenderDoc](https://renderdoc.org) and [`rdc-cli`](https://github.com/BANANASJIM/rdc-cli).

## Included Files

- `SKILL.md` - Main skill instructions and workflows
- `references/commands-quick-ref.md` - Command-oriented quick reference
- `references/debugging-recipes.md` - Investigation playbooks
- `capture_frame.py` - Capture helper template using the RenderDoc Python API
- `requirements-mcp.txt` - Python dependency for the optional MCP server
- `mcp_server/` - Optional MCP server that exposes `rdc-cli` as tools

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| RenderDoc | Needs `renderdoc.pyd` and `renderdoc.dll` or platform equivalent |
| Python 3.10+ | Must match the RenderDoc Python module build |
| `rdc-cli` | Install with `pip install rdc-cli` |
| Image-capable agent workflow | The agent should be able to open exported PNGs |

## Install From This Repo

Project-scoped install:

```bash
bash scripts/install-skills.sh --agent all --scope project --project-dir .
```

Global install:

```bash
bash scripts/install-skills.sh --agent all --scope global
```

After install, the skill is available as `renderdoc-gpu-debug` in the target agent's skills directory.

## Setup

Install `rdc-cli`:

```bash
pip install rdc-cli
```

Set `RENDERDOC_PYTHON_PATH` to the directory containing the RenderDoc Python module:

```bash
export RENDERDOC_PYTHON_PATH=/path/to/renderdoc/module
```

For Vulkan capture, also ensure the RenderDoc implicit layer is registered and set:

```bash
export ENABLE_VULKAN_RENDERDOC_CAPTURE=1
```

Verify the environment:

```bash
rdc doctor
```

## How To Use

Ask the agent naturally with prompts like:

```text
Capture a frame and inspect why the shadow map is blocky.
Open this .rdc file and tell me which draw call writes this pixel.
Compare these two RenderDoc captures and summarize what changed.
Export the GBuffer normals target and inspect it for corruption.
```

The intended loop is:

1. Capture or open an `.rdc` file.
2. Explore passes, draws, and pipeline state with `rdc`.
3. Export PNGs for suspicious render targets or textures.
4. Inspect the images and correlate them with bindings, constants, and shader state.
5. Close the session with `rdc close`.

## Capture Helper

`capture_frame.py` is a template. Set these environment variables before running it:

```bash
export RDC_CAPTURE_EXE=/path/to/your/app
export RDC_CAPTURE_CWD=/path/to/your/project
export RDC_CAPTURE_ARGS="--scene test --interactive"
export RDC_CAPTURE_PATH=./captures/frame.rdc
python skills/renderdoc-gpu-debug/capture_frame.py
```

## Optional MCP Server

If you want `rdc-cli` exposed as MCP tools, install the dependency and register the server with your MCP-capable agent:

```bash
pip install -r skills/renderdoc-gpu-debug/requirements-mcp.txt
python skills/renderdoc-gpu-debug/mcp_server/server.py
```

Claude Code registration example:

```bash
claude mcp add rdc-tools -- python skills/renderdoc-gpu-debug/mcp_server/server.py
```

The vendored server comes from the upstream project and is most directly aligned with Claude Code style MCP usage.

## Attribution

This skill package is based on the upstream project at <https://github.com/rudybear/renderdoc-skill/tree/master>. The original project also documents a Claude Code-specific installation flow and demo video.
