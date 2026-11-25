# Part Filter – Consolidated Experiment History and Engineering Lessons

**Consolidated on:** 2026-11-17  
**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Canonical branch:** `main`  
**Purpose:** Preserve useful findings from ver-04/ver-05/ver-06/ver-07 experiments without retaining those experimental LISP implementations as active source.

## 1. Canonical source policy

Keep these source references unchanged:
- `src/part-filter/ver-02/H871_PART_FILTER_VER_02.lsp` – mapped Process/Material filter and known-good native Graphical Browser selection/Apply pattern.
- `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp` – historical UICT/internal-tab implementation; retain as a reference, not as the default implementation base.
- `src/part-filter/ver-03-rebuild/H871_PART_FILTER_VER_03_REBUILD.lsp` – Stage 0 native Graphical Browser rebuild derived from ver-02. This is preserved byte-for-byte from the latest development source as a reference candidate. Its latest Results Browser opens, but the user reports that only the Part Name column is visible; therefore it is not complete or accepted as a finished replacement.

Also retain ver-01 and the small diagnostic/test LISP files already under `src/part-filter/`. All executable LISP test/diagnostic code belongs under `src/`; `tests/` is for written procedures and sanitized fixtures, not loose LISP code.

Experimental ver-04/ver-05/ver-06/ver-07 implementation files are not canonical source and are removed from the current `main` working tree. Their Git history is retained by Git; this document preserves the reusable engineering findings.

## 2. User requirements that must not drift

1. Target Creo Elements/Direct Modeling 18.1, not Creo Parametric.
2. The filter matches an exact Density Instance **AND** Density Base pair.
3. Numeric mappings are user conventions:
   - Process / Instance: CNC=1, KH=2, CG=3, COVER=4.
   - Material / Base: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
4. Historical tested Density workflow: API values were 1000 times Part Properties values:
   - UI 1/304 ↔ API 1000/304000.
   - UI 2/400 ↔ API 2000/400000.
   - The Part Note All Pages source now uses the configurable `*h871-pf-v03-density-api-multiplier*` (a `defparameter`, re-applied whenever the LISP file is loaded) (default 1000.0) instead of a hard-coded divisor. Inputs are multiplied to API scale; displayed values are divided back. Set 1.0 if a workstation's API returns Part Properties values directly.
5. The mapped Material label is not the Part's actual Material property.
6. The desired multi-search product is one Results window with internal Density-pair pages, not one Browser per search and not Creo Browser Bar docking.
7. Native row selection and native Apply must remain owned by the same visible Graphical Browser. The user's visible 3D viewport selection is the only acceptance proof for Apply.
8. Never replace a confirmed baseline with an unverified candidate merely because it has more features.

## 3. Experiment findings

### ver-04 – single Graphical Browser page-navigation diagnostic

**Purpose:** Test whether multiple Density-pair pages could share one native Graphical Browser and its native Apply action.

**Implementation concept:**
- One Browser Tree with a synthetic root per Density pair.
- One visible Graphical Browser and one table.
- Each page root owns its matching Part BrowserNodes.
- Previous/Next and a dynamic Results Pages popup switch the active table root.
- Save selected Part paths before switching and restore them after activating the target root.
- Keep the Browser's native Apply; do not supply a custom OK/Apply callback.

**Runtime evidence reported by the user:**
- The diagnostic opened one native Results Browser and displayed the active ver-03 result rows.
- A second run initially failed because the named Browser Tree still existed.
- A lifecycle correction allowed Close Results to return to the old UICT window and allowed the Browser to be recreated.
- Trace evidence showed two page roots, Part nodes, page-menu entries, a page-root change and one selected row being restored.
- The user confirmed switching to the CG-SS400 page and restoring its selected row in a later test.
- A trace containing a non-NIL selection context / `:SUCCESS` was **not** proof that Apply changed the actual 3D viewport selection.

**Lessons retained:**
- Hiding a Browser is not equivalent to destroying it. When reusing named objects, clean up the Graphical Browser before destroying its Browser Tree.
- A Browser Tree can contain multiple roots; page switching must explicitly manage the active table root.
- Programmatic selection traces are not substitutes for observing actual Modeling selection.
- UICT-to-Browser switching and persistent launcher/return workflows are diagnostic detours, not the desired final user experience.

