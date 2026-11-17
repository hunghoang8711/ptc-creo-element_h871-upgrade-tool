# H871 Part Filter VER-06 — Standalone Structure Browser shell

**Target:** PTC Creo Elements/Direct Modeling 18.1  
**Development branch:** `feature/part-filter-ver06-structure-browser-shell`  
**Base:** main at `fe1075c599b8882202cab178b37ca58e1dd163fe`  
**Stage:** 1 — native Graphical Browser shell  
**Runtime status:** NOT YET TESTED on this branch/revision.

## Objective

Create a dedicated H871 Results window using the native PTC Graphical Browser, similar to the native Structure Browser experience. Preserve native row selection, Select All, Clear Selection and Apply rather than rebuilding selection behavior in a custom UICT table.

## Implementation scope

- Preserve the numeric Density Instance + Density Base matching convention.
- Use one dedicated Graphical Browser for the current result set.
- Request floating-window placement with `:createAsTab nil`.
- Retain the native Apply action.
- Display Part Name, Density Instance, Density Base and Assembly Path.
- Keep this work isolated from VER-03 and the current stable main branch.

## Compatibility caution

The source is a candidate ported from the VER-02 native Browser workflow. PTC documentation from later releases is not proof of Modeling 18.1 compatibility. In particular, `:createAsTab nil` may be overridden by a persisted PDS Browser placement preference. Confirm actual placement in the user's 18.1 session.

## Runtime test — disposable Assembly only

1. Start a fresh Modeling 18.1 session and load this source.
2. Run `H871_PART_FILTER_VER_06`.
3. Search a known pair, e.g. CNC-SUS304 (numeric 1-304).
4. Confirm a separate floating H871 Results Browser appears.
5. Confirm the four columns and matching Part rows.
6. Select one row and press native Apply; confirm the intended Part is selected in the 3D viewport.
7. Repeat with Select All, then Clear Selection.
8. Record whether the Browser floats or docks.
9. Close and reopen the command once. Stop immediately if a fatal exception or model-data warning appears.

## Not included in Stage 1

- Multi-page results inside one Browser.
- Editable notes or custom detail panes.
- A custom Apply callback or UICT selection bridge.
- Any modification to the protected VER-03 source.

## Evidence discipline

Static inspection and source creation are not runtime validation. Only mark each behavior as verified after the user observes it in Modeling 18.1. Keep the exact error and trace file if a test fails.
