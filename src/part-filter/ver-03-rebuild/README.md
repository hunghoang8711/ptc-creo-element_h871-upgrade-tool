# Part Filter — Active VER-03 Rebuild Line

**Active development branch:** `rebuild/ver-03-stable-restart`  
**Stable references:** VER-02 and the user-confirmed VER-03 rebuild behavior  
**Target:** PTC Creo Elements/Direct Modeling 18.1

## Single active source

Use only this source for the next test:

`src/part-filter/ver-03-rebuild/H871_PART_FILTER_VER_03_REBUILD.lsp`

Load it and run:

`H871_PART_FILTER_VER_03_REBUILD`

Do not load the experimental VER-04/05/06/07 files or the UICT multi-page prototype for this test. No new version directory or command name is being introduced.

## Current implementation

This source remains based on the VER-02 Density collector and native Graphical Browser workflow:
- Density Instance + Density Base exact numeric matching.
- Existing /1000 API-to-Properties normalization.
- One standalone Results Graphical Browser.
- Native Browser row selection and native Apply handoff.
- Select All / Clear Selection.
- Four table columns: Part Name, Density Instance, Density Base, Assembly Path.

## Current focused change

The custom table definition and Density display callbacks were already present. The previous attempt queried the Browser Tree root before the Graphical Browser had been shown. Comparison with the VER-02 baseline showed that VER-02 activates table mode and shows the Browser before calling `sd-get-browsernode-struct`.

The previous post-SHOW root correction removed the root-unavailable error, but the user's latest test still displayed only the Part Name column. The active source now isolates table activation timing:
1. Show the Graphical Browser so its tree update callback can build the root.
2. Resolve the root and apply it with `:change-table-root`.
3. Re-activate the custom table.
4. Switch to Table Mode only after the root is assigned.

This tests whether Modeling 18.1 was retaining the pre-SHOW table/mode state incorrectly. It does not change the Density collector, row client data, display callbacks, Browser selection, Select All/Clear Selection, or native Apply implementation. Runtime behavior still requires confirmation in Modeling 18.1.

## Test in Creo 18.1

Use a disposable Assembly copy.

1. Load this exact file.
2. Run `H871_PART_FILTER_VER_03_REBUILD`.
3. Search a known pair, e.g. CNC-SUS304 (Density Instance=1, Density Base=304).
4. Confirm that the Results Browser is one standalone window.
5. Confirm the four columns are visible and Density Instance/Base values are populated.
6. Select a row and verify the expected Part is selected in the viewport; test Select All and Clear Selection.
7. Test Apply only if the Apply control is available in this current source; report whether the viewport selection handoff succeeds.

If the Density headers are still absent, capture the whole Results window. If the headers exist but values are blank or "-", also send `H871_PART_FILTER_RESULT.txt`.

## Validation status

- Static source checks: completed after the focused edit.
- Creo 18.1 runtime validation of this edited source: pending user test.
- VER-02 and the pre-edit VER-03 rebuild remain the regression references.
