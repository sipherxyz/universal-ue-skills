# Asset review rules

Use these rules only after reading the actual asset through an official MCP toolset. Each finding must name the inspected object, the observed state, its impact, and a concrete verification.

## Blueprints and gameplay

- Flag tick work only when the graph and measured profile data show it is on a hot path; do not estimate milliseconds from graph shape alone.
- Check event lifetime, latent actions, repeated casts, collection scans, and references in the context of the asset's execution path.
- For GAS and Gameplay Tags, verify the exact tag, query, activation condition, cost, cooldown, and references before proposing a change.

## AI behavior and State Trees

- Prove reachability from an entry state before calling a node or state orphaned.
- Inspect transition priority, abort behavior, blackboard or context data ownership, task configuration, and runtime evidence when available.
- Do not infer threading or a game freeze from a graph pattern alone.

## World, data, and animation assets

- For Data Tables, Level Instances, Data Layers, Montages, and animation graphs, compare the requested change with referencers and the live configured values.
- For streaming and world changes, use a loaded level or commandlet result to verify the outcome; a static asset read is insufficient.

## Rendering and Niagara

- Separate configuration review from profiling. Shader cost, particle count, GPU time, overdraw, and memory claims require captured runtime or profiling data.
- Record platform, map or scene, quality settings, capture method, and measurement before recommending a budget change.
