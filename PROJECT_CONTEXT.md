# H871 Upgrade Tools – Project Context

**Last consolidated:** 2026-11-16  
**Target application:** PTC Creo Elements/Direct Modeling 18.1  
**Shared branch:** `main`  
**Current focus:** preserve ver-02 native Apply while validating a single-Graphical-Browser multi-page architecture; ver-03 UICT Apply remains unresolved.

## 1. Product goal

Build reliable, reusable LISP tools for Creo Elements/Direct Modeling 18.1. The repository is both the source-code archive and the engineering knowledge base: requirements, API findings, failure causes, compatibility notes, test procedures and lessons must remain available across chats and future tools.

## 2. Part Filter version status

| Version | Purpose | Status |
|---|---|---|
| ver-01 | Numeric Density Instance + Base filter with standalone Graphical Browser | User-confirmed working baseline |
| ver-02 | Machining Process + Material convention selectors mapped to Density values | Implemented; user reported very good results |
| ver-03 | One Results window with UICT internal horizontal tabs and per-page Display Tables | Results UI/page behavior user-confirmed in project testing; UICT-to-Modeling Apply unresolved; hidden Browser bridge failed |
| ver-04 | Single Graphical Browser page-navigation diagnostic | Diagnostic only; not final architecture |
| ver-05 | One self-contained Graphical Browser with multiple Density-pair pages and native Apply | Implemented and static-checked; Modeling 18.1 runtime validation pending |

Canonical version folders:
- `src/part-filter/ver-01/H871_PART_FILTER_VER_01.lsp`
- `src/part-filter/ver-02/H871_PART_FILTER_VER_02.lsp`
- `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp`
- `src/part-filter/ver-04/diagnostics/H871_PF_V04_SINGLE_BROWSER_PAGES_DIAG.lsp` (diagnostic only; not production)
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

ver-03's UICT Results implementation provides one Results shell with horizontal internal tabs, one page per exact Density pair, page-specific result data, multi-row selection, Select All/Clear Selection, same-pair refresh and no-match preservation. The user has confirmed the Results UI and page workflow in Modeling 18.1 project testing.

Apply status:
- UICT Display Table returns valid Part selection payloads (ELAN::SEL_ITEM).
- A hidden temporary Graphical Browser does not reproduce ver-02's native Apply, even when BrowserNode counts and programmatic status calls look successful.
- Dialog Generator persistent highlight works visually but is not proof of the same Modeling selection state.
- GET_SELECTION named-Part experiments failed with an unexpected-input error.
- Direct sd-call-cmds from UICT callbacks failed as an illegal action call.
- Do not repeat the hidden Browser bridge, offscreen bridge, GET_SELECTION setter interpretation, or custom Apply callback.

Search safety:
- An iterative traversal candidate still produced Modeling fatal exception 0xC00000FD. That candidate was reverted; the active ver-03 source is the revision associated with the user-confirmed Results UI. Search root cause is unresolved. Do not test on the original/customer model; use a disposable copy and obtain the exact trace before changing the collector.

## 8. ver-04 single-Browser diagnostic (2026-11-16)

Added diagnostic-only source:
`src/part-filter/ver-04/diagnostics/H871_PF_V04_SINGLE_BROWSER_PAGES_DIAG.lsp`

It copies the existing ver-03 page data into one native Graphical Browser Tree, with one page root per Density pair and one shared table. Previous/Next buttons and a dynamic right-click Results Pages submenu switch table roots. Selection paths are saved/restored per page. The Graphical Browser's native Apply default is preserved; no custom `:okButtonAction` is supplied.

This is a page-navigation proof-of-concept, not the final horizontal-tab UI. It deliberately avoids the previously failed Browser reparenting/host-shell approach and does not modify ver-03 production source or ver-01/ver-02.

**Status:** First user test in Modeling 18.1 confirms one native Graphical Browser opens and displays the active ver-03 page; the old UICT shell is hidden. A second invocation exposed a stale named Browser Tree. A lifecycle patch now attempts Browser-then-Tree teardown before rerun and restores ver-03 UICT from Close Results / H871_PF_V04_RESTORE_UICT_RESULTS. This patch is static-checked but not yet retested. Page switching, selection restoration and native Apply remain unverified. The acceptance test is actual Part selection in the 3D viewport after pressing native Apply.

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


### ver-04 persistent UICT reopen control (2026-11-16)

The user confirmed Close Results returns from the native ver-04 Graphical Browser to the old ver-03 UICT Results shell. To avoid requiring a manual `H871_PF_V04_SINGLE_BROWSER_PAGES_DIAG` command each time, ver-04 now installs a persistent `Open Native Results` pushbutton in the existing ver-03 shell grid. The button calls the ver-04 rebuild entry point, which snapshots the latest ver-03 pages/selections, cleans up any previous named Browser/Tree, and recreates the native Browser. Previous/Next now emit `PAGE/NAVIGATION-REQUEST` and `PAGE/NAVIGATION-TARGET` trace markers. Source commit: `21ddfb945a40f2361cb09439522387f90f6fac54`.

This is static-checked only. Modeling 18.1 must confirm button placement/callback, repeated close/reopen, user-operated Previous/Next and context-menu navigation, and actual viewport Apply. The trace's `SELECT-AND-EXECUTE-SUCCESS-CONTEXT` is not itself proof of viewport selection.

## 11. Final product direction and ver-05 self-contained candidate (2026-11-16)

