# Trusted Source Domains

## Priority Levels

- **P0**: Official/authoritative - always prefer
- **P1**: High quality community - reliable
- **P2**: General community - verify before citing

---

## Dev Sources

### P0 - Official
| Domain | Type | Best For |
|--------|------|----------|
| docs.unrealengine.com | Docs | API, systems, tutorials |
| dev.epicgames.com | Blog | Best practices, deep dives |
| github.com/EpicGames | Code | Engine source, samples |

### P1 - High Quality
| Domain | Type | Best For |
|--------|------|----------|
| forums.unrealengine.com | Forum | Problem solving, edge cases |
| gdcvault.com | Talks | Architecture, post-mortems |
| gamedeveloper.com | Articles | Industry techniques |

### P2 - Community
| Domain | Type | Best For |
|--------|------|----------|
| zhihu.com | Q&A | CN developer insights |
| stackoverflow.com | Q&A | Quick code solutions |
| reddit.com/r/unrealengine | Forum | Community solutions |

---

## Game Design Sources

### P0 - Authoritative
| Domain | Type | Best For |
|--------|------|----------|
| wiki.fextralife.com | Wiki | Soulslike mechanics deep dives |
| gamedeveloper.com | Articles | Design methodology |
| gdcvault.com | Talks | Design post-mortems |

### P1 - High Quality
| Domain | Type | Best For |
|--------|------|----------|
| youtube.com (GDC/GMTK) | Video | Visual explanations |
| gdkeys.com | Database | Game design patterns |
| sensortower.com | Analytics | Market data |

### P2 - Community
| Domain | Type | Best For |
|--------|------|----------|
| reddit.com/r/gamedesign | Forum | Community feedback |
| fab.com | Assets | Reference implementations |

---

## Art/Visual Sources

### P0 - Professional
| Domain | Type | Best For |
|--------|------|----------|
| artstation.com | Portfolio | High quality references |
| 80.lv | Articles | Breakdowns, tutorials |

### P1 - High Quality
| Domain | Type | Best For |
|--------|------|----------|
| pinterest.com | Collection | Mood boards, quick refs |
| polycount.com | Forum | Technical art discussion |
| realtimevfx.com | Forum | VFX techniques |

### P2 - Community
| Domain | Type | Best For |
|--------|------|----------|
| reddit.com/r/unrealengine | Forum | VFX/shader sharing |
| cgcookie.com | Tutorials | Learning resources |

---

## Domain Detection Keywords

```yaml
dev_keywords:
  - implement, architecture, performance, code, system
  - GAS, plugin, C++, blueprint, optimization
  - memory, thread, tick, async, subsystem
  - component, actor, module, build

game_design_keywords:
  - gameplay, feel, experience, combat, boss
  - design, loop, mechanic, balance, pacing
  - difficulty, progression, player, enemy
  - parry, dodge, combo, spell, ability

art_keywords:
  - style, mood, vfx, visual, color
  - aesthetic, animation, shader, material
  - lighting, atmosphere, silhouette, palette
  - niagara, particle, effect, toon, stylized
```

---

## Search Query Patterns

```bash
# Dev search
site:docs.unrealengine.com {query}
site:github.com/EpicGames {query}

# Game Design search
site:wiki.fextralife.com {query}
site:gamedeveloper.com {query}

# Art search
site:artstation.com {query}
site:80.lv {query}
```
