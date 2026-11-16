# Known Issues and Verification Gaps

Only unresolved or unverified items belong here. Move resolved root causes into `LESSONS_LEARNED.md`.

## KI-001 – Actual Material property inquiry
- **Status:** Not implemented / not verified.
- **Details:** ver-02 maps user-defined Material labels to Density Base values; it does not read a Part's actual Material property.
- **Next step:** Diagnose a known Part in Modeling 18.1 before implementing actual Material retrieval.

## KI-002 – Additional Part properties
- **Status:** Future scope.
- **Details:** Mass, Volume, dimensions, bounding-box values, structure metadata and custom attributes have not been validated as filterable properties.
- **Next step:** Verify API, return type, units and instance/base semantics individually.

## KI-003 – General filter-condition builder
- **Status:** Not implemented.
- **Details:** Dynamic add/remove conditions, comparison operators, text matching and grouped AND/OR logic are not part of the current exact Density-pair tool.

## KI-004 – Additional Results Browser behavior
- **Status:** Partially verified / not part of baseline.
- **Details:** Clear Selection visibility/functionality and repeat-search lifecycle have not been independently reconfirmed after all UI changes.
- **Next step:** Retest only when a new feature depends on them.

## KI-005 – ver-02 dialog details
- **Status:** Implemented; user reported very good results. Detailed regression coverage should still be recorded.
- **Details:** Mapped choice dialog uses `:range`, `:label`, `:after-input` and `:display-only`. Standard dialog positions code fields on separate rows. A same-row custom layout is not implemented.
- **Next step:** Preserve current mappings and dialog behavior. Re-test only if changing this area.

## KI-006 – ver-03 UICT compatibility and Apply runtime validation
- **Status:** Results UI runtime-confirmed by user; Apply remains unresolved after rollback.
- **Details:** One UICT Results window, internal tabs, multi-column table, and Apply button were user-confirmed working on the pre-rollback revision. The attempted BrowserNode identifier-resolution patch was rolled back after a separate Search-time fatal exception; it was never runtime-confirmed and must not be treated as a fix.
- **Compatibility gap:** UICT Display Table/logical-table APIs are documented in PTC 20.7/20.8 references; exact Modeling 18.1 availability/signatures are not all proven.
- **Next step:** In Modeling 18.1, select one result row and Apply, then select multiple rows and Apply. Verify only those actual Parts become selected. Capture the exact error if any.
- **Production boundary:** ver-01/ver-02 remain unchanged as known-good selection/apply baselines. Do not mark ver-03 Apply resolved until user confirms runtime behavior.

## Resolved baseline behavior

User-confirmed in Modeling 18.1: Results Browser opens and displays rows; Select All is present; clicking a row selects that Part; native Apply transfers selected Parts to Modeling selection.

## KI-007 – Annotation frame catalogue registration
- **Status:** Unresolved / not verified.
- **Details:** The recovered `am_sheet.m`-style source loads, creates and replaces frames but does not show how the Annotation UI frame list is populated. `docu-register-frame` was only a hypothesis; user reported `am_customize` unavailable.
- **Next step:** Trace the installed 18.1 frame selection dialog and built-in frame discovery mechanism before adding multiple A4 options.

## KI-008 – Geometry measurement and export APIs
- **Status:** Unverified.
- **Details:** Initial measurement/export and command access concepts were discussed on 2026-10-09, but no real Modeling 18.1 geometry measurement API/signature/units were confirmed.
- **Next step:** Build a minimal diagnostic on a known test part and verify one geometry inquiry at a time before implementing export.

## KI-009 – Official 18.1 Integration Kit manual availability
- **Status:** Not found in currently accessible Library inventory.
- **Details:** Recovered user files are legacy Annotation macro sources and a Part Filter diagnostic; no standalone official 18.1 Integration Kit PDF was surfaced.
- **Next step:** If an official manual exists in older chat storage or local files, retrieve it and record its exact release/source before using it as authority.

## KI-010 – ver-03 fatal exception on Search

