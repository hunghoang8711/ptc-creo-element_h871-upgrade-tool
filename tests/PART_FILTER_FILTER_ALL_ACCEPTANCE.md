# Part Filter – Filter All acceptance test

**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Source under test:** `src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES_FILTER_ALL.lsp`  
**Baseline:** `src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp` (must remain unchanged)  
**Status:** Filter All base behavior was user-confirmed in Modeling 18.1. The new per-Filter Results reset is source-edited and statically checked; its Modeling 18.1 runtime acceptance is pending.

## Installation

1. Use a disposable copy of a representative assembly; do not test against the original/customer model.
2. Load the Filter All extension Lisp file.
3. Run the existing command `H871_PART_FILTER_VER_03`. The dialog title and entry command remain unchanged.

## Functional cases

| Case | Machining Process | Material | Expected behavior |
|---|---|---|---|
| Existing single pair | CNC | SUS304 | Exactly the existing CNC-SUS304 page behavior |
| All processes | ALL | SUS304 | Only populated process/SUS304 pages appear |
| All materials | CNC | ALL | Only populated CNC/material pages appear |
| All combinations | ALL | ALL | Only populated pages among the 36 mapped pairs appear |
| Single pair after ALL | KH | SS400 | Existing individual filter still works |
| No-match range | Select a pair known to have no Parts | Select corresponding value | All previous Results pages are cleared; the Results window contains no stale rows or tabs |

## Results and regression checks

1. Confirm each page title follows the existing PROCESS-MATERIAL convention.
2. Confirm every Part on a page has the exact matching Density Instance AND Density Base; None must not be treated as zero.
3. Confirm a pair with no matching Part does not create a tab.
4. Repeat Filter All; populated pages refresh rather than duplicate.
5. Confirm pages are created in convention-table order.
6. Confirm the existing Density API multiplier behavior (default 1000.0; test 1.0 only on a workstation whose API values match Part Properties).
7. Confirm Select All, Clear Selection, Apply, Edit Note, Select All Pages, Clear All Pages and Apply All Pages.
8. Observe the actual 3D Modeling selection after Apply; a trace message alone is not proof.
9. Check the trace visited count to confirm the assembly is traversed once per Filter All invocation.
10. Confirm the existing single-pair search still follows its original path and defaults.

## Evidence boundary

Static source checks do not establish Creo 18.1 dialog compatibility or runtime behavior. Record actual results and errors before treating Filter All as production-ready.


## Results refresh across Assemblies (new acceptance cases)

Each Filter invocation must represent only the Assembly and filter values selected in that invocation. Previous Results pages must not survive into the new run.

1. Filter Assembly A with ALL + ALL and record its populated tabs.
2. Filter Assembly B with ALL + ALL where B contains fewer process/material pairs. Confirm tabs that existed only in A are removed; only B's populated pairs remain.
3. From the same Results window, filter Assembly B using one specific Process + Material pair. Confirm only that one result page remains.
4. Filter an Assembly with no matching Parts. Confirm all old tabs and rows are cleared and the Results window is empty.
5. Repeat Filter All. Confirm no duplicate pages are created.
6. After each reset, verify Select All Pages, Clear All Pages, Apply All Pages, per-page Apply and Edit Note still work.

**Safety expectation:** The current Assembly scan/report must complete before the old Results UI is destroyed. If cleanup APIs are unavailable or cleanup fails, the command must stop and report the failure rather than silently mixing old and new Assembly data.

## Results window close/reopen lifecycle regression

1. Load the latest Filter All LISP.
2. Filter Assembly A and wait for its Results pages to finish.
3. Close the Results window using its normal close button (the configured action hides the Dialog Shell).
4. Filter Assembly B. Expected: the reset removes the hidden old Results Dialog Shell and its child controls, then recreates Results with only B's populated pairs. No “previous Results tab control still exists” error should appear.
5. Repeat with the Results window left open before filtering Assembly C.
6. Test a no-match Assembly and confirm the recreated Results window is empty.
7. Regression-test row selection, Select All Pages, Clear All Pages, per-page Apply, Apply All Pages and Edit Note.

**Current status:** source correction and static syntax checks completed; Modeling 18.1 runtime acceptance pending. The use of `sd-destroy-dialog-shell` is based on later-release PTC documentation and must be verified in 18.1.
