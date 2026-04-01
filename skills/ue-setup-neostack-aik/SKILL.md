---
name: ue-setup-neostack-aik
description: Help team members set up NeoStack Agent Integration Kit with SipherGateway in their Unreal Engine project. Triggers on "NeoStack setup", "AIK setup", "SipherGateway", "configure AI agent in UE", "NeoStack profile".
---

# Setup NeoStack AI (Agent Integration Kit)

Help any team member get AI agents working inside Unreal Editor using the studio's **SipherGateway**.

**What you get:** A chat panel inside UE where you can talk to AI agents (Claude, Codex, etc.) and they can read/edit your project assets directly.

**Official docs:** https://aik.betide.studio/

## Before You Start

You need two things:

1. **The plugin is already in your project's `Plugins/` folder**
   - If not, ask your TA lead or check if `Plugins/AgentIntegrationKit/` exists
2. **Your SipherGateway API key**
   - Ask your team lead or check the team's key management channel
   - The key looks like: `clp_xxxxxxxxxxxx`

## Step 1 — Open Unreal and enable the plugin

1. Open your project in Unreal Engine
2. Go to **Edit → Plugins**
3. Search for **Agent Integration Kit**
4. Check **Enabled**
5. Restart the editor when prompted

## Step 2 — Open the Agent Chat panel

After restart, look for the **Agent Chat** tab (usually docked, or find it under **Window** menu).

You should see a chat interface with tabs: **Chat**, **Studio**, **Terminal**.

## Step 3 — Install an agent

1. In the Agent Chat panel, click **Settings** (gear icon or left sidebar)
2. Go to **Agents**
3. You'll see the **ACP Agent Registry** — a list of available AI agents
4. Click **Install** on **Claude Agent** (recommended first choice)
5. Wait for the green **Installed** badge to appear

Other agents you can install later if needed:

| Agent | What it is |
|-------|-----------|
| **Claude Agent** | Anthropic's Claude — good all-rounder |
| **Codex CLI** | OpenAI's coding agent |
| **Kimi CLI** | Moonshot AI's assistant |

## Step 4 — Add SipherGateway as your provider

This is the key step — it connects the agent to the studio's AI gateway.

1. Still in **Settings → Agents**, scroll down to **Enabled Providers**
2. Click **+ Add Custom Provider**
3. Fill in exactly:

| Field | Value |
|-------|-------|
| **Display Name** | `SipherGateway` |
| **Base URL** | `https://ai-gateway.atherlabs.com/v1/` |

4. Paste your **API key** in the API Key field and click **Save**
   - You'll see `····xxxx` with a green **configured** badge when saved
5. Check the box: **Auto-discover models from /models endpoint**
6. Drag **SipherGateway** to **position 1** in the provider list (above any other providers)

It should now show **ready** next to the provider name.

## Step 5 — Pick a model and test

1. Go back to the **Chat** tab
2. In the model dropdown (top of chat), you should see models from SipherGateway
3. Pick a model (e.g., `claude-sonnet-4` or whatever is available)
4. Type a test message like: `What project am I in? Take a screenshot.`
5. If the agent responds and can describe your project — you're done

## Step 6 — Choose or create a tool profile

Profiles control **what the AI agent is allowed to do** in your project. Think of them as permission presets.

Go to **Settings → Tool Profiles**.

### Built-in profiles

These are ready to use out of the box:

| Profile | Best for | What the agent can do |
|---------|----------|-----------------------|
| **Full Toolkit** | General use | Everything — all tools enabled |
| **Animation** | Animators | Anim Blueprints, IK rigs, Motion Matching, montages |
| **Blueprint & Gameplay** | Gameplay designers | Blueprint logic, components, gameplay systems |
| **Cinematics** | Cinematic artists | Level Sequences, cameras, animation playback |
| **VFX & Materials** | VFX artists | Niagara particles, Material graphs |

Pick the one closest to your role, or start with **Full Toolkit** if unsure.

### Creating your own profile

If the built-in profiles don't fit your workflow, create a custom one:

