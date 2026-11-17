# H871 Part Filter VER-03-PARTNOTE

**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Branch:** `feature/part-filter-ver03-partnote`  
**Base source:** `main:src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp`  
**Base blob:** `45b39cbad1271fd083622380f5764c3c92a1548c`  
**Candidate source:** `H871_PART_FILTER_VER_03_PARTNOTE.lsp`  
**Runtime status:** Source created and statically checked; Modeling 18.1 integration test is pending.

## Purpose

Create a separate VER-03 variant that adds per-Part notes while retaining the completed VER-03 architecture:

- UICT Results window with internal tabs, one page per Density Instance + Density Base pair.
- Multi-column UICT Display Table and hidden logical-table `:part-object` values.
- Select All and Clear Selection scoped to the active result page.
- Explicit Apply button using the existing VER-03 native Graphical Browser Apply Bridge and queued Modeling User Action.

This variant is deliberately **not** based on the VER-06 Native Results Browser. VER-06 remains a separate architecture and is not merged into this source.

## Part Note implementation

- UDA name: `H871_PART_FILTER_NOTE`
- Key: `:note`
- Attachment: `:instance` (each Part instance owns its own note)
- Filing: `:sd-file` (attribute is filed with the Modeling model)
- Adds a visible `Part Note` column to each VER-03 result page.
- Adds an `Edit Note` button to each result page.
- Edit Note requires exactly one selected result row.
- The selected real Part object is read from the same hidden `:part-object` logical-table column already used by Apply.
- The interactive editor is launched with `sd-put-buffer` after the UICT callback returns. Do not replace this with nested `sd-call-cmds`.
- After saving, the active result page is refreshed through the existing VER-03 logical-table refresh routine.

## Protected behavior

The integration does not intentionally change:

- Density Instance/Base filter predicates or numeric mappings.
- Assembly traversal.
- Existing Results window and internal-tab architecture.
- Hidden Part object storage used by Apply.
- Select All / Clear Selection behavior.
- Apply Bridge construction, BrowserNode hand-off, or queued Apply User Action.
- Original VER-03 source on `main`.

## Static checks performed

- Source was generated from the exact VER-03 source blob listed above.
- Note UDA read/write functions and the VER-06.2 proven `sd-put-buffer` dialog-launch pattern were adapted and renamed into the VER-03 namespace.
- The logical-table schema, row contents, and visible table columns were extended consistently with a string Note field while keeping `:part-object` as the final hidden object field.
- LISP parenthesis/string scan: balanced; no negative depth; no unterminated string.
- These checks do not establish runtime compatibility or behavior in Modeling 18.1.

## Modeling 18.1 test plan

Use a disposable Assembly and save a copy before testing.

1. Load `H871_PART_FILTER_VER_03_PARTNOTE.lsp`.
2. Run `H871_PART_FILTER_VER_03` (the existing VER-03 command symbol is retained).
3. Search a known pair such as CNC-SUS304 (numeric Instance/Base = 1/304).
4. Confirm the Results window and internal tabs behave as in the existing VER-03.
5. Confirm the new Part Note column is visible.
6. Select exactly one Part row and click **Edit Note**.
7. Confirm the editor opens and pre-fills the existing note (or blank if none).
8. Enter a note and save. Confirm the Part Note cell updates.
9. Edit a second Part with a different note; confirm the first note remains associated with the first Part.
10. Save the model to a new file, close and reopen it, rerun the filter, and confirm both notes remain attached to the correct Part instances.
11. Regression-test Apply on one selected Part and on multiple selected Parts.
12. Regression-test Select All and Clear Selection on the active page.
13. Switch between two result tabs and confirm Note editing targets only the selected Part on the intended page.

Stop and capture the exact Modeling error/trace if any UICT table creation, dialog launch, UDA write, refresh, or Apply operation fails. Do not modify the Apply Bridge as a workaround for a Note-specific issue.

## Evidence discipline

The source and README are committed, but the candidate is not yet runtime-validated. Mark each test as passed only after observing it in Creo Elements/Direct Modeling 18.1. Preserve VER-03 on `main` and preserve VER-06 Native Results Browser as an independent development line.

## Right-click actions add-on

An optional companion file now adds a separate Native Graphical Browser for right-click actions while preserving the VER-03 UICT Results table and Apply Bridge:

