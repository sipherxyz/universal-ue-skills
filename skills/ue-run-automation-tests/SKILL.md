---
name: ue-run-automation-tests
description: Run and interpret Unreal Automation Tests locally or in headless continuous integration.
---

# Run Unreal Automation Tests

Use this skill to run an existing test filter or validate a focused code change. Discover the project, engine, and available test names before choosing a filter.

For a UE5.8 Sentry fix, record the engine/project revisions and treat the test as a frozen proof harness: the RED and GREEN runs must use the same filter, map/assets, configuration, flags, and observation window, with only the authorized source change different.

## Operating order

1. Identify the `.uproject`, matching editor binary, platform, and test filter from project documentation or a test-list run.
2. Start with the narrowest affected test or namespace. Run the complete suite only when requested or when the focused result requires broader coverage.
3. For unattended execution, use a deterministic map/environment and CI-safe flags supported by the project. For process-local crash/ensure signatures, start a fresh process and log and record a zero baseline before the trigger.
4. Read the Automation summary and the first failing assertion or setup error. Do not report success from process exit status alone.
5. Preserve the command, log path, test count, pass/fail/skip totals, target signature count, process health, and artifacts needed to reproduce a failure.

## Headless command shape

```text
<UnrealEditor-Cmd> <Project>.uproject \
  -ExecCmds="Automation RunTests <Filter>; Quit" \
  -unattended -nop4 -nosplash -NullRHI -NoSound -log
```

Adjust flags to the platform and project: rendering, input, networking, or editor-only tests may require a real RHI, a map, devices, or a configured test environment. Do not silently add a project-specific commandlet or test category.

## Failure triage

| Failure evidence | Next check |
| --- | --- |
| Test not found | discovered name/filter and compiled test module |
| Setup or map failure | test world, required assets, plugin/module loading |
| Assertion | first failed expectation and input data |
| Timeout | task completion, latent commands, external services |
| Editor crash | crash report and matching symbols; use `ue-crash-callstack-linker` |

If a fixture, map, asset, compile gate, or feature prerequisite fails, classify the attempt as `blocked-invalid-red`, not RED. An Editor/commandlet pass is not packaged-client proof; retain the packaged gate when the Sentry event came from a packaged build.

## Completion

Report the exact filter, environment, engine/project revisions, command, RED/GREEN comparison, totals, elapsed time, process health, and artifact/log path. A test run is complete only when its result summary and proof boundary are present.
