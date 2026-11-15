# 02 – Annotation Sheets and Frames

## Source provenance
Reviewed user-provided text file `Văn bản đã dán (1)(1).txt` (uploaded 2026-10-16; duplicated in the Library under another result reference). It is an Annotation sheet-functionality macro source and contains CoCreate Software GmbH Confidential/copyright notices. This public knowledge package records a technical summary, not a verbatim copy.

## What the source actually demonstrates

### Current-sheet state and navigation
- Global state: `Docu_current_sheet`, `Docu_current_sheet_id`.
- `Docu_set_current_sheet` resolves a sheet part ID using `DOCU_SHEET_PART_ID`, switches to the sheet using `EDIT_PART TOP`, `VIEW`, `EDIT_PART`, manages redraw/show settings, toggles `DOCU_INVISIBLE_FIT_MODE`, and fits the window.
- `Docu_set_current_sheet_by_subpart_id` walks parent parts until it finds the `DOCU_SHEET` marker, then switches to that sheet.
- `Docu_inq_highest_sheet_name` uses `DOCU_HIGHEST_SHEET_NAME`.

### Loading a frame
`Docu_load_frame(Frame_file, Frame_wm_name)` has three paths:
1. File path: `LOAD SUBPART Frame_file ABSOLUTE`, obtains the loaded part ID using `INQ 305`, marks it using `DOCU_MARK_FRAME`, then calls `Docu_unshare_all_in_subtree`.
2. WorkManager/database path: calls `Awmc_m_load_tb_frame_amsd`, checks `MACRO_EXISTS 'Awm_val_last_loaded_db_frame'`, adjusts DM text references to AM references, marks the frame and unshares the subtree.
3. Empty/dummy frame: creates a dummy subpart and marks it as a frame, adding an invisible point marker.

It sets `Docu_load_frame_result` based on `CHECK_ERROR`.

### Creating a sheet
`Docu_create_sheet(Sheet_name, Frame_file, Frame_wm_name)`:
- switches to TOP;
- initializes a new part;
- marks it as a sheet using `DOCU_MARK_SHEET`;
- loads the selected frame;
- falls back to a dummy frame when loading fails;
- calls `Docu_set_current_sheet`;
- reports success/failure through the Annotation stream if available.

`Docu_create_dummy_sheet` creates a sheet with an empty dummy frame.

### Replacing a frame
`Docu_replace_frame(Sheet, New_frame_file, New_frame_wm_name, X_size, Y_size, Keep_position_of_empty_frame)`:
- resolves the sheet part ID;
- switches to that sheet;
- deletes the existing frame;
- obtains the old sheet bounding box using `DOCU_PART_BOX_LL` / `DOCU_PART_BOX_UR` and calculates its center;
- either creates a rectangular frame for positive X/Y dimensions or loads a frame file/database object;
- calculates the new frame center and repositions it to the old sheet center;
- uses the number of sheet subparts to avoid unwanted recentering for an empty sheet, controlled by `Keep_position_of_empty_frame`;
- fits the window and reports the result.

### Other useful functions
- `Docu_move_frame`: moves the frame part to its center point via `MODIFY DEL_OLD PARTS`.
- `Docu_inq_frame_name_id_of_act_sheet`: obtains the frame unique ID.
- `Docu_inq_frame_name_of_act_sheet`: resolves the frame's displayed part name.
- `Docu_rename_frame`, `Docu_rename_sheet`.
- `Docu_inq_frame_type`: heuristic classification using selected geometry counts; source comments say further checks may be needed.
- `Docu_count_views_for_different_scale`: enumerates `DOCU_VIEW` subparts and counts views whose scale differs from a requested scale.

## Important limitation for the earlier multi-A4 frame question
The reviewed source proves how Annotation creates a sheet, loads a frame, replaces a frame and locates the current frame. It does **not** prove how the Annotation UI's available-frame catalogue/list is registered or populated.

Previously proposed `docu-register-frame` and `am_customize` were hypotheses, not verified solutions. The user reported `am_customize` was unavailable. Do not claim that this file registers new frame types or adds them to the UI list.

## Safe next investigation
- Identify the exact Annotation frame-selection dialog/list and its caller in the installed 18.1 customization files.
- Trace how existing standard A4/A3 frame definitions are discovered and enumerated.
- Verify the supported registration/configuration mechanism from the installed 18.1 files or manual.
- Only then add multiple A4 variants; avoid unregistering or replacing all existing frame definitions.
- Test load, create, replace, persistence after restart, and coexistence with built-in frames.

## Evidence status
- Source-observed in user-provided legacy Annotation macro: the functions and command sequences summarized above.
- Not independently runtime-tested by the assistant.
- The user's original goal was to add multiple A4 sheet frames in Creo Elements/Direct Modeling 18.1.
