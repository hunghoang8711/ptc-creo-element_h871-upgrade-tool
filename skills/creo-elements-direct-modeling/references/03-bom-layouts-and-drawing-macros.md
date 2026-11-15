# 03 – BOM Layouts and Drawing Arrangement

## Source provenance
Reviewed two distinct user-provided text sources from 2026-10-17:
- `Văn bản đã dán (1)(2).txt`: Annotation BOM layout customization macros (580 lines).
- `Văn bản đã dán (1)(3).txt`: legacy Annotation sheet/view arrangement macros (311 lines).
Both sources include CoCreate Software GmbH confidential/copyright headers or legacy ownership notices. This file summarizes their design and API patterns without reproducing the full source.

## A. BOM layout customization source

### Loading a layout from an MI file
`Docu_load_bom_layout(File_name, Layout_name, Layout_type)`:
- remembers the current part using `INQ_PART NO_UNIQUE_LIST '.'` and `INQ 302`;
- switches to root using `EDIT_PART '/'`;
- loads the MI file as a subpart with scale preservation: `LOAD SUBPART KEEP_SCALE File_name ABSOLUTE END`;
- obtains the loaded part ID via `INQ 305`;
- converts the loaded geometry to a sketch using `Docu_convert_to_sketch`;
- stores the sketch as a BOM layout using `DOCU_SKETCH_TO_BOM_LAYOUT Layout_type Layout_name Load_pid`;
- deletes the temporary loaded part and rebuilds the BOM layout table;
- restores the prior current part.

The source includes `Docu_load_bom_layout_error` and an `ON_ERROR` / `TRAP_ERROR` cleanup pattern. Verify these legacy command semantics in the target installation before reuse.

### Layout categories and operations
The source works with:
- `BOM_HEAD_LAYOUT`
- `BOM_COMP_LAYOUT`
- `BOM_FLAG_LAYOUT`

Useful native Annotation commands observed:
- `DOCU_BUILD_BOM_LAYOUTS_LTAB`
- `DOCU_BOM_LAYOUT_TO_CURRENT`
- `DOCU_BOM_LAYOUT_GET_LAST_PID`
- `DOCU_SKETCH_TO_BOM_LAYOUT`
- `DOCU_DELETE_ALL_BOM_LAYOUTS`

It builds temporary configuration sheets, clones the selected head/component/flag layout into the sheet, converts the clones to sketches, and stores identifying information on the sheet while the user edits them. On acceptance, it writes the sketches back to the BOM layout repository and deletes the temporary configuration sheet. On discard, it deletes the temporary sheet.

### Attach points for BOM flags
The source creates typed flag attach points by:
- editing the target sketch;
- adding temporary element info with `ADD_CURRENT_INFO`;
- creating a point at the requested position;
- removing the temporary info;
- changing line type/color for the corresponding info;
- restoring the prior current part.

This is a useful pattern for metadata-tagged geometry, but it is Annotation/BOM-specific and requires testing in the matching module context.

### Enumerating loaded layouts
The source builds `Docu_bom_layouts_ltab`, reads columns for layout name and component IDs, and sends names back through SD connection/stream functions. Do not assume these internal tables or stream calls are generic Modeling APIs.

## B. Drawing sheet arrangement source

### Arrange_sheets
The legacy `Arrange_sheets` macro:
- gets a tree part list using `PARTS_LIST TREE LTAB 'ALL_PARTS'`;
- parses part identifiers from the returned list strings;
- checks Annotation info for `DOCU_SHEET`;
- builds a logical table of sheets;
- obtains geometry extents using `INQ_ENV 7`, `INQ 101`, `INQ 102`;
- computes horizontal offsets and calls a `Move_sheet` helper.

The source comments say the first version only arranges sheets horizontally; vertical spacing is marked not implemented.

### Arrange_sheets2
The second macro:
- reads the current unit factor via `INQ_ENV 6` / `INQ 2`;
- derives a sheet spacing from 25 mm converted to model units;
- gathers sheets under the drawing root and filters to direct child sheets;
- calculates centers and extents;
- sorts a logical table and packs sheets into a grid;
- calculates offsets and calls `Move_sheet`;
- restores the original current part.

### Arrange_views
The file also contains an `Arrange_views` macro that analyzes view bounding boxes, dimensions and centers to arrange drawing views. Its exact full behavior should be inspected in the source before porting or modifying.

## Reuse guidance
- The most reusable design pattern is: enumerate → filter by Annotation metadata → collect extents → compute layout → move objects → restore original edit context → clean temporary logical tables.
- Be careful with current-part state; these macros switch edit context frequently.
- Be careful with unit conversion; `INQ_ENV 6` / `INQ 2` is specifically used to convert a 25 mm gap to current model units.
- Temporary LTAB tables must be deleted on completion and on error.
- Do not copy 1998 macro code directly into Modeling Lisp; port command-language logic deliberately and verify each command in 18.1.

## Evidence status
These are source-observed patterns from user-provided legacy macros, not assistant-run Creo tests. The source header dates to 1998; release compatibility and optional Annotation module dependencies must be confirmed.
