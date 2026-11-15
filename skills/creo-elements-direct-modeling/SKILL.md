---
name: creo-elements-direct-modeling
description: Practical engineering skill for developing, debugging, documenting and validating tools for PTC Creo Elements/Direct Modeling 18.1, including Creo Lisp, Annotation sheets/frames, BOM layouts, drawing macros, Graphical Browser UI and Part Filter.
---

# Creo Elements/Direct Modeling 18.1 – Engineering Skill

## When to use this skill

Use this skill whenever the task involves:
- PTC Creo Elements/Direct Modeling 18.1 (not Creo Parametric).
- Creo/Modeling Lisp, Integration Kit calls, UI controls, Graphical Browser, selection or Assembly traversal.
- Annotation module sheets, frames, drawing layouts, BOM customization or legacy ME10 macros.
- Measurement, geometry inquiry, export, command registration, Ribbon/menu integration or automation in Modeling.
- Continuing any H871 tool or creating a new tool in this repository.

## Mandatory context loading

Before answering or changing code, read:
1. Repository `AI_START_HERE`: `docs/AI_START_HERE.md`.
2. `PROJECT_CONTEXT.md`.
3. This skill's references:
   - `references/01-platform-and-language.md`
   - `references/02-annotation-sheets-frames.md`
   - `references/03-bom-layouts-and-drawing-macros.md`
   - `references/04-part-filter-and-api-findings.md`
   - `references/05-debugging-and-validation.md`
   - `references/06-user-reference-inventory.md`
   - `references/07-development-workflow.md`
4. The relevant current source and `docs/KNOWN_ISSUES.md`.

Work on `main`. Do not create a branch per version. Store source in `src/<tool>/ver-XX/`; preserve user-confirmed versions.

## Core engineering rules

1. **Target exact product/version.** The environment is Creo Elements/Direct Modeling 18.1. Do not substitute Creo Parametric or assume a newer Elements/Direct release.
2. **Separate language families.** Distinguish Modeling Lisp/Integration Kit code from legacy ME10 command-language macros (`DEFINE`, `PARAMETER`, `LET`, `INQ`, `END_DEFINE`). Do not paste one language into the other's interpreter.
3. **Verify every API.** For each function, establish existence, exact argument order, keywords, return type, object type, module dependency and release compatibility. A later PTC manual is a research lead, not proof for 18.1.
4. **Use evidence labels.** Specified, source-observed, statically checked, documented in later release, loaded in 18.1, functionally tested in 18.1, user-confirmed, regression-tested.
5. **Do not invent test success.** The user loads and exercises LISP in Creo. State exactly what remains for runtime verification.
6. **Preserve working behavior.** Make one focused change at a time. Never replace a known-good version in place.
7. **Treat errors as evidence.** Record exact error, triggering action, affected file, root cause if proven, and the smallest confirmed fix.
8. **Respect source provenance.** User-provided legacy source includes CoCreate Software GmbH Confidential/copyright headers. Summarize its technical patterns in this public repository; do not copy the full proprietary source into public GitHub.

## Standard task workflow

### Before coding
- Restate the requested behavior and acceptance criteria.
- Fetch the current `main` source and relevant docs.
- Identify the last user-confirmed version and preserve it.
- Search this skill package for prior attempts, APIs, known errors and relevant reference files.
- Verify whether the request concerns Lisp, ME10 macro language, Annotation module, UICT or native browser controls.

### During implementation
- Prototype uncertain UI/API features in isolation.
- Prefer minimal diagnostic commands before building a full dialog.
- Keep data retrieval, transformation/filter logic, UI and selection hand-off separable.
- Avoid speculative Common Lisp functions and undocumented helper predicates.
- Preserve native Modeling selection/apply behavior when it is already confirmed.

### After implementation
- Run static checks (delimiter balance, quote/string checks, obvious symbol consistency) and review all changed calls.
- Do not treat static checks as a Creo runtime test.
- Update project context, knowledge base, API register, issues, lessons, development log and changelog as appropriate.
- Report changed paths and commit SHA.
- Give exact LOAD/command/test steps and expected result.
- Ask the user to report exact errors or confirm each acceptance test.

## Skill references

The reference files below are the accumulated project-specific knowledge. They deliberately distinguish confirmed facts from unverified ideas.