- Add-on: `H871_PART_FILTER_VER_03_PARTNOTE_RIGHTCLICK_ADDON.lsp`
- Load the original `H871_PART_FILTER_VER_03_PARTNOTE.lsp` first, then load the add-on.
- The auxiliary Browser mirrors the currently active VER-03 Results tab and displays Part Name, Density Instance, Density Base, Assembly Path, and Part Note.
- Right-click a Part row in the auxiliary Browser for `Edit Note`, `Select All`, and `Clear Selection`.
- `Edit Note` requires exactly one selected Part and reuses the existing instance-level UDA editor.
- The original Edit Note button under the UICT table remains available.
- Switching Results tabs or refreshing/saving a Note rebuilds the auxiliary Browser for the active tab.
- The auxiliary Browser uses its own tree and selection; it does not reuse or modify the hidden Apply Bridge tree.

### Add-on test sequence

1. Load the base VER-03-PARTNOTE LISP file.
2. Load the RIGHTCLICK_ADDON LISP file.
3. Run `H871_PART_FILTER_VER_03` and perform a known filter search.
4. Confirm both the original UICT Results window and the separate `H871 - VER-03 PART ACTIONS` Browser appear.
5. Right-click a Part row in the auxiliary Browser and confirm the menu contains Edit Note, Select All, and Clear Selection.
6. Select one Part, right-click, choose Edit Note, save a note, and confirm the Part Note column refreshes.
7. Switch to another Results tab and confirm the auxiliary Browser follows that tab.
8. Regression-test the original UICT Edit Note button, Select All, Clear Selection, and Apply Bridge.

**Runtime status:** The add-on has passed a static LISP parenthesis/string scan. It has not yet been executed in the user's Modeling 18.1 session; treat it as a test candidate until the sequence above is confirmed.


## 2026-11-17 — Resizable Results Window

- Replaced the fixed UICT dialog shell with `sd-create-resizable-dialog-shell` (initial client size 920 × 560 px).
- Replaced the fixed content grid with a resizable grid and bound the internal tab control to resize with it.
- Added best-effort resize bindings for each page's Display Table and status line; action buttons are anchored to the lower-left edge.
- The first run after loading this revision intentionally destroys the old fixed-size Results shell and clears its in-memory page registry; run the filter again to rebuild the result tabs. This avoids retaining an old non-resizable shell under the same UICT handle.
- Static source check passed: balanced parentheses, no unterminated strings. **Not yet runtime-tested in Creo Elements/Direct Modeling 18.1.** In particular, verify that the tab page's Display Table binding is accepted and actually stretches with the window; UICT binding behavior can vary by control parent/version.
- The standalone Edit Note button and original Apply Bridge logic remain in the same source; no Right-click Add-on is required.


## 2026-11-17 — Persistent UICT Failure and Resize Diagnostics

- Changed the trace file from overwrite-per-filter to append-per-filter. Each run now receives a sequential run number, so a successful retry no longer erases the earlier failing run.
- Added explicit trace records around sd-insert-tab-control-page, including its return value and the existence checks for the tab handle and its -TAB-GA page grid.
- Added trace records for each resize binding. The helper captures both the return value and any condition raised inside ignore-errors, rather than silently discarding binding failures.
- Added post-creation state checks for the page grid, Display Table, status line, and action buttons.
- This is diagnostic instrumentation only. It does not change filter predicates, logical-table contents, Apply Bridge behavior, Note storage, or the tab creation strategy.
- Static check: source parentheses balanced (921 opening and 921 closing parentheses); no runtime test has yet been performed after this instrumentation.
- Next test: load this source, run the pair that fails on the first filter, then run a second pair if needed. Send the complete H871_PART_FILTER_VER_03_TRACE.txt; it now retains both runs.

### Resize architecture finding

PTC UICT documentation states that sd-set-control-binding applies only to an intermediate child control of a resizable grid area. A tab page's -TAB-GA is documented as a regular page grid whose size is automatically determined by the parent tab control. Therefore, applying bindings directly to the page's Display Table and buttons may be rejected; the previous source hid those failures with ignore-errors. The new trace records will confirm this in the user's runtime.

The next layout revision must be based on the actual Modeling 18.1 behavior and a supported UICT parent/binding hierarchy. Do not claim that the Display Table can resize until the user confirms that the table itself expands. Reference: PTC UICT Creation of UI Controls and Specific UI Control Utility Functions (resizable grid areas, tab pages, and sd-set-control-binding).
