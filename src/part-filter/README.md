# Part Filter Source Index

## Preserved source references

- `ver-01/H871_PART_FILTER_VER_01.lsp`
- `ver-02/H871_PART_FILTER_VER_02.lsp` – preserve unchanged.
- `ver-03/H871_PART_FILTER_VER_03.lsp` – preserve unchanged; UICT/internal-tab reference.
- `ver-03-rebuild/H871_PART_FILTER_VER_03_REBUILD.lsp` – native Graphical Browser rebuild reference, separate from UICT ver-03.

The ver-03 rebuild currently opens Results but has a user-reported issue: only Part Name is visible although four column definitions exist. It is not accepted as complete.

## Shared diagnostic code

The Density API tests and Part Filter diagnostics are kept directly in this folder. They are source/test utilities, not released versions.

## Retired experiments

ver-04/ver-05/ver-06/ver-07 implementation files are not retained in the current tree. Their architecture attempts, user-reported failures, useful findings and prevention rules are documented in `docs/PART_FILTER_EXPERIMENT_HISTORY.md`.

Before editing, read the project handover and experiment history. Preserve the exact Density mapping, /1000 normalization and native Apply baseline unless a specific test proves a change is required.
