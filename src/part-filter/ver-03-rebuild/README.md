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

The custom table definition and Density display callbacks were already present. The previous initialization sequence showed the Browser before assigning its table root. The active source now assigns the root before enabling table mode and showing the Browser. It does not infer success/failure from the return values of those Browser commands.

This is a focused initialization-order test. It does not change the Density collector, row client data, display callbacks, Browser selection, or Apply implementation.

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
