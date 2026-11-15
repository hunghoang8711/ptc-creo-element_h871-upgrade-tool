# H871 Upgrade Tools – Project Context

**Last consolidated:** 2026-11-15  
**Target application:** PTC Creo Elements/Direct Modeling 18.1  
**Shared branch:** `main`  
**Current focus:** Preserve Part Filter ver-01/ver-02 and prepare corrected ver-03 architecture.

## 1. Product goal

Build reliable, reusable LISP tools for Creo Elements/Direct Modeling 18.1. The repository is both the source-code archive and the engineering knowledge base: requirements, API findings, failure causes, compatibility notes, test procedures and lessons must remain available across chats and future tools.

## 2. Part Filter version status

| Version | Purpose | Status |
|---|---|---|
| ver-01 | Numeric Density Instance + Base filter with standalone Graphical Browser | User-confirmed working baseline |
| ver-02 | Machining Process + Material convention selectors mapped to Density values | Implemented; user reported very good results |
| ver-03 | One Results Browser window containing internal browser-like tabs/pages | Design specified; new implementation not yet created |

Canonical version folders:
- `src/part-filter/ver-01/H871_PART_FILTER_VER_01.lsp`
- `src/part-filter/ver-02/H871_PART_FILTER_VER_02.lsp`
- `src/part-filter/ver-03/README.md` (design and validation plan; no active LISP source yet)

Legacy root paths are retained for compatibility with earlier instructions and LOAD paths.

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
- Exactly **one separate Results Browser window**.
- That window contains its own horizontal tabs/pages, similar to desktop Chrome/Firefox.
- Tabs are internal to the Results Browser window, not tabs in Creo Browser Bar.
- One unique filter pair (Density Instance + Density Base) corresponds to one tab.
- Caption uses mapped labels, e.g. `SUS304-CNC`, `A6061-KH`.
- Searching the same pair again refreshes/overwrites that pair's existing tab; never creates a duplicate tab.
- Searching a different pair creates a new tab in the same window.
- Switching tabs preserves each page's result list and, if technically feasible, its selection state.
- Each active page supports row selection, Select All and Apply.
- Apply transfers only the selected Parts belonging to the active page.
- A no-match search must not silently erase a previous valid tab/result set.

Do not revive the superseded experiment that creates one Graphical Browser per search and docks them as Creo Browser Bar tabs.

## 7. ver-03 implementation status and technical caution

- `src/part-filter/ver-03/` currently contains design/validation notes only.
- A previous ver-03 prototype on `feature/part-filter-multi-browser-sessions` created separate Graphical Browser windows and duplicate-suffixed labels. It is explicitly superseded and is not the requested feature.
- UICT Tab Control / Dialog Shell is a possible investigation path. Documentation found so far is for later releases; exact Modeling 18.1 availability and signatures must be verified.
- A UICT display table's ability to select real Part objects and transfer them to Modeling selection is not proven.
- Prototype in small stages: tabbed shell and synthetic rows; per-page selection; actual Part selection hand-off; only then integrate the filter engine and pair-key refresh logic.
- Do not claim ver-03 implementation or runtime success until the source exists and the user tests it in Creo 18.1.

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

For the consolidated API findings, root causes and reusable procedures, see [ENGINEERING_KNOWLEDGE_BASE](docs/ENGINEERING_KNOWLEDGE_BASE.md).


## 10. Cross-chat skill package and recovered references (2026-11-15)

A reusable skill package has been added at `skills/creo-elements-direct-modeling/`. It consolidates project conversations and recovered user-provided materials beyond Part Filter:
- Annotation sheet/frame macros (`am_sheet.m`-style source, uploaded 2026-10-16): frame load/create/replace and current-sheet lifecycle.
- Annotation BOM layout customization macros (2026-10-17): layout import/store/edit/accept/discard and flag attach points.
- Annotation drawing arrangement macros (2026-10-17): Arrange_sheets, Arrange_sheets2 and Arrange_views patterns.
- Initial measurement/export and command-access concept (2026-10-09), explicitly unverified.
- Part Filter API/runtime evidence and failure history (2026-11-13/14).

Top-level indexes: `docs/API_VERIFICATION_REGISTER.md` and `docs/USER_REFERENCE_INVENTORY.md`. The skill package distinguishes Modeling Lisp from legacy Annotation/ME10 command macros. User-provided Annotation sources contain CoCreate confidential/copyright headers; only technical summaries and provenance metadata are mirrored to this public repository, not full source dumps.

The accessible Library search did not identify a standalone official Modeling 18.1 Integration Kit PDF/manual. Do not claim such a manual has been reviewed until it is retrievable and its release is verified.
