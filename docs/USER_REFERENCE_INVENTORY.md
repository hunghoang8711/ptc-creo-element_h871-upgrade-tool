# User-Provided Creo Reference Inventory

This is the top-level index of prior user-supplied Creo/Annotation material recovered from the user's Library and earlier project conversations. Full technical summaries are in `skills/creo-elements-direct-modeling/references/`.

## Recovered source files

| Date | Library file | Subject | Distinct content |
|---|---|---|---|
| 2026-10-16 | `Văn bản đã dán (1)(1).txt` | SD Annotation sheet/frame macros | 467 lines; frame load/create/replace/current-sheet functions |
| 2026-10-17 | `Văn bản đã dán (1)(2).txt` | SD Annotation BOM layout customization | 580 lines; layout load/store, edit/accept/discard, attach points |
| 2026-10-17 | `Văn bản đã dán (1)(3).txt` | Sheet/view arrangement macros | 311 lines; Arrange_sheets, Arrange_sheets2, Arrange_views |
| 2026-11-13 | `H871_PART_FILTER_DIAG.lsp` | Part Filter diagnostic prototype | 3,389 bytes; Density API diagnostic, later failed due unsupported HANDLER-CASE |

Duplicate copies/references of the three Annotation text files were found. The duplicate content is not counted as a separate source.

## Recovered prior conversation milestones

- **2026-10-09:** initial Modeling 18.1 request for drawing, measurement, data export, Ribbon/menu and manual command loading. Measurement API was not verified.
- **2026-10-16:** custom A4 Annotation frame investigation. Reviewed `am_sheet.m`; proved frame load/create/replace lifecycle, not UI frame catalogue registration. `am_customize` unavailable in user's environment; `docu-register-frame` was only a hypothesis.
- **2026-10-17:** BOM layout customization and sheet/view arrangement source analysis.
- **2026-11-13/14:** Part Filter Density API experiments, Graphical Browser behavior, row selection/Select All/native Apply, ver-02 mapping and failed multi-browser UI experiments.
- **2026-11-15:** one-main-branch policy and version-folder organization; consolidate skill package for continuation after chat loss.

## Important source handling
The Annotation macro sources contain CoCreate Software GmbH Confidential/copyright notices. This public repository stores summaries and reusable technical observations rather than full source dumps. The user's original Library files remain the source material.

## Search limitation
The accessible Library inventory did not surface a standalone official Creo Elements/Direct Modeling 18.1 Integration Kit PDF/manual. If the user previously supplied such a manual in another inaccessible location, it must be reintroduced or linked before its detailed content can be integrated. The current package does not pretend to have reviewed a manual that was not retrievable.
