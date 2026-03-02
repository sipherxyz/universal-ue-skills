# Combat-AI-Review Skill Test Cases

**Version:** 1.1
**Last Updated:** 2025-12-13
**Total Test Cases:** 12

## Test Case Overview

| ID | Test Case | Phase | Priority |
|----|-----------|-------|----------|
| TC-01 | Find existing BT .md file | Phase 0 | Critical |
| TC-02 | Find existing ST .md file | Phase 0 | Critical |
| TC-03 | Generate .md via commandlet (Editor NOT running) | Phase 0 | Critical |
| TC-04 | Handle missing .uasset (Error case) | Phase 0 | High |
| TC-05 | Generate .md when Editor IS running | Phase 0 | High |
| TC-06 | Verify _vis.md is NOT read for AI review | Phase 0/1 | Critical |
| TC-07 | Parse BT structure correctly | Phase 1 | Critical |
| TC-08 | Parse ST structure correctly | Phase 1 | Critical |
| TC-09 | Spawn parallel agents | Phase 2 | High |
| TC-10 | Debate protocol execution | Phase 3 | Medium |
| TC-11 | Consensus report generation | Phase 4 | Critical |
| TC-12 | Report saved to correct location | Phase 4 | High |

---

## Test Case Definitions

### TC-01: Find Existing BT .md File

**Phase:** 0 - Locate or Generate Combat AI Markdown
**Priority:** Critical
**Precondition:** BT markdown file already exists in `.blueprints/`

**Test Data:**
```
BT Path: /Game/S2/Core_Boss/s2_boss_baiwuchang/BT/BT_Boss_Baiwuchang_Phase_03
Expected .md: .blueprints/S2/Core_Boss/s2_boss_baiwuchang/BT/BT_Boss_Baiwuchang_Phase_03.md
```

**Steps:**
1. Request combat-ai-review for existing BT
2. Verify Phase 0 finds the existing .md file
3. Verify no generation step is triggered
4. Verify proceeds directly to Phase 1

**Expected Result:**
- [x] Existing .md file is found
- [x] No commandlet execution
- [x] Proceeds to Phase 1 parsing

**Verification Command:**
```bash
ls -la "D:/s2/.blueprints/S2/Core_Boss/s2_boss_baiwuchang/BT/BT_Boss_Baiwuchang_Phase_03.md"
```

---

### TC-02: Find Existing ST .md File

**Phase:** 0 - Locate or Generate Combat AI Markdown
**Priority:** Critical
**Precondition:** ST markdown file already exists in `.blueprints/`

**Test Data:**
```
ST Path: /Game/S2/Core_Ene/s2_ene_swordshield_01A_prototype/ST_ene_swordshield_combat
Expected .md: .blueprints/S2/Core_Ene/s2_ene_swordshield_01A_prototype/ST_ene_swordshield_combat.md
```

**Steps:**
1. Request combat-ai-review for existing ST
2. Verify Phase 0 finds the existing .md file
3. Verify no generation step is triggered
4. Verify proceeds directly to Phase 1

**Expected Result:**
- [x] Existing .md file is found
- [x] No commandlet execution
- [x] Proceeds to Phase 1 parsing

**Verification Command:**
```bash
ls -la "D:/s2/.blueprints/S2/Core_Ene/s2_ene_swordshield_01A_prototype/ST_ene_swordshield_combat.md"
```

---

### TC-03: Generate .md via Commandlet (Editor NOT Running)

**Phase:** 0 - Locate or Generate Combat AI Markdown
**Priority:** Critical
**Precondition:**
- Combat AI .uasset exists
- .md file does NOT exist
- Unreal Editor is NOT running

**Test Data:**
```
BT Path: /Game/S2/Core_Boss/s2_boss_tiger/BT/BT_s2_boss_tiger_phase_01
Output: .blueprints/S2/Core_Boss/s2_boss_tiger/BT/BT_s2_boss_tiger_phase_01.md
```

**Steps:**
1. Ensure .md file doesn't exist (delete if present)
2. Verify editor is not running
3. Request combat-ai-review for Combat AI without .md
4. Verify commandlet is triggered with correct parameters
5. Verify .md file is generated

