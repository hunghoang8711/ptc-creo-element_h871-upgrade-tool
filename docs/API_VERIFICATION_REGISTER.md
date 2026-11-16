# Creo Elements/Direct Modeling 18.1 – API Verification Register

This register prevents a symbol seen in a code sample or later-release manual from being mistaken for a verified 18.1 API.

## Evidence labels
- **User-confirmed runtime:** user explicitly ran it in Modeling 18.1 and reported result.
- **Production-source + user-confirmed workflow:** present in the working source and behavior depending on it was confirmed by the user.
- **Source-observed:** found in user-provided legacy macro; not independently tested here.
- **Later-release documentation:** documented in a newer release; 18.1 compatibility unknown.
- **Unverified proposal:** assistant suggestion or hypothesis only.
- **Rejected/failed:** user reported undefined symbol or failed runtime behavior.

## A. Modeling Lisp / Part Filter

| API / symbol | Evidence | Notes |
|---|---|---|
| `sd-inq-part-p` | User-confirmed runtime, 2026-11-14 | Defined in user's Modeling 18.1 environment; used to identify Parts. |
| `sd-inq-part-density` (one argument) | User-confirmed runtime, 2026-11-14 | For Part `010-plate_2.1.1.2.1`, returned `1000.0`, type `LONG-FLOAT`. Do not infer mode semantics from this one observation. |
| `sd-inq-part-density :instance` / `:contents` | Production-source + user-confirmed workflow | Exact-pair production filter relies on these calls; preserve the known-good source call pattern. |
| `sd-inq-obj-children` | Production-source + user-confirmed workflow | Recursive Assembly traversal in Part Filter. |
| `sd-inq-obj-basename`, `sd-inq-obj-pathname` | Production-source observed | Used for Part display/name/path. Verify separately before reuse in unrelated tools. |
| `sd-create-browser-tree`, `sd-create-browsernode`, `sd-create-graphical-browser` | Production-source + user-confirmed workflow | Standalone Graphical Browser result UI. |
| `sd-browser-define-table`, `sd-browser-set-active-table`, `sd-browser-exec-cmd`, `sd-show-graphical-browser`, `sd-query-browser` | Production-source + user-confirmed workflow | Preserve tested call signatures from current ver-01/ver-02 source. |
| `browsernode-objclientdata` | Production-source observed | Reads actual Part object stored in browser row client data. |
| `sd-browser-set-status-text` | User-confirmed fix | Must supply `:value` keyword/value; omitting it caused odd keyword argument error. |
| `sd-defdialog` | Source-observed in diagnostic | Dialogs exist in current source; verify new callbacks separately. |

## B. Known unavailable / failed symbols

| Symbol | Evidence | Rule |
|---|---|---|
| `HANDLER-CASE` | User reported undefined in Modeling 18.1 | Do not assume ANSI Common Lisp condition handler availability. |
| `SEL_ITEM-P` | User reported undefined in multiple tests | Do not use this predicate. |
| `am_customize` | User reported unavailable during Annotation investigation | Do not rely on it for startup customization. |
| `docu-register-frame` | Unverified proposal only | No evidence found in supplied `am_sheet.m`; do not present as valid API. |

## C. Annotation / legacy ME10 command-language source

The following symbols were found in uploaded Annotation macro source. Their appearance in a legacy macro does not prove that they are callable from Modeling Lisp or available outside the Annotation module.

### Sheet/frame functions and commands
- `DOCU_SHEET_PART_ID`, `DOCU_SHEET_FRAME_PART`, `DOCU_MARK_SHEET`, `DOCU_MARK_FRAME`
- `DOCU_PART_BOX_LL`, `DOCU_PART_BOX_UR`, `DOCU_PART_HAS_INFO`, `DOCU_PART_INQ_INFO_WILD`
- `DOCU_PARENT_PART_ID`, `DOCU_IS_SHEET`, `DOCU_HIGHEST_SHEET_NAME`
- `DOCU_INVISIBLE_FIT_MODE`, `DOCU_INQ_INVISIBLE_FIT_MODE`
- `LOAD SUBPART ... ABSOLUTE`, `INIT_PART`, `INIT_SUBPART`, `EDIT_PART`, `VIEW`, `RENAME_PART`, `MODIFY DEL_OLD`
- `INQ 101`, `INQ 102`, `INQ 301`, `INQ 302`, `INQ 305`, `INQ 306`, `INQ 6`, `INQ 14`, `INQ 403`, `INQ 902/903/905`

