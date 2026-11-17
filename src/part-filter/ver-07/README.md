# H871 Part Filter VER-07 — Density result table initialization

**Branch:** `feature/part-filter-ver-07-density-table`  
**Base:** user-tested VER-06 Results Browser selection workflow  
**Target:** PTC Creo Elements/Direct Modeling 18.1

## User-confirmed baseline

The user confirmed that the standalone Results Browser opens independently and that Part rows can be selected as intended. The missing feature was the Density information columns in the visible Results table.

## Change in VER-07

Source: `H871_PART_FILTER_VER_07_DENSITY_TABLE.lsp`

The table definition already contained four columns:
- Part Name
- Density Instance
- Density Base
- Assembly Path

The issue was in initialization order: the old source displayed the Browser and only afterward assigned the root node as the table root. PTC's Graphical Browser documentation states that a table is populated from the children of its selected table root. If no table root has been assigned when the view is first shown, the custom table may not appear populated as intended.

VER-07 changes the sequence to:

1. Create the tree and Browser.
2. Define the custom table and its four columns.
3. Set the active table.
4. Resolve the root BrowserNode structure.
5. Assign the root as the table root and check the command result.
6. Activate table-only mode.
7. Show the Browser.

The Density callbacks continue to read the normalized Instance/Base values already stored in each BrowserNode's client data. The matching engine, density normalization, native row selection, native Apply, Select All, and Clear Selection logic are otherwise preserved.

## Runtime test required

Use a disposable Assembly copy in Creo 18.1.

1. Load VER-07 source.
2. Run `H871_PART_FILTER_VER_07`.
3. Search a known pair, e.g. CNC-SUS304 (1-304).
4. Confirm the table visibly contains all four headers and that Density Instance and Density Base show numeric values for each row.
5. Select a Part and click Apply; confirm the same Part is selected in the 3D viewport.
6. Test Select All and Clear Selection.
7. Confirm only one Results Browser exists.

If headers appear but Density cells are blank or show "-", capture a screenshot and the generated `H871_PART_FILTER_RESULT.txt` report. Do not modify the proven filter collector until the displayed values and report are compared.

## Validation status

- Static source checks: balanced parentheses, no negative depth, no unterminated string.
- Density column definitions present.
- Root assignment is ordered before Browser display.
- Native Apply and selection commands retained.
- **Not runtime-tested by the assistant in Modeling 18.1.** User confirmation is required before accepting VER-07.
