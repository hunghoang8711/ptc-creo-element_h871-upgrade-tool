# ver-03 Stage 1 — Native multi-filter result tabs

**Branch:** `rebuild/ver-03-from-ver-02`  
**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Status:** Implemented in source; Modeling 18.1 runtime test pending.

## Source

- `H871_PART_FILTER_VER_03_STAGE1.lsp`
- Command: `H871_PART_FILTER_VER_03_STAGE1`
- Stage 0 baseline remains separately preserved at `src/part-filter/ver-03-rebuild/`.

## Stage 1 objective

Retain the verified Stage 0 native Graphical Browser workflow while allowing multiple Density Instance + Density Base searches to remain available at the same time.

## Design

- One native Graphical Browser and one dedicated Browser Tree per unique numeric Density pair.
- Request each browser to appear as a docked Browser Bar tab using `:createAsTab t` and a human-readable `:tabname`.
- CNC + SUS304 uses numeric Instance=1 and Base=304; caption is `CNC-SUS304`.
- Different pairs create separate browser tabs.
- Repeating an existing pair replaces only that pair's result browser/tree; other pair tabs remain untouched.
- A no-match search reports no results and preserves all existing result tabs.
- Each browser uses its own tree; PTC documentation states a Browser Tree cannot be shared by multiple Graphical Browsers.
- Native Graphical Browser Apply and double-click behavior are retained. There is no custom Apply bridge, UICT table, or logical table.
- Select All and Clear Selection actions are scoped to the browser tab that owns them.

## Compatibility caution

The `:createAsTab` option and Browser Tree `:update-args` are documented in later-version PTC Integration Kit references. Exact behavior in Modeling 18.1 is not established by documentation alone. This is an isolated compatibility test, not a runtime-confirmed feature.

## Stage 1 test protocol

Use a disposable model copy only.

1. Load `H871_PART_FILTER_VER_03_STAGE1.lsp`.
2. Run `H871_PART_FILTER_VER_03_STAGE1`.
3. Search CNC + SUS304 (1 / 304). Confirm a results browser tab appears and native Apply works.
4. Search a second known pair, for example KH + SS400 (2 / 400). Confirm a second separate tab appears and the first remains available.
5. Return to CNC + SUS304 and confirm its rows remain.
6. Search CNC + SUS304 again. Confirm only that pair's tab is refreshed/replaced, with the second tab retained.
7. Search a known no-match pair. Confirm existing tabs are not removed.
8. In each tab, verify double-click single-Part selection, Select All, Clear Selection, and Apply.
9. Confirm closing/hiding one browser tab does not destroy other tabs.

Record exact behavior and any Modeling 18.1 error. Do not proceed to Stage 2 until the user confirms Stage 1.

## Next stages (not yet implemented)

- **Stage 2:** Result-tab lifecycle controls (close one pair, clear all result tabs, explicit refresh) with safe per-tab state cleanup.
- **Stage 3:** Additional result metadata and usability improvements, without changing the native selection/apply path.
- **Stage 4:** Optional advanced filtering/sorting only after the preceding stages are stable.

## Preservation

- ver-01, ver-02, and Stage 0 source remain unchanged.
- The unstable former UICT-based ver-03 remains preserved for forensic reference.
- No runtime success is claimed until the user tests this source in Modeling 18.1.