### ver-05 – self-contained single-Browser multi-page candidate

**Purpose:** Remove dependency on ver-03 UICT globals and test a single Browser that owns search, pages, rows and native Apply.

**Implementation concept:**
- Reuse ver-02's recursive Assembly collector, exact Density pair predicate, normalization and mappings.
- One page registry, one Browser Tree, one Graphical Browser.
- Same pair refreshes its page; new pair adds a page; no-match preserves existing pages.
- Save/restore selected Part paths by page.
- Keep native Apply unchanged.
- Attempt dynamic horizontal page selectors through Graphical Browser menu definitions.

**Static findings retained:**
- Page-root switching must not simply add a new root. A Browser may retain old table roots, causing rows from multiple pages to appear together.
- The documented safe sequence is to buffer redraw, clear selection, clear table roots, set the requested root, then resume redraw.
- If clearing roots or setting the new root fails, page activation must stop rather than risk cross-page selection/Apply.
- Page captions must use PROCESS-MATERIAL order, e.g. CNC-SUS304.
- PTC documentation descriptions of `:modeMenu` and `:buttonMenu` were initially misread and later corrected. Do not rely on recollection or abbreviated excerpts for UI parameters; inspect the complete target API description and verify the actual rendered result.

**Evidence boundary:**
- ver-05 was static-checked but not validated as a complete workflow in Modeling 18.1.
- The horizontal page-selector rendering/callbacks, page-local selection, root isolation, repeated searches and actual viewport Apply were not all proven.
- A design that looks like ver-02 because page controls are absent is not an acceptable implementation of the requested multi-page UI.

### ver-06 – Browser shell / embedding experiments

**Purpose:** Investigate combining a Results Browser with a custom host/shell layout.

**Failures and lessons:**
- Browser embedding/reparenting attempts produced errors including:
  - `H871: Could not embed the results browser in its host window.`
  - `H871: Could not create the unified results window.`
- The errors were sensitive to whether the selected Assembly had matching Parts; no-match searches could still show the normal no-results response while matching results failed during window creation.
- Do not treat a host-shell integration as a harmless layout change. It changes window ownership and Browser lifecycle.
- Do not repeat `sd-set-graphical-browser-parent`, custom host-shell, or resizable-dialog/grid-area proposals unless the exact API is verified for Modeling 18.1 and a minimal isolated proof succeeds first.
- APIs documented as new in later releases (for example 20.6) must not be assumed available in 18.1.

**Evidence boundary:** the above are user-reported failures. Do not invent a single confirmed root cause where the available evidence only localizes the failure to Browser embedding/host creation.

### ver-07 – Density results/table and Apply investigations

**Purpose:** Improve the Results presentation and retain the Part Filter data needed by the user.

**Lessons retained:**
- Preserve the exact Density numeric convention. For example, `1-304` means CNC-SUS304; the software filter receives numeric Instance=1 and Base=304, not the string `CNC-SUS304`.
- Do not weaken the exact AND predicate or silently replace a missing Instance value with a guessed value. Some observed Parts returned NIL for Density Instance while Base was readable; this needs property-level diagnosis.
- The custom results table must be checked as a complete table definition and runtime UI, not merely by finding column definitions in source.
- A Results window appearing does not prove the requested columns were activated or displayed.
- A BrowserNode creation token such as `#:NODE241` is not itself a BrowserNode structure. PTC later-release documentation describes resolving the symbolic ID with `sd-get-browsernode-struct`; exact 18.1 compatibility and the complete selection hand-off still require runtime confirmation.
- Never equate a successful function return, a trace marker, or a non-NIL selection context with successful selection in the Modeling viewport.

**Latest reported state (2026-11-17):**
- Results Browser opens.
- Only Part Name is visible; Density Instance, Density Base and Assembly Path are not visible.
- The current candidate's source contains four column definitions, but that static fact does not explain why only one column appears at runtime.
- The latest speculative adjustment to table activation order did not improve the user's result.
- Therefore the current rebuild is not accepted as complete. Do not continue changing Browser lifecycle order without runtime diagnostics that identify the actual Browser mode, active table and table-root state.