### BOM layout commands
- `DOCU_BUILD_BOM_LAYOUTS_LTAB`
- `DOCU_BOM_LAYOUT_TO_CURRENT`
- `DOCU_BOM_LAYOUT_GET_LAST_PID`
- `DOCU_SKETCH_TO_BOM_LAYOUT`
- `DOCU_DELETE_ALL_BOM_LAYOUTS`
- `DOCU_OPEN_CONNECTION_TO_SD`, `DOCU_ADD_LINE_TO_SD`, `DOCU_CLOSE_CONNECTION_TO_SD`
- `DOCU_STREAM_OPEN`, `DOCU_STREAM_WRITE`, `DOCU_STREAM_CLOSE`

### Drawing arrangement and logical tables
- `PARTS_LIST TREE LTAB`
- `CREATE_LTAB`, `READ_LTAB`, `WRITE_LTAB`, `LTAB_ROWS`, `DELETE_LTAB_ROW`, `DELETE_LTAB`, `SORT_LTAB`
- `INQ_ENV 6/7`, `Move_sheet`

## D. UICT APIs used by ver-03 – later-release evidence only

The following signatures/patterns were inspected in official PTC Integration Kit documentation for releases 20.7/20.8. They are used by the current ver-03 implementation, but exact Modeling 18.1 availability/signatures remain unverified:

- Dialog shell and layout: `sd-create-dialog-shell`, `sd-dialog-shell-p`, `sd-dialog-shell-visible-p`, `sd-append-grid-area`
- Internal tabs: `sd-create-tab-control`, `sd-insert-tab-control-page`, `sd-set-current-tab-control-page`
- Display Table: `sd-create-logical-table`, `sd-change-logical-table-contents`, `sd-create-display-table-control`
- Multi-row selection: `sd-get-display-table-selection`, `sd-set-display-table-selection`, `sd-reset-display-table-selection`
- Page status/buttons: `sd-create-text-control`, `sd-set-text-control-value`, `sd-create-pushbutton-control`

**Display Table evidence:** PTC 20.7 documents a logical table as a typed/untyped data store, and Display Table as its multi-column presentation. The documented `:multiple-rows` selection mode returns selected logical row indices plus selected column values. An untyped hidden `:part-object` column is used to retain the real Part object while visible columns show Part Name, Density Instance, Density Base and Assembly Path.

**Native Apply bridge:** The current source builds temporary BrowserNodes for only the selected Part objects and calls the same Graphical Browser commands used by ver-02: `:set-object-selection` followed by `:select-and-execute`. The ver-02 native Apply path is user-confirmed in Modeling 18.1. However, this specific hidden bridge from a UICT Display Table into a temporary Graphical Browser has not yet been runtime-tested in 18.1. Treat it as an implementation candidate, not a verified workflow.

PTC references:
- https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/reference/uict_create.html
- https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/reference/tables.html
- https://support.ptc.com/help/creo_elements_direct/r20.7.0.0/advanced_documentation/integration_kit/reference/gbrowser.html

## E. Measurement/export
- No measurement API has been verified in Modeling 18.1 in the recovered project history.
- The 2026-10-09 `measure_export.lsp` concept and `measure_export_avail_cmds.cmd` were preliminary only.
- Any geometry/edge/face/volume/dimension inquiry must be tested for return type, units, selection semantics and model context.

## Updating this register
When a new API is found, add its exact signature, version/source, test setup, return type/units, result and evidence label. Never promote an unverified proposal to confirmed merely because it appears in a manual for another release.
