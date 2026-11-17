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


## 2026-11-17 — Modeling 18.1 runtime validation

User tested Stage 1 in Creo Elements/Direct Modeling 18.1 and confirmed:

- The H871 Results Browser appears as a separate window.
- Selecting one Part and pressing native Apply selects the correct Part in the 3D viewport.
- Select All works.
- Clear Selection works.
- Initial display appeared to show only Part Name. User then widened the Results Browser and confirmed that all four columns became visible: Part Name, Density Instance, Density Base and Assembly Path.

**Conclusion:** the table definition was correct; the apparent missing columns were outside the visible horizontal area. No source change was needed. Do not add speculative Browser keywords or alter native Apply to address this resolved presentation issue.

### Validation status after first runtime test

| Behavior | Status |
|---|---|
| Separate floating Results Browser | User-confirmed |
| Native Apply to 3D selection | User-confirmed |
| Select All | User-confirmed |
| Clear Selection | User-confirmed |
| Four custom columns | User-confirmed after widening Browser |
| Modeling 18.1 Stage 1 overall | Accepted / user-confirmed |


## Stage 2 — Per-Part Notes (feasibility first)

### Goal
Allow a user to store a text note against an individual Part and read it again after saving and reopening the model. Keep this independent from the native Results Browser selection/Apply pipeline.

### Proposed storage direction
PTC Integration Kit references document User-Defined Attributes (UDA):
- `sd-attach-item-attribute`
- `sd-mod-item-attribute`
- `sd-inq-item-attributes`
- `sd-inq-item-attribute`

The documented filing option `:sd-file` includes the attribute in standard Modeling output files. An instance-level attachment (`:attachment :instance`) is the initial candidate so notes can belong to a specific Part instance rather than being unintentionally shared through contents. This is a design candidate, not yet proven in this Modeling 18.1 session.

PTC references consulted (20.x documentation; exact 18.1 behavior still requires runtime verification):
- https://support.ptc.com/help/creo_elements_direct/r20.5.0.0/advanced_documentation/integration_kit/reference/user_atts.html
- https://support.ptc.com/help/creo_elements_direct/r20.4.0.0/advanced_documentation/integration_kit/whatsnew.html (notes UDA behavior/API history reaching back to earlier releases)

### Isolated test file
`research/attributes/H871_PF_PART_NOTE_ATTRIBUTE_PROBE.lsp`

Commands:
- `H871_PF_NOTE_PROBE_WRITE` — select a disposable Part and attach/update a test note.
- Save that test model to a new file, close it, reopen it.
- `H871_PF_NOTE_PROBE_READ` — select the same Part and verify that the note is still present.

### Acceptance criteria
1. Both probe commands load and run without undefined-function or type errors in Modeling 18.1.
2. Write command reports the same note that was entered.
3. The test model is saved to a new file and reopened.
4. Read command returns the same note after reopen.
5. A second Part can hold a different note without changing the first Part's note.
6. No change to native Apply, Select All, Clear Selection, filter predicates, or the protected VER-03 source.

Do not integrate UDA calls into the VER-06 production source until these checks pass. Runtime status: **pending user test**.
