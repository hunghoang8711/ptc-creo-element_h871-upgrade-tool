# Part Filter ver-03 – Single Results Window with Internal Tabs

**Current revision: ver-03.1 – multi-column Display Table + explicit Apply.**  
**Status: committed to `main`; Creo Elements/Direct Modeling 18.1 runtime validation pending.**

## Authoritative requirement

Build exactly one separate Results window. Inside that window, provide horizontal tabs/pages similar to a desktop browser. Do not create multiple user-facing Graphical Browser windows and do not use Creo Browser Bar tabs.

## Page identity and lifecycle

- Key: exact pair `Density Instance + Density Base`.
- Caption: mapped Material + Machining Process, e.g. `SUS304-CNC`.
- First search for a pair creates its page.
- Repeating the same pair refreshes/replaces the existing page; no duplicate tab.
- A different pair creates a new page in the same window.
- Each page owns its result data and selection.
- No-match does not silently erase an existing valid page.

## ver-03.1 result table

Each page uses a UICT Display Table backed by its own logical table.

Visible columns:
1. Part Name
2. Density Instance
3. Density Base
4. Assembly Path

An additional hidden/unshown untyped `:part-object` column stores the actual Part object for Apply. Rows are not concatenated text strings.

## Selection and buttons

- Multi-row selection is enabled.
- **Select All** selects all rows in the active page only.
- **Clear Selection** clears only the active page.
- **Apply** transfers only selected Part objects from the active page.
- Status line reports total Parts and selected count.
- Re-running the same Density pair refreshes its table and clears its previous selection to avoid stale object references.
- Selection state in other tabs is independent.

## Logical-table recovery (ver-03.2)

A Modeling 18.1 runtime test exposed: `A logical table with name "" does not exist`, followed by the Results refresh error. The page registry is held in global variables and can survive a LISP reload; older in-memory page records may therefore lack the newer `:logical-table` field. The refresh path now derives the logical-table name from the stable page ID when that field is missing, validates the name, recreates a missing logical table, verifies the Display Table binding, and restores the Display Table control if its binding is stale. The refresh error now reports the concrete logical-table name rather than hiding it behind a generic message.

## Apply implementation

Apply reads selected row values using `sd-get-display-table-selection`, retrieves the hidden `:part-object` column, and builds BrowserNodes for those Part objects using their Modeling paths. It then uses the native Graphical Browser commands `:set-object-selection` and `:select-and-execute`, matching the known-good ver-02 selection hand-off pattern.

The ver-02 Apply workflow is user-confirmed in Modeling 18.1. The new hidden bridge from Display Table to Graphical Browser is not yet runtime-tested in 18.1. If it fails, keep ver-02 as the known-good fallback and diagnose the exact bridge stage; do not substitute a guessed selection API.

## Technical compatibility boundary

PTC's official 20.7 Integration Kit documentation covers UICT Display Tables, logical tables and multi-row selection. The exact signatures in Modeling 18.1 are not yet confirmed. The tab shell and page flow were already confirmed by the user in 18.1; this revision changes the row-control implementation and adds the Apply bridge, both requiring runtime validation.

References:
- [UICT control creation](https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/reference/uict_create.html)
- [Logical and Display Tables](https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/reference/tables.html)
- [Graphical Browsers](https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/reference/gbrowser.html)

## Runtime test

1. Load `H871_PART_FILTER_VER_03.lsp` in Modeling 18.1.
2. Run `H871_PART_FILTER_VER_03`.
3. Search CNC + SUS304; verify four separate columns.
4. Click one row; verify selected count is 1.
5. Ctrl-click/Shift-click multiple rows.
6. Select All; verify all rows in this tab are selected.
7. Clear Selection; verify zero selected.
8. Select a subset and press Apply; verify only those actual Parts are selected in Modeling.
9. Switch tabs and verify each page's selection is independent.
10. Refresh an existing pair; verify its table updates and selection clears.
11. Search a no-match pair; verify existing tabs remain.

If the Display Table fails to load, capture the exact error. If Apply fails, report whether the bridge browser was created and provide the exact error/status.


## ver-03.2 follow-up – explicitly reject empty-string metadata

A retest showed the empty logical-table error persisted. Root cause in the first recovery patch: Common Lisp treats the empty string as truthy, so `(or stored-name fallback-name)` incorrectly retained an explicitly empty `:logical-table` value. The refresh code now accepts the stored name only when it is a string with length greater than zero; otherwise it derives the name from the non-empty page ID. This directly addresses the reported `name ""` case. Modeling 18.1 runtime retest is still required.
