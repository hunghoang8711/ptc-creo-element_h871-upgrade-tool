# H871 Engineering Knowledge Base

A durable, cross-chat reference for Creo Elements/Direct Modeling 18.1 LISP development. This document consolidates reusable facts, API observations, verified workflows, failure causes and working practices. It is not a substitute for checking the actual source or target-version documentation.

## 1. Environment and development principles

- Target: **PTC Creo Elements/Direct Modeling 18.1** (not Creo Parametric).
- Language: Creo/Elements Direct Lisp environment. Do not assume all ANSI Common Lisp functions or third-party helper symbols are available.
- User's LISP experience: basic; provide clear LOAD command, command name, test steps and expected result when handing over code.
- Prefer incremental changes and preserve a known-good source version.
- Separate property retrieval, filtering logic, UI/result presentation and selection hand-off where practical.
- Do not use customer models, drawings, credentials or private data in this public repo.

## 2. Verified Part Filter facts

### Density inquiry
- Instance: `(sd-inq-part-density part :instance)`
- Base/contents: `(sd-inq-part-density part :contents)`
- Current exact-pair matching uses AND: both Instance and Base must match.
- In the tested workflow, raw API values are 1000 times the Part Properties display values. Examples:
  - UI Instance/Base 1/304 → API raw 1000/304000.
  - UI Instance/Base 2/400 → API raw 2000/400000.
- The current Part Filter normalizes these Density values by dividing by 1000.
- Do not apply this conversion to any other property without independently checking its scale and units.

### Assembly traversal and Part identification
- The current implementation recursively traverses `(sd-inq-obj-children obj)`.
- Part test in current source: `(sd-inq-part-p obj)`.
- Name/path helpers in current source: `sd-inq-obj-basename`, `sd-inq-obj-pathname`.
- These are source-observed calls in the current working implementation; verify signatures before reusing in a different context.

### Results Graphical Browser
- The user-confirmed workflow displays Part results in a dedicated Graphical Browser.
- User-confirmed: individual row selection, Select All and native Apply hand-off to Modeling selection.
- Browser row client data stores the actual Part object and display fields; current helper reads it through `browsernode-objclientdata`.
- Current source uses `sd-create-browser-tree`, `sd-create-browsernode`, `sd-create-graphical-browser`, `sd-browser-define-table`, `sd-browser-set-active-table`, `sd-browser-exec-cmd`, `sd-show-graphical-browser`, `sd-query-browser`.
- Treat these as source-observed API usage, not blanket guarantees for all 18.1 contexts. Preserve the tested call patterns.

### Status text
Correct form observed in working source:
```lisp
(sd-browser-set-status-text
  browser-name
  :value "Status message")
```
Omitting `:value` caused “Odd number of arguments for keywords.”

## 3. ver-02 convention mapping

The user-facing selectors map onto the existing Density fields:

| Machining Process | Density Instance |
|---|---:|
| CNC | 1 |
| KH | 2 |
| CG | 3 |
| COVER | 4 |

| Material label | Density Base |
|---|---:|
| A6061 | 6061 |
| SUS201 | 201 |
| SUS304 | 304 |
| SS400 | 400 |
| POM | 10 |
| Bakelit | 20 |
| MC | 30 |
| MIKA | 40 |
| PU | 50 |

- Default: CNC + SUS304 = 1/304.
- Dialog Generator pattern in source: numeric `:range` entries with `:label`; display-only code fields updated by `:after-input`.
- Important distinction: these are user conventions. No actual Material property is read from the model.

## 4. User-confirmed behavior and regression boundary

The following have been explicitly confirmed by the user in Modeling 18.1:
1. Results Browser opens and displays matching Part rows.
2. Select All is present.
3. Clicking an individual row selects the corresponding Part.
4. Native Apply transfers selected Parts to Modeling selection.

Any Results UI change must retest these behaviors. Keep native Apply unless a replacement is proven to preserve the same selection semantics.

## 5. Failure patterns and root causes

### Custom Apply callback broke selection
- Symptom: clicking rows and pressing Apply no longer worked.
- Cause: custom callback replaced native Apply and reopened the Browser immediately after selection hand-off.
- Fix: remove callback; retain native default Apply.
- Prevention: do not override native Apply without a verified need and regression tests.

### Unified host-shell / browser reparenting failed
- Errors included:
  - `Could not embed the results browser in its host window.`
  - `Could not create the unified results window.`
- Resolution: restore standalone Graphical Browser.
- Prevention: do not revive the failed browser-parent architecture as a shortcut for UI rearrangement.