- **Status:** Candidate stack-overflow mitigation committed; Modeling 18.1 runtime verification pending.
- **User-reported error:** `Fatal exception Oxc00000fd occurred at 00000000652A9F21. Model data may have been damaged.` It occurs immediately after pressing OK to Search, before Results UI appears.
- **Containment:** `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp` on `main` has been restored to commit `8c0a1cd56f25f125958080b3ab6316e55827b141`, the last source version associated with the user-confirmed Results window, tabs, table, and Apply button appearing. This rollback removes the two recent BrowserNode-resolution edits. It does not prove that the restored file is safe or that the Apply error is fixed.
- **Important:** The recent Apply patch changed the Apply tree builder and Apply guard, not the Search dialog or `h871-pf-v03-run`. The fatal exception during Search is therefore not yet causally explained. Do not claim the BrowserNode lookup caused the Search crash without a reproducer.
- **Next investigation:** Reproduce only on a disposable copy/model; inspect Modeling 18.1 call stack/log and trace file; isolate load-time, dialog OK-action, collect, shell, tab/page creation and refresh stages. Keep ver-01/ver-02 untouched. Do not run more tests against the original customer model.


- **Follow-up diagnosis (2026-11-16):** The active Search path called `h871-pf-v03-collect`, which recursively called itself for every child object and had no visited-object guard. Windows exception `0xC00000FD` is commonly associated with stack exhaustion, so this is a strong source-level candidate because collection runs before Results UI creation. It is not yet a proven root cause without a trace or controlled reproduction.
- **Candidate fix:** Replaced recursive traversal with iterative depth-first traversal using an EQ-based visited hash table. This avoids consuming one native/Lisp call frame per Assembly level and prevents revisiting the same object reference. Numeric Density matching and result ordering are preserved.
- **Static verification:** Parentheses balanced; no unterminated strings; collector no longer self-recurses. No Creo runtime test has been performed by the assistant.
- **Next step:** User must first save a separate disposable model copy and test this source there. If the exception persists, provide `H871_PART_FILTER_VER_03_TRACE.txt` and the exact last trace marker. Keep ver-01/ver-02 untouched.


## KI-011 – ver-03 Search fatal exception persists after iterative traversal

- **Status:** Unresolved; active source reverted to the last Results-UI-confirmed revision.
- **User retest (2026-11-16):** The iterative depth-first traversal change did not prevent the same Modeling fatal exception: `0xC00000FD`, occurring during Search before Results UI.
- **Conclusion:** The recursive collector was not established as the root cause. Do not continue treating stack recursion in `h871-pf-v03-collect` as the confirmed cause.
- **Containment:** Reverted the active ver-03 source to `8c0a1cd56f25f125958080b3ab6316e55827b141`, the last source revision associated with user-confirmed Results UI appearance. This is not a safety certification; Search must not be run on a production/original model.
- **Next evidence required:** Obtain the exact `H871_PART_FILTER_VER_03_TRACE.txt` generated by the failed run, plus whether the trace file timestamp updated during that run. Identify the last completed/entered marker before proposing another code change.
- **Investigation boundary:** Isolate Search dialog OK action, dialog variable values, recursive/iterative object inquiry APIs, report writing, shell creation, and tab/page operations one stage at a time on a disposable model. Do not change ver-01/ver-02.



## KI-012 – Native Apply with multiple result pages: single-Browser diagnostic pending

- Status: Diagnostic source committed; no Creo 18.1 runtime result yet.
- Known-good reference: ver-02's visible Results Graphical Browser uses its own native Apply/OK action. This is the only Apply path user-confirmed in Modeling 18.1.
- Failed architecture: ver-03 UICT Display Table selection copied into a separate hidden Graphical Browser did not reproduce native Apply. Do not revive the hidden bridge.
- New candidate: src/part-filter/ver-04/diagnostics/H871_PF_V04_SINGLE_BROWSER_PAGES_DIAG.lsp builds one Graphical Browser with one BrowserNode page root per existing ver-03 Density pair. It changes the table root to switch pages and leaves the native Apply action untouched.
- Navigation limitation: this diagnostic uses Previous/Next buttons and a right-click Results Pages submenu. It does not yet reproduce the requested horizontal tabs.
- Next test: Load ver-03, create at least two result pages, load the diagnostic, run H871_PF_V04_SINGLE_BROWSER_PAGES_DIAG, switch pages, select one Part and press native Apply. Verify the Part is actually selected in the 3D viewport. Then test multi-select, Select All/Clear Selection and page-local selection restoration.
- Safety: Run only on a disposable model copy. Do not claim success from tree creation, row display, Browser selected count or a SUCCESS trace; viewport selection is the acceptance test.
