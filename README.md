# PTC Creo Elements/Direct Modeling – H871 Upgrade Tools

Version-controlled engineering workspace for custom tools targeting **PTC Creo Elements/Direct Modeling 18.1**.

## Current focus

**H871 Part Filter ver-02 – mapped machining-process and material selection UI.**

The ver-02 candidate preserves the user-confirmed ver-01 filter engine and Results Browser behavior. Its dialog replaces the two numeric density inputs with fixed choices:

- Machining Process: CNC=1, KH=2, CG=3, COVER=4.
- Material: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.

The selected numeric codes are still passed to the existing exact Density Instance + Density Base search. The corresponding code fields are display-only. The standard dialog currently places them in separate rows; a right-side same-row layout is deferred pending 18.1 UI verification. The default selection remains CNC + SUS304 (1/304).

**Important:** ver-02 source has been added on the feature branch but has not yet been loaded or functionally tested in Modeling 18.1. The confirmed ver-01 source remains unchanged on `main`.

## Repository map

- `PROJECT_CONTEXT.md` – current state, mappings, verification and next steps.
- `src/part-filter/H871_PART_FILTER.lsp` – confirmed ver-01 baseline.
- `src/part-filter/H871_PART_FILTER_VER_02.lsp` – ver-02 mapped-choice candidate.
- `src/part-filter/H871_PART_FILTER_DIAG.lsp` – preserved diagnostic baseline.
- `docs/TECHNICAL_DECISIONS.md` – active technical decisions.
- `docs/KNOWN_ISSUES.md` – unresolved or unverified items.
- `docs/LESSONS_LEARNED.md` – confirmed root causes and prevention rules.
- `docs/DEVELOPMENT_LOG.md` – milestone history and evidence.
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

## Deferred UI direction

Preserve the user's next-stage idea: each search should create an independent result session, with multiple result sets available as browser-like tabs (for example, a material/process tab named SUS304-CNC). Do not implement this as part of ver-02; first validate the mapped filter dialog.

## Start a new development session

Read `PROJECT_CONTEXT.md`, then the active decisions and known issues. Inspect the current Part Filter source before implementation.
