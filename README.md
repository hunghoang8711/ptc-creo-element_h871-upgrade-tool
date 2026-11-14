# PTC Creo Elements/Direct Modeling – H871 Upgrade Tools

Version-controlled engineering workspace for custom tools targeting **PTC Creo Elements/Direct Modeling 18.1**.

## Current focus

**H871 Part Filter – baseline restored and ready for the next feature definition (2026-11-14).**

The current user-confirmed workflow is:
- Select an Assembly and search using an exact Density Instance + Density Base pair.
- View matching Parts in the dedicated Graphical Browser results table.
- Select individual result rows or use Select All.
- Use the native Apply action to transfer the selected Part(s) to Creo Modeling selection.

The user has confirmed that the results list, Select All control, individual row selection, and Apply workflow work in Creo Elements/Direct Modeling 18.1. Do not regress this baseline.

## Repository map

- `PROJECT_CONTEXT.md` – concise current state and handover notes.
- `src/part-filter/` – Part Filter source and preserved diagnostic baseline.
- `docs/TECHNICAL_DECISIONS.md` – active technical decisions and compatibility constraints.
- `docs/KNOWN_ISSUES.md` – only unresolved or unverified items.
- `docs/LESSONS_LEARNED.md` – confirmed root causes and prevention rules.
- `docs/DEVELOPMENT_LOG.md` – concise milestone history and verification evidence.
- `docs/CHANGELOG.md` – user-visible/source-level change summary.
- `tests/` – repeatable tests and sanitized fixtures.

## Development rules

1. Inspect the current source, repository state, and relevant documentation before changing code.
2. Preserve the working Results Browser, row-selection, Select All, and native Apply behavior.
3. Make the smallest focused change; avoid unrelated UI or architecture rewrites.
4. Target Modeling 18.1. Do not assume Creo Parametric APIs or later Elements/Direct APIs are compatible.
5. Separate static checks, successful loading, functional tests, and regression tests.
6. Record exact user-observed runtime results; never infer runtime success from source code alone.
7. Update the relevant documentation with every meaningful implementation change.
8. Keep customer models, proprietary drawings, credentials, and personal data out of this public repository.

## Verification terminology

- **Implemented** – source has been changed.
- **Static-checked** – source structure/syntax has been inspected; not proof of Creo compatibility.
- **Loaded in Creo** – file loaded in the target application.
- **Functionally tested** – behavior was exercised in Creo.
- **User-confirmed** – the user reported the behavior working in their target environment.
- **Regression-tested** – existing confirmed behavior was retested after a change.

## Start a new development session

Read `PROJECT_CONTEXT.md`, then the active decisions and known issues. Inspect the latest Part Filter source before implementation. Use the development log only for milestone history; detailed abandoned UI experiments have been condensed into the lessons and constraints that matter.
