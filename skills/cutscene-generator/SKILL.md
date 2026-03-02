---
name: cutscene-generator
description: Generate JSON cutscene specifications for SipherCutsceneTools from natural language
---

# Cutscene Generator

Generate JSON cutscene specifications for SipherCutsceneTools from natural language descriptions.

## Usage

Describe the cutscene you want to create, and this skill will:
1. Recommend an appropriate template
2. Generate a complete JSON specification
3. Include camera work, timing, and events
4. Validate the output

## Examples

- "Create a boss introduction for the Nine-Tailed Fox"
- "Make a player death cutscene with slow-motion"
- "Design a phase transition where the boss transforms"
- "Generate a dialogue cutscene between player and NPC"

## Output

The skill outputs a valid JSON specification that can be:
- Saved to a `.json` file in `Content/S2/Cutscenes/Specs/`
- Imported into a `UCutsceneSpecAsset` in the editor
- Processed by `USipherCutsceneGeneratorCommandlet`

## Legacy Metadata

```yaml
invoke: /game-design:cutscene-generator
```
