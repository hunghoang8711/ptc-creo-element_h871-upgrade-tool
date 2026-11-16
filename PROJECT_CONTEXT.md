# H871 Upgrade Tools – Project Context

**Last consolidated:** 2026-11-16  
**Target application:** PTC Creo Elements/Direct Modeling 18.1  
**Shared branch:** `main`  
**Current focus:** ver-03 internal-tab Results UI prototype; runtime compatibility and Apply hand-off validation pending.

## 1. Product goal

Build reliable, reusable LISP tools for Creo Elements/Direct Modeling 18.1. The repository is both the source-code archive and the engineering knowledge base: requirements, API findings, failure causes, compatibility notes, test procedures and lessons must remain available across chats and future tools.

## 2. Part Filter version status

| Version | Purpose | Status |
|---|---|---|
| ver-01 | Numeric Density Instance + Base filter with standalone Graphical Browser | User-confirmed working baseline |
| ver-02 | Machining Process + Material convention selectors mapped to Density values | Implemented; user reported very good results |
| ver-03 | One standalone Results window with internal horizontal tabs | UICT prototype implemented; static-checked; 18.1 runtime not yet tested; Apply hand-off pending |

Canonical version folders:
- `src/part-filter/ver-01/H871_PART_FILTER_VER_01.lsp`
- `src/part-filter/ver-02/H871_PART_FILTER_VER_02.lsp`
- `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp`
- `src/part-filter/ver-03/README.md` (requirements, status and test plan)

## 3. Confirmed Part Filter behavior

The user confirmed in Creo Elements/Direct Modeling 18.1:
- Results Graphical Browser opens and displays matching Part rows.
- Select All is available.
- Clicking an individual result row selects that Part.
- Native Apply transfers selected Part(s) to Modeling selection.

Preserve the standalone Graphical Browser architecture and native Apply hand-off in ver-01/ver-02. A custom Apply callback previously broke row selection/Apply and must not be reintroduced without a proven requirement and regression test.

## 4. Filter engine and numeric scale

The current search is an exact pair (AND):
- Density Instance: `sd-inq-part-density :instance`
- Density Base: `sd-inq-part-density :contents`

The current implementation divides API values by 1000 to match the Part Properties scale. Confirmed sample pairs:
- UI 1 / 304 ↔ API 1000 / 304000
- UI 2 / 400 ↔ API 2000 / 400000

This conversion is specific to the tested Density workflow. Never apply it automatically to unrelated properties.

## 5. ver-02 user convention mappings

Machining Process → Density Instance:
- CNC=1, KH=2, CG=3, COVER=4.

Material label → Density Base:
- A6061=6061, SUS201=201, SUS304=304, SS400=400,
- POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.

Important: these are user-defined mapping conventions. ver-02 does **not** retrieve the actual Material property from a Part. Default is CNC + SUS304 (1/304). Code fields are display-only and synchronized by `:after-input`; they are vertically arranged in the standard dialog.

## 6. Correct ver-03 requirement (authoritative)

The earlier interpretation of “multiple searches” as multiple Graphical Browser windows or Creo Browser Bar tabs was incorrect.

Required UI:
- Exactly **one separate Results window**.
- That window contains its own horizontal tabs/pages, similar to a desktop browser.
- Tabs are internal to the Results window, not tabs in Creo Browser Bar.
- One unique filter pair (Density Instance + Density Base) corresponds to one tab.
- Caption uses mapped labels, e.g. `SUS304-CNC`, `A6061-KH`.
- Searching the same pair again refreshes/overwrites that pair's existing tab; never creates a duplicate tab.
- Searching a different pair creates a new tab in the same window.
- Switching tabs preserves each page's result list and selection state where feasible.
- Each active page supports row selection, Select All and Apply.
- Apply transfers only the selected Parts belonging to the active page.
- A no-match search must not silently erase a previous valid tab/result set.

Do not revive the superseded experiment that creates one Graphical Browser per search and docks them as Creo Browser Bar tabs.

## 7. ver-03 implementation status and technical caution (2026-11-16)

Implemented in `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp`:
- ver-02 Density-pair scan, normalization and mapped choice dialog retained.
- One UICT Dialog Shell with one horizontal internal Tab Control.
- Each unique pair creates one page; same pair refreshes the existing page.
- Per-page list control with multi-selection, Select All and Clear Selection.
- Selection count/status per page.
- No-match search leaves existing tabs and results unchanged.
- Refresh preserves selected display rows when their row labels remain present.

Static checks passed: parentheses balanced and string delimiters balanced. No Creo 18.1 runtime test has been performed.

**Not yet complete:** the UICT APIs are currently supported by later-release PTC documentation only (20.7/20.8 references). Modeling 18.1 availability/signatures must be confirmed by loading and testing. The prototype does not yet transfer selected real Part objects into Modeling selection; no Apply action is wired. The user-confirmed native Apply path in ver-01/ver-02 remains the safe production baseline.

See [ver-03 Implementation Record](docs/VER03_IMPLEMENTATION_NOTES.md) for detailed scope, references and exact runtime test steps.

## 8. Repository workflow

- Work directly on `main`; do not create branches per version.
- Keep each LISP version in its own `ver-XX` folder.
- Keep prior versions unchanged once user-confirmed.
- Update shared documentation on `main` in the same work session as meaningful code/knowledge changes.
- At the start of a new chat/tool, read `docs/AI_START_HERE.md` and this file.
- Before code edits, fetch and inspect current main-branch source and docs.
- Record whether each change is specified, implemented, static-checked, loaded, functionally tested, user-confirmed or regression-tested.

## 9. Other confirmed development lessons

- `sd-browser-set-status-text` requires the `:value` keyword/value argument.
- A custom Apply callback replacing the native default caused selection/Apply regression.
- Embedding/reparenting the working Results Browser into a custom host shell failed with “Could not embed the results browser in its host window” / “Could not create the unified results window.”
- Do not assume `HANDLER-CASE` or `SEL_ITEM-P` exists in this Modeling 18.1 Lisp environment; both were reported undefined.
- A command entered directly in the user input line may not work as expected for some LISP tests; use a verified load/command invocation route.

For consolidated API findings, root causes and reusable procedures, see [ENGINEERING_KNOWLEDGE_BASE](docs/ENGINEERING_KNOWLEDGE_BASE.md).

## 10. Cross-chat skill package and recovered references (2026-11-15)

A reusable skill package has been added at `skills/creo-elements-direct-modeling/`. It consolidates project conversations and recovered user-provided materials beyond Part Filter:
- Annotation sheet/frame macros (`am_sheet.m`-style source, uploaded 2026-10-16): frame load/create/replace and current-sheet lifecycle.
- Annotation BOM layout customization macros (2026-10-17): layout import/store/edit/accept/discard and flag attach points.
- Annotation drawing arrangement macros (2026-10-17): Arrange_sheets, Arrange_sheets2 and Arrange_views.
- Initial measurement/export and command-access concept (2026-10-09), explicitly unverified.
- Part Filter API/runtime evidence and failure history (2026-11-13/14).

Top-level indexes: `docs/API_VERIFICATION_REGISTER.md` and `docs/USER_REFERENCE_INVENTORY.md`. The skill package distinguishes Modeling Lisp from legacy Annotation/ME10 command macros. User-provided Annotation sources contain CoCreate confidential/copyright headers; only technical summaries and provenance metadata are mirrored to this public repository, not full source dumps.

The accessible Library search did not identify a standalone official Modeling 18.1 Integration Kit PDF/manual. Do not claim such a manual has been reviewed until it is retrievable and its release is verified.
