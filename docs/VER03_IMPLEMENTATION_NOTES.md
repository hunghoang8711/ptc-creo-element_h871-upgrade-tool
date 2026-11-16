# H871 Part Filter ver-03 – Implementation Record

**Implementation milestone:** 2026-11-16  
**Branch:** `main`  
**Source:** `src/part-filter/ver-03/H871_PART_FILTER_VER_03.lsp`  
**Current revision:** ver-03.1 – multi-column Display Table + explicit Apply bridge  
**Status:** Implemented and committed; Modeling 18.1 runtime validation pending.

## What changed in ver-03.1

The user's first runtime test confirmed the single Results window and internal pages work, but identified three regressions: rows were concatenated into one text column, row clicks/Select All did not select Parts, and there was no explicit Apply action.

The source has now been revised:

- Replaced each page's List Control with a multi-column UICT Display Table.
- Visible columns are **Part Name**, **Density Instance**, **Density Base**, and **Assembly Path**.
- A hidden untyped logical-table column stores the actual Part object; the UI shows no object token.
- Display Table uses `:multiple-rows` selection mode.
- Added page-scoped **Select All**, **Clear Selection**, and **Apply** buttons.
- Selection count is displayed per page.
- Repeating a pair updates the existing logical table in place and clears stale selection; other pages are not changed.
- Apply reads the selected `:part-object` values from the active page only.
- Apply builds a temporary, non-user-facing Graphical Browser bridge and uses the native Graphical Browser selection commands already used by ver-02: `:set-object-selection` and `:select-and-execute`.
- The one Results window and its internal tabs remain the user-facing result architecture.

## Preserved behavior

- Recursive Assembly scan and exact Density Instance + Density Base matching.
- Density normalization by /1000.
- Existing ver-02 mappings:
  - Machining Process: CNC=1, KH=2, CG=3, COVER=4.
  - Material convention: A6061=6061, SUS201=201, SUS304=304, SS400=400, POM=10, Bakelit=20, MC=30, MIKA=40, PU=50.
- Pair identity, same-pair refresh, different-pair tab creation, no-match preservation.
- ver-01 and ver-02 source files are unchanged.

## API evidence and compatibility

PTC's official 20.7 Integration Kit documentation describes:
- UICT Display Table creation using `sd-create-display-table-control`.
- A logical table data store created by `sd-create-logical-table`.
- Multi-row selection using `:multiple-rows`.
- Selected row indices and selected column values via `sd-get-display-table-selection`.
- Programmatic row selection/reset via `sd-set-display-table-selection` and `sd-reset-display-table-selection`.

The table's untyped `:part-object` column stores real Part objects. This follows the documented logical-table behavior that untyped cells can contain any LISP data.

The native hand-off reuses ver-02's Graphical Browser pattern. The user's Modeling 18.1 ver-02 workflow already confirms row selection and native Apply. However, the new hidden bridge that creates BrowserNodes from selected Display Table Part objects has not been tested in Modeling 18.1. Likewise, Display Table/UICT signatures are documented in PTC 20.7, not confirmed for 18.1.

References:
- https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/reference/uict_create.html
- https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/reference/tables.html
- https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/reference/gbrowser.html

## Runtime test requested

1. Load the updated canonical file in Creo Elements/Direct Modeling 18.1:
   `(load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER_VER_03.lsp")`
2. Run `H871_PART_FILTER_VER_03`.
3. Search CNC + SUS304. Confirm the table has separate columns for Part Name, Density Instance, Density Base and Assembly Path.
4. Click one row; verify the status count becomes 1 selected.
5. Ctrl-click/Shift-click additional rows; verify multi-selection.
6. Press Select All; verify all rows in the current tab are selected.
7. Press Clear Selection; verify the current tab returns to 0 selected.
8. Select a small number of rows and press Apply. Verify only those Parts become the active Modeling selection.
9. Switch to another tab and repeat; verify selection is page-scoped.
10. Refresh the same pair; verify its data updates and selection resets.
11. Search a no-match pair; verify existing tabs remain intact.

## Known test boundary

- No Creo 18.1 runtime test is possible from the development environment.
- Do not call ver-03.1 production-verified until Display Table creation, multi-row selection, and Apply hand-off all pass the above tests.
- If Apply does not transfer Parts, report the exact error and whether the temporary bridge appeared; ver-02 remains the known-good fallback.


