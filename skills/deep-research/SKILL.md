---
name: deep-research
description: Deep web research from vague input, outputs professional reports with verified sources
---

# Deep Research Skill

## ⛔ CRITICAL RULES - READ FIRST

```
╔══════════════════════════════════════════════════════════════════╗
║  NEVER ASK USER FOR PERMISSION TO ACCESS WEBSITES                ║
║  NEVER ASK USER TO CONFIRM SEARCH QUERIES                        ║
║  NEVER ASK USER ABOUT BLOCKED/FAILED FETCHES                     ║
║  NEVER PROMPT USER FOR CLARIFICATION ON ERRORS                   ║
║                                                                  ║
║  → Just DO the research silently                                 ║
║  → Skip failed sources WITHOUT mentioning them                   ║
║  → Auto-proceed on ALL ambiguity                                 ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## What This Skill Does

Transform vague keywords into comprehensive research reports with verified sources and **inline hyperlinks on every fact**.

## Input

Accepts anything:
- `GAS performance` → researches GAS optimization
- `boss feel juicy` → researches game feel
- `niagra vfx` (misspelled) → auto-corrects to Niagara VFX
- `soulslike stamina ue5` → researches all

## Output

```
claude-agents/reports/deep-research/
├── {topic}-research.md          # Markdown report
├── {topic}-research.html        # Visual HTML report
└── {topic}-assets/              # Downloaded images
    ├── img-001.png
    ├── img-002.jpg
    └── ...
```

---

## Workflow

### Phase 1: Parse Input (NO USER PROMPTS)

1. Extract keywords
2. Auto-detect domain(s):
   - **Dev**: implement, architecture, performance, code, system, GAS, plugin, C++
   - **Game Design**: gameplay, feel, experience, combat, boss, design, loop, mechanic
   - **Art**: style, mood, vfx, visual, color, aesthetic, animation, shader
3. If unclear → **default to ALL domains, do NOT ask user**

### Phase 2: Launch 5 Parallel Agents

```
┌────────────────────────────────────────────────────────────┐
│ LAUNCH ALL 5 SIMULTANEOUSLY - NO SEQUENTIAL WAITS          │
├────────────────────────────────────────────────────────────┤
│ Agent 1: WebSearch Dev sites (docs, forums)                │
│ Agent 2: WebSearch Game Design sites (wikis, GDC)          │
│ Agent 3: WebSearch Art sites (ArtStation, Pinterest)       │
│ Agent 4: WebSearch YouTube videos & GDC talks              │
│ Agent 5: WebSearch images & visual references              │
└────────────────────────────────────────────────────────────┘
```

**Site Filters:**

| Domain | Sites |
|--------|-------|
| Dev | docs.unrealengine.com, dev.epicgames.com, github.com, forums.unrealengine.com, gdcvault.com |
| Game Design | wiki.fextralife.com, gamedeveloper.com, youtube.com, reddit.com/r/gamedesign |
| Art | artstation.com, pinterest.com, 80.lv, polycount.com, realtimevfx.com |

### Phase 3: Fetch Content (SILENT FAILURES)

Use WebFetch on search results.

**ON ANY FAILURE:**
```
❌ Auth required    → skip silently, next source
❌ 404 error        → skip silently, next source
❌ Timeout          → skip silently, next source
❌ Rate limited     → skip silently, next source
❌ Blocked          → skip silently, next source

✅ Success          → extract content, continue
```

**NEVER tell user about skipped sources. Just use what works.**

### Phase 4: Download Images & Embed Videos

**IMAGES - Download and attach locally:**

```bash
# Create assets folder
mkdir -p claude-agents/reports/deep-research/{topic}-assets

# Download images using curl (silent, no prompts)
curl -sL "https://example.com/image.png" -o "{topic}-assets/img-001.png"
```

**Image download rules:**
- Download max 10 images per report
- Prefer PNG/JPG under 2MB
- Skip if download fails (silent)
- Always credit source below image

### Phase 5: Write Report with Inline Links

**MANDATORY: Every fact has inline hyperlink.**

```markdown
✅ CORRECT:
According to [Gamedeveloper.com](https://gamedeveloper.com/article),
boss telegraphs need minimum 340ms reaction window.

❌ WRONG:
Boss telegraphs need minimum 340ms reaction window.
(Source listed at bottom)
```

### Phase 6: Save Reports

1. Write markdown to: `claude-agents/reports/deep-research/{topic}-research.md`
2. Generate HTML report: `claude-agents/reports/deep-research/{topic}-research.html`

---

## Report Structure

```markdown
# Research: {Topic}

**Generated**: {date}
**Domain**: {detected domains}
**Query**: "{user input}"

---

## Executive Summary
{2-3 sentences with [inline](url) [links](url)}

## Key Findings
- Finding 1 - [Source](url)
- Finding 2 - [Source](url)

## {Domain} Details
### {Concept}
{Explanation with [inline](url) citations}

---

## Visual References

### Images (Downloaded)
| Preview | Description | Source |
|---------|-------------|--------|
| ![img](./{topic}-assets/img-001.png) | {description} | [ArtStation](url) |

### Video Tutorials & Talks
[![GDC Talk](https://img.youtube.com/vi/VIDEO_ID/mqdefault.jpg)](https://youtube.com/watch?v=VIDEO_ID)
> **[Title of Video](https://youtube.com/watch?v=VIDEO_ID)** - {brief description}

---

## Sources
1. [{Title}]({url}) - {site}
2. [{Title}]({url}) - {site}
```

---

## Error Handling - ALWAYS SILENT

| Situation | Action |
|-----------|--------|
| Ambiguous query | Research all domains, NO prompt |
| No results | Broaden search automatically |
| WebFetch blocked | Skip source, use others |
| Auth required | Skip source, NO prompt |
| Rate limit | Continue with available data |
| Any error | Log internally, continue silently |

---

## Success Criteria

- [ ] Zero user prompts during research
- [ ] 5 parallel agents launched
- [ ] 10+ sources with working hyperlinks
- [ ] Every fact has inline citation
- [ ] 3-10 images downloaded to `{topic}-assets/`
- [ ] 2-5 videos embedded with thumbnails
- [ ] Markdown report saved to correct path
- [ ] HTML report generated with embedded media
- [ ] Completes in <90 seconds

## Legacy Metadata

```yaml
skill: deep-research
```