### Keyword argument error
- Error: `Odd number of arguments for keywords.`
- Cause: status-text call omitted `:value`.
- Fix: pass `:value` explicitly.

### Undefined Lisp symbols
- User observed `HANDLER-CASE` undefined.
- User observed `SEL_ITEM-P` undefined in several diagnostic attempts.
- Prevention: do not assume generic Common Lisp or undocumented Creo helper symbols exist. Verify in the target environment before using them.

### User input line invocation
- Some attempted LISP test calls did not work when entered directly on the user input line.
- Prevention: provide a known LOAD procedure and a verified command entry point; do not assume arbitrary function forms are accepted as interactive commands.

## 6. Correct multi-search design (ver-03)

Authoritative user requirement:
- One separate Results Browser window.
- Multiple internal horizontal tabs/pages inside that same window.
- One filter pair maps to one page.
- Caption uses Material + Process, e.g. `SUS304-CNC`.
- Same pair refreshes existing page; different pair creates a new page.
- Switching pages preserves each result list and ideally its selection.
- Select All and Apply are scoped to active page; Apply transfers only selected Parts from that page.
- A no-match search must not silently erase a valid page.
- Do not create one Graphical Browser per search or dock multiple windows as tabs in Creo Browser Bar.

Potential UICT tab-control direction is research only. Validate Modeling 18.1 API signatures and actual Part-selection/Apply hand-off before integrating it. A safe prototype sequence is: tab shell with synthetic rows → page switching/state isolation → real Part selection → Apply hand-off → integrate filter engine and pair-key refresh.

## 7. Compatibility and API research rules

- Prefer official PTC Integration Kit documentation.
- Record the exact release/version of every reference.
- Later-release references are not proof that a symbol exists in 18.1.
- Verify function existence, exact keyword names, required parent/container objects, callback calling convention, return values and object lifetime.
- Avoid large UI architecture changes before a minimal proof-of-concept is tested.
- If a symbol is undefined, do not keep retrying variants without evidence; isolate the environment and inspect supported references.

## 8. Reusable development workflow

1. Inspect `main`, current source and this knowledge base.
2. Confirm the user requirement and current version.
3. Preserve previous known-good code.
4. Make one small change.
5. Run static syntax/delimiter checks and inspect changed call signatures.
6. Ask the user to load the exact file in Modeling 18.1.
7. Capture exact error text or successful behavior.
8. Update the shared knowledge docs and test checklist.
9. Mark runtime status only at the evidence level actually achieved.

## 9. Scope not yet verified

Do not present these as implemented:
- Actual Material-property inquiry.
- Mass, Volume, bounding-box/dimension, custom attribute or other property filters.
- General dynamic filter-condition builder.
- UICT internal tab control compatibility and Apply hand-off in Modeling 18.1.
- New ver-03 implementation.


## 10. Recovered Annotation and drawing knowledge

A cross-chat skill package now records prior user-provided legacy sources and their reusable patterns:
- `Docu_load_frame`, `Docu_create_sheet`, `Docu_replace_frame`, current-sheet switching and frame inquiry are summarized in `skills/creo-elements-direct-modeling/references/02-annotation-sheets-frames.md`.
- BOM layout load/store and editing flows, plus attach-point patterns, are summarized in `references/03-bom-layouts-and-drawing-macros.md`.
- `Arrange_sheets`, `Arrange_sheets2` and `Arrange_views` demonstrate enumerate/filter/bounds/calculate/move/restore/cleanup patterns.
- These files use legacy Annotation/ME10 command language, not Modeling Lisp. Do not load them as Lisp or assume the commands are available outside Annotation.
- The sources carry CoCreate Software GmbH confidential/copyright markings; public GitHub stores summaries, not full source dumps.

## 11. Initial measurement/export and frame catalogue investigations

- On 2026-10-09, drawing measurement, data export and Ribbon/menu access were discussed. `measure_export.lsp` and `measure_export_avail_cmds.cmd` were preliminary concepts; real measurement API calls were not verified.
- On 2026-10-16, the user wanted multiple A4 frames in the Annotation workflow. The reviewed sheet/frame source proves frame loading, sheet creation and frame replacement, but does not reveal the UI frame catalogue registration mechanism.
- `docu-register-frame` and `am_customize` were suggestions, not verified APIs; the user reported `am_customize` unavailable.
- Do not use these as established facts. See API Verification Register and skill references.

## 12. API evidence and language separation

The canonical API status is maintained in `docs/API_VERIFICATION_REGISTER.md`. In particular, the user reported on 2026-11-14 that one-argument `sd-inq-part-density` returned `1000.0` (`LONG-FLOAT`) for Part `010-plate_2.1.1.2.1`; this does not alone establish the semantic mode. The explicit `:instance` and `:contents` calls remain the production filter's tested pattern.