The user reconfirmed that the final architecture must remain exactly one Results window: native direct row selection and Apply from ver-02, combined with multiple result pages from ver-03. ver-04's UICT-to-Browser switching, persistent launcher, and Close-to-UICT return path were diagnostic steps only and are not accepted as the final workflow.

New candidate source:
`src/part-filter/ver-05/H871_PART_FILTER_VER_05.lsp`

Design:
- One standalone Graphical Browser owns all result rows and every Density-pair page.
- The candidate includes its own Assembly search action and ver-02 Process/Material numeric mapping; it does not require ver-03 page data or UICT globals.
- One Browser Tree has a root per Density pair; one shared Browser table shows the active page's direct Part children.
- The same visible Browser owns selection and the untouched native Apply action. No hidden Browser bridge or custom Apply callback.
- Same-pair search refreshes its page and clears only that page's selection; new pair creates a page; no-match preserves existing pages.
- Page-local selected paths are saved/restored when changing pages.
- Navigation is Previous/Next and a Results Pages popup inside the same Browser. Horizontal tab-strip rendering remains open work; do not claim it is implemented.
- On successful search, the named Browser/Tree are rebuilt so the one Browser contains the latest page registry. No additional Results window or manual reopen step is intended.

Density mapping and search rules remain unchanged: CNC=1, KH=2, CG=3, COVER=4; A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50; API values are divided by 1000; matching requires both Instance and Base.

**Evidence status:** ver-05 is static-checked only, not loaded or tested in Modeling 18.1. In particular, native Apply, dynamic page popup, page switching/selection restore, repeated searches and no-match preservation require runtime verification on a disposable model copy. ver-01/ver-02/ver-03 are preserved as baselines; ver-04 remains diagnostic.

### ver-05 horizontal page-button strip refinement (2026-11-16)

The single Browser now receives a dynamically generated `:modeMenu` row with one page button per stored Density pair; the active page is supplied through `:modeMenuInitialButton`. This is the current attempt to approximate the requested horizontal internal tabs inside the same Results Browser, not Browser Bar docking. The active page action changes the table root in that same Browser. PTC's detailed modeMenu documentation is from a later release; exact Modeling 18.1 behavior is unverified. Native Apply remains the default action.



### ver-05 critical page-root isolation correction (2026-11-16)

Source review found that switching a page did not clear the previous Graphical Browser table root before setting the new one. Since a Browser can retain multiple table roots, this could cause mixed-page rows and invalidate Select All/Apply page scope. ver-05 now executes a buffered sequence: :buffer-display t → :clear-select-list → :clear-table-roots → :change-table-root active-page t → :buffer-display nil, then records :number-of-table-roots in the trace. Source commit: c510c7c76243f9ceed5430eee86e68111d183f3a.

This is a static source correction based on the PTC 20.6 documented command sequence, not a Modeling 18.1 runtime confirmation. The modeMenu horizontal page buttons and their callbacks, one-root-only behavior, page-local selection restore, and actual native Apply to the 3D viewport still require a disposable-model test. Do not call ver-05 complete until all acceptance tests pass.


ver-05 follow-up: page activation now fails closed if :clear-table-roots or :change-table-root does not return success. The :number-of-table-roots inquiry is wrapped as diagnostic-only so an unavailable query cannot interrupt the Browser. Latest source commit: 30d679156b879339cdefd1a922649feb4a937bd4. Runtime confirmation remains pending.


ver-05 caption correction: page labels now use PROCESS-MATERIAL order (CNC-SUS304, CG-SS400), matching the established ver-03 convention. The numeric Density mapping and search values are unchanged. Source commit: 8a189bb6ec8e44234b5b6607deb8600af3541c0a.


### ver-05 page-selector UI correction (2026-11-16)

The missing multi-page UI was traced to using :modeMenu as a horizontal tab strip. PTC documentation states modeMenu maps to right-click popup entries; :buttonMenu is the visible horizontal button row. The user therefore saw a ver-02-like table without page buttons. ver-05 now builds each Density-pair page selector dynamically through :buttonMenu, followed by Select All and Clear Selection. The incorrect modeMenu page configuration and popup menu installer call were removed. Source commit: ca85cf158cdb345381f989f46f3e6cadbfe9bdc4. Runtime visibility and callback behavior in Modeling 18.1 remain unverified.


Correction: the previous note saying modeMenu is not a horizontal row was wrong. PTC specifies modeMenu as a row of toggle buttons directly above buttonMenu, while both menus are also mapped to right-click popup entries for compatibility. The original modeMenu page selector is restored in source commit 7763d35, with trace markers for the evaluated mode-menu specification and Browser creation. The actual runtime cause of the missing page strip remains unresolved.


## Part Filter – direction reaffirmed (2026-11-16)

The user has explicitly selected ver-03 as the accepted interface: one Results window with internal tabs/pages per Density Instance + Density Base pair, multi-column Display Table, direct single/multi-row selection, Select All/Clear Selection and Apply. Continue development from ver-03. ver-04/ver-05 are diagnostic experiments only and must not redirect the product toward a single-Graphical-Browser UI or intermediate-window workflow.

Apply source correction commit `068ee4123b5aadf6cde5bce54321f1ee031ea064`: resolve every `sd-create-browsernode` identifier through `sd-get-browsernode-struct` before passing nodes to `:set-object-selection`. Runtime hand-off to Modeling selection is still unverified; require visible viewport selection as proof.
