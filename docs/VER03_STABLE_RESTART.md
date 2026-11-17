# VER-03 Stable Restart — Active Development Line

## Source organization

There is one active Part Filter development line:

- **Active branch:** `rebuild/ver-03-stable-restart`
- **Active source:** `src/part-filter/ver-03-rebuild/H871_PART_FILTER_VER_03_REBUILD.lsp`
- **Command:** `H871_PART_FILTER_VER_03_REBUILD`
- **Target:** PTC Creo Elements/Direct Modeling 18.1

The original VER-02 source remains the stable logic reference. The pre-edit VER-03 rebuild commit remains available as a regression point on `rebuild/ver-03-from-ver-02`. Do not create additional numbered versions or parallel feature branches for this work.

## User-confirmed baseline behavior

The user has confirmed the standalone Results Browser opens and Part rows can be selected as intended. VER-02/VER-03 rebuild remain the only accepted stable references. Do not infer that an untested change is runtime-verified.

## Preserved implementation

- Standalone native Graphical Browser Results window.
- Native Browser selection and Apply workflow.
- Select All / Clear Selection.
- Recursive Assembly collector and exact Density Instance AND Density Base match.
- Numeric convention: CNC=1, KH=2, CG=3, COVER=4; material values SUS304=304, etc.
- API density values normalized by dividing by 1000.
- Four table columns are defined: Part Name, Density Instance, Density Base, Assembly Path.

## Current focused test change

The user reported that the standalone Results window and row selection work, but Density columns are not visible. A subsequent test of the earlier ordering edit returned: `H871: Results tree root is unavailable.`

Comparison with the exact VER-02 source established that VER-02 performs this sequence:
1. Sets the active table.
2. Activates Table Mode.
3. Shows the Graphical Browser.
4. Resolves the Browser Tree root.
5. Applies the root with `:change-table-root`.

The root is created by the Browser Tree update callback, so querying it before showing/initializing the Browser was premature. The active VER-03 rebuild source has been corrected to follow the VER-02 order. If root resolution still fails after SHOW, the new error message explicitly says so; do not add a fallback Browser/window.

No collector, Density mapping, BrowserNode row data, Browser selection, Select All/Clear Selection, or native Apply code was changed.

## Runtime test still required

Use a disposable Assembly copy. Load the active source from this branch and run `H871_PART_FILTER_VER_03_REBUILD`. Verify the four columns and actual Density values, then test row selection, Select All/Clear Selection, and Apply in the viewport. The edited source is not marked as runtime-verified until the user confirms these checks.

## Branch hygiene

Experimental VER-04/05/06/07 lines are not active and must not be used as development bases. Preserve only the technical lessons already established; do not add their source files to the active development line. Keep the workflow on this single VER-03 rebuild line.
