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


## KI-013 – ver-04 Browser/Tree lifecycle and UICT recovery

- **Status:** User-confirmed lifecycle defect; source recovery patch committed, Modeling 18.1 retest pending.
- **Observed:** First run opened one Graphical Browser and displayed the active ver-03 page. On a second invocation, sd-create-browser-tree reported that H871-PF-V04-SINGLE-RESULTS-TREE already exists. The supplied trace ends immediately after DIAG/PAGES-COPIED, listing CNC-SS400 (8 Parts) and CG-SS400 (2 Parts); no page-switch or Apply stage was recorded.
- **Cause established:** The diagnostic created named Browser/Tree objects but had no normal teardown/reinitialization path. Closing/hiding the window did not guarantee that the named Tree was destroyed before the next create call.
- **Patch:** Added a single reset routine that attempts to hide/destroy the Graphical Browser first and then destroy its Browser Tree. It runs before each new tree creation and from Close Results. Close Results then restores the existing ver-03 UICT shell. Added command H871_PF_V04_RESTORE_UICT_RESULTS.
- **Not yet verified:** The destroy calls and restore command must be tested in Modeling 18.1. This patch does not establish that page switching, selection restoration or native Apply works.
- **Next test:** Load the updated diagnostic; use Close Results / H871_PF_V04_RESTORE_UICT_RESULTS to return to ver-03; run the diagnostic twice in succession; verify no duplicate-tree error; then test Previous/Next and native Apply on a disposable model.


## KI-014 – ver-04 return navigation and page-navigation callbacks

- **Status:** Persistent UICT launcher and navigation tracing committed; Modeling 18.1 retest pending.
- **User-confirmed baseline:** Close Results returns from the native ver-04 Browser to ver-03 UICT. Previously, reopening the native Browser required re-running `H871_PF_V04_SINGLE_BROWSER_PAGES_DIAG`.
- **Patch:** ver-04 now installs a persistent `Open Native Results` button in the ver-03 shell grid. The button calls the diagnostic entry point, which captures the latest UICT page state, resets stale Browser/Tree objects and recreates the native Results Browser. It should remove the need to manually re-run the LISP command after returning to UICT.
- **Navigation diagnostics:** Previous/Next now log `PAGE/NAVIGATION-REQUEST` and `PAGE/NAVIGATION-TARGET`; the existing Results Pages context submenu remains available. These markers will show whether the controls invoke their callbacks.
- **Unverified:** UICT button placement/callback, repeat close/reopen, user-operated page switching and actual viewport selection after Apply.
- **Next test:** Load updated ver-04; run once to install the button; Close Results; click `Open Native Results` in ver-03; confirm it reopens without a command; then use Previous/Next and right-click Results Pages and inspect the trace markers.

## KI-015 – ver-05 runtime and horizontal-tab verification pending (2026-11-16)

- New source `src/part-filter/ver-05/H871_PART_FILTER_VER_05.lsp` is a self-contained single-Graphical-Browser candidate.
- Static source structure and local helper references pass checks, but no Modeling 18.1 runtime test has been performed.
- Native Apply, popup menu navigation, Previous/Next, page-local selection restore, same-pair refresh, no-match preservation and repeated search lifecycle remain unverified.
- The current page UI uses Previous/Next plus a Results Pages popup, not the final horizontal tab strip requested by the user.
- Do not fall back to a second Results window, UICT launcher, hidden Browser bridge, or custom Apply callback to solve these issues.
- Use a disposable model copy. If Search crashes, capture the exact ver-05 trace and error before changing traversal; retain ver-02's known-working recursive collector until evidence indicates otherwise.

### KI-015 follow-up – horizontal modeMenu compatibility

ver-05 now uses Graphical Browser `:modeMenu` as a horizontal page-button row. The detailed API reference found is for a later Elements/Direct release, not 18.1. Confirm that the mode menu is accepted, page buttons render horizontally, switching invokes the correct page callback, and the active button state follows the selected page. If the modeMenu is unsupported, retain the same single Browser and use the existing popup selector while investigating a verified 18.1-compatible horizontal UI. Do not create a second Results window.



## KI-016 – ver-05 page switching could retain multiple table roots (2026-11-16)

Symptom/risk: ver-05 switched to a new page by calling :change-table-root without clearing the previous table root. Graphical Browser supports multiple table roots; previous page rows could remain visible alongside the active page. This would also make Select All and native Apply unsafe because they operate on visible/selected BrowserNodes.

Correction: h871-pf-v05-activate-page now buffers redraw, clears selection, calls :clear-table-roots, sets only the requested page root, resumes redraw and logs :number-of-table-roots.

Evidence: source-level defect is confirmed. The clear-roots command sequence is documented in PTC Graphical Browser 20.6; exact Modeling 18.1 behavior remains unverified.

