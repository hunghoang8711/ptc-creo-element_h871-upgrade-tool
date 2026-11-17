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
