# H871 Upgrade Tools – Project Context

**Last consolidated:** 2026-11-18  
**Target application:** PTC Creo Elements/Direct Modeling 18.1  
**Canonical branch:** `main`  
**Repository:** `hunghoang8711/ptc-creo-element_h871-upgrade-tool`

## 1. Project purpose

Build reliable, reusable LISP tools for Creo Elements/Direct Modeling 18.1. This repository is both source control and the durable engineering knowledge base. New chats must use the documented API evidence and prior failure history instead of repeating experiments.

## 2. Canonical Part Filter source

| Source | Role | Preservation rule |
|---|---|---|
| `src/part-filter/ver-02/H871_PART_FILTER_VER_02.lsp` | Mapped Process/Material filter; native Graphical Browser selection and Apply baseline | Keep unchanged |
| `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp` | UICT/internal-tab implementation reference | Keep unchanged; do not assume hidden Apply bridge works |
| `src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE.lsp` | Part Note baseline with page-local selection and Edit Note | Preserve unchanged |
| `src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp` | Part Note extension with Select All Pages / Clear All Pages / Apply All Pages; Select All Pages confirmed in Modeling 18.1 on 2026-11-18 | Current tested extension; Clear All Pages and Apply All Pages still require independent runtime verification |
| `src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES_FILTER_ALL.lsp` | Separate Filter All extension based on the canonical Part Note / All Pages source | Static checks only; Modeling 18.1 runtime acceptance pending |
| `src/part-filter/ver-03-rebuild/H871_PART_FILTER_VER_03_REBUILD.lsp` | Stage 0 native Graphical Browser rebuild derived from ver-02 | Keep as a reference candidate; latest user test reports only Part Name visible |
| `src/part-filter/ver-01/` | Earlier numeric filter baseline | Preserve |

The ver-03 UICT source and the ver-03 native Browser rebuild are different implementation paths. Do not conflate their runtime results or Apply behavior.

## 3. Current runtime status (2026-11-18)

- User reports that the current native Browser rebuild opens the Results window.
- The Results window displays only the Part Name column. Density Instance, Density Base and Assembly Path are not visible.
- The source contains four custom column definitions, but source presence is not proof that the custom table is active or rendered.
- The most recent change to table activation order did not improve the runtime result.
- The native Browser rebuild remains **not complete**. Do not make further speculative lifecycle-order changes. First add targeted runtime diagnostics for actual Browser mode, active table, table roots and table-definition/activation return values, and inspect the entire Results window including horizontal scroll state.
- Separately, the ver-03 Part Note UICT extension includes cross-page Select All / Clear All / Apply All. The user confirmed Select All Pages works in Modeling 18.1 on source revision 415481d0a62a744d3b09cb7b0cc697b623b14716. Clear All Pages and Apply All Pages remain pending separate runtime verification.
- Density API scaling is now configurable in the main Part Note All Pages source via `*h871-pf-v03-density-api-multiplier*` (a `defparameter`, re-applied whenever the LISP file is loaded) (default 1000.0). The new conversion code is static-checked but its runtime behavior has not yet been tested in Creo 18.1.
- Filter All extension added as a separate source file. It adds ALL to both selectors, expands selected dimensions into existing process/material convention pairs, traverses the assembly once, and creates/refreshes only populated pair pages. Static validation passed; Modeling 18.1 runtime verification is pending.
- Row selection, Select All, Clear Selection and native Apply must be regression-tested after any change. Do not assume they still work merely because Results opens.

## 4. Filter mapping and invariant

The filter uses an exact Density Instance AND Density Base pair.

Machining Process → Density Instance:
- CNC=1, KH=2, CG=3, COVER=4.

Material convention → Density Base:
- A6061=6061, SUS201=201, SUS304=304, SS400=400,
- POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.

Historical tested API values were 1000 times the Part Properties values:
- UI 1/304 ↔ API 1000/304000.
- UI 2/400 ↔ API 2000/400000.
- The Part Note All Pages source now uses `*h871-pf-v03-density-api-multiplier*` (a `defparameter`, re-applied whenever the LISP file is loaded) (default 1000.0): multiply filter inputs before comparing with raw API values, and divide only when displaying them. Set to 1.0 on a workstation where API values match Part Properties directly.

