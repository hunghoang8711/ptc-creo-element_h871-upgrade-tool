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