## 2026-11-16 – ver-03.2 stale logical-table recovery

- User runtime-tested the mapped parameter dialog and reported: `A logical table with name "" does not exist`, followed by `H871 ver-03: Could not refresh the result table.`
- Diagnosis: the per-page registry is stored in global variables and can persist across LISP reloads. A page record retained from an earlier revision may not contain the newer `:logical-table` property, causing refresh to pass NIL/empty name to the logical-table API.
- Updated refresh logic to derive the deterministic logical-table name from the page ID when metadata is missing; reject blank names; check `sd-logical-table-p`; recreate a missing logical table; verify the Display Table's logical-table binding; and recreate a stale Display Table control when necessary.
- Improved the refresh error to include the actual logical-table identifier.
- Static source update committed; requires a fresh Modeling 18.1 runtime test. No claim of runtime resolution until user confirms.


## ver-03.2 follow-up – explicitly reject empty-string metadata

A retest showed the empty logical-table error persisted. Root cause in the first recovery patch: Common Lisp treats the empty string as truthy, so `(or stored-name fallback-name)` incorrectly retained an explicitly empty `:logical-table` value. The refresh code now accepts the stored name only when it is a string with length greater than zero; otherwise it derives the name from the non-empty page ID. This directly addresses the reported `name ""` case. Modeling 18.1 runtime retest is still required.


## 2026-11-16 – preserve numeric filter codes and tab label convention

- Reconfirmed against the known-good ver-02 implementation: CNC + SUS304 is searched as numeric Density Instance `1` and Density Base `304`; the raw API values are normalized by `/1000.0` before comparison.
- `CNC-SUS304` is only the human-readable tab caption. It is never used as a search value.
- Corrected ver-03 tab caption order from `SUS304-CNC` to `CNC-SUS304`.
- Added an early numeric-input guard in the search entry point. Missing/non-numeric dialog values now produce a clear diagnostic before scanning or creating the Results UI.
- This does not yet identify the reported `NIL is not of type STRING` source. The numeric mapping is now explicit and guarded; Modeling 18.1 runtime retest is required to identify the failing UI/API call if that error persists.


## 2026-11-16 – NIL UI handle during first tab creation

- Symptom: `LISP error: NIL is not of type STRING` immediately after OK; Results window never appears.
- Root cause candidate identified by control-flow review: first-page insertion can trigger `h871-pf-v03-tab-changed` before `h871-pf-v03-create-page` pushes its page record. The callback previously called `h871-pf-v03-update-status`, which passed the missing `:table` value (NIL) into `sd-get-display-table-selection`.
- Fix: make tab callback and status updater tolerate the pre-registration callback; validate page/table/status handles as non-empty strings before calling UICT functions.
- Filter alignment: ver-03 collector now explicitly rejects NIL Density Instance/Base before numeric comparison, as ver-02 does. Numeric filter values remain Instance=process code and Base=material code; `/1000.0` normalization is unchanged.
- This is a code-path diagnosis, not a confirmed runtime fix. Test on Modeling 18.1 before marking resolved.


## 2026-11-16 – ver-03 partial UICT initialization recovery

- User retested the previous callback/status guard and confirmed the same NIL-is-not-of-type-STRING error remains before the Results window appears.
- A second review found that shell, grid-area and tab-control creation were all inside one unless sd-dialog-shell-p block. A previous failed attempt could leave the shell alive but leave the grid or tab control missing. The next run would see the shell, skip all child initialization, then attempt to insert a page into an incomplete UI.
- Changed h871-pf-v03-create-shell to check/create the dialog shell, grid area and tab control independently. Uses sd-control-p for the child UICT handles; this is documented as checking controls, areas, grid areas and dialog shells.
- Changed :tabChangedAction from a quoted symbol to a function object (#'h871-pf-v03-tab-changed), matching PTC's official UICT tab-control examples.
- This is a source-level correction based on the initialization lifecycle; it has not yet been confirmed in Modeling 18.1. If the same error persists, the next revision should add per-call stage diagnostics around the remaining UICT creation calls rather than alter density matching.