## 4. Recurrent errors and prevention rules

| Observed error / symptom | What it tells us | Prevention |
|---|---|---|
| `NIL is not of type STRING` before Results appears | A UI/API call received NIL where a string was required; previous guesses around callback timing and stale UICT handles did not resolve it | Add stage-level diagnostics around the exact call; validate handles before passing them; do not alter Density matching without evidence |
| `#:NODE... is not of type BROWSERNODE` on Apply | A symbolic node ID was passed where a BrowserNode structure was required | Resolve the ID with the documented lookup pattern; then still verify actual viewport selection |
| `Could not embed the results browser in its host window` | Browser embedding/parenting failed | Do not retry host-shell reparenting as a routine UI adjustment |
| `Could not create the unified results window` | Unified host/Browser creation failed | Isolate Browser creation from host layout; preserve standalone Browser fallback |
| Browser Tree “already exists” on second run | Named Tree survived the previous run | Destroy Browser first, then Tree; verify cleanup before recreation |
| Results opens but only Part Name appears | Custom table is not visibly active/populated as intended, despite source definitions | Inspect runtime mode/table/root and full window screenshot; do not claim the other columns work from source inspection |
| Fatal exception `0xC00000FD` during Search | Stack overflow/fatal runtime failure; iterative traversal attempt did not resolve it | Do not assume recursion is the sole cause; capture last trace marker and test only on a disposable model copy |
| Select All / Apply does nothing after UI unification | UI selection context no longer matches native Browser selection | Keep selection and Apply in the same visible native Browser; regression-test every UI refactor |

## 5. API and compatibility discipline

- Evidence from PTC 20.6/20.7/20.8 documentation is **later-release documentation**, not proof of Modeling 18.1 support.
- Preserve exact tested call signatures from ver-02 where possible.
- Do not assume `HANDLER-CASE` or `SEL_ITEM-P` exists; user reported these as undefined.
- `sd-browser-set-status-text` requires the `:value` keyword/value.
- `sd-create-browsernode` returns a symbolic identifier in the documented API; a BrowserNode structure must be resolved before passing it to BrowserNode-typed commands.
- `:change-table-root` changes the table root; children of that root are the displayed table rows in the documented Graphical Browser behavior.
- `:clear-table-roots`, `:number-of-table-roots`, `:modeMenu`, and other later-documented commands/parameters require Modeling 18.1 runtime verification before they become dependencies.
- Do not claim API availability solely because a function appears in a later-version manual.

## 6. Required engineering workflow for the next implementation

1. Read `docs/AI_START_HERE.md`, `PROJECT_CONTEXT.md`, this history, the API register, Known Issues and Lessons Learned.
2. Fetch the exact `main` source and compare it with the preserved ver-02 and ver-03 references.
3. Write down the intended behavior and the specific source function to change before editing.
4. Preserve the verified filter engine and native Apply behavior; change one isolated layer at a time.
5. Add diagnostic output that reports the actual stage and returned values. Avoid broad speculative rewrites.
6. Static-check parentheses, strings, symbol references and call ordering.
7. Label all results precisely: source-reviewed, static-checked, loaded, runtime-tested, user-confirmed or regression-tested.
8. For runtime tests, use a disposable model copy. Never test experimental traversal or Apply bridges on the original/customer model.
9. Require the user-visible 3D viewport selection as proof of Apply.
10. Update this history and the project log when a new error is reproduced or a root cause is confirmed.

## 7. Current unresolved work

- Explain why the active native Browser rebuild displays only Part Name despite four source column definitions.
- Confirm all required columns in Modeling 18.1.
- Reconfirm row selection, Select All, Clear Selection and native Apply after any source change.
- Do not mark the rebuild complete until the user confirms the full workflow.


## 2026-11-18 – ver-03 Part Note with cross-page selection

**Accepted development source:** src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp

**Baseline and preservation:** Built from the user's exact ver-03-partnote baseline (H871_PART_FILTER_VER_03_PARTNOTE.lsp, main commit 4f84371351c4fdf3f1961873f7870d2a553b2f74). The original baseline remains unchanged. The feature is an additional source file, not an overwrite of ver-03 or ver-03-partnote.

