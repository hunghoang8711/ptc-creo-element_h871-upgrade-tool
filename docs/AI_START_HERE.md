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
- ver-02 is the user-confirmed mapped Machining Process + Material filter; its visible Results Graphical Browser owns row selection and native Apply. Do not alter it.
- ver-03 UICT Results pages, result tables and page-local selection are user-confirmed in project testing; UICT-to-Modeling Apply is unresolved. The hidden Graphical Browser bridge, GET_SELECTION experiments and direct UICT callback hand-off failed.
- A Search candidate produced Modeling fatal exception 0xC00000FD; the iterative traversal candidate did not fix it and was reverted. Search root cause is unresolved. Use a disposable model and inspect the trace before changing the collector.
- ver-04 diagnostic: `src/part-filter/ver-04/diagnostics/H871_PF_V04_SINGLE_BROWSER_PAGES_DIAG.lsp`. User confirmed native Browser opens and Close Results restores ver-03 UICT. The updated source installs a persistent `Open Native Results` button in UICT so the Browser can be reopened without retyping the command; Previous/Next now write navigation trace markers. Static-checked only: button placement/callback, repeat close/reopen, user-operated page switching and actual viewport Apply still require Modeling 18.1 testing. This is not yet a horizontal-tab UI.
- Keep ver-01/ver-02 untouched. Do not retry Browser reparenting or hidden Browser Apply without a new, proven cause.
- Read TD-008, TD-010, TD-011, TD-012, KI-012, KI-013 and KI-014 before changing multi-search, Results navigation or Apply architecture.

## New tool development

For a new tool in this repository:
1. Create a dedicated `src/<tool-name>/` folder and versioned source folders.
2. Add a short tool specification and a test plan before coding.
3. Reuse only APIs/lessons that are relevant and verified for Modeling 18.1.
4. Add newly discovered reusable functions, compatibility notes and failure patterns to the Engineering Knowledge Base.
5. Keep tool-specific implementation details in its own context/README; keep cross-tool engineering rules in the shared knowledge base.


## Required skill package for all Creo work

Before any Creo task (including a new tool), also read [`skills/creo-elements-direct-modeling/SKILL.md`](../skills/creo-elements-direct-modeling/SKILL.md) and its relevant references. This package includes knowledge recovered from prior chats and user-provided Annotation macro files, not only the current Part Filter thread.

Use [API_VERIFICATION_REGISTER](API_VERIFICATION_REGISTER.md) to check symbol evidence and [USER_REFERENCE_INVENTORY](USER_REFERENCE_INVENTORY.md) to identify the historical source material. Do not confuse Lisp with Annotation/ME10 command language. Do not copy full CoCreate confidential legacy sources into this public repository.

## Current direction – Part Filter single-window implementation (2026-11-16)

The user's final product requirement is unchanged: one Results window only, with direct native Part selection/Apply as in ver-02 and multiple Density-pair pages as in ver-03. ver-04 remains a diagnostic experiment only; its UICT launcher/return workflow is not the product architecture.

A new self-contained candidate has been added:
- Canonical candidate: `src/part-filter/ver-05/H871_PART_FILTER_VER_05.lsp`
- It owns the numeric Density search, page registry, one Browser Tree, one visible Graphical Browser, row selection, page navigation and native Apply.
- It no longer reads ver-03 UICT page globals, opens/restores a UICT Results shell, installs an Open Native Results button, or uses a hidden Browser bridge.
- Search/mapping behavior follows ver-02; exact Density Instance + Base pair and /1000 normalization are preserved.
- Each pair has one page; same-pair search refreshes that page; a no-match leaves existing pages unchanged.
- Page navigation is currently Previous/Next plus a Results Pages popup. A horizontal tab strip is still not implemented.
- The Browser is rebuilt under the same named Browser/Tree after each successful search so the active Browser contains all current page roots. This is one Results Browser, not multiple simultaneous Results windows.

**Status:** source added and static-checked only. Not loaded or functionally tested in Modeling 18.1. Native Apply must be proven by selecting one/multiple rows and confirming the actual 3D viewport selection. Test only on a disposable model copy. Preserve ver-01/ver-02/ver-03 and the Density mapping. Do not treat ver-05 as user-confirmed until runtime testing.

### ver-05 horizontal page-button strip revision

The ver-05 Browser now builds a dynamic Graphical Browser `:modeMenu` row with one page button per Density pair and sets `:modeMenuInitialButton` to the active page. This is intended to provide horizontal, in-window page switching while preserving one Browser's native Apply. Previous/Next helper functions remain in source as diagnostic fallbacks; the current toolbar button row is Select All/Clear Selection. PTC's detailed modeMenu reference is from a later release, so Modeling 18.1 compatibility and mutual-exclusion behavior must be tested before confirmation.



### ver-05 page-isolation correction (2026-11-16)

A source review after the first ver-05 handoff found a critical page-switch defect: h871-pf-v05-activate-page changed the table root without first clearing the previous table root. Graphical Browser tables can retain multiple table roots; this risks showing rows from multiple Density pages at once and makes Select All/native Apply page scope unsafe.

The ver-05 activation path now buffers redraw, clears the current selection and all table roots, sets exactly the requested page root, resumes redraw, and traces the resulting table-root count. This is based on the documented Graphical Browser command sequence (:BUFFER-DISPLAY, :CLEAR-TABLE-ROOTS, :CHANGE-TABLE-ROOT) in the PTC 20.6 reference; Modeling 18.1 runtime compatibility still requires testing.

Do not call ver-05 complete: page strip rendering/callbacks, page isolation, page-local selection restore and actual viewport Apply remain unverified in Modeling 18.1. The horizontal modeMenu is a candidate page-button strip, not a confirmed native tab control. Keep one visible Results Browser; no UICT launcher, hidden Browser bridge or second Results window.


### ver-05 fail-safe page activation refinement

The page-root correction now checks the return from :clear-table-roots before attempting :change-table-root. If the old roots cannot be cleared or the requested root cannot be set, page activation stops rather than risking mixed-page selection. The :number-of-table-roots trace query is diagnostic-only and wrapped with ignore-errors so an unavailable query cannot interrupt page activation. Latest source commit: 30d679156b879339cdefd1a922649feb4a937bd4. Runtime testing in Modeling 18.1 is still required.