These labels are user-defined mappings; the Material selector does not read the Part's actual Material property. Never replace numeric filter inputs with labels such as CNC-SUS304. Never weaken the AND predicate or invent a missing Density Instance value.

Filter All selector sentinel: `-1` is reserved only for the dialog's `ALL` option and is not a valid Density code. `ALL + one specific value` expands only that dimension; `ALL + ALL` expands the 4×9 = 36 mapped combinations. The collector still requires exact Density Instance AND Density Base matches; pairs without Parts do not create result pages.

## 5. Product requirement

The intended product is one separate Results window with internal pages/tabs for unique Density pairs. Each page must show only its matching Parts, preserve page-local selection where feasible, and support direct row selection, Select All, Clear Selection and Apply. Native Apply must transfer only selected Parts to the actual Modeling selection.

Do not create one Browser per query, dock result windows in the Creo Browser Bar, use a hidden Browser bridge, or reparent the Browser into a custom host shell without a separately proven 18.1 API path.

## 6. Lessons and experiment history

Read [Part Filter Experiment History](docs/PART_FILTER_EXPERIMENT_HISTORY.md) for consolidated ver-04 through ver-07 findings, exact reported errors, failed architectures, lifecycle lessons and the mandatory next workflow.

Read [Engineering Knowledge Base](docs/ENGINEERING_KNOWLEDGE_BASE.md), [API Verification Register](docs/API_VERIFICATION_REGISTER.md), [Known Issues](docs/KNOWN_ISSUES.md), [Lessons Learned](docs/LESSONS_LEARNED.md) and [Technical Decisions](docs/TECHNICAL_DECISIONS.md) before changing source.

## 7. API evidence discipline

- User-confirmed Modeling 18.1 behavior, source-observed behavior, later-release documentation and unverified proposals are separate evidence classes.
- PTC 20.6/20.7/20.8 documentation is not proof of 18.1 compatibility.
- Preserve exact tested API call patterns from ver-02.
- Do not assume `HANDLER-CASE` or `SEL_ITEM-P` exists; both were reported undefined.
- `sd-browser-set-status-text` requires `:value`.
- A BrowserNode creation symbol such as `#:NODE241` is not a BrowserNode structure. Resolve it before calling a BrowserNode-typed API, then verify actual viewport selection.
- A trace status or non-NIL return is not proof of Apply.

## 8. Repository workflow

- Work directly on `main`.
- Preserve ver-02 and ver-03 LISP source byte-for-byte unless explicitly authorized.
- Keep all executable LISP and test/diagnostic code under `src/`; keep written test plans under `tests/`.
- Do not keep rejected experimental versions as permanent code folders. Consolidate their reusable lessons in the experiment history.
- Before editing, inspect current `main` source and related docs.
- Make one isolated change at a time and record exact evidence.
- Static-check source before asking for runtime tests.
- Use a disposable model copy for risky tests; never use the original/customer model.
- Never claim a feature is complete until the user confirms it in Modeling 18.1.

## 9. Other Creo knowledge

The reusable skill package at `skills/creo-elements-direct-modeling/` preserves recovered knowledge beyond Part Filter, including Annotation sheet/frame macros, BOM layout customization, drawing arrangement, platform/language boundaries and debugging workflow. Do not copy confidential user-provided source dumps into this public repository; preserve technical summaries and provenance only.


## 10. H871 Ribbon integration (2026-11-18)

A first-phase native Ribbon integration package is available under `src/h871-ribbon/`.

### Confirmed Modeling 18.1 runtime state

The user has completed and confirmed the end-to-end UI workflow:

- The existing Part Filter Lisp source is loaded and works normally.
- The H871 user-defined command is saved in Modeling's Customize / Commands interface.
- The command appears in the custom command group `H871-TOOL`.
- The user created a custom Ribbon group/tool and placed the H871 command on it.
- The Ribbon button is visible and clicking it successfully opens the existing H871 Part Filter dialog.

This is user-confirmed runtime behavior in the target application, not merely a source-level or later-release documentation claim.

### Command configuration