**Feature behavior:**
- Preserves page-local Select All, Clear Selection, Apply and Edit Note.
- Adds Select All Pages, Clear All Pages and Apply All Pages controls.
- Select All Pages iterates the existing page registry and invokes the established page-local selection function for each page; it does not switch tabs or rebuild result pages.
- Apply All Pages reads selected real Part objects from each page's hidden :part-object logical-table column, de-duplicates by eq, and routes the combined list through the existing Apply bridge.
- The cross-page Apply path uses a nil pending-page sentinel so the completion handler can update statuses across pages.

**Callback dispatch issue and resolution:** The first two UICT callback forms (bare symbol, then one-element list) both produced an unbound-variable error in Modeling 18.1. The working form uses a two-element list with an explicit nil argument, matching the existing page-scoped callbacks: (list 'callback-name nil). Each cross-page function accepts an optional callback argument. The user then confirmed that Select All Pages works.

**Runtime evidence as of 2026-11-18:**
- User confirms the cross-page Select All action now works in Modeling 18.1.
- Existing page-local controls were reported stable during the test cycle.
- Clear All Pages and Apply All Pages are present in source but have not yet been independently confirmed by the user; keep their status as pending runtime verification.
- Do not infer that a trace :SUCCESS alone proves viewport selection. For Apply All Pages, the acceptance test remains observation of the actual 3D selection.

**Commits on feature branch:**
- ce2089bc6a14e530900cd796e18e6116e2cefa2c – initial cross-page implementation.
- 7693ed8440091f8eb6413c90e0f8acf16c4b2bb3 – first callback-dispatch adjustment (not sufficient).
- 415481d0a62a744d3b09cb7b0cc697b623b14716 – explicit nil callback argument, optional function argument and callback-entry traces; this is the runtime-confirmed source revision.


## 2026-11-23 – Filter All extension (separate from the canonical baseline)

**Source:** `src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES_FILTER_ALL.lsp`

- Derived from the selected canonical `H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp`; no changes were made to the canonical source.
- Added `ALL` to both Machining Process and Material selectors. Existing options, mappings and default values are retained.
- `-1` is a dialog-only sentinel; actual filter pairs always use the established numeric codes.
- Selecting ALL in only one selector expands that dimension (4 process values or 9 material values). Selecting ALL in both expands the 36 mapped pairs.
- The new collector traverses the assembly once, applies the exact Density Instance AND Density Base predicate, and groups each matching Part under its mapped pair.
- A Results tab is created/refreshed only when its pair bucket contains at least one Part. No-match pairs do not produce empty tabs; prior tabs are not deleted or cleared by a no-match.
- Static checks passed. No Modeling 18.1 runtime evidence is available yet. In particular, verify that the dialog accepts the `-1 :label "ALL"` range entries and that the recursive collector preserves the existing 18.1 traversal behavior.


## 2026-11-23 – Filter All default selection

- Changed the default Machining Process and Material selections to `ALL` (`-1`) in the Filter All extension. Updated their display-only code defaults to `-1` as well, so the dialog starts with both selectors visibly and internally aligned to ALL.
- Existing individual choices and the single-pair filtering path are unchanged. Canonical Part Note / All Pages baseline remains untouched.
- Static source check only; user previously confirmed the Filter All feature runs successfully. Verify the initial dialog display once after loading this update in Modeling 18.1.


## 2026-11-23 – Filter All accepted in Creo Elements/Direct Modeling 18.1

**Accepted source:** `src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES_FILTER_ALL.lsp`

**User runtime evidence:**
- User explicitly confirmed that the Filter All feature runs perfectly in the target Creo Elements/Direct Modeling 18.1 environment.
- Treat the Filter All implementation as user-confirmed runtime success. This supersedes the earlier “runtime acceptance pending” statements above, which accurately described the state before the user test.
- Do not downgrade this accepted feature to an untested prototype in future handovers.

**Preservation and architecture rules:**
- Keep Filter All as a separate derivative of `H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp`; do not overwrite the canonical baseline.
- Keep `-1` as a dialog-only ALL sentinel. Never pass `-1` into the actual Density comparison; expand it to the established numeric process/material codes first.
- Preserve the exact Density Instance AND Density Base predicate. Do not substitute labels for numeric filter values.
- Preserve the single-pass assembly traversal and grouping by mapped pair. Create/refresh only result pages whose pair buckets contain Parts; no-match pairs must not create empty pages or erase existing valid pages.
- Preserve the original single-pair execution path when neither selector is ALL.

**Default-selection follow-up:**
- Commit `9fefe722e7ddfb9a2e09db64cd45b417dcd7cd1f` sets all four dialog defaults (selected Process, Process display code, selected Material, Material display code) to `-1`, so the dialog is intended to open as ALL + ALL.
- Static source verification passed for these four defaults and balanced LISP structure.
- The feature itself is runtime-confirmed, but the specific initial ALL + ALL display introduced by this later commit should be visually checked once after reloading the latest file. Keep this narrow verification separate from the already accepted Filter All behavior.

**Next-work rule:** Make future changes incrementally against the accepted Filter All derivative, re-fetch `main` before editing, preserve the canonical baseline, and record both the exact commit and whether verification was static or user-confirmed in Creo 18.1.


## 2026-11-25 – Results lifecycle: replace stale Assembly pages on every Filter

**User-reported problem:** Filtering a new Assembly left old process/material tabs in the Results window. The current run refreshed pages for pairs populated in the new Assembly, but did not remove tabs for pairs that existed only in the previous Assembly. The result mixed multiple Assembly runs and was difficult to control.

**Root cause in the Filter All derivative:**
- `h871-pf-v03-run-filter-all` iterated only populated pair buckets and used `h871-pf-v03-find-page` to reuse matching old pages. It did not remove old pages absent from the new Assembly.
- The no-match branch explicitly preserved all previous Results tabs.
- The single-pair route similarly refreshed/created one pair without replacing other old pages.

**New intended behavior:**
- Every invocation of Filter is a complete Results refresh, regardless of whether the user selected ALL or one specific Process/Material pair.
- First complete the current Assembly scan and report generation. Only then remove the previous Results set.
- Destroy the old tab control and its child page controls; destroy each previous page's logical table; clear the page registry and current-page state.
- Recreate the Results tab control and add only populated Density-pair pages from the current Assembly.
- If the current Assembly has no matching Parts, clear all previous pages and show an empty Results window plus a no-match message.
- This makes the Results window represent exactly one filter invocation / one selected Assembly at a time. Part Note values remain stored on the Parts themselves; the refresh removes only Results UI/table data.

**Implementation and safety notes:**
- Added `h871-pf-v03-reset-results-pages` to the separate Filter All source. It checks `fboundp` for `sd-destroy-control` and `sd-destroy-logical-table`, destroys the tab control, verifies the control no longer exists, then destroys each registered logical table and clears the registry.
- Both `h871-pf-v03-run-filter-all` and `h871-pf-v03-run` call this helper after scan/report completion and before creating the new Results pages.
- If required cleanup APIs are unavailable or cleanup returns failure, the filter stops with a diagnostic. The source does not silently continue with stale tabs.
- `sd-destroy-control` and `sd-destroy-logical-table` are documented in later PTC Integration Kit manuals; this is not proof of availability/signature behavior in Modeling 18.1. The helper guards against undefined functions, but a runtime test remains essential.
- Canonical `H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp` is untouched. Only the separate Filter All derivative is changed.

**Required Modeling 18.1 acceptance tests:**
1. Filter Assembly A with ALL + ALL and note the populated tabs.
2. Filter Assembly B where only a subset of A's process/material pairs exist. Confirm every tab from A that is absent in B disappears; only B's populated pairs remain.
3. Filter Assembly B with one specific pair. Confirm the Results window contains only that one pair, not pages from the previous ALL + ALL run.
4. Filter an Assembly with no matching Parts. Confirm all old tabs disappear and the Results window is empty; no stale Part rows remain.
5. Repeat Filter All and confirm no duplicate tabs, and recheck Select All Pages, Clear All Pages, Apply All Pages, per-page Apply and Edit Note.

**Verification status:** source edit and static checks only. Runtime acceptance in Creo Elements/Direct Modeling 18.1 is pending.