## 13. Part Filter: same-Browser Apply ownership and ver-04 page prototype (2026-11-16)

- ver-02's visible Results Graphical Browser is itself the selection context. The visible result rows, selected BrowserNodes and native Apply/OK button all belong to the same Browser instance.
- ver-03 UICT Display Table can identify real Part SEL_ITEM values, but transferring those values into a second hidden Browser does not reproduce ver-02's native Apply behavior. BrowserNode counts, :SUCCESS trace markers and Dialog Generator persistent highlight are not proof of Modeling selection.
- The current diagnostic candidate uses one Graphical Browser Tree with a page root per Density pair. The children of the active table root are the visible Part rows. Switching the table root keeps row selection and native Apply within the same Browser instance.
- Page selection is stored as Part path strings and restored only after the corresponding page root is active. The diagnostic offers Previous/Next toolbar buttons and a dynamic Results Pages popup submenu. This is not yet the final horizontal-tab UI.
- Diagnostic file: `src/part-filter/ver-04/diagnostics/H871_PF_V04_SINGLE_BROWSER_PAGES_DIAG.lsp`.
- Modeling 18.1 runtime validation is pending. Only actual 3D viewport selection after native Apply counts as success.


## 14. ver-04 single-Browser runtime feedback and lifecycle recovery (2026-11-16)

The first Modeling 18.1 test confirmed that the ver-04 diagnostic can hide the ver-03 UICT shell and open exactly one native Graphical Browser displaying the active page's Parts. The trace showed two copied pages: CNC-SS400 (8 Parts) and CG-SS400 (2 Parts). The trace stopped after DIAG/PAGES-COPIED; it contains no evidence of page navigation, selection restoration or Apply.

A second diagnostic invocation failed because the named Browser Tree already existed. The source had no normal successful-run teardown path. The revised diagnostic adds h871-pf-v04-reset-browser-objects: hide/destroy the Browser, then destroy its Tree, clear node maps, and trace the cleanup attempt. It runs before rebuilding and from Close Results. Close Results restores the ver-03 UICT shell. Recovery command: H871_PF_V04_RESTORE_UICT_RESULTS.

The cleanup patch is static-checked only. Do not infer that the destroy APIs work correctly in Modeling 18.1 until retested. The one-Browser native Apply hypothesis remains unverified until the user sees the actual Part selected in the 3D viewport. Do not change ver-01/ver-02/ver-03 production code or Density mapping while validating this lifecycle fix.


## 15. ver-04 persistent return path and page-navigation tracing (2026-11-16)

The first runtime feedback confirmed Close Results restores the old ver-03 UICT shell. The missing usability step was reopening the native Browser without re-running a command. ver-04 now installs a uniquely named `Open Native Results` pushbutton in the existing UICT grid. Its callback calls the Browser rebuild function, which snapshots the latest UICT pages and selections before resetting/recreating the native Browser. The launcher is installed only if `sd-control-p` reports that its control name does not already exist.

Previous/Next callbacks now log `PAGE/NAVIGATION-REQUEST` and `PAGE/NAVIGATION-TARGET`, allowing a runtime trace to distinguish actual button callback invocation from the initial page activation during Browser startup. Existing right-click Results Pages submenu remains.

Static source check passed, but target-version runtime verification is still required for button placement, pushAction callback, repeat close/reopen, page navigation and viewport Apply. A non-NIL `SELECT-AND-EXECUTE-SUCCESS-CONTEXT` is diagnostic evidence only, not proof that the viewport selection changed.

## 16. Part Filter ver-05 – one Browser owns search, pages and native selection (2026-11-16)

ver-05 is the first self-contained candidate that removes the ver-03 UICT page dependency. It uses the ver-02 recursive Assembly collector and Process/Material mapping, then stores each exact numeric Density Instance/Base pair in a page record. One Browser Tree contains one page root per pair, and one Graphical Browser displays the active page. Native Apply is not overridden; the visible Browser rows and selection are intended to be the same native context that ver-02 proved.

Page rules:
- new pair → new page;
- same pair → refresh that page and clear its old selection;
- no match → leave existing pages unchanged;
- page navigation → save/restore selected Part paths per page.

Current navigation is Previous/Next plus the Results Pages popup, not a horizontal tab strip. This is intentionally honest about the gap between multiple data pages and a true tab bar. ver-05 is static-checked only; all Creo 18.1 behavior, especially actual viewport Apply, remains to be user-tested.

