# Changelog

Notable repository changes. Detailed implementation and test evidence lives in `DEVELOPMENT_LOG.md`.

## [Unreleased]

- Added first exact Density Instance/Base Part filter implementation; pending Creo 18.1 load and functional testing.

## 2026-11-13 – Documentation baseline

- Initialized repository documentation structure.
- Added project context for Creo Elements/Direct Modeling 18.1.
- Recorded exact Instance/Base Part filter requirements.
- Recorded historical filter mismatch and LISP unexpected-end-of-input reports as unresolved investigations.
- Added development, decision, lesson, and issue tracking conventions.

## 2026-11-13 – Exact Density Instance/Base filter

- Added `H871_PART_FILTER.lsp` with two-field exact matching and recursive Assembly scanning.
- Preserved the uploaded diagnostic LISP unchanged.
- Added a backup branch before implementation.
- Static source structure check passed; Creo execution remains unverified.

- Updated Part Filter to pass exact matches through Creo's native GET_SELECTION selector; pending Creo 18.1 test.

- Replaced GET_SELECTION-based selection assumption with direct Structure Browser node selection using `:set-object-selection`; reports matching and selected counts separately. Pending Creo 18.1 verification.

- Part Filter UX direction changed to a dedicated BOM-like Graphical Browser result list; research completed, implementation pending 18.1 API verification.

## 2026-11-13 – Dedicated Part Filter results browser

- Replaced direct manipulation of the standard Structure Browser selection with a dedicated Graphical Browser results view.
- Added BOM-like columns: Part Name, Density Instance, Density Base, and Assembly Path.
- Added browser Select All, Clear Selection, and selected-row count actions.
- Preserved exact Density Instance/Base pair matching and text report output.
- Static parenthesis/string scan passed after correcting a missing close parenthesis in the browser constructor form.
- Creo 18.1 loading, row selection, double-click model navigation, and downstream Add to Drawlist behavior remain unverified.

## 2026-11-14 – Density value normalization and diagnostics

- Added numeric normalization for Density comparisons, including numeric strings such as `1` and `1.0`.
- Added first-30-Part raw Density value/type samples to the result report for diagnosing zero-match searches.
- Added `H871_DENSITY_DIAG.lsp` to inspect one known Part's Density inquiry results and instance/contents attributes in Creo 18.1.
- Static scan passed; Creo execution not performed.
