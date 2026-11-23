# Part Filter – Filter All acceptance test

**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Source under test:** `src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES_FILTER_ALL.lsp`  
**Baseline:** `src/part-filter/ver-03/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp` (must remain unchanged)  
**Status:** Static checks passed; runtime acceptance pending.

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
| No-match range | Select a pair known to have no Parts | Select corresponding value | No empty page is created; existing Results pages remain unchanged |

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
