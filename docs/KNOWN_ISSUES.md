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


## KI-012 – ver-03 rebuild Stage 0 runtime validation

- **Status:** Source baseline created; Modeling 18.1 runtime validation pending.
- **Decision:** Rebuild ver-03 from the user-confirmed ver-02 native Graphical Browser workflow. Do not continue patching the unstable UICT-based ver-03 branch/source until the root cause is independently understood.
- **Branch:** `rebuild/ver-03-from-ver-02`.
- **New source:** `src/part-filter/ver-03-rebuild/H871_PART_FILTER_VER_03_REBUILD.lsp`.
- **Isolation:** New helper/global symbols use `h871-pf-rb-`; new dialog command is `H871_PART_FILTER_VER_03_REBUILD`. This avoids redefining ver-02's functions and dialog when both are loaded.
- **Stage 0 scope:** Same Filter dialog, numeric Density Instance/Base matching, native Graphical Browser, row selection, Select All, Clear Selection, and native Apply as ver-02. No UICT Display Table, internal tabs, logical tables, or hidden Apply bridge.
- **Test requirement:** Load and test only on a disposable model copy. Verify one known filter pair, one-row Apply, multi-row selection, Select All, Clear Selection, and normal dialog close.
- **Gate:** Do not add tabs or other new features until the user confirms Stage 0 works in Creo Modeling 18.1.
- **No runtime claim:** Creating the source clone and static review do not establish that it works in the user's installation.


## KI-013 – Stage 1 native multi-filter tabs compatibility

- **Status:** Implemented; Modeling 18.1 runtime validation pending.
- **Baseline:** Stage 0 was user-confirmed working on 2026-11-16: Results display, Select All, Apply, and double-click single-Part selection.
- **New source:** `src/part-filter/ver-03-stage1/H871_PART_FILTER_VER_03_STAGE1.lsp`.
- **Design:** One dedicated native Graphical Browser and Browser Tree per unique numeric Density Instance/Base pair, requested as a docked Browser Bar tab using `:createAsTab t`.
- **Isolation:** Each browser has its own tree and browser name. Same pair replaces only its own browser/tree; different pairs retain separate tabs; no-match leaves previous tabs untouched.
- **Selection:** Native browser Apply and double-click remain unchanged. Select All/Clear Selection callbacks receive the owning browser name to avoid cross-tab targeting.
- **User runtime result (2026-11-16):** Pressing Search OK immediately produced Fatal Exception `0xC00000FD`. Closing the message left Modeling and the model apparently usable, matching the earlier incident; no Results Browser appeared.
- **Investigation:** The filter dialog opens, so the failure is after the OK action starts. Stage 1's result collection and Density matching were cloned from the Stage 0 baseline. The key new Browser Tree API difference was use of the later-version `:update-args` option with a two-argument callback.
- **Correction (source only; runtime pending):** Removed `:update-args`. Each unique tree now registers a unique zero-argument callback closure that captures its own tree name and Density-pair key, matching Stage 0's zero-argument updater convention. Added trace milestones to `H871_PART_FILTER_STAGE1_TRACE.txt` in the Modeling user's home directory.
- **Remaining compatibility risk:** `:createAsTab` remains based on later-version PTC documentation and is not yet verified in Modeling 18.1. PDS preferences may override initial docking behavior.
- **Required retest:** Use a disposable model copy. Run one CNC-SUS304 search. If the exception repeats, close the message and report the last line in `%USERPROFILE%/H871_PART_FILTER_STAGE1_TRACE.txt`; it localizes the last completed stage. If successful, test a second pair, same-pair refresh, no-match preservation, double-click, Select All, Clear Selection, and Apply.
- **Safety:** Stage 0, ver-01, and ver-02 source files remain unchanged. Do not proceed to Stage 2 until user confirms.


## KI-014 – Stage 1 Search fatal exception and diagnostic reset

- **Status:** Isolated `:createAsTab t` test passed basic runtime/functionality; visible tab behavior still needs confirmation.
- **Runtime evidence:** User reports Fatal Exception `0xC00000FD` immediately after Search OK; Results Browser does not appear. Removing Browser Tree `:update-args` and using unique zero-argument callbacks did not resolve it.
- **Trace finding:** `H871_PART_FILTER_STAGE1_TRACE.txt` was created once but remained 0 KB and was not updated on a subsequent search. The trace writer used `ignore-errors`, so it can silently fail. An empty trace is inconclusive and must not be used to infer the last executed stage.
- **Current isolation step:** Active Stage 1 source is now a mechanical clone of the user-confirmed Stage 0 source, with only the helper/global prefix and dialog command renamed. Multi-browser sessions, callback closures, `:createAsTab`, `:tabname`, and file tracing have been removed.
- **User runtime result (2026-11-16):** User loaded and tested the current Stage 1 diagnostic source in Creo Modeling 18.1. Search completed successfully, and its functionality is the same as Stage 0. The user explicitly confirmed that no new feature is present yet.
- **Conclusion:** The Stage 0-equivalent Stage 1 source and its renamed command/helper prefix work in the user's environment. The earlier `0xC00000FD` is therefore associated with one or more removed multi-browser/tab-related changes, but the exact failing API/expression is not yet identified.
- **User runtime result (2026-11-16):** User tested the Stage 1 revision containing only `:createAsTab t`. It runs successfully and retains the same filtering/selection/Apply functionality as Stage 0; no `0xC00000FD` was reported.
- **Interpretation:** The option is accepted without breaking the existing single-browser workflow. This test does not yet establish whether the Browser is visibly presented as a tab, because the user described the functionality as the same as Stage 0.
- **Next step:** Confirm whether the Results Browser is actually shown as a tab or remains a separate window. Do not add multiple browsers or more tab arguments until this behavior is clear.
- **Preservation:** Stage 0, ver-01 and ver-02 source files remain unchanged. The current Stage 1 single-browser baseline is now user-runtime-confirmed.


## KI-015 – Stage 1 Browser remains floating despite createAsTab

- **User runtime result (2026-11-16):** Results Browser still appears as a separate floating window. Searching a different Density pair refreshes/replaces the displayed Results window. Core filter/selection/Apply behavior remains successful.
- **PTC API finding:** PTC Graphical Browser reference documents that `:createAsTab t` requests an initially docked Browser, but the setting can be overwritten by the docking preference saved in PDS from the previous Modeling session. The same reference documents `sd-dock-graphical-browser` as the explicit API to dock a floating Browser into the Browser Bar.
- **Next isolated experiment:** After the existing `sd-show-graphical-browser` call, Stage 1 now calls `(sd-dock-graphical-browser *h871-pf-mt-browser-name* :show t)`. This is wrapped in `ignore-errors` so an unavailable/rejected docking API cannot prevent the already-working floating Results window from opening.
- **Scope:** One Browser and one Browser Tree only. No second result session, unique tab per pair, `:tabname`, callback changes, filter changes, or selection/Apply changes.
- **Static status:** Source patch committed; parenthesis/API availability not yet runtime-verified in the user's Modeling 18.1 installation.
- **User test required:** Run one known matching pair. Confirm whether Results is now docked in the Browser Bar and whether row selection, Select All, double-click and Apply still work. If it remains floating, report whether any error appears; because the docking call is protected, the window should still be available if the API is unsupported.
- **References:** PTC Creo Elements/Direct Modeling Integration Kit, Graphical Browsers reference (20.6/20.7 documentation; exact 18.1 runtime compatibility still requires user test).