1. In **Settings → Tool Profiles**, click **Add Profile** (or duplicate an existing one)
2. Give it a name that describes your focus (e.g., `Environment Art`, `Lighting`, `Audio Design`)
3. Configure these fields:

| Field | What it does | Example |
|-------|-------------|---------|
| **Display Name** | Name shown in the profile list | `Environment Art` |
| **Description** | Short note for yourself or teammates | `Foliage, landscape, world partition tools` |
| **Enabled Tools** | Which tools the agent can use (empty = all) | Pick from the tool list |
| **Custom Instructions** | Extra context the agent always gets | `Focus on landscape and foliage workflows.` |

**Tips for custom instructions** — tell the agent:
- What domain you work in, so it gives relevant answers
- Naming conventions or folder structures your team follows
- Safety rules like "never delete foliage actors without asking first"

**Tips for tool selection:**
- Start with all tools enabled, then restrict if the agent touches things it shouldn't
- `read_asset` and `screenshot` are safe — they only read, never modify
- `execute_python` is powerful but broad — enable only if you need scripting

### Example: Environment Artist profile

```
Display Name:  Environment Art
Description:   Landscape, foliage, world partition, PCG workflows

Enabled Tools: execute_python, read_asset, edit_graph, read_logs, screenshot

Custom Instructions:
  You are working in an ENVIRONMENT ART context.
  - Focus on landscape editing, foliage placement, and world partition
  - Use PCG for procedural generation when appropriate
  - Never delete landscape components or foliage instances without asking
  - Prefer reading existing assets before suggesting changes
```

## Verify

- [ ] Plugin enabled (Edit → Plugins → Agent Integration Kit → checked)
- [ ] Agent Chat panel opens
- [ ] At least one agent shows green **Installed** badge
- [ ] SipherGateway shows **ready** in Enabled Providers
- [ ] Test message gets a response from the agent
- [ ] A profile is selected in Settings → Tool Profiles

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Can't find Agent Integration Kit in Plugins | Ask your TA lead — the plugin may not be in your project yet |
| Chat panel is blank | In Settings → General, try switching **Web UI Source** to **Hosted** |
| Agent doesn't respond | Check that SipherGateway shows **ready** and API key is **configured** |
| "No models found" in dropdown | Make sure **Auto-discover models** is checked for SipherGateway |
| Agent responds but can't touch assets | That's normal on first use — it may ask for tool permissions, click **Allow** |

## Help Us Improve This Skill

This plugin is new to the team — we're still learning the best ways to use it. Your experience matters.

**How to contribute:**
- Open an issue or PR on the [universal-ue-skills repo](https://github.com/sipherxyz/universal-ue-skills)
- Or message your TA lead with what you learned — we'll add it here

**Things we'd like to learn from the team:**
- Which **profiles** work best for different roles (lighting, env art, audio, etc.)
- Good **custom instructions** that make the agent more useful for your domain
- Common **gotchas** or mistakes to warn others about
- **Prompts** that reliably produce good results for specific tasks

Every tip you share helps the whole team work better with this tool.

## For TA / Tech Leads — Additional Setup Notes

If you're setting up the plugin for the first time in a new project:

### Plugin install

Copy the plugin folder into your project:

```bash
cp -R /path/to/AgentInt3ca4e6fee621V1 <ProjectRoot>/Plugins/AgentIntegrationKit
```

### Recommended default config

Create `Config/DefaultAgentIntegrationKit.ini` (commit this to version control):

```ini
[/Script/AgentIntegrationKit.ACPSettings]
bEnableAnalytics=False
bEnableCrashReporting=False
bUseBetideCredits=False
```

### Claude Code permissions

If team members use Claude Code alongside AIK, create `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": [
      "mcp__unreal-editor__execute_script"
    ]
  }
}
```

## Legacy Metadata

```yaml
skill: ue-setup-neostack-aik
invoke: /tooling:ue-setup-neostack-aik
type: setup
category: tooling
scope: project-root
```
