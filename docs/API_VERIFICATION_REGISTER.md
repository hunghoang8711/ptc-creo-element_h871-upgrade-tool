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

## F. BrowserNode creation and structure lookup – Apply bridge

| API | Evidence | Contract / use |
|---|---|---|
| `sd-create-browsernode` | PTC official Integration Kit 20.7 documentation; exact Modeling 18.1 contract not independently checked | Returns a **Symbol** (symbolic BrowserNode name), not a BrowserNode structure. |
| `sd-get-browsernode-struct` | PTC official Integration Kit 20.7 documentation; also present in preserved ver-02 source | `(sd-get-browsernode-struct tree-name node-name)` returns the BrowserNode structure or NIL. |
| `:set-object-selection` | Later-release Graphical Browser reference; used by current ver-03 bridge | Its object argument must be a BrowserNode structure. Modeling 18.1 Apply bridge runtime retest pending. |

Documented resolution pattern:
```lisp
(setq node-id (sd-create-browsernode ...))
(setq node (sd-get-browsernode-struct tree-name node-id))
```

The ver-03 Apply bridge now follows this pattern. The PTC reference establishes the return/lookup contract for the documented release; ver-02's existing root lookup provides additional project evidence. Do not label the full ver-03 Apply workflow as 18.1 runtime-confirmed until the user tests it.



## G. Single Graphical Browser page navigation (ver-04 diagnostic)

| API / behavior | Evidence | Status |
|---|---|---|
| sd-browser-add-popup-entry | PTC Graphical Browser reference 20.6, exact callback signature and string-client-data behavior documented | Later-release documented; Modeling 18.1 runtime pending |
| :change-table-root | Used in preserved ver-02 source; PTC Graphical Browser reference describes children of a table root as the visible table rows | Project source-observed; 18.1 runtime baseline |
| :get-selected-objects | Used by ver-02 to read the current Graphical Browser selection | Project source-observed and user-confirmed through ver-02 behavior |
| :set-object-selection on visible nodes | PTC docs say only visible BrowserNodes can be selected | Used only to restore page-local selection in the diagnostic; 18.1 runtime test pending |
| :select-and-execute default Apply | ver-02's own native Graphical Browser Apply/OK action; user-confirmed in Modeling 18.1 | Confirmed baseline; must remain the Browser's native default |

The ver-04 diagnostic uses one Browser Tree containing a synthetic page root per Density pair. Each page root has the matching Part BrowserNodes as direct children. One Graphical Browser table is reused by changing the active table root. Previous/Next toolbar actions and a dynamic Results Pages popup submenu switch roots; selection paths are saved per page and restored only after its root is active.

Important UI distinction: the diagnostic uses page navigation controls and a right-click page menu, not a horizontal tab strip. It is a proof-of-concept for same-Browser selection ownership and native Apply, not the final approved UI.

PTC reference:
- https://support.ptc.com/help/creo_elements_direct/r20.6.0.0/advanced_documentation/integration_kit/reference/gbrowser.html

The documented Graphical Browser reference says sd-browser-add-popup-entry creates push/toggle/submenu entries and that functions receive (BrowserNode, browser-name) or (BrowserNode, browser-name, string-client-data) when client data is supplied. Modeling 18.1 compatibility and the full page-switch/selection-restore flow still require runtime testing.

The previously attempted sd-set-graphical-browser-parent host-shell integration is not used by this diagnostic. Earlier project attempts to reparent the Browser into a UICT host shell failed; do not retry that route without isolating and proving the exact failure cause.


## H. Graphical Browser and Browser Tree lifecycle – ver-04 recovery

| API | Evidence | Status |
|---|---|---|
| sd-destroy-graphical-browser | Already used in ver-04 diagnostic failure cleanup; now used by normal reset/Close Results | Modeling 18.1 teardown behavior still needs runtime confirmation |
| sd-destroy-browser-tree | Already used in ver-04 diagnostic failure cleanup; now used after Browser destruction | Modeling 18.1 teardown behavior still needs runtime confirmation |

User's first ver-04 test confirmed the Browser Tree name remains registered after the first diagnostic run: a second sd-create-browser-tree call returned the “already exists” failure. The revised source attempts teardown in the required order (hide/destroy Browser, then destroy Tree) before creating the same names again. This is a targeted recovery candidate, not yet a verified 18.1 API contract. Close Results invokes the same teardown and then shows the existing ver-03 UICT shell. The recovery command H871_PF_V04_RESTORE_UICT_RESULTS invokes that action explicitly.