Required runtime test: after every page switch, confirm only the active page's rows are visible and the trace reports exactly one table root. Then select one/multiple rows and verify native Apply selects only those Parts in the 3D viewport. Test on a disposable Assembly copy.


KI-016 follow-up: ver-05 now checks that :clear-table-roots and :change-table-root both succeed before considering the page active. If either fails, it stops page activation (fail-closed) instead of risking mixed results. The table-root count inquiry is diagnostic-only and guarded with ignore-errors. Latest source commit: 30d679156b879339cdefd1a922649feb4a937bd4.


ver-05 caption follow-up: the page label order was corrected from MATERIAL-PROCESS to PROCESS-MATERIAL (CNC-SUS304). This is a presentation correction only; Density search logic is unchanged. Source commit: 8a189bb6ec8e44234b5b6607deb8600af3541c0a.


## KI-017 – ver-05 page selectors were attached to modeMenu instead of visible buttonMenu (2026-11-16)

**Symptom:** The Results window looked like ver-02 and showed no horizontal Density page selectors.

**Root cause:** PTC Graphical Browser reference states that modeMenu is mapped to right-click popup entries; buttonMenu creates the visible horizontal row. ver-05 incorrectly used modeMenu for the page selectors.

**Correction:** Generate page selector buttons dynamically in :buttonMenu and append Select All/Clear Selection. Remove the incorrect modeMenu page selector and duplicate popup menu installation. Source commit: ca85cf158cdb345381f989f46f3e6cadbfe9bdc4.

**Verification:** Static source checks passed. Must test in Modeling 18.1: after two successful searches, two horizontal page buttons must be visible in the same Results Browser, and clicking each must switch to only that page's Parts. Do not treat source inspection as runtime proof.


## KI-017 correction – modeMenu is a horizontal row

The previous KI-017 root-cause statement was incorrect. PTC's Graphical Browser reference explicitly documents modeMenu as a row of toggle buttons directly above buttonMenu. Both are also mapped to right-click popup entries for compatibility. Therefore modeMenu was valid in principle; moving page buttons to buttonMenu was not a proven fix and has been reverted. Source commit 7763d35 restores modeMenu and adds diagnostic trace markers. The reason the user did not see page buttons remains unresolved and must be diagnosed from the generated menu spec and runtime behavior.


## KI-018 – ver-03 Apply hand-off still requires runtime verification (2026-11-16)

The user has reaffirmed ver-03 as the accepted Results UI: one window with internal Density-pair tabs and direct row selection. The current ver-03 source was found still passing raw `sd-create-browsernode` return tokens (for example `#:NODE241`) into `:set-object-selection`, despite an earlier documentation note claiming the conversion had already been applied.

Correction committed in source: root and Part node IDs are now resolved using `sd-get-browsernode-struct`; only resolved structures are stored/passed to Browser selection APIs. The source logs root resolution, each Part-node resolution and the resolved count, and fails closed if any selected Part cannot be resolved.

**Not verified:** whether the hidden temporary Browser bridge can transfer those selected Parts into Modeling's actual selection context. Previous investigations found hidden/offscreen Browser hand-off unreliable. A successful BrowserNode lookup or `:select-and-execute` status is not acceptance evidence. User must verify the selected Parts are visibly selected in the 3D viewport.

Next test: load the updated ver-03 source in a fresh Modeling 18.1 session, search a known pair, select one row, Apply, then repeat with multiple rows. Capture `H871_PART_FILTER_VER_03_TRACE.txt` and report actual viewport selection. Do not change the ver-03 UI or filter collector while diagnosing this boundary.


## Critical direction correction – UICT ver-03 is not the active base (2026-11-16)

The prior note recommending continued development from UICT ver-03 is superseded. That path is associated with fatal exception `0xC00000FD` and must not be loaded as the current candidate. The attempted BrowserNode ID resolution in commit `068ee4123b5aadf6cde5bce54321f1ee031ea064` only modifies the obsolete UICT hidden Apply bridge; it does not address the fatal search path and is not the active solution.

Use these separate evidence boundaries:
- Stage 0 native Graphical Browser: user-confirmed direct row selection, Select All and native Apply selecting actual Parts.
- ver-04 single-Browser page-root diagnostic: user-confirmed page switching and restoring row selection for `CG-SS400`; its Apply trace status alone is not proof of viewport selection.
- ver-05: integration candidate; horizontal page selector behavior in Modeling 18.1 remains unverified.

Target is one standalone visible Results Browser combining Stage 0 native selection/Apply with ver-04 page-root logic. No intermediate-window workflow, UICT/hidden bridge, Browser Bar docking, extra Browser per search, or reparenting.
