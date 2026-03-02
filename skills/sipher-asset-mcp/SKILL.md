---
name: sipher-asset-mcp
description: Configure sipher-assets MCP server to use Python, installing dependencies as needed
---

# Sipher Asset MCP Setup Skill

**Role:** MCP Server Configuration Utility
**Scope:** Current Working Directory
**Platform:** Windows

## Objective

Configure the sipher-assets MCP server using Python. Auto-detects project path from current working directory.

## Workflow

### Step 1: Check Python Installation

```bash
python --version
```

**Required:** Python 3.10+

### Step 2: Detect Project Path

Find the `.uproject` file to determine the UE5 project root:

```bash
ls {CWD}/*.uproject
```

**Project Path:** Use the directory containing the `.uproject` file. This is typically `{CWD}`.

**IMPORTANT:** Use forward slashes (`/`) in the path for cross-platform JSON compatibility.

### Step 3: Install Dependencies

```bash
pip install -e "{CWD}/tools/SipherAssetMCP"
```

### Step 4: Update MCP Configuration

Update `.mcp.json` with the **actual resolved project path** (NOT `${workspaceFolder}` - Claude Code doesn't resolve VS Code variables):

```json
{
    "mcpServers": {
        "sipher-assets": {
            "command": "python",
            "args": ["-m", "sipher_asset_mcp"],
            "env": {
                "S2_PROJECT_PATH": "{RESOLVED_PROJECT_PATH}"
            }
        }
    }
}
```

Where `{RESOLVED_PROJECT_PATH}` is the actual path like `G:/s2` or `C:/Projects/S2`.

### Step 5: Verify Module

```bash
python -c "from sipher_asset_mcp.server import main; print('OK')"
```

### Step 6: Restart Claude Code

Inform user to restart Claude Code or start a new conversation to reload the MCP server.

## Success Criteria

- Python 3.10+ detected
- `.uproject` file found in CWD
- sipher-asset-mcp package installed
- `.mcp.json` uses **actual resolved path** (e.g., `G:/s2`), NOT `${workspaceFolder}`
- Module imports successfully
- User instructed to restart Claude Code

## Legacy Metadata

```yaml
skill: sipher-asset-mcp
invoke: /dev-workflow:sipher-asset-mcp
type: utility
category: mcp-setup
scope: project-root
```