## H. Graphical Browser page-root switching – clear prior roots before changing page

PTC's official Graphical Browser 20.6 reference documents:
- :BUFFER-DISPLAY with t to suspend redraw and nil to resume.
- :CLEAR-TABLE-ROOTS to remove all active table roots.
- :CHANGE-TABLE-ROOT with a BrowserNode structure and t to make it a table root.
- :NUMBER-OF-TABLE-ROOTS query to inspect how many roots are active.

The PTC reference's own example uses the sequence :buffer-display t → :clear-table-roots → :change-table-root → :buffer-display nil. A Browser can retain more than one table root; therefore a page-switch implementation must clear the previous root before setting the next page root. Otherwise the table may contain multiple pages' children and Select All/native Apply can target unintended rows.

ver-05 now uses this sequence and traces the table-root count after switching. Evidence is later-release documentation (20.6), not proof of Modeling 18.1 compatibility. Runtime must confirm the query/commands and verify the root count is exactly 1 after every page switch.


## I. Graphical Browser modeMenu vs buttonMenu – page selector placement

PTC Graphical Browser reference (20.6/20.7) specifies that modeMenu, buttonMenu and topMenu are mapped to right-click popup menu entries for compatibility. Separately, the reference explicitly defines buttonMenu as a visible row of buttons directly above topMenu; modeMenu is a row of mode toggle buttons above buttonMenu in the UI description but its menu compatibility behavior means it must not be assumed to provide the desired page-tab row. The official UI examples show buttonMenu specifications with :label and :push/:release actions.

For ver-05, use :buttonMenu to render Density-pair page navigation buttons. Keep the active page identity in the status line unless an exclusive toggle state is proven available. Modeling 18.1 rendering and callback compatibility still require runtime verification.


### Correction to section I – modeMenu UI placement

PTC Graphical Browser documentation explicitly defines modeMenu as a row of toggle buttons directly above buttonMenu. It separately states that buttonMenu provides a row of toggle buttons directly above topMenu. The statement that modeMenu is only a right-click popup was incorrect; the compatibility note means these menu definitions are also mapped into right-click popup entries. Both are visible UI rows. ver-05 restores page selectors to modeMenu and logs the evaluated specification, initial button and Browser creation stage.


## 2026-11-16 – BrowserNode creation ID versus structure in ver-03 Apply

- API use: `sd-create-browsernode` creates a node and returns an identifier; `:set-object-selection` expects a BrowserNode structure.
- Source correction: resolve the root and each created Part node with `sd-get-browsernode-struct` before using them in Browser selection commands.
- Static source check: balanced Lisp parentheses after commit `068ee4123b5aadf6cde5bce54321f1ee031ea064`.
- Runtime status: not yet verified in Modeling 18.1. In particular, this does not establish that a hidden Graphical Browser can hand off selection to Modeling. Acceptance requires observing the intended Part(s) selected in the viewport.


## J. User-Defined Attributes for per-Part notes — feasibility candidate (2026-11-17)

PTC's later Integration Kit references document these functions:
- `sd-attach-item-attribute`
- `sd-mod-item-attribute`
- `sd-inq-item-attributes`
- `sd-inq-item-attribute`

The documented `:filing :sd-file` option includes the UDA in standard Modeling output files. `:attachment :instance` is the initial candidate for notes that belong to a specific Part instance rather than shared contents.

Version evidence: PTC's later What's New documentation records UDA behavior changes as early as Modeling 17.0, and the Modeling 18.1 What's New section does not indicate that these functions were introduced later. This is useful historical evidence, but it is **not** proof that every exact 20.x signature/keyword behaves identically in 18.1.

Probe source:
`research/attributes/H871_PF_PART_NOTE_ATTRIBUTE_PROBE.lsp`

Evidence status:
- Function family / concept: later-release documented; historical feature predates 18.1.
- Exact 18.1 runtime availability and signatures: pending user test.
- Save/reopen persistence: pending user test.
- Production integration: prohibited until probe passes in a disposable model.

Do not use Model Manager database-exchange functions (`sd-define-db-attribute`, etc.) for this local-file note feature; no Model Manager dependency has been established.