**Expected Result:**
- [x] Commandlet runs with `-bt=...` or `-st=...` parameter
- [x] Only `.md` and `_vis.md` generated
- [x] File created in correct location with preserved path

**Verification Commands:**
```bash
# Delete existing .md to test generation
rm -f "D:/s2/.blueprints/S2/Core_Boss/s2_boss_tiger/BT/BT_s2_boss_tiger_phase_01.md"
rm -f "D:/s2/.blueprints/S2/Core_Boss/s2_boss_tiger/BT/BT_s2_boss_tiger_phase_01_vis.md"

# Verify .uasset exists
ls "D:/s2/Content/S2/Core_Boss/s2_boss_tiger/BT/BT_s2_boss_tiger_phase_01.uasset"
```

---

### TC-04: Handle Missing .uasset (Error Case)

**Phase:** 0 - Locate or Generate Combat AI Markdown
**Priority:** High
**Precondition:**
- Combat AI .uasset does NOT exist
- .md file does NOT exist

**Test Data:**
```
Path: /Game/S2/NonExistent/BT_DoesNotExist
```

**Steps:**
1. Request combat-ai-review for non-existent Combat AI
2. Verify error is reported
3. Verify no generation attempt

**Expected Result:**
- [x] Error message: "Combat AI asset does not exist. Cannot proceed with review."
- [x] No file generation attempted
- [x] Review process stops gracefully

---

### TC-05: Generate .md When Editor IS Running

**Phase:** 0 - Locate or Generate Combat AI Markdown
**Priority:** High
**Precondition:**
- Combat AI .uasset exists
- .md file does NOT exist
- Unreal Editor IS running with S2.uproject

**Steps:**
1. Ensure Unreal Editor is running with S2.uproject
2. Delete existing .md file if present
3. Use toolbar button or console command
4. Verify .md file is generated

**Expected Result:**
- [x] Generation succeeds while editor is running
- [x] Only `.md` and `_vis.md` generated
- [x] File saved to correct location

**Note:** This test case requires manual verification when editor is running.

---

### TC-06: Verify _vis.md is NOT Read for AI Review

**Phase:** 0/1 - Critical Validation
**Priority:** Critical
**Precondition:** Both `.md` and `_vis.md` files exist

**Steps:**
1. Verify both files exist
2. Start combat-ai-review process
3. Monitor which files are read
4. Verify only `.md` file content is used for Phase 1 parsing

**Expected Result:**
- [x] Only `BT_*.md` or `ST_*.md` file is read
- [x] `_vis.md` file is NOT read
- [x] Parsed structure comes from raw `.md` file only

---

### TC-07: Parse BT Structure Correctly

**Phase:** 1 - Parse Combat AI Structure
**Priority:** Critical
**Precondition:** Valid BT .md file exists

**Test Data:**
```
BT: BT_Boss_Baiwuchang_Phase_03
Expected Metrics:
  - Total Nodes: > 50
  - Blackboard Keys: 15
  - Asset Class: BehaviorTree
```

**Steps:**
1. Read the .md file
2. Extract key metrics
3. Verify structure is parsed correctly

**Expected Result:**
- [x] Asset name extracted correctly
- [x] Blackboard keys (15) parsed
- [x] Node structure parsed
- [x] Decorators identified
- [x] Tasks identified

---

### TC-08: Parse ST Structure Correctly

**Phase:** 1 - Parse Combat AI Structure
**Priority:** Critical
**Precondition:** Valid ST .md file exists

**Test Data:**
```
ST: ST_ene_swordshield_combat
Expected:
  - Asset Class: StateTree
  - States/Transitions parsed
  - Parameters identified
```

**Steps:**
1. Read the .md file
2. Extract key metrics
3. Verify State Tree structure is parsed correctly

**Expected Result:**
- [x] Asset name extracted correctly
- [x] Schema/Parameters parsed
- [x] States identified
- [x] Transitions identified
- [x] Tasks/Conditions identified

---

### TC-09: Spawn Parallel Agents

**Phase:** 2 - Parallel Agent Analysis
**Priority:** High
**Precondition:** Phase 1 completed with parsed Combat AI structure