- Existing dialog entry point: `H871_PART_FILTER_VER_03`.
- Available Command application: `SolidDesigner`.
- User-defined command: `H871 Part Filter - All Pages`.
- Display title: `H871 Part Filter`.
- User's Customize command group: `H871-TOOL`.
- Icon resource: `H871/part_filter`, generated as a 32×32 BMP by `src/h871-ribbon/tools/Generate-H871Icon.ps1`.
- The Ribbon wrapper calls the existing dialog; no Part Filter Lisp core rewrite was required.

### Installation and lifecycle boundary

- Follow `src/h871-ribbon/INSTALL_AND_TEST.md` for the detailed procedure.
- The process has two distinct UI stages: (1) save/register the user-defined command in Customize / Commands, then (2) create/select a Ribbon tab/group and add the saved command to it.
- The current workflow requires the Lisp source to have been loaded in the active Modeling session before clicking the Ribbon button.
- Automatic startup loading and multi-workstation deployment are not implemented yet.
- Successful Ribbon dispatch does not prove every Part Filter function. Regression-test Search, selection, Apply, Edit Note and cross-page controls separately after changes to the Lisp core.
- Preserve factory and existing user customization files. Never overwrite `sd_avail_cmds.cmd`, an existing `user_avail_cmds.cmd`, or unrelated Ribbon customization files.


### Portable installer – release 0.1 (2026-11-18)

- Installer: src/h871-ribbon/portable/Install-H871.ps1.
- Instructions: src/h871-ribbon/portable/README_INSTALL.txt.
- Scope and acceptance: src/h871-ribbon/portable/INSTALLER_SCOPE.md.
- It copies the canonical Part Note / All Pages Lisp, copies the Available Command reference, generates the 32×32 icon in a user-selected personal customization directory, and writes LOAD_H871_PART_FILTER.txt.
- It stops on existing targets by default. The explicit -Force switch backs up existing target files to a timestamped backup folder before replacement.
- It never writes to user_avail_cmds.cmd, sd_avail_cmds.cmd, Ribbon customization files or startup files.
- On a new workstation, user still needs to LOAD the Lisp, register the user-defined command in Customize / Commands, and add it to a Ribbon tab/group. These are intentional safety boundaries, not completed automation.
- Verification status: installer source committed; Windows PowerShell execution and second-workstation Modeling 18.1 acceptance remain pending. Do not claim one-click deployment.


## 2026-11-25 – Part Filter Filter All Results refresh update

- Accepted Filter All source remains `src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES_FILTER_ALL.lsp`; the canonical `H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp` remains unchanged.
- User previously confirmed the Filter All feature runs perfectly in Modeling 18.1. A new issue was then reported: when filtering a different Assembly, pages belonging only to the previous Assembly remained in Results.
- The Filter All derivative now implements a full Results replacement on every Filter invocation, for both ALL-range and single-pair searches. It scans/reports first, then removes the previous tab control/pages and per-page logical tables, resets the page registry, and rebuilds only the current run's populated pairs.
- A no-match run is intended to clear previous pages and leave an empty Results window rather than preserve stale data.
- New cleanup uses `sd-destroy-control` and `sd-destroy-logical-table`, guarded by `fboundp` and return checks. These APIs are documented in later PTC Integration Kit references; exact Modeling 18.1 behavior is not yet user-confirmed.
- Runtime acceptance pending: test Assembly A → Assembly B with fewer pairs, ALL → one specific pair, and a no-match Assembly. Then regression-test selection, Apply, Part Note and cross-page controls.

## 2026-11-25 – Results reset lifecycle correction

- User reported that filtering a new Assembly after closing the Results window stopped with `H871: The previous Results tab control still exists. Filter was stopped.`
- The Results Shell close action is `sd-hide-dialog-shell`; closing it hides the shell instead of destroying it.
- The active Filter All derivative now resets the parent Results Dialog Shell using `sd-destroy-dialog-shell`, removes per-page Logical Tables, and uses `sd-destroy-control` only as a fallback for an orphaned Tab Control. The incorrect post-destroy Tab Control existence assertion was removed.
- Updated source is committed after the previous Results refresh revision. Static syntax checks pass; Modeling 18.1 runtime validation remains pending.
- Required test: Filter Assembly A → close Results → Filter Assembly B; then repeat with Results left open and with a no-match Assembly. Regression-test selection, Apply and Part Note controls.
