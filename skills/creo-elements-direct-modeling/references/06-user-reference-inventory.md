# 06 – User-Provided Reference Inventory

This inventory was reconstructed from the user's Library and prior project conversations. It records what was actually found, not assumptions about manuals that may have existed elsewhere.

## Reviewed source materials

### 1. Annotation sheet/frame macros
- Library name: `Văn bản đã dán (1)(1).txt`
- Uploaded: 2026-10-16.
- Size/content: 12,294 characters, 467 lines.
- Duplicate Library result: same content also appeared as `Văn bản đã dán (1)(1).txt` under another reference.
- Header identifies macros for SD Annotation sheet functionality.
- Main functions: `Docu_set_current_sheet`, `Docu_set_current_sheet_by_subpart_id`, `Docu_inq_highest_sheet_name`, `Docu_load_frame`, `Docu_create_sheet`, `Docu_create_dummy_sheet`, `Docu_rename_sheet`, `Docu_replace_frame`, `Docu_move_frame`, frame name inquiry/rename helpers, `Docu_inq_frame_type`, `Docu_count_views_for_different_scale`.
- Summary: see `02-annotation-sheets-frames.md`.

### 2. Annotation BOM layout macros
- Library name: `Văn bản đã dán (1)(2).txt`
- Uploaded: 2026-10-17.
- Size/content: 14,836 characters, 580 lines.
- Duplicate Library result: same content also appeared under another reference.
- Header identifies macros for SD Annotation BOM layout customization.
- Main functions include `Docu_load_bom_layout`, error cleanup, `Docu_unload_all_bom_layouts`, layout enumeration, temporary configuration sheet creation, clone-to-sketch editing, accept/discard operations and BOM flag attach-point helpers.
- Summary: see `03-bom-layouts-and-drawing-macros.md`.

### 3. Sheet/view arrangement macros
- Library name: `Văn bản đã dán (1)(3).txt`
- Uploaded: 2026-10-17.
- Size/content: 10,805 characters, 311 lines.
- Duplicate Library result: same content appeared under another reference.
- Header: CoCreate Software GmbH Confidential; ME10 macro; Annotation package; author Jens Hoefflinger; created May 7, 1998.
- Main functions: `Arrange_sheets`, `Arrange_sheets2`, `Arrange_views`, plus a `Move_sheet` helper.
- Summary: see `03-bom-layouts-and-drawing-macros.md`.

### 4. Part Filter diagnostic prototype
- Library name: `H871_PART_FILTER_DIAG.lsp`
- Uploaded: 2026-11-13.
- Size: 3,389 bytes.
- Lisp diagnostic attempted recursive Assembly traversal and Density inquiries for `:contents`, `:instance`, `:realized`, wrote a report to the user's home directory, and exposed an `sd-defdialog`.
- It uses `HANDLER-CASE`, later reported undefined by the user. Treat as a failed prototype, not a working reference.
- Relevant lessons are in `04-part-filter-and-api-findings.md` and `05-debugging-and-validation.md`.

## Other earlier project work recovered from conversation history

### 2026-10-09 – measurement/export and command access
- User asked for a Modeling 18.1 tool for drawing/measurement/data export and Ribbon/menu access.
- A preliminary `measure_export.lsp` and `measure_export_avail_cmds.cmd` idea was supplied.
- Real geometry measurement APIs and 18.1 syntax were not verified. Treat as an unvalidated draft concept.

### 2026-10-16 – custom A4 Annotation frames
- User wanted multiple A4 frames available in the Annotation frame workflow.
- `am_sheet.m` was reviewed. It showed frame loading and sheet/frame lifecycle, not frame catalogue registration.
- Suggestions `docu-register-frame` and `am_customize` were not proven; user reported `am_customize` unavailable.
- Do not reuse these as established APIs.

### 2026-11-13/14 – Part Filter
- User tested Density API and Part predicates in Modeling 18.1; exact result is recorded in `04-part-filter-and-api-findings.md`.
- User-confirmed ver-01/02 behavior and all failed UI experiments are recorded in the same reference and `05-debugging-and-validation.md`.

## What was not found in the accessible Library inventory

- No standalone official PTC Creo Elements/Direct Modeling 18.1 Integration Kit PDF/manual was identified in the accessible Library file inventory/search.
- The reviewed text files are legacy Annotation/ME10 macro source, not a complete official API manual.
- There may be other manuals in older chats or external storage that are not present in the accessible Library. Do not claim the inventory is exhaustive beyond the files currently retrievable.

## Copyright/provenance rule
The legacy Annotation files contain CoCreate Software GmbH Confidential/copyright markings. Do not mirror full source text into this public GitHub repository. Keep only technical summaries, API names, design patterns and provenance metadata. If the user later supplies public redistribution permission or a public manual, record its license/source before mirroring.
