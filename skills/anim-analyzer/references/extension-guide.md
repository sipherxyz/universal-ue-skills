# Adding New Asset Types to anim-analyzer

Step-by-step guide for extending the analyzer to support new animation asset types.

## Overview

The anim-analyzer is designed for modular extension. Each asset type has:
1. Detection pattern (prefix + export class)
2. Analysis section (type-specific logic)
3. Issue patterns (what to flag)
4. Report template (output format)

---

## Step 1: Add Detection Pattern

In `SKILL.md` Step 2, add to the detection table:

```markdown
| `NEW_` | `NewAssetClass` | NewAssetType |
```

Example for ChooserTable:
```markdown
| `CHT_` | `ChooserTable` | ChooserTable |
```

---

## Step 2: Create Analysis Section

Add a new section `### 4.X NEW_ (NewType) Analysis` in SKILL.md:

```markdown
### 4.X NEW_ (NewType) Analysis

**Step 4.X.1: {Core Feature Detection}**

Scan name table for relevant patterns:

| Pattern | Category | Significance |
|---------|----------|--------------|
| `PatternA_*` | CategoryA | What it means |
| `PatternB_*` | CategoryB | What it means |

**Step 4.X.2: {Secondary Analysis}**

[Additional analysis specific to this type]

**Step 4.X.3: Quality Metrics**

| Metric | Weight | Scoring |
|--------|--------|---------|
| Metric 1 | X% | Scoring criteria |
| Metric 2 | Y% | Scoring criteria |
```

---

## Step 3: Define Issue Patterns

Add type-specific issues to Step 5:

```markdown
### {NewType} Issues

| Issue | Detection | Severity | Impact |
|-------|-----------|----------|--------|
| Issue 1 | Pattern | P0/P1/P2 | Description |
| Issue 2 | Pattern | P0/P1/P2 | Description |
```

---

## Step 4: Create Report Template

Create `templates/{prefix}-analysis-template.md`:

```markdown
# {AssetType} Analysis: {{asset_name}}

| Field | Value |
|-------|-------|
| **Analysis Date** | {{analysis_date}} |
| **Asset Path** | `{{asset_path}}` |
| **Engine Version** | {{engine_version}} |
| **File Size** | {{file_size}} |
| **Quality Score** | {{quality_score}}% {{status_badge}} |

---

## {Type}-Specific Analysis

### Section 1: {Core Feature}
{{section1_content}}

### Section 2: {Secondary Feature}
{{section2_content}}

---

## Issues Found
{{issues_list}}

---

## Recommendations
{{recommendations}}
```

---

## Step 5: Create Pattern Reference

Create `references/{prefix}-patterns.md`:

```markdown
# {AssetType} ({PREFIX}_) Analysis Patterns

## Detection Patterns

| Pattern | Category | Significance |
|---------|----------|--------------|
| ... | ... | ... |

## Quality Checklist

- [ ] Check 1
- [ ] Check 2
- [ ] Check 3

## Common Issues

### Issue Category 1
- Description
- Detection method
- Fix recommendation
```

---

## Step 6: Update Status Table

In SKILL.md header, update the status:

```markdown
| **NEW_** | NewType | ✅ Implemented | Analysis focus |
```

---

## Step 7: Test with Real Assets

Test against project assets:

```bash
# Find assets of new type
find "S:/Projects/s2/Content" -name "{PREFIX}_*.uasset" | head -5

# Run analysis
python scripts/parse_uasset.py "{asset}" --deep --format text
```

Verify:
- Detection works correctly
- Analysis produces useful output
- Scoring reflects actual quality
- Report is actionable
- No false positives in issues

---

## Example: Adding ChooserTable (CHT_) Support

### Detection
```markdown
| `CHT_` | `ChooserTable` | ChooserTable |
```

### Analysis Section
```markdown
### 4.2 CHT_ (ChooserTable) Analysis

**Step 4.2.1: Parameter Detection**

Scan for chooser parameters:
| Pattern | Category |
|---------|----------|
| `EGameplayTag*` | Tag parameter |
| `float*` | Numeric parameter |
| `bool*` | Boolean parameter |

**Step 4.2.2: Logic Complexity**

Count:
- Total branches
- Parameter count
- Referenced animations

**Step 4.2.3: Quality Metrics**

| Metric | Weight |
|--------|--------|
| Has fallback | 30% |
| All refs valid | 40% |
| No dead branches | 20% |
| Naming consistent | 10% |
```

### Issues
```markdown
### ChooserTable Issues

| Issue | Detection | Severity |
|-------|-----------|----------|
| Missing fallback | No default case | P1 |
| Dead branch | Unreachable condition | P2 |
| Invalid ref | Missing animation | P0 |
```

### Template
`templates/cht-analysis-template.md`

---

## Current Extension Roadmap

### Phase 2 Assets

| Type | Priority | Complexity | Status |
|------|----------|------------|--------|
| CHT_ | High | Medium | Planned |
| BS_ | High | Low | Planned |
| RTG_ | Medium | Low | Planned |

### Phase 3 Assets

| Type | Priority | Complexity | Status |
|------|----------|------------|--------|
| ABP_ | Low | High | Research needed |
| CR_ | Low | High | Research needed |

---

## Parser Considerations

When adding new types, check if `parse_uasset.py` needs updates:

**Name table analysis** (already works):
- All FNames are extracted
- Pattern matching works for any type

**Dependency analysis** (may need extension):
- Add categorization rules in `categorize_dependency()`
- Add patterns to `analyze_names()`

**Export class detection** (already works):
- Class names are in exports
- Just need to add pattern to SKILL.md

**Deep analysis limitations**:
- Cannot read binary property data
- Cannot parse graph structures
- Cannot extract timing information

For complex types (ABP_), may need UE Editor automation or custom tooling.