**Test Data:**
```
Agents to spawn:
  1. combat-engineer (GAS, performance, scalability)
  2. combat-designer (feel, balance, readability)
  3. qa-manager (edge cases, test coverage, bugs)
```

**Steps:**
1. Complete Phase 1 parsing
2. Spawn 3 agents in PARALLEL (single message with multiple Task calls)
3. Wait for all agents to complete
4. Collect responses

**Expected Result:**
- [x] All 3 agents spawned simultaneously
- [x] Each agent provides independent analysis
- [x] Each agent returns top 5 concerns with severity ratings
- [x] No agent blocks another

---

### TC-10: Debate Protocol Execution

**Phase:** 3 - Debate Protocol
**Priority:** Medium
**Precondition:** All 3 agents completed Phase 2 analysis

**Test Data:**
```
Input: Top 5 concerns from each agent (15 total issues)
Expected: Response matrix with AGREE/CHALLENGE/ADD CONTEXT
```

**Steps:**
1. Collect all agent findings
2. Present each agent's top 5 concerns
3. Generate response matrix
4. Identify challenges and resolutions
5. Flag unresolved issues for human review

**Expected Result:**
- [x] Response matrix generated
- [x] Challenges include reasoning
- [x] Consensus reached OR issue flagged for human review
- [x] Context additions incorporated

---

### TC-11: Consensus Report Generation

**Phase:** 4 - Consensus Report Synthesis
**Priority:** Critical
**Precondition:** Debate completed

**Test Data:**
```
Expected Report Sections:
  - Executive Summary
  - Combat Designer Feel Assessment
  - Consensus Findings (Critical/High/Medium/Low)
  - Action Items by Owner
  - Test Plan
```

**Steps:**
1. Complete debate phase
2. Generate consensus report
3. Verify all required sections present
4. Verify severity counts are accurate

**Expected Result:**
- [x] Executive Summary with severity counts
- [x] Overall Combat AI Health percentage
- [x] Combat Readiness percentage
- [x] Console Cert Status
- [x] Action items assigned by role
- [x] Test plan included

---

### TC-12: Report Saved to Correct Location

**Phase:** 4 - Final Output
**Priority:** High
**Precondition:** Consensus report generated

**Test Data:**
```
Expected Location: claude-agents/reports/combat-ai-reviews/{asset_name}_review_{date}.md
Example: claude-agents/reports/combat-ai-reviews/BT_Boss_Baiwuchang_Phase_03_review_2025-12-13.md
```

**Steps:**
1. Complete combat-ai-review process
2. Verify report is saved to correct directory
3. Verify filename format is correct
4. Verify file is not empty

**Expected Result:**
- [x] Report saved to `claude-agents/reports/combat-ai-reviews/`
- [x] Filename includes asset name and date
- [x] File contains full report content
- [x] File size > 5KB (substantial content)

**Verification Commands:**
```bash
# Check directory exists
ls -la "D:/s2/claude-agents/reports/combat-ai-reviews/"

# Check for recent reports
ls -la "D:/s2/claude-agents/reports/combat-ai-reviews/" | grep "$(date +%Y-%m-%d)"
```

---

## Test Summary Template

After running tests, update this summary:

| TC | Status | Notes |
|----|--------|-------|
| TC-01 | [ ] PASS / [ ] FAIL | |
| TC-02 | [ ] PASS / [ ] FAIL | |
| TC-03 | [ ] PASS / [ ] FAIL | |
| TC-04 | [ ] PASS / [ ] FAIL | |
| TC-05 | [ ] PASS / [ ] FAIL | (Manual - Editor required) |
| TC-06 | [ ] PASS / [ ] FAIL | |
| TC-07 | [ ] PASS / [ ] FAIL | |
| TC-08 | [ ] PASS / [ ] FAIL | |
| TC-09 | [ ] PASS / [ ] FAIL | |
| TC-10 | [ ] PASS / [ ] FAIL | |
| TC-11 | [ ] PASS / [ ] FAIL | |
| TC-12 | [ ] PASS / [ ] FAIL | |

**Overall Status:** [ ] ALL PASS / [ ] FAILURES DETECTED
