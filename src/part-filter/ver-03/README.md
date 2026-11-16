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


## 2026-11-16 – preserve numeric filter codes and tab label convention

- Reconfirmed against the known-good ver-02 implementation: CNC + SUS304 is searched as numeric Density Instance `1` and Density Base `304`; the raw API values are normalized by `/1000.0` before comparison.
- `CNC-SUS304` is only the human-readable tab caption. It is never used as a search value.
- Corrected ver-03 tab caption order from `SUS304-CNC` to `CNC-SUS304`.
- Added an early numeric-input guard in the search entry point. Missing/non-numeric dialog values now produce a clear diagnostic before scanning or creating the Results UI.
- This does not yet identify the reported `NIL is not of type STRING` source. The numeric mapping is now explicit and guarded; Modeling 18.1 runtime retest is required to identify the failing UI/API call if that error persists.


## 2026-11-16 – guard tab initialization callback

A new `NIL is not of type STRING` runtime failure occurred before the Results window appeared. Review against the ver-02 filter flow identified an initialization-order hazard specific to ver-03: `sd-insert-tab-control-page` can invoke the tab-change callback while the page is still being created, before its registry entry and table/status handles have been registered. The old callback immediately called `sd-get-display-table-selection` with the missing table handle. The callback/status path now validates page, table and status handles and safely does nothing until the page registry exists. The recursive filter also now explicitly skips Parts with NIL Density Instance/Base, matching ver-02's null-safe matching semantics. Runtime validation in Modeling 18.1 is still required.


## 2026-11-16 – recover partially-created Results UI

The user retested the callback-guard revision and still received the same NIL-is-not-of-type-STRING error before the Results window appeared. A second control-flow review found a separate initialization flaw: h871-pf-v03-create-shell previously grouped shell, grid-area and tab-control creation inside one unless sd-dialog-shell-p check. If an earlier failed attempt left the dialog shell alive but did not finish creating its grid or tab control, every later search skipped all child-control creation and attempted to insert a page into a missing tab control. This is consistent with a repeatable failure after reloads/retries. The function now checks and creates the shell, grid area and tab control independently using the documented generic sd-control-p check, preserving any valid layer already present. The tab callback is also now passed as a function object (#'...) matching PTC's official UICT tab examples. This is a source-level correction; Modeling 18.1 runtime confirmation is still required.



## 2026-11-16 – Runtime milestone: Results UI works; Apply BrowserNode type error

User tested the latest instrumented source after restarting Modeling in a new window/session. Confirmed working:
- One Results window is created.
- Internal tabs are created for the searched Density pairs.
- The result table is populated with Part Name, Density Instance, Density Base and other configured columns.
- The Apply button is present.

New runtime failure occurs only after pressing Apply:

`LISP error: #:NODE241 is not of type "BROWSERNODE".`

### Evidence from source comparison

The ver-03 Apply bridge currently stores the direct return value of each `sd-create-browsernode` call in `*h871-pf-v03-apply-nodes*`, then passes each stored value directly to:

`(sd-browser-exec-cmd ... :set-object-selection node t)`

The runtime error identifies the supplied value as an uninterned symbol (`#:NODE241`), while the operation requires a BrowserNode object. This strongly localizes the defect to the conversion/lookup between BrowserNode creation and BrowserNode selection. It is not a Density filter, Display Table creation, tab creation, or Results population failure.

### Required next investigation

- Inspect the exact return contract of `sd-create-browsernode` in the Modeling 18.1 Integration Kit, not just later-version examples.
- Compare how ver-02 obtains actual BrowserNode structures after creating its tree. In ver-02, selected nodes are obtained from `sd-query-browser ... :get-selected-objects`; it does not assume that a creation token is itself a BrowserNode structure.
- Determine the supported way to resolve the returned node identifier to a BrowserNode structure (potentially via the tree's node lookup API) before calling `:set-object-selection`.
- Do not pass `#:NODE...` tokens directly to APIs requiring `BROWSERNODE`.
- Keep the ver-02 native selection-and-execute flow as the reference behavior. Do not alter numeric Density matching or the now-working Results UI while repairing Apply.

Status: Results UI runtime-confirmed by user. Apply remains failed and unverified. This is a high-confidence localization from the exact runtime type error and source call path; the exact 18.1 node-resolution API still needs authoritative verification.

## 2026-11-16 – Apply BrowserNode identifier resolution fix

The user-reported Apply error was `#:NODE241 is not of type "BROWSERNODE"`. The source review and PTC Graphical Browser reference identify the cause: `sd-create-browsernode` returns a symbolic node ID, while `:set-object-selection` requires a BrowserNode structure.

The Apply bridge now captures the symbolic ID returned by `sd-create-browsernode`, resolves it with `sd-get-browsernode-struct` using the Apply tree name, stores only the resolved BrowserNode structure in `*h871-pf-v03-apply-nodes*`, and passes the structure to `:set-object-selection`.

The lookup function is also already used by the preserved ver-02 source to obtain the tree root. PTC's official 20.7 reference explicitly documents the symbolic return value and this exact resolution pattern. This is strong API-contract evidence, but it does not prove all Apply bridge behavior in Modeling 18.1. Runtime test is still required.

`CNC-SUS304` is the current caption convention; numeric search remains Density Instance=1 and Density Base=304.


## ver-05 integration lesson – page root isolation

The single-Browser ver-05 candidate must clear all previous table roots before activating a new Density-pair page. :change-table-root is not a replacement operation by itself; a Browser can retain multiple roots. The ver-05 source now uses the buffered clear-selection/clear-roots/set-root/resume sequence and records the active root count. This fix is not a ver-03 source change and does not alter ver-03's user-confirmed UI behavior.


## 2026-11-16 – Apply BrowserNode ID resolution correction

The current ver-03 source now treats the return value of `sd-create-browsernode` as a node identifier, not as a BrowserNode structure. The Apply-tree builder resolves the root and every Part child with `sd-get-browsernode-struct` before storing or passing them to `:set-object-selection`. It traces each resolution and stops before selection hand-off if the number of resolved Part nodes does not equal the selected Part count.

This directly addresses the reported runtime type error `#:NODE241 is not of type "BROWSERNODE"`. Static Lisp parenthesis validation passed after the change. **This is not yet proof that Apply selects Parts in Modeling 18.1.** The temporary hidden Graphical Browser hand-off remains a known unverified/previously problematic boundary. The next runtime test must report the node-resolution trace and whether the actual viewport selection changes. Do not claim Apply success from a successful node lookup or `:select-and-execute` return alone.

## Architecture direction reaffirmed – continue from ver-03

The user has explicitly reaffirmed that ver-03's one Results window with internal Density-pair tabs is the accepted UI direction. Continue from ver-03; do not continue ver-05's single-Graphical-Browser UI experiment. Preserve ver-03's tab shell, per-page Display Tables, row multi-selection and Select All/Clear Selection. Focus remaining work on making selected rows Apply to actual Modeling Parts in the same user-facing Results workflow. ver-04/ver-05 remain diagnostic/experimental history only.
