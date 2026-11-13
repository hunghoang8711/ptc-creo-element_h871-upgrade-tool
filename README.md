# PTC Creo Elements/Direct Modeling – H871 Upgrade Tools

A version-controlled workspace for developing, testing, documenting, and maintaining custom tools for **PTC Creo Elements/Direct Modeling 18.1**.

The repository is intended to be the engineering source of truth for:
- LISP utilities and related source code.
- Technical decisions and implementation constraints.
- Development history, test evidence, known issues, and lessons learned.
- Reusable test files and sample data that do not contain confidential customer information.

## Project status

**Documentation baseline initialized – 2026-11-13.**

The repository was empty when this baseline was created. No production LISP source files have been imported yet. Existing behavior described in the project context is recorded as historical requirements, not as verified source-code behavior.

## Repository map

```text
.
├── README.md
├── PROJECT_CONTEXT.md
├── docs/
│   ├── DEVELOPMENT_LOG.md
│   ├── LESSONS_LEARNED.md
│   ├── TECHNICAL_DECISIONS.md
│   ├── KNOWN_ISSUES.md
│   └── CHANGELOG.md
├── src/
│   └── README.md
└── tests/
    └── README.md
```

## Development principles

1. **Inspect before changing.** Read the relevant source, project context, decisions, known issues, and recent history before editing.
2. **Preserve working behavior.** Make focused changes; avoid unrelated refactoring.
3. **Test in the target application.** Static inspection or successful file loading is not equivalent to functional verification in Creo Elements/Direct Modeling.
4. **Report evidence honestly.** Every change must state what was tested, the environment, and what remains untested.
5. **Record reusable knowledge.** Document root causes and prevention steps when a defect is understood.
6. **Keep changes traceable.** Use clear commits and update the development log and changelog.
7. **Protect confidential data.** Do not commit customer-sensitive models, credentials, proprietary drawings, or personal data without explicit approval.

## Workflow for every new development session

1. Read this README and `PROJECT_CONTEXT.md`.
2. Read the relevant sections of `docs/TECHNICAL_DECISIONS.md`, `docs/KNOWN_ISSUES.md`, `docs/LESSONS_LEARNED.md`, and `docs/DEVELOPMENT_LOG.md`.
3. Inspect the current GitHub branch, recent commits, and relevant source/test files.
4. Confirm the intended behavior and identify regression risks.
5. Implement the smallest practical change.
6. Test and record exact results. If Creo is not available to the assistant, mark in-application testing as **not performed** and provide steps for the user to run.
7. Update the relevant documentation in the same change set.

## Status terminology

- **Implemented:** source changes have been made.
- **Static-checked:** source has been reviewed for syntax/structure, but not run in Creo.
- **Loaded in Creo:** the file loaded successfully in the target application.
- **Functionally tested:** the specified behavior was exercised in Creo with recorded test conditions.
- **Regression-tested:** relevant existing behavior was retested after the change.

Never describe a feature as functionally complete solely because code was written.

## Current known project scope

The first recorded tool requirement is a Part filter based on the exact **Instance** and **Base** values of Part properties such as Material and Density. See `PROJECT_CONTEXT.md` and `docs/TECHNICAL_DECISIONS.md`.

## Contributing / handover

When handing work to a new ChatGPT conversation or another developer, start with `PROJECT_CONTEXT.md`, then follow the workflow above. Keep this repository as the durable record; do not rely on chat history as the only source of technical decisions.
