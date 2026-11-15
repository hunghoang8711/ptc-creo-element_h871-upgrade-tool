# AI Start Here – H871 Creo Tools

This file is the entry point for any new ChatGPT conversation, assistant, or developer continuing this repository.

## Mandatory first steps

1. Confirm the repository is `hunghoang8711/ptc-creo-element_h871-upgrade-tool` and work on `main`.
2. Read `PROJECT_CONTEXT.md`.
3. Read `docs/ENGINEERING_KNOWLEDGE_BASE.md`.
4. Read `docs/TECHNICAL_DECISIONS.md`, `docs/KNOWN_ISSUES.md` and `docs/LESSONS_LEARNED.md`.
5. Inspect the exact current LISP version and any related source before editing.
6. Check the latest Git state and file contents; never assume a previous chat's file paths or branch state are still current.

## Shared workflow rules

- `main` is the single shared branch for source, decisions and engineering knowledge. Do not create a branch for each version.
- Store separate LISP versions in `src/<tool>/ver-XX/`. Never overwrite a user-confirmed version.
- Keep root-level legacy source paths only when needed for backward-compatible LOAD paths; state which file is canonical.
- Every meaningful discovery must be written to the relevant shared docs on main, not left only in chat history.
- Preserve working behavior. Make one focused change at a time.
- Do not invent Creo APIs. Check exact function names, signatures, argument keywords, return values and object types for Modeling 18.1.
- Documentation from later PTC releases is research guidance only, not proof of 18.1 compatibility.
- Keep customer CAD, proprietary drawings, credentials and personal information out of this public repository.

## Required status labels

Use precise labels:
- Specified
- Implemented
- Static-checked
- Loaded in Creo 18.1
- Functionally tested in Creo 18.1
- User-confirmed
- Regression-tested

Never promote a feature to runtime-tested without an explicit test result from the user or a verified target environment.

## Before making a change

1. State the intended behavior and identify the smallest affected source.
2. Identify the last user-confirmed version that must remain untouched.
3. Check relevant known issues and lessons to avoid repeating failed approaches.
4. Make a small change and run available static checks.
5. Update project context, knowledge base, decisions/issues/lessons, development log and changelog as applicable.
6. Report exact changed paths, commit(s), static-check result and what remains for the user to test.

## Current Part Filter handover

- ver-01 is the user-confirmed numeric Density-pair baseline.
- ver-02 is the mapped Machining Process + Material convention dialog; user reported very good results.
- ver-03 is specified but has no new implementation yet.
- The correct ver-03 UI is one separate Results Browser window with its own internal horizontal tabs/pages. It is not multiple Graphical Browser windows and not Creo Browser Bar tabs.
- Read TD-008 in `docs/TECHNICAL_DECISIONS.md` before working on multi-search behavior.

## New tool development

For a new tool in this repository:
1. Create a dedicated `src/<tool-name>/` folder and versioned source folders.
2. Add a short tool specification and a test plan before coding.
3. Reuse only APIs/lessons that are relevant and verified for Modeling 18.1.
4. Add newly discovered reusable functions, compatibility notes and failure patterns to the Engineering Knowledge Base.
5. Keep tool-specific implementation details in its own context/README; keep cross-tool engineering rules in the shared knowledge base.
