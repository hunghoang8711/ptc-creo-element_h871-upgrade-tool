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


## Stage 2 — Per-Part Notes (UDA feasibility — passed)

### Goal
Allow a user to store a text note against an individual Part and read it again after saving and reopening the model. Keep this independent from the native Results Browser selection/Apply pipeline.

### Proposed storage direction
PTC Integration Kit references document User-Defined Attributes (UDA):
- `sd-attach-item-attribute`
- `sd-mod-item-attribute`
- `sd-inq-item-attributes`
- `sd-inq-item-attribute`

The documented filing option `:sd-file` includes the attribute in standard Modeling output files. An instance-level attachment (`:attachment :instance`) is the initial candidate so notes can belong to a specific Part instance rather than being unintentionally shared through contents. User tested WRITE and READ successfully in Modeling 18.1, including the intended save/reopen persistence workflow. UDA storage is now accepted for the project.

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

UDA feasibility checks have passed according to user runtime feedback. The original VER-06 source remains preserved; integration is implemented in a separate VER-06.1 candidate.


## Stage 3 — VER-06.1 Part Notes UI candidate

Source:
`src/part-filter/ver-06/H871_PART_FILTER_VER_06_1_WITH_NOTES.lsp`

### UI behavior
- Adds a `Part Note` column to the native Results Browser table.
- Adds an `Edit Note` toolbar button.
- The user selects exactly one Part row and clicks `Edit Note`.
- The note editor is prefilled from the selected Part's instance-level UDA.
- Saving updates/attaches `H871_PART_FILTER_NOTE` with key `:note`, using the already user-tested attribute pattern and `:filing :sd-file`.
- After save, the Browser requests a tree refresh so the Note column can redraw from the Part object.

### Protected behavior
- Native Apply remains the default `:select-and-execute` behavior; no custom `:okButtonAction` is added.
- Select All and Clear Selection callbacks are unchanged.
- Density filter predicates and Assembly traversal are unchanged.
- Original VER-06 source and protected VER-03 source are not overwritten.

### Static checks performed
- Parenthesis balance: zero final depth, no negative depth, no unterminated string.
- Source inspection confirms Note column, Edit Note button, instance UDA and `:sd-file`.
- This is not a Modeling runtime test. The `:refresh-tree` command and launching the note dialog from a Browser button still require validation on 18.1.

### Modeling 18.1 acceptance test
1. Load VER-06.1 source (not the original VER-06 file) in a disposable model session.
2. Run `H871_PART_FILTER_VER_06` and search for a known Density pair.
3. Widen the Results Browser enough to see the new `Part Note` column.
4. Select exactly one Part row; click `Edit Note`.
5. Confirm the editor opens and shows the existing note (or blank for a Part without one).
6. Enter a note and save. Confirm the `Part Note` cell updates.
7. Select another Part and save a different note. Confirm the first Part's note remains unchanged.
8. Save the model, close and reopen it, rerun the filter, and confirm both notes remain.
9. Select one Part, click `Edit Note`, then press native Apply. Confirm the intended Part is still selected in the 3D viewport.
10. Retest Select All and Clear Selection.

Stop and report the exact error if the dialog does not open, the Note column does not refresh, or selection changes unexpectedly. Do not modify the native Apply pipeline as a workaround.
